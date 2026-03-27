import { router } from '@kit.ArkUI'

@Entry
@Component
struct HomePage {

  build() {
    Column() {
      // 标题
      Text('智能衣橱')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 40 })

      // 按钮1：跳转衣橱页面
      Button('进入衣橱')
        .width('80%')
        .height(50)
        .margin({ bottom: 20 })
        .onClick(() => {
          router.pushUrl({
            url: 'pages/ClosetPage'
          })
        })

      // 按钮2：跳转推荐页面
      Button('穿搭推荐')
        .width('80%')
        .height(50)
        .onClick(() => {
          router.pushUrl({
            url: 'pages/RecommendPage'
          })
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}