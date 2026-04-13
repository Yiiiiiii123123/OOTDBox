import router from '@ohos.router';
import { Clothing } from '../model/Clothing';
import { ClothingRepo } from '../repository/ClothingRepo';
import { ClothingUtils } from '../utils/ClothingConfig';

@Entry
@Component
struct DataAnalysisView {
  private repo: ClothingRepo = new ClothingRepo();

  // --- 状态数据 (接管真实的数据库流) ---
  @State isLoading: boolean = true;
  @State totalCount: number = 0;

  // 环形图数据
  @State categoryValues: number[] = [];
  @State categoryLabels: string[] = [];
  private colorPalette: string[] = ['#FF7A8A', '#7A9BFF', '#FFD166', '#06D6A0', '#A682FF', '#FFA07A'];

  // 红黑榜数据源
  @State topFavorites: Clothing[] = [];
  @State idleWarnings: Clothing[] = [];

  onPageShow() {
    this.loadData();
  }

  async loadData() {
    try {
      // 1. 从数据库拉取全部衣服
      const list = await this.repo.getAll() || [];
      this.totalCount = list.length;

      if (this.totalCount === 0) {
        this.isLoading = false;
        return;
      }

      // 2. 动态计算环形图：按一级分类统计数量
      const categoryMap = new Map<string, number>();
      list.forEach((item: Clothing) => {
        // 使用翻译官，将底层的英文枚举转为中文大类名
        const label = ClothingUtils.getMainCategoryLabel(item.mainCategory.toString());
        categoryMap.set(label, (categoryMap.get(label) || 0) + 1);
      });

      // 将统计结果转换为数组并按占比从大到小排序
      const sortedCategories = Array.from(categoryMap.entries()).sort((a, b) => b[1] - a[1]);

      this.categoryLabels = sortedCategories.map(e => e[0]);
      this.categoryValues = sortedCategories.map(e => e[1]);

      // 3. 🌟 基于真实的 wearCount 进行红黑榜排序
      // 先将所有衣服按穿戴次数从高到低排序 (防止旧数据没该字段，默认设为0)
      const sortedByWear = [...list].sort((a, b) => (b.wearCount || 0) - (a.wearCount || 0));

      // 🔴 红榜：过滤出至少穿过 1 次的衣服，取前 3 名
      this.topFavorites = sortedByWear.filter(item => (item.wearCount || 0) > 0).slice(0, 3);

      // ⚫️ 黑榜：过滤出穿戴次数为 0 的衣服，取前 3 名
      this.idleWarnings = sortedByWear.filter(item => (item.wearCount || 0) === 0).slice(0, 3);

    } catch (e) {
      console.error('数据分析页加载失败:', e);
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      // --- 标题区 ---
      Row() {
        Button('< 返回')
          .backgroundColor(Color.Transparent)
          .fontColor('#333')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .padding({ left: 0 })
          .onClick(() => router.back())

        Blank()
        Text('衣橱数据洞察').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#333')
        Blank()
        Text('').width(60) // 占位居中
      }
      .width('100%').height(56).padding({ left: 20, right: 20 }).backgroundColor(Color.White)

      if (this.isLoading) {
        Text('数据生成中...').margin({ top: 100 }).fontColor('#999')
      } else if (this.totalCount === 0) {
        Column({ space: 16 }) {
          Text('📭').fontSize(50)
          Text('衣橱空空如也，快去添加衣服吧').fontSize(15).fontColor('#999')
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 20 }) {
            this.buildCategoryCard()
            this.buildTopFavoriteCard()
            this.buildIdleWarningCard()
            Blank().height(40)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 20 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .backgroundColor('#F5F7FA')
      }
    }
    .width('100%').height('100%')
  }

  // ================= 拆分组件 Builder =================

  @Builder buildCategoryCard() {
    Column() {
      Text(`品类构成 (共 ${this.totalCount} 件)`)
        .fontSize(16).fontWeight(FontWeight.Medium).fontColor('#444')
        .width('100%').margin({ bottom: 20 })

      Row() {
        DataPanel({ values: this.categoryValues, max: this.totalCount, type: DataPanelType.Circle })
          .width(120).height(120)
          .valueColors(this.colorPalette)

        Column({ space: 12 }) {
          ForEach(this.categoryLabels, (label: string, index: number) => {
            if (index < this.colorPalette.length) {
              this.buildLegendItem(
                label,
                Math.round((this.categoryValues[index] / this.totalCount) * 100) + '%',
                this.colorPalette[index]
              );
            }
          })
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

  @Builder buildLegendItem(name: string, percent: string, color: string) {
    Row({ space: 8 }) {
      Circle({ width: 10, height: 10 }).fill(color)
      Text(name).fontSize(14).fontColor('#666')
      Blank()
      Text(percent).fontSize(14).fontWeight(FontWeight.Bold).fontColor('#333')
    }.width('100%')
  }

  @Builder buildTopFavoriteCard() {
    Column() {
      Row() {
        Text('穿着频次 Top 3').fontSize(16).fontWeight(FontWeight.Medium).fontColor('#444')
        Text('红榜').fontSize(12).fontColor('#FF4B4B').backgroundColor('#FFEAEA').padding({ left: 6, right: 6, top: 2, bottom: 2 }).borderRadius(4).margin({ left: 8 })
      }.width('100%').margin({ bottom: 15 })

      if (this.topFavorites.length === 0) {
        Text('还没有打卡记录哦，快去试穿吧~')
          .fontSize(13).fontColor('#999').width('100%').textAlign(TextAlign.Center).margin({ top: 10, bottom: 10 })
      } else {
        List({ space: 15 }) {
          ForEach(this.topFavorites, (item: Clothing, index: number) =>{
            ListItem() {
              Column({ space: 8 }) {
                Stack({ alignContent: Alignment.TopStart }) {
                  Image(item.imageUri).width(100).height(100).borderRadius(12).objectFit(ImageFit.Cover)
                  Text(`NO.${index + 1}`)
                    .fontSize(10).fontColor(Color.White).fontWeight(FontWeight.Bold)
                    .backgroundColor(index === 0 ? '#FFD166' : (index === 1 ? '#C0C0C0' : '#CD7F32'))
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .borderRadius({ topLeft: 12, bottomRight: 8 })
                }
                Text(ClothingUtils.getLabelBySubCategory(item.subCategory.toString())).fontSize(13).fontColor('#333')
                // 🌟 动态显示真实穿戴次数
                Text(`共穿过 ${item.wearCount || 0} 次`).fontSize(11).fontColor('#999')
              }.width(100)
            }
          })
        }
        .listDirection(Axis.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 10, color: 'rgba(0,0,0,0.05)', offsetY: 4 })
  }

  @Builder buildIdleWarningCard() {
    Column() {
      Row() {
        Text('吃灰预警').fontSize(16).fontWeight(FontWeight.Medium).fontColor('#444')
        Text('黑榜').fontSize(12).fontColor('#666').backgroundColor('#F0F0F0').padding({ left: 6, right: 6, top: 2, bottom: 2 }).borderRadius(4).margin({ left: 8 })
      }.width('100%').margin({ bottom: 15 })

      // 🌟 新增空状态判断
      if (this.idleWarnings.length === 0) {
        Text('太棒啦！你的衣橱利用率极高，没有吃灰的衣服哦 🎉')
          .fontSize(13).fontColor('#007AFF').width('100%').textAlign(TextAlign.Center).margin({ top: 10, bottom: 10 })
      } else {
        Column({ space: 15 }) {
          ForEach(this.idleWarnings, (item: Clothing) =>{
            Row({ space: 12 }) {
              Image(item.imageUri).width(60).height(60).borderRadius(8).objectFit(ImageFit.Cover)

              Column({ space: 6 }) {
                Text(ClothingUtils.getLabelBySubCategory(item.subCategory.toString())).fontSize(14).fontWeight(FontWeight.Medium).fontColor('#333')
                Text(`已穿过 ${item.wearCount || 0} 次，快给它个机会`).fontSize(12).fontColor('#FF4B4B')
              }.layoutWeight(1).alignItems(HorizontalAlign.Start)

              Button('搭配')
                .width(60).height(28).fontSize(12)
                .backgroundColor('rgba(0,0,0,0.05)').fontColor('#333')
            }.width('100%')
          })
        }.width('100%')
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 10, color: 'rgba(0,0,0,0.05)', offsetY: 4 })
  }
}