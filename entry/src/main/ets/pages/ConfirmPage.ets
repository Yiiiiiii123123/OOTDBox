import router from '@ohos.router'
import { ClothingService } from '../service/ClothingService'
import { ClothingDraft } from '../model/Clothing'

@Entry
@Component
struct ConfirmPage {

  @State imageUri: string = ''
  @State category: string = ''
  @State color: string = ''

  private service: ClothingService = new ClothingService()

  private categories: string[] = ['上衣', '外套', '裤子', '鞋子']
  private colors: string[] = ['黑色', '白色', '灰色', '蓝色', '红色', '绿色', '黄色', '棕色']

  // 页面加载
  onPageShow() {
    const params = router.getParams() as Partial<ClothingDraft>

    this.imageUri = params.imageUri ?? ''
    this.category = params.category ?? ''
    this.color = params.color ?? ''
  }

  build() {
    Column() {

      // ======================
      // 图片展示
      // ======================
      Image(this.imageUri)
        .width(200)
        .height(200)
        .margin({ top: 20, bottom: 20 })

      // ======================
      // 类别选择
      // ======================
      Text('选择类别')
        .fontSize(18)
        .margin({ bottom: 10 })

      // 使用 Flex 布局来替代 Flow，自动换行
      Flex({
        wrap: FlexWrap.Wrap,
        justifyContent: FlexAlign.Start
      }) {
        ForEach(this.categories, (item: string) => {
          Button(item)
            .backgroundColor(this.category === item ? '#007dff' : '#eee')
            .fontColor(this.category === item ? '#fff' : '#000')
            .borderRadius(20)
            .padding({ left: 15, right: 15 })
            .onClick(() => {
              this.category = item
            })
        })
      }
      .width('90%')
      .margin({ bottom: 20 })

      // ======================
      // 颜色选择（优化版）
      // ======================
      Text('选择主颜色')
        .fontSize(18)
        .margin({ bottom: 10 })

      // 使用 Flex 布局来替代 Flow，自动换行
      Flex({
        wrap: FlexWrap.Wrap,
        justifyContent: FlexAlign.Start
      }) {
        ForEach(this.colors, (item: string) => {
          Row() {

            // 颜色小圆点
            Circle()
              .width(16)
              .height(16)
              .fill(this.getColorValue(item))
              .margin({ right: 6 })

            Text(item)
              .fontSize(14)
          }
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .margin({ right: 10, bottom: 10 })
          .backgroundColor(this.color === item ? '#007dff' : '#eee')
          .borderRadius(20)
          .onClick(() => {
            this.color = item
          })

        })
      }
      .width('90%')
      .margin({ bottom: 30 })

      // ======================
      // 确认按钮
      // ======================
      Button('确认保存')
        .width('80%')
        .height(45)
        .backgroundColor('#52c41a')
        .onClick(async () => {

          if (!this.category || !this.color) {
            console.error('请先选择类别和颜色')
            return
          }

          await this.service.saveClothing({
            imageUri: this.imageUri,
            category: this.category,
            color: this.color,
            cutoutUri: this.imageUri
          })

          console.log('保存成功')

          router.back()
        })

    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Start)
  }

  // ======================
  // 颜色映射（用于填充颜色块）
  // ======================
  getColorValue(name: string): string {
    switch (name) {
      case '黑色': return '#000000'
      case '白色': return '#ffffff'
      case '灰色': return '#888888'
      case '蓝色': return '#1677ff'
      case '红色': return '#ff4d4f'
      case '绿色': return '#52c41a'
      case '黄色': return '#fadb14'
      case '棕色': return '#8B4513'
      default: return '#ccc'
    }
  }
}