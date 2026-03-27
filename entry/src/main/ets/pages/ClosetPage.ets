import { Clothing } from '../model/Clothing'
import { ClothingRepo } from '../repository/ClothingRepo'
import { ClothingService } from '../service/ClothingService'
import { BusinessError } from '@kit.BasicServicesKit'
import { picker } from '@kit.CoreFileKit'

@Entry
@Component
struct ClosetPage {

  @State clothingList: Clothing[] = []

  private repo: ClothingRepo = new ClothingRepo()
  private service: ClothingService = new ClothingService()

  aboutToAppear() {
    this.loadData()
  }

  async loadData() {
    try {
      const list = await this.repo.getAll()
      this.clothingList = list ?? []
      console.log('加载完成:', this.clothingList.length)
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

              // 图片（直接使用 URI）
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
  // UI层：只负责选图
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
        console.log('未选择图片')
        return
      }

      const uri: string = result.photoUris[0]
      console.log('选中图片:', uri)

      // ❗交给 Service
      await this.service.addClothing(uri)

      // ❗统一刷新
      await this.loadData()

    } catch (error) {
      const err: BusinessError = error as BusinessError
      console.error('选择图片失败: ' + err.message)
    }
  }

  async handleDelete(id: number) {
    try {
      await this.service.deleteClothing(id)
      await this.loadData()
    } catch (e) {
      console.error('删除失败', e)
    }
  }
}