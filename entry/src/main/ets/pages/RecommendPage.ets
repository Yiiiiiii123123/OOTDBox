import { Clothing, MainCategory } from '../model/Clothing';
import { ClothingRepo } from '../repository/ClothingRepo';
import { RecommendService } from '../service/RecommendService';
import { ClothingService } from '../service/ClothingService';
import { WeatherService } from '../service/WeatherService';
import { ClothingUtils } from '../utils/ClothingConfig';
import { City } from '../utils/CityList';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import dataPreferences from '@ohos.data.preferences'; // 🌟 用于小组件数据共享
import formProvider from '@ohos.app.form.formProvider';
import formBindingData from '@ohos.app.form.formBindingData';
import fs from '@ohos.file.fs'; // 🌟 引入文件系统，用于读取相册图片
import { APP_WALLPAPERS } from '../utils/BackgroundList';
import { RecommendationService } from '../service/RecommendationService';


@Entry
@Component
struct RecommendPage {
  // 🌟 使用 @StorageProp 监听广播站，只要 HomePage 更新了，这里会自动变
  @StorageProp('currentCityName') city: string = '未知'
  @StorageProp('currentCityCode') cityCode: string = '350200'
  @StorageProp('currentTemp') @Watch('onTempChange') temperature: number = 20
  @StorageProp('currentWeatherText') weatherText: string = '获取中'

  @StorageProp('wallpaper_index') wallpaperIndex: number = 0;

  // 监听全局选中的城市
  @StorageLink('selectedCity') selectedCity: City | null = null

  @State clothingList: Clothing[] = []
  @State outfit: Clothing[] = []
  @State isGenerating: boolean = false
  @State isFavorited: boolean = false

  private repo: ClothingRepo = new ClothingRepo()
  private weatherService: WeatherService = new WeatherService()
  private recommendService: RecommendationService = new RecommendationService()
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

  // 🌟 将生成搭配方法升级为异步调用新算法
  async generateOutfit() {
    // 检查是否有衣服，如果没有直接返回
    if (!this.clothingList || this.clothingList.length === 0) {
      promptAction.showToast({ message: '衣橱太少啦，无法推荐~' });
      return;
    }

    this.isGenerating = true;
    this.isFavorited = false; // 换一套时重置状态

    // 稍微延迟一下，给用户一个“正在思考算法”的视觉缓冲，体验更好
    setTimeout(async () => {
      try {
        // 🌟 调用新的核心推荐算法
        const result = await this.recommendService.getBestRecommendation(this.temperature);

        if (result && result.clothes.length > 0) {
          // 将算法计算出的实体衣服数组赋值给 UI 绑定的 outfit 变量
          this.outfit = result.clothes;
          // (可选) 如果你需要马上就把这个 combination 存库，也可以在这里操作
          // this.currentCombination = result.combination;
        } else {
          // 如果算法返回 null，说明找不齐必需的衣服（比如没鞋子）
          this.outfit = [];
          promptAction.showToast({ message: '当前温度下找不到合适的搭配，去买新衣服吧！' });
        }
      } catch (error) {
        console.error('推荐算法执行失败:', error);
        promptAction.showToast({ message: '推荐过程出错' });
      } finally {
        this.isGenerating = false;
      }
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

  /**
   * 🌟 确认穿这套衣服的打卡逻辑
   * @param selectedOutfit 包含当前搭配中所有衣服单品的数组
   */
  async confirmOutfit(selectedOutfit: Clothing[]) {
    try {
      // 1. 基础校验
      if (!selectedOutfit || selectedOutfit.length === 0) {
        promptAction.showToast({ message: '当前搭配为空哦~' });
        return;
      }

      // 给用户一个正在处理的视觉反馈
      promptAction.showToast({ message: 'OOTD 记录中...' });

      // 2. 遍历当前穿搭中的每一件衣服，更新其穿着次数
      for (let i = 0; i < selectedOutfit.length; i++) {
        let item = selectedOutfit[i];

        // 🌟 核心：将穿着次数 + 1
        // 使用 (item.wearCount || 0) 是为了防止旧数据没有这个字段时报错 NaN
        item.wearCount = (item.wearCount || 0) + 1;

        // 进阶拓展：如果你以后想做更精准的“吃灰预警”，这里可以加一行记录最后一次穿着的时间戳
         item.lastWornDate = new Date().getTime();

        // 3. 调用 Service 层更新到本地数据库
        await this.clothingService.updateClothing(item);
      }

      // 4. 成功反馈与闭环跳转
      promptAction.showToast({ message: '打卡成功！衣服数据已更新 ✨' });

      // 延迟 500ms 后返回上一页或者跳转回主页
      setTimeout(() => {
        router.back();
      }, 500);

    } catch (error) {
      console.error('更新穿搭次数失败:', error);
      promptAction.showToast({ message: '打卡失败，请重试' });
    }
  }

  build() {
    Stack() {
      Image(APP_WALLPAPERS[this.wallpaperIndex])
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
                this.confirmOutfit(this.outfit);
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