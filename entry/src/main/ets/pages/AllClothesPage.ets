import { Clothing } from '../model/Clothing'
import { ClothingRepo } from '../repository/ClothingRepo'
import { ClothingService } from '../service/ClothingService'
import router from '@ohos.router'

@Entry
@Component
struct AllClothesPage {
  @State clothingList: Clothing[] = []

  private repo: ClothingRepo = new ClothingRepo()
  private service: ClothingService = new ClothingService()

  aboutToAppear() {
    this.loadData()
  }

  onPageShow() {
    this.loadData()
  }

  async loadData() {
    try {
      const list = await this.repo.getAll()
      this.clothingList = list ?? []
    } catch (e) {
      console.error('加载失败', e)
    }
  }

  // 跳转到衣物详情
  goToDetail(item: Clothing) {
    router.pushUrl({
      url: 'pages/ClothingDetailPage',
      params: { clothing: item }
    })
  }

  // 删除衣物
  async deleteClothing(id: number) {
    await this.service.deleteClothing(id)
    await this.loadData()
  }

  build() {
    Stack() {
      // 背景
      Image($r('app.media.background1'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      Column() {
        // 标题栏
        Row() {
          Button('返回')
            .width(60)
            .height(40)
            .backgroundColor('rgba(255,255,255,0.8)')
            .fontColor('#333333')
            .borderRadius(20)
            .onClick(() => {
              router.back()
            })

          Blank()

          Text('所有衣物')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')

          Blank()

          // 占位
          Row().width(60)
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 48, bottom: 12 })

        // 衣物列表（可删除和修改）
        if (this.clothingList.length === 0) {
          Column() {
            Text('📭')
              .fontSize(48)
              .margin({ bottom: 16 })
            Text('暂无衣物')
              .fontSize(16)
              .fontColor('#999')
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else {
          List() {
            ForEach(this.clothingList, (item: Clothing) => {
              ListItem() {
                Row() {
                  // 图片
                  if (item.imageUri) {
                    Image(item.imageUri)
                      .width(60)
                      .height(60)
                      .objectFit(ImageFit.Cover)
                      .borderRadius(8)
                      .margin({ right: 12 })
                  } else {
                    Column() {
                      Text('📷')
                        .fontSize(30)
                    }
                    .width(60)
                    .height(60)
                    .backgroundColor('#F0F0F0')
                    .borderRadius(8)
                    .margin({ right: 12 })
                    .justifyContent(FlexAlign.Center)
                  }

                  // 衣物信息
                  Column() {
                    Text(`类别: ${item.category || '无分类'}`)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                    Text(`颜色: ${item.color || '未标注'}`)
                      .fontSize(14)
                      .fontColor('#666')

                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)

                  // 编辑和删除按钮
                  Row() {
                    Button('编辑')
                      .fontSize(12)
                      .backgroundColor('#007AFF')
                      .width(50)
                      .height(32)
                      .borderRadius(16)
                      .margin({ right: 8 })
                      .onClick(() => {
                        this.goToDetail(item)
                      })

                    Button('删除')
                      .fontSize(12)
                      .backgroundColor('#ff4d4f')
                      .width(50)
                      .height(32)
                      .borderRadius(16)
                      .onClick(async () => {
                        if (item.id !== undefined) {
                          await this.deleteClothing(item.id)
                        }
                      })
                  }
                }
                .width('100%')
                .padding(12)
                .backgroundColor('rgba(255,255,255,0.9)')
                .borderRadius(12)
                .margin({ bottom: 8 })
              }
            }, (item: Clothing) => String(item.id ?? Date.now()))
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 16, right: 16 })
        }
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}