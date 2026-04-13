import { Clothing } from '../model/Clothing'
import { ClothingRepo } from '../repository/ClothingRepo'
import { ClothingService } from '../service/ClothingService'
import router from '@ohos.router'
// 🌟 引入配置与工具类
import { ClothingUtils } from '../utils/ClothingConfig'
import { APP_WALLPAPERS } from '../utils/BackgroundList';

@Entry
@Component
struct AllClothesPage {
  @State clothingList: Clothing[] = []
  @StorageProp('wallpaper_index') wallpaperIndex: number = 0;

  private repo: ClothingRepo = new ClothingRepo()
  private service: ClothingService = new ClothingService()

  // 页面首次挂载
  aboutToAppear() {
    this.loadData()
  }

  // 🌟 核心：从详情页返回时触发刷新
  onPageShow() {
    this.loadData()
  }

  /**
   * 刷新并加载数据
   */
  async loadData() {
    try {
      const list = await this.repo.getAll()
      // 🌟 技巧：slice().reverse() 创建新数组引用，强制触发 @State 列表刷新
      // 同时保证新添加的衣服在最上面
      this.clothingList = list ? list.slice().reverse() : []
      console.info('AllClothesPage', `数据已同步，共 ${this.clothingList.length} 件`)
    } catch (e) {
      console.error('AllClothesPage', '加载数据失败: ' + JSON.stringify(e))
    }
  }

  // 跳转详情页
  goToDetail(item: Clothing) {
    router.pushUrl({
      url: 'pages/ClothingDetailPage',
      params: { clothingItem: item }
    })
  }

  // 删除逻辑
  deleteClothing(id: string) {
    AlertDialog.show({
      title: '删除确认',
      message: '确定要移除这件衣物吗？相关的穿搭组合也将被清理。',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '删除',
        fontColor: '#FF4D4F',
        action: async () => {
          const isSuccess = await this.service.deleteClothingSafely(id)
          if (isSuccess) {
            this.loadData()
          }
        }
      }
    })
  }

  build() {
    Stack() {
      // 1. 背景层
      Image(APP_WALLPAPERS[this.wallpaperIndex])
        .width('100%').height('100%').objectFit(ImageFit.Cover)

      Column() {
        // 2. 顶部标题栏
        Row() {
          Button('返回')
            .width(70).height(36).backgroundColor('rgba(255,255,255,0.8)')
            .fontColor('#333').borderRadius(18)
            .onClick(() => router.back())

          Blank()
          Text('我的衣橱').fontSize(22).fontWeight(FontWeight.Bold).fontColor('#333')
          Blank()

          Row().width(70) // 占位保持标题居中
        }
        .width('100%').padding({ left: 16, right: 16, top: 32, bottom: 32 })

        // 3. 列表内容区
        if (this.clothingList.length === 0) {
          this.buildEmptyState()
        } else {
          List({ space: 10 }) {
            ForEach(this.clothingList, (item: Clothing) => {
              ListItem() {
                Row() {
                  // --- 左侧图片 ---
                  Image(item.imageUri)
                    .width(70).height(70).borderRadius(8).objectFit(ImageFit.Cover)
                    .margin({ right: 12 })

                  // --- 中间信息 ---
                  Column({ space: 6 }) {
                    // 🌟 调用工具类：获取中文款式名
                    Text(ClothingUtils.getLabelBySubCategory(item.subCategory))
                      .fontSize(17).fontWeight(FontWeight.Medium).fontColor('#333')

                    Row({ space: 10 }) {
                      // 🌟 调用工具类：获取颜色 Hex 和中文标签
                      Row({ space: 4 }) {
                        Circle({ width: 10, height: 10 }).fill(ClothingUtils.getColorHex(item.color))
                        Text(ClothingUtils.getColorLabel(item.color)).fontSize(13).fontColor('#666')
                      }

                      Text('|').fontColor('#EEE').fontSize(12)

                      // 保暖指数
                      //Text(`🔥 指数 ${item.warmthIndex}`).fontSize(13).fontColor('#666')
                    }
                  }
                  .layoutWeight(1).alignItems(HorizontalAlign.Start)

                  // --- 右侧按钮 ---
                  Row({ space: 8 }) {
                    Button('详情')
                      .width(62).height(32).fontSize(13).padding(0) // 🌟 宽度调优，消除 ...
                      .backgroundColor('#E6F7FF').fontColor('#007AFF').borderRadius(16)
                      .onClick(() => this.goToDetail(item))

                    Button('删除')
                      .width(62).height(32).fontSize(13).padding(0) // 🌟 宽度调优
                      .backgroundColor('#FFF1F0').fontColor('#FF4D4F').borderRadius(16)
                      .onClick(() => { if (item.id) this.deleteClothing(item.id) })
                  }
                }
                .width('100%').padding(12).backgroundColor('rgba(255,255,255,0.95)')
                .borderRadius(15).shadow({ radius: 4, color: '#10000000' })
              }
            }, (item: Clothing) => item.id + item.wearCount.toString()) // 🌟 Key 绑定 wearCount 强制内容更新
          }
          .width('100%').layoutWeight(1).padding({ left: 16, right: 16 })
        }
      }
      .width('100%').height('100%')
    }
  }

  // 空状态展示
  @Builder buildEmptyState() {
    Column() {
      Text('👗').fontSize(60).margin({ bottom: 10 })
      Text('衣橱空荡荡，快去添加吧').fontColor('#999').fontSize(16)
    }.width('100%').height('100%').justifyContent(FlexAlign.Center)
  }
}