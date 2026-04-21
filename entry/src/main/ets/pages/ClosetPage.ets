import { Clothing} from '../model/Clothing'
import { ClothingRepo } from '../repository/ClothingRepo'
import { ClothingService } from '../service/ClothingService'
import { BusinessError } from '@kit.BasicServicesKit'
import { picker } from '@kit.CoreFileKit'
import router from '@ohos.router'
import { APP_WALLPAPERS } from '../utils/BackgroundList'
import { ClothingUtils, MainCategory } from '../utils/ClothingConfig'

// 定义左侧侧边栏的 UI 分类配置 (包含 'all' 和 MainCategory)
interface UICategory {
  key: string;
  label: string;
}

const UI_CATEGORY_LIST: UICategory[] = [
  { key: 'all', label: '全部' },
  { key: MainCategory.TOP, label: '上装' },
  { key: MainCategory.BOTTOM, label: '下装' },
  { key: MainCategory.ONE_PIECE, label: '连体' },
  { key: MainCategory.OUTERWEAR, label: '外套' },
  { key: MainCategory.SHOES, label: '鞋子' },
  { key: MainCategory.ACCESSORY, label: '配饰' }
]

@Entry
@Component
struct ClosetPage {
  @State clothingList: Clothing[] = []
  @State filteredList: Clothing[] = []
  @State selectedCategory: string = 'all' // 当前选中的一级分类
  @StorageProp('wallpaper_index') wallpaperIndex: number = 0;


  private repo: ClothingRepo = new ClothingRepo()
  private service: ClothingService = new ClothingService()
  private categories: UICategory[] = UI_CATEGORY_LIST

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

      const categoryStats = this.clothingList.reduce((acc: Record<string, number>, item: Clothing) => {
        const cat = item.mainCategory || 'unknown';
        acc[cat] = (acc[cat] || 0) + 1;
        return acc;
      }, {})
      console.info('一级分类分布:', JSON.stringify(categoryStats))

      this.filterByCategory(this.selectedCategory)
    } catch (e) {
      console.error('加载失败', e)
    }
  }

  // 根据 mainCategory 过滤衣物
  filterByCategory(categoryKey: string) {
    if (categoryKey === 'all') {
      this.filteredList = [...this.clothingList]
    } else {
      this.filteredList = this.clothingList.filter(item => item.mainCategory === categoryKey)
    }
  }

  // 切换分类
  selectCategory(categoryKey: string) {
    this.selectedCategory = categoryKey
    this.filterByCategory(categoryKey)
  }

  // 跳转到所有衣物管理页面
  goToAllClothes() {
    router.pushUrl({ url: 'pages/AllClothesPage' })
  }

  // 跳转到衣物详情页面
  goToClothingDetail(item: Clothing) {
    router.pushUrl({
      url: 'pages/ClothingDetailPage',
      params: { clothingItem: item }
    })
  }

  build() {
    Stack() {
      // 背景图片
      Image(APP_WALLPAPERS[this.wallpaperIndex])
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
        .padding({ left: 20, right: 20, top: 32, bottom: 20 })

        // 圆角矩形容器
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
        Text('+').fontSize(32).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
      }
      .width(56).height(56).backgroundColor('#007AFF').borderRadius(28)
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
      ForEach(this.categories, (category: UICategory) => {
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
    .borderRadius({ topLeft: 24, topRight: 0, bottomLeft: 0, bottomRight: 0 })
  }

  // 右侧网格布局
  @Builder
  buildClothingGrid() {
    Column() {
      if (this.filteredList.length === 0) {
        Column() {
          Text('📭').fontSize(48).margin({ bottom: 16 })
          Text('暂无衣物').fontSize(16).fontColor('#999').margin({ bottom: 8 })
        }
        .width('100%').height('100%').justifyContent(FlexAlign.Center)
      } else {
        Grid() {
          ForEach(this.filteredList, (item: Clothing) => {
            GridItem() {
              Column() {
                if (item.imageUri) {
                  Image(item.imageUri)
                    .width('100%')
                    .aspectRatio(1)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(12)
                } else {
                  Column() { Text('📷').fontSize(40) }
                  .width('100%')
                  .aspectRatio(1)
                  .backgroundColor('#F0F0F0')
                  .borderRadius(12)
                  .justifyContent(FlexAlign.Center)
                }

                Text(ClothingUtils.getLabelBySubCategory(item.subCategory))
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

  // 🌟 核心修改：直接跳转到确认页
  async selectImage() {
    try {
      const photoPicker = new picker.PhotoViewPicker()
      const options: picker.PhotoSelectOptions = {
        MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      }
      const result: picker.PhotoSelectResult = await photoPicker.select(options)
      if (!result || !result.photoUris || result.photoUris.length === 0) return

      const uri: string = result.photoUris[0]

      // 直接把图片 URI 当作参数传过去
      router.pushUrl({
        url: 'pages/ConfirmPage',
        params: { imageUri: uri }
      })

    } catch (error) {
      const err: BusinessError = error as BusinessError
      console.error('选择图片失败: ' + err.message)
    }
  }
}