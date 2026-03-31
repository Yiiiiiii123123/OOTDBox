import { Clothing } from '../model/Clothing'
import { ClothingRepo } from '../repository/ClothingRepo'
import { ClothingService } from '../service/ClothingService'
import router from '@ohos.router'

@Entry
@Component
struct ClothingDetailPage {
  @State clothing: Clothing | null = null
  @State isEditing: boolean = false
  @State editCategory: string = ''
  @State editColor: string = ''
  @State editBrand: string = ''

  private repo: ClothingRepo = new ClothingRepo()
  private service: ClothingService = new ClothingService()

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>
    if (params && params['clothing']) {
      this.clothing = params['clothing'] as Clothing
      this.editCategory = this.clothing?.category || ''
      this.editColor = this.clothing?.color || ''
    }
  }

  // 保存修改
  // 保存修改
  // 保存修改
  async saveChanges() {
    if (!this.clothing?.id) return

    // 直接修改原对象属性
    this.clothing.category = this.editCategory
    this.clothing.color = this.editColor

    try {
      await this.service.updateClothing(this.clothing)
      this.isEditing = false
      console.info('保存成功')
    } catch (e) {
      console.error('保存失败', e)
    }
  }

  // 删除衣物
  async deleteClothing() {
    if (!this.clothing?.id) return

    await this.service.deleteClothing(this.clothing.id)
    router.back()
  }

  // 分类选项
  categoryOptions: SelectOption[] = [
    { value: '上装' },
    { value: '下装' },
    { value: '连体' },
    { value: '鞋子' },
    { value: '配饰' }
  ]

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

          Text('衣物详情')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')

          Blank()

          if (!this.isEditing) {
            Button('编辑')
              .width(60)
              .height(40)
              .backgroundColor('rgba(255,255,255,0.8)')
              .fontColor('#007AFF')
              .borderRadius(20)
              .onClick(() => {
                this.isEditing = true
              })
          } else {
            Row() {
              Button('取消')
                .width(60)
                .height(40)
                .backgroundColor('rgba(255,255,255,0.8)')
                .fontColor('#999')
                .borderRadius(20)
                .margin({ right: 8 })
                .onClick(() => {
                  this.isEditing = false
                  this.editCategory = this.clothing?.category || ''
                  this.editColor = this.clothing?.color || ''
                })

              Button('保存')
                .width(60)
                .height(40)
                .backgroundColor('#007AFF')
                .fontColor('#FFFFFF')
                .borderRadius(20)
                .onClick(() => {
                  this.saveChanges()
                })
            }
          }
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 48, bottom: 20 })

        if (this.clothing) {
          Scroll() {
            Column() {
              // 衣物图片
              if (this.clothing.imageUri) {
                Image(this.clothing.imageUri)
                  .width('80%')
                  .aspectRatio(1)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(24)
                  .margin({ bottom: 24 })
              } else {
                Column() {
                  Text('📷')
                    .fontSize(80)
                }
                .width('80%')
                .aspectRatio(1)
                .backgroundColor('#F0F0F0')
                .borderRadius(24)
                .margin({ bottom: 24 })
                .justifyContent(FlexAlign.Center)
              }

              // 信息卡片
              Column() {
                if (this.isEditing) {
                  // 编辑模式
                  Row() {
                    Text('分类:')
                      .fontSize(16)
                      .width(80)

                    Select(this.categoryOptions)
                      .selected(0)
                      .value(this.editCategory || '请选择')
                      .onSelect((index: number, value: string) => {
                        this.editCategory = value
                      })
                      .width(200)
                  }
                  .width('100%')
                  .margin({ bottom: 16 })

                  Row() {
                    Text('颜色:')
                      .fontSize(16)
                      .width(80)

                    TextInput({ text: this.editColor })
                      .width(200)
                      .height(40)
                      .backgroundColor('#F5F5F5')
                      .borderRadius(8)
                      .onChange((value: string) => {
                        this.editColor = value
                      })
                  }
                  .width('100%')
                  .margin({ bottom: 16 })

                  Row() {
                    Text('品牌:')
                      .fontSize(16)
                      .width(80)

                    TextInput({ text: this.editBrand })
                      .width(200)
                      .height(40)
                      .backgroundColor('#F5F5F5')
                      .borderRadius(8)
                      .onChange((value: string) => {
                        this.editBrand = value
                      })
                  }
                  .width('100%')
                } else {
                  // 查看模式
                 // InfoRow('分类', this.clothing.category || '未标注')
                 // InfoRow('颜色', this.clothing.color || '未标注')
                 // InfoRow('添加时间', this.clothing.createTime || '未知')
                }
              }
              .width('90%')
              .padding(20)
              .backgroundColor('rgba(255,255,255,0.9)')
              .borderRadius(20)
              .margin({ top: 16 })

              // 删除按钮
              Button('删除衣物')
                .width('80%')
                .height(50)
                .fontSize(16)
                .backgroundColor('#ff4d4f')
                .fontColor('#FFFFFF')
                .borderRadius(25)
                .margin({ top: 30, bottom: 30 })
                .onClick(() => {
                  this.deleteClothing()
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
          }
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}

// 信息行组件
@Component
struct InfoRow {
  @Prop label: string = ''
  @Prop value: string = ''

  build() {
    Row() {
      Text(this.label + ':')
        .fontSize(16)
        .fontColor('#666')
        .width(80)

      Text(this.value)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333')
    }
    .width('100%')
    .margin({ bottom: 12 })
  }
}