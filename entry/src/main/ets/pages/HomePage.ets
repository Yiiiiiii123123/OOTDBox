import { WeatherService } from '../service/WeatherService'
import { router } from '@kit.ArkUI'
import { City } from '../utils/CityList'
import { APP_WALLPAPERS } from '../utils/BackgroundList';

@Entry
@Component
struct HomePage {
  @State temperature: number = 0
  @State weatherText: string = '加载中...'
  @State city: string = '厦门'
  @State cityCode: string = '350200'
  @StorageProp('wallpaper_index') wallpaperIndex: number = 0;

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

        // 🌟 【新增关键代码】：将数据同步到全局广播站
        AppStorage.setOrCreate('currentCityName', result.city);
        AppStorage.setOrCreate('currentCityCode', this.cityCode);
        AppStorage.setOrCreate('currentTemp', result.temperature);
        AppStorage.setOrCreate('currentWeatherText', result.weather);

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
          // 左侧：定位图标 + 城市名 + 切换按钮
          Row() {
            // 定位图标
            Image($r('app.media.icon_location'))
              .width(28)
              .height(28)
              .margin({ right: 6 })

            // 城市名
            Text(this.city)
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')

            // 切换城市按钮（无背景，小圆角）
            Button('>')
              .width(50)
              .height(28)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .backgroundColor(Color.Transparent)
              .fontColor('#333333')
              .borderRadius(4)
              .margin({ left: 4 })
              .onClick(() => {
                this.onSelectCity()
              })
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Start)

          // 右上角："我的"图标按钮（无底色）
          Column() {
            Image($r('app.media.icon_profile'))
              .width(28)
              .height(28)
          }
          .onClick(() => {
            router.pushUrl({ url: 'pages/PersonalPage' })
          })
        }
        .width('100%')
        .padding({ left: 10, right: 20, top: 20 })
        .alignItems(VerticalAlign.Center)

        // 温度显示
        Text(`${this.temperature}℃`)
          .fontSize(72)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ top: 100 })
          .shadow({ radius: 10, color: '#00000020' })

        // 天气描述
        Text(this.weatherText)
          .fontSize(24)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .margin({ top: 8 })
          .shadow({ radius: 8, color: '#00000020' })

        // 两个卡片形按钮
        Row() {
          // 进入衣橱按钮（卡片样式）
          Button() {
            Column() {
              //Image($r('app.media.icon_closet')).width(48).height(48).margin({ bottom: 8 })

              Text('我的衣橱').fontSize(22).fontWeight(FontWeight.Medium).fontColor('#333333')
            }
            .padding({ top: 20, bottom: 20 })
          }
          .width('42%')
          .height(80)
          .backgroundColor('rgba(255, 255, 255, 0.65)')
          .borderRadius(16)
          .type(ButtonType.Normal)
          .shadow({ radius: 8, color: '#00000020' })
          .onClick(() => {
            router.pushUrl({ url: 'pages/ClosetPage' })
          })

          // 查看推荐按钮（卡片样式）
          Button() {
            Column() {
              //Image($r('app.media.icon_match')).width(48).height(48).margin({ bottom: 8 })

              Text('穿搭推荐').fontSize(22).fontWeight(FontWeight.Medium).fontColor('#333333')
            }
            .padding({ top: 20, bottom: 20 })
          }
          .width('42%')
          .height(80)
          .backgroundColor('rgba(255, 255, 255, 0.65)')
          .borderRadius(16)
          .type(ButtonType.Normal)
          .shadow({ radius: 8, color: '#00000020' })
          .onClick(() => {
            router.pushUrl({ url: 'pages/RecommendPage' })
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceEvenly)
        .margin({ top: 350, bottom: 20 })

       // Blank()
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}