// src/pages/HomePage.ets

import { WeatherService } from '../service/WeatherService'
import { router } from '@kit.ArkUI'

@Entry
@Component
struct HomePage {

  @State temperature: number = 0
  @State weatherText: string = '加载中...'
  @State city: string = '厦门' // 初始城市是厦门
  @State cityCode: string = '350200' // 初始城市代码是厦门

  private weatherService: WeatherService = new WeatherService()

  // 页面显示时获取天气
  onPageShow() {
    this.loadWeather()
  }

  async loadWeather() {
    const result = await this.weatherService.getWeather(this.cityCode)

    if (result) {
      this.city = result.city
      this.temperature = result.temperature
      this.weatherText = `${this.city} 当前天气：${result.weather}，温度：${this.temperature}℃`
    } else {
      this.weatherText = '获取天气失败，请稍后重试'
    }
  }

  // 跳转到城市选择页面
  onSelectCity() {
    router.pushUrl({
      url: 'pages/CitySelectPage'
    })
  }

  build() {
    Column() {

      // 标题
      Text('首页')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 30, bottom: 20 })

      // 城市选择按钮
      Button(`当前城市: ${this.city}`)
        .width('80%')
        .height(45)
        .margin({ bottom: 20 })
        .onClick(() => {
          this.onSelectCity()
        })

      // 天气显示
      Text(this.weatherText)
        .fontSize(18)
        .margin({ bottom: 30 })

      // 跳转按钮
      Button('进入衣橱')
        .width('80%')
        .height(45)
        .margin({ bottom: 20 })
        .onClick(() => {
          router.pushUrl({
            url: 'pages/ClosetPage'
          })
        })

      Button('查看推荐')
        .width('80%')
        .height(45)
        .onClick(() => {
          router.pushUrl({
            url: 'pages/RecommendPage'
          })
        })

    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }
}