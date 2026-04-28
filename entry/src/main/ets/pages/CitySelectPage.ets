import router from '@ohos.router';
import { groupedCities, alphabets, City, CityGroup } from '../utils/CityList';
import { APP_WALLPAPERS } from '../utils/BackgroundList';
import dataPreferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { PreferenceRepo } from '../repository/PreferenceRepo';

//城市选择页

@Entry
@Component
export struct CitySelectPage {
  @StorageProp('wallpaper_index') wallpaperIndex: number = 0;
  @StorageProp('selectedCity') selectedCity: City | null = null;

  private scroller: Scroller = new Scroller();

  @Builder itemHead(text: string) {
    Text(text)
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
      .fontColor('#007AFF')
      .backgroundColor('#F5F7FA')
      .width('100%')
      .padding({ left: 20, top: 4, bottom: 4 })
  }

  // 抽离出来的独立异步方法，逻辑清清爽爽，一眼就能找到！
  async handleCitySelect(item: City) {
    // 1. 存入内存 (UI 层的活)
    AppStorage.setOrCreate('selectedCity', item);

    // 2. 存入硬盘 (派发给 Service 层去干)
    let context = getContext(this) as common.UIAbilityContext;
    await PreferenceRepo.saveCity(context, item.city, item.adcode);

    // 3. 页面返回 (UI 层的活)
    router.back();
  }

  build() {
    Stack() {
      // --- 底层：全局动态壁纸 ---
      Image(APP_WALLPAPERS[this.wallpaperIndex])
        .width('100%').height('100%').objectFit(ImageFit.Cover).opacity(0.65)

      // --- 顶层：UI 内容 ---
      Column() {
        // 顶部导航栏
        Row() {
          Button('< 返回')
            .backgroundColor(Color.Transparent).fontColor('#333')
            .fontSize(16).fontWeight(FontWeight.Medium).padding({ left: 0 })
            .onClick(() => router.back())
          Blank()
          Text('选择城市').fontSize(20).fontWeight(FontWeight.Bold).fontColor('#333')
          Blank()
          Text('').width(60)
        }
        .width('100%').height(56).padding({ left: 20, right: 20 }).margin({ top: 10, bottom: 10 })

        // 城市列表大卡片
        Column() {
          Stack({ alignContent: Alignment.End }) {
            // 左侧主体：分组列表
            List({ scroller: this.scroller }) {
              ForEach(groupedCities, (group: CityGroup) => {
                ListItemGroup({ header: this.itemHead(group.letter) }) {
                  ForEach(group.cities, (item: City) => {
                    ListItem() {
                      Row() {
                        Text(item.city)
                          .fontSize(16)
                          .fontWeight(this.selectedCity?.adcode === item.adcode ? FontWeight.Bold : FontWeight.Normal)
                          .fontColor(this.selectedCity?.adcode === item.adcode ? '#007AFF' : '#333')

                        Blank() // 自动撑开，把打勾推到最右侧

                        if (this.selectedCity?.adcode === item.adcode) {
                          Text('✓').fontColor('#007AFF').fontSize(16).fontWeight(FontWeight.Bold)
                        }
                      }
                      .width('100%').height(56).padding({ left: 20, right: 40 })
                    }
                    .stateStyles({
                      pressed: { .backgroundColor('rgba(0,0,0,0.05)') },
                      normal: { .backgroundColor(Color.Transparent) }
                    })
                    .onClick(() => {
                      this.handleCitySelect(item);
                    })
                  }, (item: City) => item.adcode)
                }
                .divider({ strokeWidth: 0.5, color: '#EAEAEA', startMargin: 20, endMargin: 40 })
              }, (group: CityGroup) => group.letter)
            }
            .width('100%')
            .height('100%')
            .scrollBar(BarState.Off)
            .sticky(StickyStyle.Header) // 吸顶效果！

            // 右侧控件
            AlphabetIndexer({ arrayValue: alphabets, selected: 0 })
              .color('#666')
              .selectedColor('#666')
              .selectedBackgroundColor(Color.Transparent)
              .font({ size: 12 })
              .selectedFont({ size: 12, weight: FontWeight.Normal })
              .usingPopup(false) // 关掉气泡
              .itemSize(20)
              .margin({ right: 4 })
              .onSelect((index: number) => {
                this.scroller.scrollToIndex(index);
              })
          }
          .width('100%')
          .layoutWeight(1)
        }
        .width('92%')
        .layoutWeight(1)
        .backgroundColor('rgba(255, 255, 255, 0.85)')
        .borderRadius({ topLeft: 24, topRight: 24 })
        .padding({ top: 10 })
      }
      .width('100%').height('100%')
    }
  }
}