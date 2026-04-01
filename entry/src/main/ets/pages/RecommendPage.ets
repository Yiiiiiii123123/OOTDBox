import { Clothing, MainCategory } from '../model/Clothing';
import { ClothingRepo } from '../repository/ClothingRepo';
import { RecommendService } from '../service/RecommendService';
import { ClothingService } from '../service/ClothingService';
import { WeatherService } from '../service/WeatherService';
import { ClothingUtils } from '../utils/ClothingUtils';
import { City } from '../utils/CityList';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import dataPreferences from '@ohos.data.preferences'; // 🌟 用于小组件数据共享

@Entry
@Component
struct RecommendPage {
  // 🌟 使用 @StorageProp 监听广播站，只要 HomePage 更新了，这里会自动变
  @StorageProp('currentCityName') city: string = '未知'
  @StorageProp('currentCityCode') cityCode: string = '350200'
  @StorageProp('currentTemp') @Watch('onTempChange') temperature: number = 20
  @StorageProp('currentWeatherText') weatherText: string = '获取中'

  // 监听全局选中的城市
  @StorageLink('selectedCity') selectedCity: City | null = null

  @State clothingList: Clothing[] = []
  @State outfit: Clothing[] = []
  @State isGenerating: boolean = false
  @State isFavorited: boolean = false

  private repo: ClothingRepo = new ClothingRepo()
  private weatherService: WeatherService = new WeatherService()
  private recommendService: RecommendService = new RecommendService()
  private clothingService: ClothingService = new ClothingService()
  private isUpdatingWeather: boolean = false

  onTempChange() {
    // 逻辑：每当主页同步过来的温度变化时，就自动跑一遍推荐算法
    this.generateOutfit();
  }

  aboutToAppear() {
    this.initCityData(); // 1. 先同步城市
    this.loadData();     // 2. 加载衣服
    this.loadWeather();  // 3. 获取天气
  }

  onPageShow() {
    // 🌟 如果在其他页面切换了城市，返回或进入该页面时立即刷新
    this.initCityData();
  }

  // 🌟 新增：城市数据初始化方法
  private initCityData() {
    // 从 AppStorage 尝试获取持久化的城市信息，如果没有则保持默认
    // 注意：HomePage 选择城市后应存入 AppStorage
    if (this.selectedCity) {
      this.city = this.selectedCity.city;
      this.cityCode = this.selectedCity.adcode;
      // 切换了城市后，需要重新拉取天气
      this.loadWeather();
    }
  }

  async loadWeather() {
    if (this.isUpdatingWeather) return;
    this.isUpdatingWeather = true;

    try {
      const result = await this.weatherService.getWeather(this.cityCode);
      if (result) {
        this.temperature = result.temperature;
        this.weatherText = result.weather;
        this.city = result.city;
        // 天气好了，立即生成推荐
        this.generateOutfit();
      }
    } catch (err) {
      this.weatherText = '获取失败';
    } finally {
      this.isUpdatingWeather = false;
    }
  }

  async loadData() {
    const list = await this.repo.getAll();
    this.clothingList = list ?? [];
  }

  async generateOutfit() {
    if (this.clothingList.length === 0) return;
    this.isGenerating = true;
    this.isFavorited = false; // 换一套时重置状态

    setTimeout(() => {
      this.outfit = this.recommendService.generate(this.temperature, this.clothingList);
      this.isGenerating = false;
    }, 600);
  }

  // --- 🌟 收藏逻辑：增加异步等待和成功判断 ---
  async toggleFavorite() {
    if (this.outfit.length === 0 || this.isGenerating) return;

    if (!this.isFavorited) {
      // 🌟 传入 outfit 和当前的气温 temperature
      const success = await this.clothingService.saveFavoriteOutfit(this.outfit, this.temperature);

      if (success) {
        this.isFavorited = true;
        promptAction.showToast({ message: '✨ 收藏成功！' });
      } else {
        promptAction.showToast({ message: '保存失败，请检查数据库' });
      }
    }
  }

  async confirmOutfit() {
    if (this.outfit.length === 0) return;

    try {
      // 1. 同步数据到小组件首选项 (Preferences)
      const preferences = await dataPreferences.getPreferences(getContext(this), 'outfit_storage');
      // 把图片路径拼成字符串 "path1,path2..."
      const imgPaths = this.outfit.map(item => item.imageUri).join(',');

      await preferences.put('today_images', imgPaths);
      await preferences.put('today_temp', this.temperature + '℃');
      await preferences.flush(); // 强制刷盘

      // 2. (可选) 增加这几件衣服的穿着次数 wearCount
      // await this.clothingService.increaseWearCount(this.outfit);

      promptAction.showToast({ message: '穿搭已选定并同步至桌面' });

      // 3. 最后再返回
      setTimeout(() => {
        router.back();
      }, 500);

    } catch (err) {
      console.error('ConfirmOutfitError', JSON.stringify(err));
      router.back(); // 出错也返回，避免卡死
    }
  }

  build() {
    Stack() {
      Image($r('app.media.background1'))
        .width('100%').height('100%').objectFit(ImageFit.Cover).opacity(0.4)

      Column() {
        // 顶部
        Row() {
          Button('返回')
            .width(70).height(36).backgroundColor('rgba(0,0,0,0.05)').fontColor('#333')
            .onClick(() => router.back())

          Blank()

          Column() {
            Row() {
              Text(this.city).fontSize(14).fontColor('#666')
              Text(' · ').fontColor('#999')
              Text(this.weatherText).fontSize(14).fontColor('#666')
            }
            Text(`${this.temperature}℃`).fontSize(32).fontWeight(FontWeight.Bold)
          }.alignItems(HorizontalAlign.End)
        }
        .width('90%').padding({ top: 48, bottom: 20 })

        if (this.outfit.length === 0) {
          this.buildEmptyState()
        } else {
          // 收藏工具条
          Row() {
            Text('智能推荐结果').fontSize(16).fontWeight(FontWeight.Medium).fontColor('#444')
            // 🌟 动态切换图标
            Image(this.isFavorited ? $r('app.media.ic_favorite_filled') : $r('app.media.ic_favorite_border'))
              .width(30).height(30)
              .scale({ x: this.isFavorited ? 1.1 : 1.0, y: this.isFavorited ? 1.1 : 1.0 }) // 点亮时稍微放大
              .animation({ duration: 200, curve: Curve.EaseInOut })
              .onClick(() => this.toggleFavorite())
          }
          .width('90%').justifyContent(FlexAlign.SpaceBetween).margin({ bottom: 15 })

          Scroll() {
            Column({ space: 12 }) {
              ForEach(this.outfit, (item: Clothing) => {
                this.buildClothingItem(item)
              })
            }.width('100%').padding({ bottom: 20 })
          }.layoutWeight(1)
        }

        if (this.outfit.length > 0) {
          Row({ space: 15 }) {
            Button('换一套')
              .layoutWeight(1).height(50).borderRadius(25)
              .backgroundColor('rgba(255,255,255,0.8)').fontColor('#333')
              .onClick(() => this.generateOutfit())

            Button('就穿这套')
              .layoutWeight(1).height(50).borderRadius(25)
              .backgroundColor('#007AFF').fontColor(Color.White)
              .onClick(() => {
                // 🌟 改为调用这个异步方法
                this.confirmOutfit();
              })
          }
          .width('90%').margin({ bottom: 40 })
        }
      }
      .width('100%').height('100%')
    }
  }

  @Builder buildClothingItem(item: Clothing) {
    Row() {
      Image(item.imageUri)
        .width(85).height(85).borderRadius(12).objectFit(ImageFit.Cover)

      Column({ space: 6 }) {
        Text(ClothingUtils.getLabelBySubCategory(item.subCategory))
          .fontSize(18).fontWeight(FontWeight.Bold)

        Row({ space: 8 }) {
          Circle({ width: 10, height: 10 }).fill(ClothingUtils.getColorHex(item.color))
          Text(ClothingUtils.getColorLabel(item.color)).fontSize(12).fontColor('#666')
          Text(`🔥 保暖 ${item.warmthIndex}`).fontSize(12).fontColor('#888')
        }
      }
      .margin({ left: 15 }).layoutWeight(1).alignItems(HorizontalAlign.Start)

      Text(ClothingUtils.getMainCategoryLabel(item.mainCategory))
        .fontSize(10).fontColor('#007AFF').padding({ left: 6, right: 6, top: 2, bottom: 2 })
        .border({ width: 1, color: '#007AFF' }).borderRadius(4)
    }
    .width('95%').padding(12).backgroundColor('rgba(255,255,255,0.95)').borderRadius(16)
  }

  @Builder buildEmptyState() {
    Column({ space: 20 }) {
      Text('👗').fontSize(80)
      Text(this.isGenerating ? '正在挑选...' : '衣橱数据不足或尚未加载')
        .fontColor('#999')
    }.justifyContent(FlexAlign.Center).layoutWeight(1)
  }
}