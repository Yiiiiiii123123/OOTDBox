import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { Clothing } from '../model/Clothing';
import { ClothingRepo } from '../repository/ClothingRepo';
import { ClothingService } from '../service/ClothingService';
import { ClothingUtils } from '../utils/ClothingConfig';
import { APP_WALLPAPERS } from '../utils/BackgroundList';

//配饰选择页

// ==================== 终极确认弹窗组件 ====================
@CustomDialog
struct OutfitConfirmDialog {
  controller: CustomDialogController
  // 接收合并后的所有衣服和饰品
  finalOutfit: Clothing[] = []
  temperature: number = 20

  @State isFavorited: boolean = false
  @StorageProp('wallpaper_index') wallpaperIndex: number = 0;

  // 核心操作回调，由父页面传入具体实现
  confirmAction: () => void = () => {}
  toggleFavorite: () => void = () => {}

  build() {
    Stack() {
      // 背景层
      Image(APP_WALLPAPERS[this.wallpaperIndex])
        .width('100%')
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      Column() {
        Text('✨ 今日完美穿搭 ✨')
          .fontSize(22).fontWeight(FontWeight.Bold).fontColor(Color.White)
          .margin({ top: 30, bottom: 20 })

        // 🌟 核心：3列网格展示所有单品
        Grid() {
          ForEach(this.finalOutfit, (item: Clothing) => {
            GridItem() {
              Image(item.imageUri)
                .width(80).height(80)
                .borderRadius(12)
                .objectFit(ImageFit.Cover)
                .border({ width: 2, color: 'rgba(255,255,255,0.2)' })
            }
          })
        }
        .columnsTemplate('1fr 1fr 1fr') // 固定 3 列
        .columnsGap(10).rowsGap(10)
        .width('90%')
        .height(this.finalOutfit.length > 6 ? 280 : 190) // 根据数量动态调整高度

        Blank()

        // 底部按钮区
        Row({ space: 20 }) {
          // 收藏星星按钮
          Column() {
            Image(this.isFavorited ? $r('app.media.ic_favorite_filled') : $r('app.media.ic_favorite_border'))
              .width(36).height(36)
              .fillColor(this.isFavorited ? '#FFD700' : '#FFFFFF') // 点亮时变成金色
              .animation({ duration: 300, curve: Curve.EaseInOut })
            Text(this.isFavorited ? '已收藏' : '收藏').fontSize(12).fontColor(Color.White).margin({ top: 4 })
          }
          .onClick(() => {
            this.isFavorited = !this.isFavorited;
            this.toggleFavorite();
          })

          // 确认穿戴按钮
          Button('就穿这套！')
            .layoutWeight(1).height(50).borderRadius(25)
            .backgroundColor('#007AFF').fontColor(Color.White)
            .fontSize(18).fontWeight(FontWeight.Bold)
            .onClick(() => {
              this.confirmAction();
              this.controller.close();
            })
        }
        .width('90%').margin({ bottom: 30 })
      }
      .width('100%').height('100%')
    }
    .width('90%')
    .height(450)
    .borderRadius(24)
    .clip(true)
  }
}

// ==================== 饰品选择主页面 ====================
@Entry
@Component
struct AccessorySelectionPage {
  // 接收上一页传来的基础穿搭
  @State baseOutfit: Clothing[] = [];
  @State temperature: number = 20;

  // 饰品数据状态
  @State allAccessories: Clothing[] = [];
  @State subCategories: string[] = []; // 动态提取的二级分类列表
  @State currentCategory: string = ''; // 当前选中的左侧分类

  // 用户选中的饰品
  @State selectedAccessories: Clothing[] = [];

  private repo = new ClothingRepo();
  private clothingService = new ClothingService();

  // 注册弹窗控制器
  dialogController: CustomDialogController = new CustomDialogController({
    builder: OutfitConfirmDialog({
      finalOutfit: [...this.baseOutfit, ...this.selectedAccessories],
      temperature: this.temperature,
      confirmAction: () => { this.confirmOutfit(); },
      toggleFavorite: () => { this.saveToFavorite(); }
    }),
    customStyle: true, // 允许弹窗完全自定义样式和圆角
    alignment: DialogAlignment.Center
  })

  aboutToAppear() {
    // 解析路由参数
    let params = router.getParams() as Record<string, Object>;
    if (params) {
      this.baseOutfit = (params.baseOutfit as Clothing[]) || [];
      this.temperature = (params.temperature as number) || 20;
    }
    this.loadAccessories();
  }

  //加载配饰分类
  async loadAccessories() {
    // 只拿数组，简单直接
    this.allAccessories = await this.clothingService.getAccessories();

    // 分类列表直接从工具类里拿“全集”
    this.subCategories = ClothingUtils.getAccessorySubCategories();

    if (this.subCategories.length > 0) {
      this.currentCategory = this.subCategories[0];
    }
  }

  // 选中或取消选中饰品逻辑
  toggleAccessory(item: Clothing) {
    let index = this.selectedAccessories.findIndex(c => c.id === item.id);
    if (index > -1) {
      // 如果已经选中，则取消
      this.selectedAccessories.splice(index, 1);
    } else {
      // 如果未选中，判断是否达到上限
      if (this.selectedAccessories.length >= 6) {
        promptAction.showToast({ message: '饰品最多只能戴 6 件哦，太多就沉啦~' });
        return;
      }
      this.selectedAccessories.push(item);
    }
  }

  // 弹窗内的打卡逻辑
  async confirmOutfit() {
    let finalOutfit = [...this.baseOutfit, ...this.selectedAccessories];
    promptAction.showToast({ message: 'OOTD 记录中...' });

    await this.clothingService.confirmDailyOutfit(finalOutfit);
    // 新增这行代码：把最终穿搭发给全系统！首页一听到就更新了！
    AppStorage.setOrCreate('todayOutfit', finalOutfit);
    promptAction.showToast({ message: '打卡成功！你今天真好看 ✨' });
    setTimeout(() => { router.back({ url: 'pages/HomePage' }) }, 800); // 彻底回到主页
  }

  // 🌟 弹窗内的收藏逻辑
  async saveToFavorite() {
    let finalOutfit = [...this.baseOutfit, ...this.selectedAccessories];
    await this.clothingService.saveToFavorite(finalOutfit, this.temperature);
    promptAction.showToast({ message: '已加入收藏夹 🌟' });
  }

  build() {
    Column() {
      // 1. 顶部栏
      Row() {
        Text('< 返回').fontSize(16).fontColor('#333').onClick(() => router.back())
        Blank()
        Text(`已选饰品: ${this.selectedAccessories.length}/6`).fontSize(14).fontColor('#666')
      }
      .width('90%').height(56).margin({ top: 30 })

      // 2. 顶部基础穿搭展示 (横向滑动)
      Scroll() {
        Row({ space: 10 }) {
          ForEach(this.baseOutfit, (item: Clothing) => {
            Image(item.imageUri)
              .width(70).height(70).borderRadius(8).objectFit(ImageFit.Cover)
          })
        }.padding({ left: 20, right: 20 })
      }.scrollable(ScrollDirection.Horizontal).width('100%').margin({ bottom: 10 })

      // 3. 提示小字
      Text('💡 挑选同色或撞色可以让搭配更出彩哦~')
        .fontSize(12).fontColor('#FF7F50').backgroundColor('#FFF5EE')
        .padding({ left: 12, right: 12, top: 6, bottom: 6 }).borderRadius(12)
        .margin({ bottom: 15 })

      // 4. 核心：3:7 左右联动布局
      Row() {
        // 左侧：30% 分类菜单
        List() {
          ForEach(this.subCategories, (sub: string) => {
            ListItem() {
              Text(ClothingUtils.getLabelBySubCategory(sub))
                .fontSize(14)
                .fontWeight(this.currentCategory === sub ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.currentCategory === sub ? '#007AFF' : '#666')
                .width('100%').textAlign(TextAlign.Center).padding({ top: 20, bottom: 20 })
                .backgroundColor(this.currentCategory === sub ? Color.White : '#F5F5F5')
            }.onClick(() => { this.currentCategory = sub; })
          })
        }.width('30%').height('100%').backgroundColor('#F5F5F5')

        // 右侧：70% 饰品网格展示区
        Stack() {
          if (this.allAccessories.filter(c => c.subCategory === this.currentCategory).length > 0) {
            Grid() {
              ForEach(this.allAccessories.filter(c => c.subCategory === this.currentCategory), (acc: Clothing) => {
                GridItem() {
                  Stack({ alignContent: Alignment.TopEnd }) {

                    Image(acc.imageUri)
                      .width('100%').aspectRatio(1).borderRadius(8).objectFit(ImageFit.Cover)
                      .opacity(this.selectedAccessories.some(c => c.id === acc.id) ? 0.6 : 1)

                    // 选中时的遮罩和打勾符号
                    if (this.selectedAccessories.some(c => c.id === acc.id)) {
                      Row().width('100%').aspectRatio(1).borderRadius(8).border({ width: 2, color: '#007AFF' })
                      Circle({ width: 20, height: 20 }).fill('#007AFF').margin(4)
                      Text('✓').fontColor(Color.White).fontSize(12).fontWeight(FontWeight.Bold).margin({ top: 6, right: 8 })
                    }
                  }.onClick(() => this.toggleAccessory(acc))
                }
              })
            }
            .columnsTemplate('1fr 1fr 1fr') // 右边排  3列
            .columnsGap(10).rowsGap(10)
            .width('70%').height('100%').padding(10).backgroundColor(Color.White)
          }else {
            // 增加空状态占位
            Text('该分类下暂无饰品').fontColor('#999').fontSize(14)
          }
        }.layoutWeight(1)


      }.layoutWeight(1).width('100%')

      // 5. 底部完成按钮
      Button('完成穿搭 🚀')
        .width('90%').height(50).borderRadius(25).margin({ top: 15, bottom: 30 })
        .backgroundColor('#007AFF').fontColor(Color.White).fontSize(18).fontWeight(FontWeight.Bold)
        .onClick(() => {
          // 呼出确认弹窗
          // 注意：必须重新给弹窗传递最新的合并数据
          this.dialogController = new CustomDialogController({
            builder: OutfitConfirmDialog({
              finalOutfit: [...this.baseOutfit, ...this.selectedAccessories],
              temperature: this.temperature,
              confirmAction: () => {this.confirmOutfit()},
              toggleFavorite: () => {this.saveToFavorite()}
            }),
            customStyle: true, alignment: DialogAlignment.Center
          });
          this.dialogController.open();
        })
    }.width('100%').height('100%').backgroundColor(Color.White)
  }
}