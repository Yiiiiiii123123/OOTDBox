import { Clothing } from '../model/Clothing'
import { ClothingRepo } from '../repository/ClothingRepo'
import { ClothingService } from '../service/ClothingService'
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { ClothingUtils } from '../utils/ClothingConfig'
import { APP_WALLPAPERS } from '../utils/BackgroundList'
import { DataMigrationService } from '../service/DataMigrationService'
import common from '@ohos.app.ability.common'

//所有衣物管理页

@Entry
@Component
struct AllClothesPage {

  @State clothingList: Clothing[] = []
  @StorageProp('wallpaper_index') wallpaperIndex: number = 0;

  private service: ClothingService = new ClothingService()
  private migrationService: DataMigrationService = new DataMigrationService()

  // 触发刷新
  onPageShow() {
    this.loadData()
  }

  /**
   * 刷新并加载数据
   */
  async loadData() {
    try {
      const list = await this.service.getAllClothes();
      // slice().reverse() 创建新数组引用，强制触发 @State 列表刷新
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

  //导出数据
  async handleExportData() {
    // 拿到当前页面的上下文，必须要有它才能读写沙盒！
    const context = getContext(this) as common.UIAbilityContext;
    promptAction.showToast({ message: '正在打包数据...' });

    const success = await this.migrationService.exportData(context);
    if (success) {
      promptAction.showToast({ message: '导出成功！已保存到手机' });
    } else {
      promptAction.showToast({ message: '导出失败或取消' });
    }
  }

  //导入衣橱
  async handleImportData() {
    const context = getContext(this) as common.UIAbilityContext;
    promptAction.showToast({ message: '正在解析数据包...' });

    //接收返回的具体信息
    const result = await this.migrationService.importData(context);

    // 把底层的具体原因或成功提示弹出来！
    //promptAction.showToast({ message: result.msg });

    // 如果成功了，就刷新页面列表
    if (result.success) {
      this.loadData();
    }
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

          // 保持宽度 70，是为了和左侧的“返回”按钮对称，让“我的衣橱”绝对居中
          Row() {
            Image($r('app.media.icon_database')) // 确保你的图片在这个路径下
              .width(28)
              .height(28)
              .objectFit(ImageFit.Contain)
                // 绑定系统原生下拉菜单
              .bindMenu([
                {
                  value: '导出衣橱数据',
                  action: () => {
                    this.handleExportData()
                  }
                },
                {
                  value: '载入衣橱数据',
                  action: () => {
                    this.handleImportData()
                  }
                }
              ])
          }
          .width(70)
          .justifyContent(FlexAlign.End) // 让图标靠最右边显示
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
                    // 调用工具类：获取中文款式名
                    Text(ClothingUtils.getLabelBySubCategory(item.subCategory))
                      .fontSize(17).fontWeight(FontWeight.Medium).fontColor('#333')

                    Row({ space: 10 }) {
                      // 调用工具类：获取颜色 Hex 和中文标签
                      Row({ space: 4 }) {
                        Circle({ width: 10, height: 10 }).fill(ClothingUtils.getColorHex(item.color))
                        Text(ClothingUtils.getColorLabel(item.color)).fontSize(13).fontColor('#666')
                      }

                      Text('|').fontColor('#EEE').fontSize(12)

                    }
                  }
                  .layoutWeight(1).alignItems(HorizontalAlign.Start)

                  // --- 右侧按钮 ---
                  Row({ space: 8 }) {
                    Button('详情')
                      .width(62).height(32).fontSize(13).padding(0)
                      .backgroundColor('#E6F7FF').fontColor('#007AFF').borderRadius(16)
                      .onClick(() => this.goToDetail(item))

                    Button('删除')
                      .width(62).height(32).fontSize(13).padding(0)
                      .backgroundColor('#FFF1F0').fontColor('#FF4D4F').borderRadius(16)
                      .onClick(() => { if (item.id) this.deleteClothing(item.id) })
                  }
                }
                .width('100%').padding(12).backgroundColor('rgba(255,255,255,0.95)')
                .borderRadius(15).shadow({ radius: 4, color: '#10000000' })
              }
            }, (item: Clothing) => item.id + item.wearCount.toString() + item.imageUri) // Key 绑定 wearCount 强制内容更新
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