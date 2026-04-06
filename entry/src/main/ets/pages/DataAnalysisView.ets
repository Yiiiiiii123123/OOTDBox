import router from '@ohos.router'; // 🌟 必须引入路由模块才能实现返回

class FavoriteItem {
  id: number = 0;
  name: string = '';
  image: ResourceStr = ''; // ResourceStr 兼容 $r() 和 字符串路径
  wearCount: number = 0;
}

class WarningItem {
  id: number = 0;
  name: string = '';
  image: ResourceStr = '';
  reason: string = '';
}

@Entry
@Component
struct DataAnalysisView {
  // --- 1. 模拟假数据 (方便预览 UI) ---

  // 环形图数据 (上装40%, 下装30%, 鞋子20%, 配饰10%)
  private categoryValues: number[] = [40, 30, 20, 10];

  // 颜色盘 (对应上装、下装、鞋子、配饰)
  private colorPalette: string[] = ['#FF7A8A', '#7A9BFF', '#FFD166', '#06D6A0'];

  // 🌟 修改：指定类型为 FavoriteItem[]，并加上 as 断言
  private topFavorites: FavoriteItem[] = [
    { id: 1, name: '纯棉白T恤', image: $r('app.media.background1'), wearCount: 15 } as FavoriteItem,
    { id: 2, name: '直筒牛仔裤', image: $r('app.media.background1'), wearCount: 12 } as FavoriteItem,
    { id: 3, name: '黑色马丁靴', image: $r('app.media.background1'), wearCount: 8 } as FavoriteItem
  ];

  // 🌟 修改：指定类型为 WarningItem[]，并加上 as 断言
  private idleWarnings: WarningItem[] = [
    { id: 4, name: '碎花雪纺裙', image: $r('app.media.background1'), reason: '系统推荐 8 次，均未采纳' } as WarningItem,
    { id: 5, name: '荧光绿卫衣', image: $r('app.media.background1'), reason: '系统推荐 5 次，均未采纳' } as WarningItem
  ];

  build() {
    Scroll() {
      Column({ space: 20 }) {
        // --- 标题区 (🌟 已加入返回按钮) ---
        Row() {
          Button('返回')
            .width(60)
            .height(32)
            .backgroundColor('rgba(0,0,0,0.05)')
            .fontColor('#333')
            .fontSize(14)
            .margin({ right: 12 })
            .onClick(() => router.back())

          Text('衣橱数据洞察')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333')
        }
        .width('100%')
        .padding({ left: 10, top: 20, bottom: 10 })
        .alignItems(VerticalAlign.Center) // 确保返回按钮和标题垂直居中对齐

        // --- 卡片 1：品类占比 (环形图) ---
        this.buildCategoryCard()

        // --- 卡片 2：红榜 - 最爱 Top 3 ---
        this.buildTopFavoriteCard()

        // --- 卡片 3：黑榜 - 吃灰预警 ---
        this.buildIdleWarningCard()

        // 底部留白
        Blank().height(40)
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      .backgroundColor('#F5F7FA') // 浅灰蓝色背景，让白色卡片更凸显
    }
    .width('100%')
    .height('100%')
  }

  // ================= 拆分组件 Builder =================

  // 📈 卡片 1: 品类占比
  @Builder buildCategoryCard() {
    Column() {
      Text('品类构成占比')
        .fontSize(16).fontWeight(FontWeight.Medium).fontColor('#444')
        .width('100%').margin({ bottom: 20 })

      Row() {
        // 左侧：使用鸿蒙自带的 DataPanel 绘制环形图
        DataPanel({ values: this.categoryValues, max: 100, type: DataPanelType.Circle })
          .width(120).height(120)
          .valueColors(this.colorPalette)

        // 右侧：图例说明
        Column({ space: 12 }) {
          this.buildLegendItem('上装', '40%', this.colorPalette[0])
          this.buildLegendItem('下装', '30%', this.colorPalette[1])
          this.buildLegendItem('鞋子', '20%', this.colorPalette[2])
          this.buildLegendItem('配饰', '10%', this.colorPalette[3])
        }
        .layoutWeight(1).margin({ left: 20 }).alignItems(HorizontalAlign.Start)
      }
      .width('100%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 10, color: 'rgba(0,0,0,0.05)', offsetY: 4 })
  }

  // 辅助图例
  @Builder buildLegendItem(name: string, percent: string, color: string) {
    Row({ space: 8 }) {
      Circle({ width: 10, height: 10 }).fill(color)
      Text(name).fontSize(14).fontColor('#666')
      Blank()
      Text(percent).fontSize(14).fontWeight(FontWeight.Bold).fontColor('#333')
    }.width('100%')
  }

  // ❤️ 卡片 2: 最爱 Top 3
  @Builder buildTopFavoriteCard() {
    Column() {
      Row() {
        Text('穿着频次 Top 3').fontSize(16).fontWeight(FontWeight.Medium).fontColor('#444')
        Text('红榜').fontSize(12).fontColor('#FF4B4B').backgroundColor('#FFEAEA').padding({ left: 6, right: 6, top: 2, bottom: 2 }).borderRadius(4).margin({ left: 8 })
      }.width('100%').margin({ bottom: 15 })

      // 横向滑动列表
      List({ space: 15 }) {
        ForEach(this.topFavorites, (item: FavoriteItem, index: number) =>{
          ListItem() {
            Column({ space: 8 }) {
              Stack({ alignContent: Alignment.TopStart }) {
                Image(item.image).width(100).height(100).borderRadius(12).objectFit(ImageFit.Cover)
                // 排名角标
                Text(`NO.${index + 1}`)
                  .fontSize(10).fontColor(Color.White).fontWeight(FontWeight.Bold)
                  .backgroundColor(index === 0 ? '#FFD166' : (index === 1 ? '#C0C0C0' : '#CD7F32'))
                  .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                  .borderRadius({ topLeft: 12, bottomRight: 8 })
              }
              Text(item.name).fontSize(13).fontColor('#333')
              Text(`本月穿过 ${item.wearCount} 次`).fontSize(11).fontColor('#999')
            }.width(100)
          }
        })
      }
      .listDirection(Axis.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 10, color: 'rgba(0,0,0,0.05)', offsetY: 4 })
  }

  // ⚠️ 卡片 3: 吃灰预警
  @Builder buildIdleWarningCard() {
    Column() {
      Row() {
        Text('吃灰预警').fontSize(16).fontWeight(FontWeight.Medium).fontColor('#444')
        Text('黑榜').fontSize(12).fontColor('#666').backgroundColor('#F0F0F0').padding({ left: 6, right: 6, top: 2, bottom: 2 }).borderRadius(4).margin({ left: 8 })
      }.width('100%').margin({ bottom: 15 })

      Column({ space: 15 }) {
        ForEach(this.idleWarnings, (item: WarningItem) =>{
          Row({ space: 12 }) {
            Image(item.image).width(60).height(60).borderRadius(8).objectFit(ImageFit.Cover)

            Column({ space: 6 }) {
              Text(item.name).fontSize(14).fontWeight(FontWeight.Medium).fontColor('#333')
              Text(item.reason).fontSize(12).fontColor('#FF4B4B')
            }.layoutWeight(1).alignItems(HorizontalAlign.Start)

            Button('处理')
              .width(60).height(28).fontSize(12)
              .backgroundColor('rgba(0,0,0,0.05)').fontColor('#333')
          }.width('100%')
        })
      }.width('100%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 10, color: 'rgba(0,0,0,0.05)', offsetY: 4 })
  }
}