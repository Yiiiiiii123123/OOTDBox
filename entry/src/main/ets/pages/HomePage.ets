import { WeatherService } from '../service/WeatherService'
import { router } from '@kit.ArkUI'
import { City } from '../utils/CityList'

@Entry
@Component
struct HomePage {
  @State temperature: number = 0
  @State weatherText: string = '加载中...'
  @State city: string = '厦门'
  @State cityCode: string = '350200'
  @State selectedTab: number = 0  // 0:首页 1:衣橱 2:搭配 3:我的

  @StorageLink('selectedCity') selectedCity: City | null = null

  private weatherService: WeatherService = new WeatherService()
  private isUpdatingWeather: boolean = false

  aboutToAppear() {
    AppStorage.setOrCreate('selectedCity', null)
  }

  onPageShow() {
    if (this.selectedCity) {
      console.info(`[城市选择] 新城市: ${this.selectedCity.city}, 代码: ${this.selectedCity.adcode}`)
      this.city = this.selectedCity.city
      this.cityCode = this.selectedCity.adcode
      this.loadWeather()
      this.selectedCity = null
    } else {
      if (this.cityCode === '350200' && this.weatherText === '加载中...') {
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

      if (requestCityCode !== this.cityCode) {
        console.warn(`[丢弃旧数据] 请求时城市: ${requestCityCode}, 当前城市: ${this.cityCode}`)
        return
      }

      if (result) {
        this.city = result.city
        this.temperature = result.temperature
        this.weatherText = `${result.weather}`
      } else {
        this.weatherText = `获取失败`
      }
    } catch (err) {
      console.error(`[请求异常] ${JSON.stringify(err)}`)
      if (requestCityCode === this.cityCode) {
        this.weatherText = `获取失败`
      }
    } finally {
      this.isUpdatingWeather = false
    }
  }

  onSelectCity() {
    router.pushUrl({ url: 'pages/CitySelectPage' })
  }

  // 底部Tab切换
  onTabChange(index: number) {
    this.selectedTab = index
    switch (index) {
      case 0:
        // 已在首页，无需跳转
        break
      case 1:
        router.pushUrl({ url: 'pages/ClosetPage' })
        break
      case 2:
        router.pushUrl({ url: 'pages/RecommendPage' })
        break
      case 3:
        router.pushUrl({ url: 'pages/PersonalPage' })
        break
    }
  }

  build() {
    Stack() {
      // 背景图片
      Image($r('app.media.background1'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      // 主要内容
      Column() {
        // 顶部区域：图标 + 城市名 + 切换按钮
        Row() {
          // 图标
          Image($r('app.media.cover'))
            .width(32)
            .height(32)
            .margin({ right: 8 })

          // 城市名
          Text(this.city)
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')

          // 切换城市按钮
          Button('切换')
            .width(60)
            .height(32)
            .fontSize(14)
            .backgroundColor('rgba(255, 255, 255, 0.3)')
            .fontColor('#FFFFFF')
            .borderRadius(16)
            .margin({ left: 12 })
            .onClick(() => {
              this.onSelectCity()
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 40 })
        .justifyContent(FlexAlign.Start)

        // 温度显示
        Text(`${this.temperature}°`)
          .fontSize(72)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .margin({ top: 40 })
          .shadow({ radius: 10, color: '#00000040' })

        // 天气描述
        Text(this.weatherText)
          .fontSize(24)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .margin({ top: 8 })
          .shadow({ radius: 8, color: '#00000040' })

        // 两个圆角矩形按钮
        Row() {
          // 进入衣橱按钮
          Button('进入衣橱')
            .width('45%')
            .height(50)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .backgroundColor('rgba(255, 255, 255, 0.5)')
            .fontColor('#FFFFFF')
            .borderRadius(25)
            .onClick(() => {
              router.pushUrl({ url: 'pages/ClosetPage' })
            })

          // 查看推荐按钮
          Button('查看推荐')
            .width('45%')
            .height(50)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .backgroundColor('rgba(255, 255, 255, 0.5)')
            .fontColor('#FFFFFF')
            .borderRadius(25)
            .onClick(() => {
              router.pushUrl({ url: 'pages/RecommendPage' })
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceEvenly)
        .margin({ top: 50, bottom: 30 })

        Blank()

        // 底部Tab栏
        Row() {
          // 首页
          this.buildTabItem('首页', 0, 'icon_home')

          // 衣橱
          this.buildTabItem('衣橱', 1, 'icon_closet')

          // 搭配
          this.buildTabItem('搭配', 2, 'icon_match')

          // 我的
          this.buildTabItem('我的', 3, 'icon_profile')
        }
        .width('100%')
        .height(70)
        .backgroundColor('rgba(255, 255, 255, 0.2)')
        .borderRadius({ topLeft: 20, topRight: 20 })
        .justifyContent(FlexAlign.SpaceAround)
        .padding({ bottom: 10 })
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  // Tab项构建
  @Builder
  buildTabItem(label: string, index: number, iconName: string) {
    Column() {
      Image($r(`app.media.${iconName}`))
        .width(24)
        .height(24)
        .opacity(this.selectedTab === index ? 1 : 0.6)

      Text(label)
        .fontSize(12)
        .fontColor('#FFFFFF')
        .opacity(this.selectedTab === index ? 1 : 0.6)
        .margin({ top: 4 })
    }
    .onClick(() => {
      this.onTabChange(index)
    })
  }
}