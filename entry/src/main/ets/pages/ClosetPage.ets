import { Clothing } from '../model/Clothing'
import { ClothingRepo } from '../repository/ClothingRepo'
import { ClothingService } from '../service/ClothingService'
import { BusinessError } from '@kit.BasicServicesKit'
import { picker } from '@kit.CoreFileKit'
import router from '@ohos.router'
import { ClothingCategory, CATEGORY_LIST } from '../model/Category'

// 使用统一的分类类型
type CategoryKey = ClothingCategory

// 使用统一的分类配置
interface Category {
  key: CategoryKey
  label: string
}

@Entry
@Component
struct ClosetPage {

  @State clothingList: Clothing[] = []
  @State filteredList: Clothing[] = []
  @State selectedCategory: CategoryKey = ClothingCategory.ALL

  private repo: ClothingRepo = new ClothingRepo()
  private service: ClothingService = new ClothingService()

  // 使用统一的分类列表
  private categories: Category[] = CATEGORY_LIST

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
      console.info(`加载了 ${this.clothingList.length} 件衣物`)
      // 打印分类分布用于调试
      const categoryStats = this.clothingList.reduce((acc, item) => {
        acc[item.category] = (acc[item.category] || 0) + 1
        return acc
      }, {} as Record<string, number>)
      console.info('分类分布:', JSON.stringify(categoryStats))

      this.filterByCategory(this.selectedCategory)
    } catch (e) {
      console.error('加载失败', e)
    }
  }

  // 根据分类过滤衣物
  filterByCategory(category: CategoryKey) {
    console.info(`筛选分类: ${category}`)
    if (category === ClothingCategory.ALL) {
      this.filteredList = [...this.clothingList]
    } else {
      this.filteredList = this.clothingList.filter(item => {
        const itemCategory = item.category || ''
        // 精确匹配
        const match = itemCategory === category
        if (!match) {
          console.debug(`不匹配: item.category="${itemCategory}" vs filter="${category}"`)
        }
        return match
      })
    }
    console.info(`筛选结果: ${this.filteredList.length} 件`)
  }

  // 切换分类
  selectCategory(category: CategoryKey) {
    this.selectedCategory = category
    this.filterByCategory(category)
  }

  // 跳转到所有衣物管理页面
  goToAllClothes() {
    router.pushUrl({ url: 'pages/AllClothesPage' })
  }

  // 跳转到衣物详情页面
  goToClothingDetail(item: Clothing) {
    router.pushUrl({
      url: 'pages/ClothingDetailPage',
      params: { clothing: item }
    })
  }

  build() {
    Stack() {
      // 背景图片
      Image($r('app.media.background1'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      Column() {
        // 标题栏
        Row() {
          Text('我的衣橱')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')

          Blank()

          // 管理衣物按钮
          Button('管理衣物')
            .width(100)
            .height(40)
            .fontSize(14)
            .backgroundColor('rgba(255, 255, 255, 0.8)')
            .fontColor('#333333')
            .borderRadius(20)
            .onClick(() => {
              this.goToAllClothes()
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 48, bottom: 12 })

        // 圆角矩形容器（左上角和右上角圆角）
        Column() {
          Row() {
            // 左侧导航栏
            this.buildCategorySidebar()

            // 右侧内容区（网格布局）
            this.buildClothingGrid()
          }
          .width('100%')
          .layoutWeight(1)
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('rgba(255, 255, 255, 0.9)')
        .borderRadius({ topLeft: 24, topRight: 24, bottomLeft: 0, bottomRight: 0 })
      }
      .width('100%')
      .height('100%')

      // 右下角加号按钮
      Button() {
        Text('+')
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
      }
      .width(56)
      .height(56)
      .backgroundColor('#007AFF')
      .borderRadius(28)
      .shadow({ radius: 8, color: '#00000030' })
      .position({ x: '80%', y: '85%' })
      .onClick(async () => {
        await this.selectImage()
      })
    }
    .width('100%')
    .height('100%')
  }

  // 左侧导航栏
  @Builder
  buildCategorySidebar() {
    Column() {
      ForEach(this.categories, (category: Category) => {
        Button(category.label)
          .width('100%')
          .height(48)
          .fontSize(16)
          .backgroundColor(this.selectedCategory === category.key ? '#007AFF' : 'rgba(0,0,0,0)')
          .fontColor(this.selectedCategory === category.key ? '#FFFFFF' : '#333333')
          .borderRadius(0)
          .margin({ bottom: 4 })
          .onClick(() => {
            this.selectCategory(category.key)
          })
      })
    }
    .width('30%')
    .height('100%')
    .padding({ left: 12, right: 12, top: 16 })
    .backgroundColor('rgba(248, 248, 248, 0.8)')
  }

  // 右侧网格布局
  @Builder
  buildClothingGrid() {
    Column() {
      if (this.filteredList.length === 0) {
        // 空状态
        Column() {
          Text('📭')
            .fontSize(48)
            .margin({ bottom: 16 })

          Text('暂无衣物')
            .fontSize(16)
            .fontColor('#999')
            .margin({ bottom: 8 })

          Text('点击右下角"+"添加衣物')
            .fontSize(14)
            .fontColor('#CCC')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Grid() {
          ForEach(this.filteredList, (item: Clothing) => {
            GridItem() {
              // 衣物卡片
              Column() {
                // 衣物图片
                if (item.cutoutUri) {
                  Image(item.cutoutUri)
                    .width('100%')
                    .aspectRatio(1)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(12)
                } else if (item.imageUri) {
                  Image(item.imageUri)
                    .width('100%')
                    .aspectRatio(1)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(12)
                } else {
                  Column() {
                    Text('📷')
                      .fontSize(40)
                  }
                  .width('100%')
                  .aspectRatio(1)
                  .backgroundColor('#F0F0F0')
                  .borderRadius(12)
                  .justifyContent(FlexAlign.Center)
                }

                // 分类标签
                Text(item.category || '未分类')
                  .fontSize(12)
                  .fontColor('#666')
                  .margin({ top: 4 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .onClick(() => {
                this.goToClothingDetail(item)
              })
            }
            .width('33.3%')
            .padding(4)
          })
        }
        .columnsTemplate('1fr 1fr 1fr')
        .width('100%')
        .layoutWeight(1)
        .padding(8)
      }
    }
    .layoutWeight(1)
    .width('70%')
    .padding({ top: 16 })
  }

  // 选择图片
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

      const draft = await this.service.analyzeClothing(uri)

      console.log('AI结果:', JSON.stringify(draft))

      router.pushUrl({
        url: 'pages/ConfirmPage',
        params: draft
      })

    } catch (error) {
      const err: BusinessError = error as BusinessError
      console.error('选择图片失败: ' + err.message)
    }
  }
}