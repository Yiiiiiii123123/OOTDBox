import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { Clothing } from '../model/Clothing';
import { ClothingService, OutfitViewData } from '../service/ClothingService';
import { ClothingUtils } from '../utils/ClothingConfig';

@Entry
@Component
struct FavoriteOutfitPage {
  @State favoriteOutfits: Array<OutfitViewData> = [];
  @State isLoading: boolean = true;

  private service: ClothingService = new ClothingService();

  aboutToAppear() {
    this.loadFavorites();
  }

  async loadFavorites() {
    this.isLoading = true;
    try {
      this.favoriteOutfits = await this.service.getFavoriteOutfits() || [];
    } finally {
      this.isLoading = false;
    }
  }

  async handleWearOutfit(outfit: Clothing[]) {
    try {
      promptAction.showToast({ message: '打卡记录中...' });
      const currentTime = new Date().getTime();
      for (let i = 0; i < outfit.length; i++) {
        let item = outfit[i];
        item.wearCount = (item.wearCount || 0) + 1;
        item.lastWornDate = currentTime;
        await this.service.updateClothing(item);
      }
      promptAction.showToast({ message: '打卡成功！各单品数据已更新 ✨' });
    } catch (error) {
      promptAction.showToast({ message: '记录失败，请重试' });
    }
  }

  handleDeleteOutfit(index: number, viewData: OutfitViewData) {
    promptAction.showDialog({
      title: '移除收藏',
      message: '确定要将这套搭配从收藏夹移除吗？',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '移除', color: '#FF4B4B' }
      ]
    }).then(async (data) => {
      if (data.index === 1) {
        this.favoriteOutfits.splice(index, 1);
        await this.service.deleteFavoriteOutfit(viewData.outfitId);
        promptAction.showToast({ message: '已移除收藏' });
      }
    });
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
        // 🌟 核心修改：使用 List 替换 Scroll + Column，天然支持从上往下排列
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