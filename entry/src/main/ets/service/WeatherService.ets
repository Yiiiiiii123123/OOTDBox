// src/service/WeatherService.ts

import http from '@ohos.net.http'

interface WeatherLiveInfo {
  province: string
  city: string
  adcode: string
  weather: string
  temperature: string
  winddirection: string
  windpower: string
  humidity: string
  reporttime: string
}

interface WeatherResponse {
  status: string
  count: string
  info: string
  infocode: string
  lives: WeatherLiveInfo[]
}

export interface WeatherResult {
  city: string
  weather: string
  temperature: number
}

export class WeatherService {
  private readonly API_KEY: string = '2e11e57e73a0dd82668058d91192978a'

  async getWeather(cityCode: string): Promise<WeatherResult | null> {
    let httpRequest = http.createHttp()

    try {
      const url = `https://restapi.amap.com/v3/weather/weatherInfo?city=${cityCode}&key=${this.API_KEY}`

      let response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0'
        }
      })

      if (response.responseCode !== 200) {
        return null
      }

      if (typeof response.result !== 'string') {
        return null
      }

      let parsedResult: WeatherResponse = JSON.parse(response.result)

      if (parsedResult.status !== '1' || !parsedResult.lives || parsedResult.lives.length === 0) {
        return null
      }

      const live = parsedResult.lives[0]
      const temperature = Number(live.temperature)

      if (isNaN(temperature)) {
        return null
      }

      return {
        city: live.city,
        weather: live.weather,
        temperature: temperature
      }

    } catch (err) {
      console.error('获取天气异常:', err)
      return null
    } finally {
      httpRequest.destroy()
    }
  }
}