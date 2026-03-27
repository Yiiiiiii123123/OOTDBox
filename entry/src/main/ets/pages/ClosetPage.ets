import { Clothing } from '../model/Clothing'
import { ClothingRepo } from '../repository/ClothingRepo'
import { ClothingService } from '../service/ClothingService'
import { BusinessError } from '@kit.BasicServicesKit'
import { picker } from '@kit.CoreFileKit'
import router from '@ohos.router'

// 定义分类类型
type CategoryKey = 'all' | '上衣' | '外套' | '裤子' | '鞋子'

// 定义分类接口
interface Category {
  key: CategoryKey
  label: string
  icon: string
}

// 定义统计数据接口
interface CategoryStat {
  category: Category
  count: number
}

@Entry
@Component
struct ClosetPage {

  @State clothingList: Clothing[] = []
  @State filteredList: Clothing[] = []
  @State selectedCategory: CategoryKey = 'all'
  @State showMenu: boolean = false
  @State categoryStats: CategoryStat[] = []  // 存储统计数据

  private repo: ClothingRepo = new ClothingRepo()
  private service: ClothingService = new ClothingService()

  // 分类列表配置
  private categories: Category[] = [
    { key: 'all', label: '全部', icon: '📦' },
    { key: '上衣', label: '上衣', icon: '👕' },
    { key: '外套', label: '外套', icon: '🧥' },
    { key: '裤子', label: '裤子', icon: '👖' },
    { key: '鞋子', label: '鞋子', icon: '👟' }
  ]

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
      this.filterByCategory(this.selectedCategory)
      this.updateCategoryStats()  // 更新统计数据
    } catch (e) {
      console.error('加载失败', e)
    }
  }

  // 更新各分类的统计数据
  updateCategoryStats() {
    const stats: CategoryStat[] = []

    // 遍历所有分类（排除"全部"）
    for (const category of this.categories) {
      if (category.key === 'all') {
        continue
      }

      // 计算该分类的衣物数量
      const count = this.clothingList.filter(item => {
        const itemCategory = item.category || ''
        return itemCategory === category.key
      }).length

      stats.push({
        category: category,
        count: count
      })
    }

    this.categoryStats = stats
  }

  // 根据分类过滤衣物
  filterByCategory(category: CategoryKey) {
    if (category === 'all') {
      this.filteredList = [...this.clothingList]
    } else {
      this.filteredList = this.clothingList.filter(item => {
        const itemCategory = item.category || ''
        return itemCategory === category
      })
    }
  }

  // 切换分类
  selectCategory(category: CategoryKey) {
    this.selectedCategory = category
    this.filterByCategory(category)
    if (this.showMenu) {
      this.showMenu = false
    }
  }

  // 获取当前分类显示名称
  getCurrentCategoryLabel(): string {
    const category = this.categories.find(c => c.key === this.selectedCategory)
    return category ? `${category.icon} ${category.label}` : '全部'
  }

  build() {
    Row() {
      // 左侧分类栏
      this.buildCategorySidebar()

      // 右侧内容区
      Column() {

        // 衣橱标题和添加按钮
        this.buildHeader()

        // 衣物列表
        this.buildClothingList()
      }
      .layoutWeight(1)
      .height('100%')
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
  }

  // 左侧分类栏
  @Builder
  buildCategorySidebar() {
    Column() {
      Text('分类')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 30, bottom: 20 })

      // 分类按钮列表
      ForEach(this.categories, (category: Category) => {
        Button(`${category.icon} ${category.label}`)
          .width('100%')
          .height(50)
          .backgroundColor(this.selectedCategory === category.key ? '#007AFF' : '#FFFFFF')
          .fontColor(this.selectedCategory === category.key ? '#FFFFFF' : '#333333')
          .margin({ bottom: 8 })
          .onClick(() => {
            this.selectCategory(category.key)
          })
      })

      Blank()

      // 统计信息区域
      Column() {
        Text(`共 ${this.clothingList.length} 件衣物`)
          .fontSize(12)
          .fontColor('#999')
          .margin({ bottom: 8 })

        // 使用预计算的统计数据
        ForEach(this.categoryStats, (stat: CategoryStat) => {
          Row() {
            Text(`${stat.category.icon} ${stat.category.label}: ${stat.count}件`)
              .fontSize(11)
              .fontColor('#999')
          }
          .margin({ bottom: 4 })
        })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#F8F8F8')
      .borderRadius(12)
      .margin({ bottom: 20 })
    }
    .width('25%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .padding({ left: 16, right: 16 })
    .border({ width: { right: 1 }, color: '#E5E5E5' })
  }

  // 标题和添加按钮
  @Builder
  buildHeader() {
    Row() {

      Text('我的衣橱')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)

      Blank()

      Button('添加衣物')
        .width(100)
        .height(40)
        .backgroundColor('#007AFF')
        .fontSize(14)
        .onClick(async () => {
          await this.selectImage()
        })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 20, bottom: 12 })
    .backgroundColor('#FFFFFF')
  }

  // 衣物列表
  @Builder
  buildClothingList() {
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

          Text('点击"添加衣物"开始管理你的衣橱')
            .fontSize(14)
            .fontColor('#CCC')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List() {
          ForEach(this.filteredList, (item: Clothing) => {
            ListItem() {
              this.buildClothingItem(item)
            }
          }, (item: Clothing) => String(item.id ?? Date.now() + Math.random()))
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 8 })
      }
    }
    .layoutWeight(1)
    .width('100%')
  }

  // 单个衣物卡片
  @Builder
  buildClothingItem(item: Clothing) {
    Row() {
      // 图片
      if (item.imageUri) {
        Image(item.imageUri)
          .width(80)
          .height(80)
          .objectFit(ImageFit.Cover)
          .borderRadius(8)
          .margin({ right: 15 })
      } else {
        Column() {
          Text('📷')
            .fontSize(40)
        }
        .width(80)
        .height(80)
        .backgroundColor('#F0F0F0')
        .borderRadius(8)
        .justifyContent(FlexAlign.Center)
        .margin({ right: 15 })
      }

      // 衣物信息
      Column() {
        Text(`${this.getCategoryIcon(item.category)} ${item.category || '无分类'}`)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 4 })

        Row() {
          Text('🎨')
            .fontSize(12)
            .margin({ right: 4 })
          Text(item.color || '未标注')
            .fontSize(14)
            .fontColor('#666')
        }
        .margin({ bottom: 4 })


      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 删除按钮
      Button('删除')
        .fontSize(12)
        .backgroundColor('#ff4d4f')
        .width(60)
        .height(32)
        .onClick(async () => {
          if (item.id !== undefined) {
            await this.handleDelete(item.id)
          }
        })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 12 })
    .shadow({ radius: 4, color: '#00000010' })
  }

  // 获取分类图标
  getCategoryIcon(category?: string): string {
    switch (category) {
      case '上衣': return '👕'
      case '外套': return '🧥'
      case '裤子': return '👖'
      case '鞋子': return '👟'
      default: return '📄'
    }
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

      console.log('AI结果:', draft)

      router.pushUrl({
        url: 'pages/ConfirmPage',
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