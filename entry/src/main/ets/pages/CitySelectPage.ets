import router from '@ohos.router'
import { cityList, City } from '../utils/CityList'

@Entry
@Component
export struct CitySelectPage {
  @State cityListData: City[] = cityList

  build() {
    Column() {
      Row() {
        Button('返回').width(60).height(40).onClick(() => { router.back() })
        Text('选择城市').fontSize(28).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center)
        Text('').width(60)
      }
      .width('100%').padding({ left: 16, right: 16, top: 20 }).margin({ bottom: 20 })

      List() {
        ForEach(this.cityListData, (item: City) => {
          ListItem() {
            Row() {
              Text(item.city).fontSize(18).fontWeight(FontWeight.Medium)
              Text(item.adcode).fontSize(12).fontColor('#999999').margin({ left: 12 })
            }
            .width('100%').height(55).padding({ left: 20, right: 20 })
            .justifyContent(FlexAlign.Start).alignItems(VerticalAlign.Center)
            .backgroundColor('#F5F5F5').borderRadius(8)
          }
          .onClick(() => {
            console.info(`选择城市: ${item.city}`)
            // 存入 AppStorage
            AppStorage.set('selectedCity', item)
            router.back()
          })
          .margin({ bottom: 8 })
        }, (item: City) => item.adcode)
      }
      .width('100%').layoutWeight(1).padding({ left: 16, right: 16 })
    }
    .width('100%').height('100%').backgroundColor('#FFFFFF')
  }
}