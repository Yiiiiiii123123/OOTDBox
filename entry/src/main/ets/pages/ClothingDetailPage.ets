import router from '@ohos.router';
import { Clothing } from '../model/Clothing';
import { ClothingService } from '../service/ClothingService';
import { ClothingRepo } from '../repository/ClothingRepo'; // 🌟 引入 Repo
import { ClothingUtils } from '../utils/ClothingConfig';   // 🌟 引入工具类

@Entry
@Component
struct ClothingDetailPage {
  // 初始数据从路由拿
  @State clothing: Clothing = (router.getParams() as Record<string, Clothing>)['clothingItem'];

  private service: ClothingService = new ClothingService();
  private repo: ClothingRepo = new ClothingRepo(); // 实例化 Repo

  // 🌟 关键：每次进入或返回此页面都会触发
  onPageShow() {
    this.refreshData();
  }

  async refreshData() {
    if (this.clothing && this.clothing.id) {
      try {
        const latest = await this.repo.getById(this.clothing.id);
        if (latest) {
          // 重新赋值给 @State 变量，UI 会感知变化并局部刷新
          this.clothing = latest;
          console.info('ClothingDetail', '数据已同步最新状态');
        }
      } catch (err) {
        console.error('ClothingDetail', '刷新失败: ' + JSON.stringify(err));
      }
    }
  }

  // --- 辅助函数：计算相对时间 ---
  private getRelativeTime(timestamp: number): string {
    if (!timestamp || timestamp === 0) return "还未穿过";
    const now = new Date().getTime();
    const diffDays = Math.floor((now - timestamp) / (1000 * 60 * 60 * 24));
    if (diffDays === 0) return "今天穿过";
    if (diffDays === 1) return "昨天穿过";
    if (diffDays < 7) return `${diffDays}天前`;
    return "很久没穿了";
  }

  build() {
    Column() {
      // 1. 顶部导航栏
      Row() {
        Image($r('app.media.icon_back'))
          .width(24).height(24)
          .onClick(() => router.back())
        Text('单品详情').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 16 })
      }
      .width('100%').padding(16).alignItems(VerticalAlign.Center)

      Scroll() {
        Column({ space: 20 }) {
          // 2. 图片 (自动根据最新的 clothing.imageUri 刷新)
          Image(this.clothing.imageUri)
            .width('90%').aspectRatio(1).borderRadius(16).objectFit(ImageFit.Cover)

          // 3. 汉化品类与颜色 (使用工具类)
          Row({ space: 16 }) {
            Text(ClothingUtils.getLabelBySubCategory(this.clothing.subCategory)) // 🌟 使用工具类
              .fontSize(16).fontWeight(FontWeight.Medium)
              .backgroundColor('#F0F0F0').padding({ top: 6, bottom: 6, left: 16, right: 16 })
              .borderRadius(20)

            Blank()

            Row({ space: 8 }) {
              Text('主色调:').fontSize(14).fontColor('#666')
              Circle({ width: 24, height: 24 })
                .fill(ClothingUtils.getColorHex(this.clothing.color)) // 🌟 使用工具类
                .border({ width: 1, color: '#E0E0E0' })
            }.alignItems(VerticalAlign.Center)
          }.width('90%')

          // 4. 保暖可视化 (自动刷新)
          Column({ space: 8 }) {
            Text('保暖指数').fontSize(14).fontColor('#666').width('100%')
            Row({ space: 4 }) {
              ForEach(new Array(this.clothing.warmthIndex).fill(0), () => {
                Text('🔥').fontSize(20)
              })
              Text(`(${this.clothing.warmthIndex}/10)`).fontSize(14).fontColor('#999').margin({ left: 8 })
            }.width('100%')
          }.width('90%')

          Divider().width('90%').color('#EEEEEE')

          // 5. 统计面板 (自动刷新)
          Row() {
            Column({ space: 4 }) {
              Text(this.clothing.wearCount.toString()).fontSize(28).fontWeight(FontWeight.Bolder)
              Text('总穿着次数').fontSize(12).fontColor('#999')
            }.layoutWeight(1)

            Divider().vertical(true).height(40).color('#EEEEEE')

            Column({ space: 4 }) {
              Text(this.getRelativeTime(this.clothing.lastWornDate)).fontSize(18).fontWeight(FontWeight.Bold)
              Text('上次穿戴').fontSize(12).fontColor('#999')
            }.layoutWeight(1)
          }
          .width('90%').backgroundColor('#FAFAFA').borderRadius(12).padding(16)

          Blank().height(40)

          // 6. 编辑与删除
          Row({ space: 20 }) {
            Button('编辑资料')
              .backgroundColor('#F0F0F0').fontColor('#333').layoutWeight(1)
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/ConfirmPage',
                  params: {
                    imageUri: this.clothing.imageUri,
                    editMode: true,
                    oldId: this.clothing.id,
                    clothingItem: this.clothing // 传过去回填
                  }
                })
              })

            Button('删除单品')
              .backgroundColor('#FF4D4F').fontColor(Color.White).layoutWeight(1)
              .onClick(() => this.showDeleteDialog())
          }.width('90%')
        }
      }.layoutWeight(1)
    }.width('100%').height('100%')
  }

  private showDeleteDialog() {
    AlertDialog.show({
      title: '确认删除',
      message: '删除后无法找回，确定吗？',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '删除',
        fontColor: '#FF4D4F',
        action: async () => {
          if (await this.service.deleteClothingSafely(this.clothing.id)) router.back();
        }
      }
    })
  }
}