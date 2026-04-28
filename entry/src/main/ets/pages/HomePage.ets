import { WeatherService } from '../service/WeatherService'
import { router } from '@kit.ArkUI'
import { City } from '../utils/CityList'
import { APP_WALLPAPERS } from '../utils/BackgroundList';
import { Clothing } from '../model/Clothing';
import { PreferenceRepo } from '../repository/PreferenceRepo';
import { common } from '@kit.AbilityKit';
import { ClothingService } from '../service/ClothingService';

//首页

@Entry
@Component
struct HomePage {
  @State temperature: number = 0
  @State weatherText: string = '加载中...'
  @State city: string = '厦门'
  @State cityCode: string = '350200'
  @StorageProp('wallpaper_index') wallpaperIndex: number = 0;

  @StorageLink('selectedCity') selectedCity: City | null = null

  // 🌟 核心：监听全局广播的“今日穿搭”数据
  @StorageLink('todayOutfit') todayOutfit: Clothing[] = []

  private weatherService: WeatherService = new WeatherService()
  private isUpdatingWeather: boolean = false

  private clothingService = new ClothingService();

  aboutToAppear() {
    this.city = AppStorage.get<string>('currentCityName') || '厦门';
    this.cityCode = AppStorage.get<string>('currentCityCode') || '350200';

    AppStorage.setOrCreate('selectedCity', null)
    this.loadTodayOutfit();
  }

  onPageShow() {
    if (this.selectedCity) {
      console.info(`[城市选择] 新城市: ${this.selectedCity.city}, 代码: ${this.selectedCity.adcode}`)
      this.city = this.selectedCity.city
      this.cityCode = this.selectedCity.adcode
      this.loadWeather()
      this.selectedCity = null
    } else {
      if (this.weatherText === '加载中...') {
        this.loadWeather()
      }
    }
  }

  async loadWeather() {
    if (this.isUpdatingWeather) {
      console.info('[防抖] 已有请求在进行中，跳过')
      return
    }

    this.isUpdatingWeather = true
    const requestCityCode = this.cityCode
    this.weatherText = '加载中...'

    try {
      const result = await this.weatherService.getWeather(this.cityCode)
      if (requestCityCode !== this.cityCode) return;

      if (result) {
        this.city = result.city
        this.temperature = result.temperature
        this.weatherText = `${result.weather}`

        AppStorage.setOrCreate('currentCityName', result.city);
        AppStorage.setOrCreate('currentCityCode', this.cityCode);
        AppStorage.setOrCreate('currentTemp', result.temperature);
        AppStorage.setOrCreate('currentWeatherText', result.weather);
      } else {
        this.weatherText = `获取失败`
      }
    } catch (err) {
      if (requestCityCode === this.cityCode) {
        this.weatherText = `获取失败`
      }
    } finally {
      this.isUpdatingWeather = false
    }
  }

  // 今日穿搭加载方法
  async loadTodayOutfit() {
    let context = getContext(this) as common.UIAbilityContext;

    // 1. 从偏好设置获取今天的 ID 列表
    let ids = await PreferenceRepo.getTodayOutfitIds(context);

    if (ids.length > 0) {
      let outfitClothes: Clothing[] = [];

      // 2. 拿着 ID 去数据库逐个捞出真实的衣服
      for (let i = 0; i < ids.length; i++) {
        let item: Clothing | null = await this.clothingService.getClothingById(ids[i]);
        if (item) {
          outfitClothes.push(item);
        }
      }

      // 3. 将装满真实衣服的数组广播出去，面板瞬间点亮！
      AppStorage.setOrCreate('todayOutfit', outfitClothes);
    } else {
      // 如果没有数据，或者过期了，就给个空数组
      AppStorage.setOrCreate('todayOutfit', []);
    }
  }

  onSelectCity() {
    router.pushUrl({ url: 'pages/CitySelectPage' })
  }

  build() {
    Stack() {
      // 背景图片
      Image(APP_WALLPAPERS[this.wallpaperIndex])
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      // 主要内容
      Column() {
        // 顶部区域：左侧（图标+城市名+切换按钮）+ 右上角"我的"图标
        Row() {
          Row() {
            Image($r('app.media.icon_location')).width(28).height(28).margin({ right: 6 })
            Text(this.city).fontSize(18).fontWeight(FontWeight.Medium).fontColor('#333333')
            Button('>')
              .width(50).height(28).fontSize(16).fontWeight(FontWeight.Bold)
              .backgroundColor(Color.Transparent).fontColor('#333333')
              .borderRadius(4).margin({ left: 4 })
              .onClick(() => this.onSelectCity())
          }.layoutWeight(1).justifyContent(FlexAlign.Start)

          Column() {
            Image($r('app.media.icon_profile')).width(28).height(28)
          }.onClick(() => router.pushUrl({ url: 'pages/PersonalPage' }))
        }
        .width('100%').padding({ left: 10, right: 20, top: 20 }).alignItems(VerticalAlign.Center)

        // 温度显示
        Text(`${this.temperature}℃`)
          .fontSize(72).fontWeight(FontWeight.Bold).fontColor('#333333')
          .margin({ top: 60 }) // 稍微上移给中间面板留空间
          .shadow({ radius: 10, color: '#00000020' })

        // 天气描述
        Text(this.weatherText)
          .fontSize(24).fontWeight(FontWeight.Medium).fontColor('#333333')
          .margin({ top: 8 })
          .shadow({ radius: 8, color: '#00000020' })

        // 今日穿搭展示面板
        this.buildTodayOutfitPanel()

        // 使用弹性留白，自动把底部的按钮顶下去
        Blank()

        // 两个卡片形按钮
        Row() {
          Button() {
            Column() {
              Text('我的衣橱').fontSize(22).fontWeight(FontWeight.Medium).fontColor('#333333')
            }.padding({ top: 20, bottom: 20 })
          }
          .width('42%').height(80)
          .backgroundColor('rgba(255, 255, 255, 0.65)').borderRadius(16).type(ButtonType.Normal)
          .shadow({ radius: 8, color: '#00000020' })
          .onClick(() => router.pushUrl({ url: 'pages/ClosetPage' }))

          Button() {
            Column() {
              Text('穿搭推荐').fontSize(22).fontWeight(FontWeight.Medium).fontColor('#333333')
            }.padding({ top: 20, bottom: 20 })
          }
          .width('42%').height(80)
          .backgroundColor('rgba(255, 255, 255, 0.65)').borderRadius(16).type(ButtonType.Normal)
          .shadow({ radius: 8, color: '#00000020' })
          .onClick(() => router.pushUrl({ url: 'pages/RecommendPage' }))
        }
        .width('100%').justifyContent(FlexAlign.SpaceEvenly).margin({ bottom: 40 })

      }
      .width('100%').height('100%')
    }
    .width('100%').height('100%')
  }

  // 独立出来的面板构建器：今日完美穿搭面板 (固定高度+内部滑动版)
  @Builder buildTodayOutfitPanel() {
    Column() {
      // 标题
      Text('✨ 今日完美穿搭 ✨')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333')
        .margin({ bottom: 15 })

      // 判断有没有数据
      if (this.todayOutfit && this.todayOutfit.length > 0) {
        // 🌟 核心修改 1：用 Scroll 包裹内部列表，开启内部滑动
        Scroll() {
          // 使用 Flex 自动折行排列衣服
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center }) {
            ForEach(this.todayOutfit, (item: Clothing) => {
              Image(item.imageUri)
                .width(75)
                .height(75)
                .borderRadius(10)
                .margin(6) // 图片间距
                .objectFit(ImageFit.Cover)
            })
          }
          .width('100%')
        }
        .width('100%')
        .height(280) // 🌟 核心修改 2：固定内容区的高度
        .scrollBar(BarState.Auto) // 衣服多的时候自动显示滚动条
        .edgeEffect(EdgeEffect.Spring) // 滑到边缘的弹簧效果，更丝滑

      } else {
        // 没数据：显示引导文案
        Column({ space: 8 }) {
          Text('👗').fontSize(40)
          Text('快去穿搭吧~').fontSize(16).fontColor('#666')
        }
        .height(280) // 🌟 保持和上面一样的固定高度，确保有无数据时面板大小一模一样
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('85%')
    .height(350) // 🌟 核心修改 3：给整个大面板锁定一个固定的总高度！
    .padding(20)
    .margin({ top: 30 })
    .backgroundColor('rgba(255, 255, 255, 0.65)') // 半透明白色背景
    .borderRadius(20)
    .shadow({ radius: 10, color: 'rgba(0,0,0,0.05)', offsetY: 4 })
  }
}