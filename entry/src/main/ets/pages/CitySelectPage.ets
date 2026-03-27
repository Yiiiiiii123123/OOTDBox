// src/pages/CitySelectPage.ets

import { cityList } from '../utils/CityList'
import { router } from '@kit.ArkUI'
import { City } from '../utils/CityList'

@Entry
@Component
struct CitySelectPage {

  @State selectedCity: string = ''

  // 根据首字母对城市进行排序
  cityListSorted: City[] = [...cityList].sort((a, b) =>
  a.city.localeCompare(b.city)
  )

  // 选中城市
  onSelectCity(city: string, adcode: string) {
    this.selectedCity = city
    // 选择城市后，跳转到 HomePage，并传递选中的城市adcode
    router.pushUrl({
      url: 'pages/HomePage',
      params: { cityCode: adcode, cityName: city }
    })
  }

  build() {
    Column() {
      // 标题
      Text('选择城市')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 30, bottom: 20 })

      // 城市列表
      ForEach(
        this.cityListSorted,
        (item: City) => {
          ListItem() {
            Row() {
              Text(item.city)
                .fontSize(20)
                .onClick(() => {
                  this.onSelectCity(item.city, item.adcode)
                })
            }
            .padding(10)
          }
        },
        (item: City) => item.adcode   // ✅ key
      )

    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }
}