import router from '@ohos.router'
import { ClothingService } from '../service/ClothingService'
import { ClothingDraft } from '../model/Clothing'
import { ClothingCategory, CATEGORY_LIST, normalizeCategory, Category } from '../model/Category'

@Entry
@Component
struct ConfirmPage {

  @State imageUri: string = ''
  @State category: string = ''
  @State color: string = ''

  private service: ClothingService = new ClothingService()
  private colors: string[] = ['黑色', '白色', '灰色', '蓝色', '红色', '绿色', '黄色', '棕色']

  onPageShow() {
    const params = router.getParams() as Partial<ClothingDraft>
    this.imageUri = params.imageUri ?? ''
    this.category = normalizeCategory(params.category ?? '')
    this.color = params.color ?? ''
  }

  build() {
    Column() {
      // 图片展示
      Image(this.imageUri)
        .width(200)
        .height(200)
        .margin({ top: 20, bottom: 20 })
        .objectFit(ImageFit.Cover)
        .borderRadius(12)

      // 类别选择
      Text('选择类别')
        .fontSize(18)
        .margin({ bottom: 10 })
        .fontWeight(FontWeight.Medium)

      // 分类按钮网格
      Grid() {
        ForEach(CATEGORY_LIST.filter((c: Category) => c.key !== ClothingCategory.ALL), (item: Category) => {
          GridItem() {
            Button(item.label)
              .width('100%')
              .height(40)
              .backgroundColor(this.category === item.key ? '#007dff' : '#f5f5f5')
              .fontColor(this.category === item.key ? '#ffffff' : '#333333')
              .borderRadius(20)
              .fontSize(14)
              .onClick(() => {
                this.category = item.key
              })
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr')
      .width('90%')
      .height(90)
      .margin({ bottom: 20 })

      // 颜色选择
      Text('选择主颜色')
        .fontSize(18)
        .margin({ bottom: 10 })
        .fontWeight(FontWeight.Medium)

      Flex({
        wrap: FlexWrap.Wrap,
        justifyContent: FlexAlign.Start
      }) {
        ForEach(this.colors, (item: string) => {
          Row() {
            Circle()
              .width(16)
              .height(16)
              .fill(this.getColorValue(item))
              .margin({ right: 6 })
              .stroke(this.color === item ? '#007dff' : 'transparent')
              .strokeWidth(2)

            Text(item)
              .fontSize(14)
              .fontColor(this.color === item ? '#007dff' : '#333333')
          }
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .margin({ right: 10, bottom: 10 })
          .backgroundColor(this.color === item ? '#e6f7ff' : '#f5f5f5')
          .borderRadius(20)
          .border({
            width: this.color === item ? 1 : 0,
            color: '#007dff'
          })
          .onClick(() => {
            this.color = item
          })
        })
      }
      .width('90%')
      .margin({ bottom: 30 })

      // 确认按钮
      Button('确认保存')
        .width('80%')
        .height(45)
        .backgroundColor('#52c41a')
        .enabled(this.category !== '' && this.color !== '')
        .opacity(this.category !== '' && this.color !== '' ? 1 : 0.5)
        .onClick(async () => {
          if (!this.category || !this.color) {
            console.error('请先选择类别和颜色')
            return
          }

          const normalizedCategory = normalizeCategory(this.category)

          await this.service.saveClothing({
            imageUri: this.imageUri,
            category: normalizedCategory,
            color: this.color,
            cutoutUri: this.imageUri
          })

          console.log('保存成功:', normalizedCategory, this.color)
          router.back()
        })

    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Start)
    .backgroundColor('#ffffff')
  }

  getColorValue(name: string): string {
    const colorMap: Record<string, string> = {
      '黑色': '#000000',
      '白色': '#ffffff',
      '灰色': '#888888',
      '蓝色': '#1677ff',
      '红色': '#ff4d4f',
      '绿色': '#52c41a',
      '黄色': '#fadb14',
      '棕色': '#8B4513'
    }
    return colorMap[name] || '#cccccc'
  }
}