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

  @StorageLink('selectedCity') selectedCity: City | null = null

  private weatherService: WeatherService = new WeatherService()
  private isUpdatingWeather: boolean = false  // 防止重复请求

  aboutToAppear() {
    AppStorage.setOrCreate('selectedCity', null)
  }

  onPageShow() {
    if (this.selectedCity) {
      console.info(`[城市选择] 新城市: ${this.selectedCity.city}, 代码: ${this.selectedCity.adcode}`)
      this.city = this.selectedCity.city
      this.cityCode = this.selectedCity.adcode
      this.loadWeather()
      this.selectedCity = null  // 清空
    } else {
      // 首次加载或返回时，确保天气数据正确
      if (this.cityCode === '350200' && this.weatherText === '加载中...') {
        this.loadWeather()
      }
    }
  }

  async loadWeather() {
    // 防止重复请求
    if (this.isUpdatingWeather) {
      console.info('[防抖] 已有请求在进行中，跳过')
      return
    }

    this.isUpdatingWeather = true

    const requestCityCode = this.cityCode  // 记录本次请求的城市代码
    const requestStartTime = Date.now()
    console.info(`[请求开始] 城市: ${this.city}, 代码: ${requestCityCode}, 时间: ${requestStartTime}`)

    // 先显示加载状态
    this.weatherText = '加载中...'

    try {
      const result = await this.weatherService.getWeather(this.cityCode)

      // 检查是否是最新的请求
      if (requestCityCode !== this.cityCode) {
        console.warn(`[丢弃旧数据] 请求时城市: ${requestCityCode}, 当前城市: ${this.cityCode}, 忽略此结果`)
        return  // 丢弃过时的结果
      }

      const requestEndTime = Date.now()
      console.info(`[请求完成] 耗时: ${requestEndTime - requestStartTime}ms, 结果: ${result ? '成功' : '失败'}`)

      if (result) {
        console.info(`[更新UI] 城市: ${result.city}, 天气: ${result.weather}, 温度: ${result.temperature}°C`)
        this.city = result.city
        this.temperature = result.temperature
        this.weatherText = `${this.city} 当前天气：${result.weather}，温度：${this.temperature}℃`
      } else {
        console.error(`[请求失败] 城市代码: ${requestCityCode}`)
        // 失败时不更新 city 和 weatherText，保留之前的数据
        // 但可以显示错误提示
        this.weatherText = `获取${this.city}天气失败，请稍后重试`
      }
    } catch (err) {
      console.error(`[请求异常] ${JSON.stringify(err)}`)
      if (requestCityCode === this.cityCode) {
        this.weatherText = `获取${this.city}天气失败，请稍后重试`
      }
    } finally {
      this.isUpdatingWeather = false
    }
  }

  onSelectCity() {
    router.pushUrl({ url: 'pages/CitySelectPage' })
  }

  build() {
    Column() {
      Text('首页')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 30, bottom: 20 })

      Button(`当前城市: ${this.city}`)
        .width('80%')
        .height(45)
        .margin({ bottom: 20 })
        .onClick(() => {
          this.onSelectCity()
        })

      Text(this.weatherText)
        .fontSize(18)
        .margin({ bottom: 30 })

      Button('进入衣橱')
        .width('80%')
        .height(45)
        .margin({ bottom: 20 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/ClosetPage' })
        })

      Button('查看推荐')
        .width('80%')
        .height(45)
        .onClick(() => {
          router.pushUrl({ url: 'pages/RecommendPage' })
        })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }
}