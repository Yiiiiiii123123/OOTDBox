import { Clothing } from '../model/Clothing'
import { ClothingRepo } from '../repository/ClothingRepo'
import { ClothingService } from '../service/ClothingService'
import { BusinessError } from '@kit.BasicServicesKit'
import { picker } from '@kit.CoreFileKit'
import router from '@ohos.router' // ❗新增

@Entry
@Component
struct ClosetPage {

  @State clothingList: Clothing[] = []

  private repo: ClothingRepo = new ClothingRepo()
  private service: ClothingService = new ClothingService()

  aboutToAppear() {
    this.loadData()
  }

  onPageShow() {
    this.loadData() // 返回刷新
  }

  async loadData() {
    try {
      const list = await this.repo.getAll()
      this.clothingList = list ?? []
    } catch (e) {
      console.error('加载失败', e)
    }
  }

  build() {
    Column() {

      Text('我的衣橱')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })

      Button('添加衣物')
        .width('80%')
        .height(45)
        .margin({ bottom: 20 })
        .onClick(async () => {
          await this.selectImage()
        })

      List() {
        ForEach(this.clothingList, (item: Clothing) => {

          ListItem() {
            Row() {

              Image(item.imageUri ?? '')
                .width(80)
                .height(80)
                .margin({ right: 15 })

              Column() {
                Text('类别: ' + (item.category ?? ''))
                Text('颜色: ' + (item.color ?? ''))
                  .fontColor('#666')
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Button('删除')
                .fontSize(12)
                .backgroundColor('#ff4d4f')
                .onClick(async () => {
                  if (item.id !== undefined) {
                    await this.handleDelete(item.id)
                  }
                })
            }
            .padding(10)
          }

        }, (item: Clothing) => String(item.id ?? Math.random()))
      }
      .layoutWeight(1)
      .width('100%')

    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }

  // ======================
  // 关键修改在这里 👇
  // ======================
  async selectImage() {
    try {
      const photoPicker = new picker.PhotoViewPicker()

      const options: picker.PhotoSelectOptions = {
        MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      }

      const result: picker.PhotoSelectResult = await photoPicker.select(options)

      if (!result || !result.photoUris || result.photoUris.length === 0) {
        return
      }

      const uri: string = result.photoUris[0]

      // ❗1. 调用“分析”，不入库
      const draft = await this.service.analyzeClothing(uri)

      console.log('AI结果:', draft)

      // ❗2. 跳转确认页面
      router.pushUrl({
        url: 'pages/ConfirmPage',   // ⚠️ 确保路径正确
        params: draft
      })

    } catch (error) {
      const err: BusinessError = error as BusinessError
      console.error('选择图片失败: ' + err.message)
    }
  }

  async handleDelete(id: number) {
    await this.service.deleteClothing(id)
    await this.loadData()
  }
}