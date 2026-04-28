import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { Clothing } from '../model/Clothing';
import { ClothingService, OutfitViewData } from '../service/ClothingService';
import { ClothingUtils } from '../utils/ClothingConfig';

//收藏的穿搭页面

@Entry
@Component
struct FavoriteOutfitPage {
  @State favoriteOutfits: Array<OutfitViewData> = [];
  @State isLoading: boolean = true;
  @StorageProp('currentTemp') currentTemp: number = 20;

  private service: ClothingService = new ClothingService();

  onPageShow() {
    this.loadFavorites();
  }

  //加载穿搭数据
  async loadFavorites() {
    this.isLoading = true;
    try {
      this.favoriteOutfits = await this.service.getFavoriteOutfits() || [];
    } finally {
      this.isLoading = false;
    }
  }

  async handleWearOutfit(outfitItems: Clothing[]) {
    try {
      // 🌟 1. 定义什么是“基础衣物”（根据你的业务逻辑，通常是这五类）
      const baseCategories = ['outerwear', 'top', 'bottom', 'one_piece', 'shoes'];

      // 🌟 2. 阵型剥离：利用 filter 把混合数组拆成两拨
      const baseClothes = outfitItems.filter(item => baseCategories.includes(item.mainCategory));
      const accessories = outfitItems.filter(item => !baseCategories.includes(item.mainCategory));

      // 🌟 3. 完美调用新版打卡方法，算自推荐
      await this.service.confirmDailyOutfit(baseClothes, accessories, this.currentTemp, true);

      promptAction.showToast({ message: '打卡成功！各单品数据已更新 ✨' });
    } catch (error) {
      console.error('FavoritePage', '打卡异常: ' + JSON.stringify(error));
      promptAction.showToast({ message: '记录失败，请重试' });
    }
  }

  async handleDeleteOutfit(index: number, viewData: OutfitViewData) {
    // 1. 直接 await 弹窗结果，代码瞬间变平级！没有嵌套了！
    const data = await promptAction.showDialog({
      title: '移除收藏',
      message: '确定要将这套搭配从收藏夹移除吗？',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '移除', color: '#FF4B4B' }
      ]
    });

    // 2. 判断用户的选择
    if (data.index === 1) {
      // 3. 等待数据库彻底删除
      const success = await this.service.deleteFavoriteOutfit(viewData.outfit.id);

      // 4. 根据真实结果决定是否刷新界面
      if (success) {
        this.favoriteOutfits.splice(index, 1);
        promptAction.showToast({ message: '已移除收藏' });
      } else {
        promptAction.showToast({ message: '移除失败，请检查数据库状态' });
      }
    }
  }

  build() {
    Column() {
      // 导航栏
      Row() {
        Button('< 返回')
          .backgroundColor(Color.Transparent).fontColor('#333')
          .fontSize(16).fontWeight(FontWeight.Medium).padding({ left: 0 })
          .onClick(() => router.back())
        Blank()
        Text('收藏穿搭').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#333')
        Blank()
        Text('').width(60)
      }
      .width('100%').height(56).padding({ left: 20, right: 20 }).backgroundColor(Color.White)

      // 主体内容
      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40).color('#007AFF')
          Text('加载中...').fontSize(14).fontColor('#999').margin({ top: 10 })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.favoriteOutfits.length === 0) {
        Column({ space: 16 }) {
          Text('✨').fontSize(50)
          Text('还没有收藏过搭配哦').fontSize(15).fontColor('#999')
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        //使用 List ，天然支持从上往下排列
        List({ space: 20 }) {
          ForEach(this.favoriteOutfits, (viewData: OutfitViewData, index: number) => {
            ListItem() {
              this.buildOutfitCard(viewData, index)
            }
          })

          // 底部防遮挡留白作为单独的 ListItem
          ListItem() {
            Row().width('100%').height(40) // 用一个空的 Row 完美替代 Blank
          }
        }
        .width('100%')
        .layoutWeight(1) // 占满剩余高度
        .padding({ left: 16, right: 16, top: 16 })
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring) // 添加鸿蒙原生的边缘回弹效果，手感更高级
      }
    }
    .width('100%').height('100%').backgroundColor('#F5F7FA')
  }

  @Builder buildOutfitCard(viewData: OutfitViewData, index: number) {
    Column() {
      Scroll() {
        Row({ space: 12 }) {
          ForEach(viewData.clothes, (item: Clothing) => {
            Column({ space: 8 }) {
              Image(item.imageUri).width(100).aspectRatio(1).borderRadius(12).objectFit(ImageFit.Cover).border({ width: 0.5, color: 'rgba(0,0,0,0.05)' })
              Text(ClothingUtils.getLabelBySubCategory(item.subCategory.toString())).fontSize(12).fontWeight(FontWeight.Medium).fontColor('#444')
            }
          })
        }
        .padding({ left: 16, right: 16, top: 20, bottom: 16 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')

      Divider().color('rgba(0,0,0,0.03)').strokeWidth(1).padding({ left: 16, right: 16 })

      Row() {
        Text(`共 ${viewData.clothes.length} 件单品`).fontSize(13).fontColor('#999')
        Blank()

        Button('移除')
          .height(32).fontSize(13).fontColor('#666').backgroundColor('#F0F0F0').margin({ right: 12 })
          .onClick(() => this.handleDeleteOutfit(index, viewData))

        Button('就穿这套')
          .height(32).fontSize(13).fontWeight(FontWeight.Medium).fontColor(Color.White).backgroundColor('#007AFF').shadow({ radius: 6, color: 'rgba(0, 122, 255, 0.3)', offsetY: 2 })
          .onClick(() => this.handleWearOutfit(viewData.clothes))
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 16 })
      .alignItems(VerticalAlign.Center)
    }
    .backgroundColor(Color.White).borderRadius(16).shadow({ radius: 10, color: 'rgba(0,0,0,0.04)', offsetY: 4 })
  }
}