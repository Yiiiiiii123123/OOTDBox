import router from '@ohos.router';
import util from '@ohos.util';
import { Clothing } from '../model/Clothing';
import { ClothingService } from '../service/ClothingService';
import { COLOR_OPTIONS, WARMTH_OPTIONS, CATEGORY_UI_DATA, ClothingColor } from '../utils/ClothingConfig';
import { ClothingUtils } from '../utils/ClothingConfig';
import { ColorOption, WarmthOption } from '../utils/ClothingConfig';

@Entry
@Component
struct ConfirmPage {
  private params = router.getParams() as Record<string, Object>;
  @State imageUri: string = this.params?.['imageUri'] as string || '';
  @State isEditMode: boolean = this.params?.['editMode'] as boolean || false;
  @State oldId: string = this.params?.['oldId'] as string || '';

  // 状态绑定
  @State selectedSubLabel: string = 'T恤';
  @State selectedColor: ClothingColor = ClothingColor.BLACK;
  @State selectedWarmth: number = 6;

  private service: ClothingService = new ClothingService();

  aboutToAppear() {
    if (this.isEditMode && this.params?.['clothingItem']) {
      const item = this.params['clothingItem'] as Clothing;
      this.selectedSubLabel = ClothingUtils.getLabelBySubCategory(item.subCategory);
      this.selectedColor = item.color;
      this.selectedWarmth = item.warmthIndex;
    }
  }

  async handleSave() {
    const subEnum = ClothingUtils.getSubCategoryByLabel(this.selectedSubLabel);
    if (this.isEditMode) {
      const updatedItem = new Clothing(this.oldId, this.imageUri, subEnum, this.selectedWarmth, this.selectedColor);
      const success = await this.service.updateClothing(updatedItem);
      if (success) router.back();
    } else {
      const newId = util.generateRandomUUID();
      const newItem = new Clothing(newId, this.imageUri, subEnum, this.selectedWarmth, this.selectedColor);
      const success = await this.service.addClothing(newItem);
      if (success) router.back();
    }
  }

  build() {
    Column() {
      // --- 顶部导航栏 ---
      Row() {
        Text('取消').fontSize(16).fontColor('#666').onClick(() => router.back())
        Text(this.isEditMode ? '修改衣物信息' : '录入新衣物').fontSize(18).fontWeight(FontWeight.Bold)
        Text('完成').fontSize(16).fontColor('#007AFF').fontWeight(FontWeight.Bold).onClick(() => this.handleSave())
      }
      .width('100%').height(56).padding({ left: 20, right: 20 }).justifyContent(FlexAlign.SpaceBetween)

      Scroll() {
        Column({ space: 20 }) {
          // --- 图片预览区 ---
          Image(this.imageUri)
            .width(200).height(200)
            .borderRadius(20).objectFit(ImageFit.Cover)
            .shadow({ radius: 15, color: 'rgba(0,0,0,0.1)' })
            .margin({ top: 10, bottom: 10 })

          // --- 卡片 1：款式选择 ---
          Column({ space: 8 }) {
            Text('款式分类').fontSize(13).fontWeight(FontWeight.Medium).fontColor('#666').width('100%')
            TextPicker({ range: CATEGORY_UI_DATA })
              .height(110).width('100%')
              .onChange((value: string | string[]) => {
                if (Array.isArray(value)) this.selectedSubLabel = value[1];
              })
          }
          .padding(10).width('90%').backgroundColor('#F9F9F9').borderRadius(16)

          // --- 卡片 2：主色调选择 ---
          Column({ space: 15 }) {
            Text('主色调').fontSize(13).fontWeight(FontWeight.Medium).fontColor('#666').width('100%')

            // 使用 Flex 实现自动换行的色板
            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
              ForEach(COLOR_OPTIONS, (item: ColorOption) => {
                Column({ space: 6 }) {
                  Circle({ width: 34, height: 34 })
                    .fill(item.hex)
                      // 🌟 选中的圆圈增加外发光和粗边框效果
                    .border({
                      width: this.selectedColor === item.value ? 3 : 1,
                      color: this.selectedColor === item.value ? '#007AFF' : '#E0E0E0'
                    })
                    .shadow(this.selectedColor === item.value ? { radius: 8, color: item.hex } : { radius: 0 })
                    .onClick(() => this.selectedColor = item.value)
                  Text(item.label)
                    .fontSize(12)
                    .fontColor(this.selectedColor === item.value ? '#333' : '#888')
                    .fontWeight(this.selectedColor === item.value ? FontWeight.Medium : FontWeight.Normal)
                }
                // 🌟 核心修改：将 20% 改为 14.28%，完美平分 7 列
                .width('14.28%')
                .margin({ bottom: 12 })
              })
            }.width('100%')
          }
          .padding(10).width('90%').backgroundColor('#F9F9F9').borderRadius(16)

          // --- 卡片 3：保暖指数 ---
          Column({ space: 12 }) {
            Text('保暖厚度描述').fontSize(13).fontWeight(FontWeight.Medium).fontColor('#666').width('100%')
            Flex({ justifyContent: FlexAlign.SpaceBetween }) {
              ForEach(WARMTH_OPTIONS, (item: WarmthOption) => {
                Text(item.label)
                  .fontSize(13)
                  .height(36).layoutWeight(1).margin({ left: 4, right: 4 })
                  .textAlign(TextAlign.Center)
                  .backgroundColor(this.selectedWarmth === item.value ? '#007AFF' : Color.White)
                  .fontColor(this.selectedWarmth === item.value ? Color.White : '#333')
                  .borderRadius(8)
                  .border({ width: this.selectedWarmth === item.value ? 0 : 0.5, color: '#E0E0E0' })
                  .onClick(() => this.selectedWarmth = item.value)
              })
            }.width('100%')
          }
          .padding(10).width('90%').backgroundColor('#F9F9F9').borderRadius(16)

          Blank().height(20)
        }
        .width('100%')
      }.layoutWeight(1).scrollBar(BarState.Off)
    }
    .width('100%').height('100%').backgroundColor(Color.White)
  }
}