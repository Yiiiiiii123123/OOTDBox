import router from '@ohos.router';
import { Clothing } from '../model/Clothing';
import { ClothingService } from '../service/ClothingService';
import { ClothingUtils } from '../utils/ClothingUtils';

@Entry
@Component
struct FavoriteOutfitPage {
  // 🌟 二维数组：外层是“套”，内层是“件”
  @State favoriteOutfits: Array<Clothing[]> = [];
  @State isLoading: boolean = true;

  private service: ClothingService = new ClothingService();

  aboutToAppear() {
    this.loadFavorites();
  }

  async loadFavorites() {
    this.isLoading = true;
    try {
      // 🌟 现在这个调用是真实的了！
      const data = await this.service.getFavoriteOutfits();
      this.favoriteOutfits = data;
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      // 导航栏
      Row() {
        Text('返回').fontColor('#007AFF').onClick(() => router.back())
        Text('我的收藏搭配').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 20 })
      }
      .width('100%').padding({ left: 16, top: 50, bottom: 20 })

      if (this.isLoading) {
        LoadingProgress().width(50).height(50).layoutWeight(1)
      } else if (this.favoriteOutfits.length === 0) {
        Column() {
          Text('💝').fontSize(60).margin({ bottom: 10 })
          Text('还没有收藏过穿搭哦').fontColor('#999')
        }.layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List({ space: 20 }) {
          ForEach(this.favoriteOutfits, (outfit: Clothing[]) => {
            ListItem() {
              this.buildOutfitCard(outfit)
            }
          })
        }
        .width('100%').layoutWeight(1).padding(16)
      }
    }
    .width('100%').height('100%').backgroundColor('#F5F5F5')
  }

  // 🌟 核心 UI：整套穿搭的预览卡片
  @Builder buildOutfitCard(outfit: Clothing[]) {
    Column() {
      // 1. 图片并排展示区
      Scroll() {
        Row({ space: 10 }) {
          ForEach(outfit, (item: Clothing) => {
            Column({ space: 5 }) {
              Image(item.imageUri)
                .width(100).height(100).borderRadius(8).objectFit(ImageFit.Cover)
              Text(ClothingUtils.getLabelBySubCategory(item.subCategory))
                .fontSize(12).fontColor('#666')
            }
          })
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%').padding(15)

      // 2. 底部操作栏
      Row() {
        Text(`共 ${outfit.length} 件单品`).fontSize(12).fontColor('#999')
        Blank()
        Button('今日穿着')
          .height(30).fontSize(12).backgroundColor('#007AFF')
          .onClick(() => {
            // TODO: 批量增加这几件衣服的 wearCount
          })
      }
      .width('100%').padding({ left: 15, right: 15, bottom: 15 })
    }
    .backgroundColor(Color.White).borderRadius(16).shadow({ radius: 8, color: '#05000000' })
  }
}