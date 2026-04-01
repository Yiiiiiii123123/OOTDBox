import router from '@ohos.router';

@Entry
@Component
struct PersonalPage {
  build() {
    Stack() {
      // 背景
      Image($r('app.media.background1'))
        .width('100%').height('100%').objectFit(ImageFit.Cover).opacity(0.2)

      Column() {
        // --- 1. 顶部个人信息简报 ---
        Column({ space: 10 }) {
          Image($r('app.media.icon_profile')) // 借用你的头像图标
            .width(80).height(80).borderRadius(40)
            .border({ width: 2, color: Color.White })

          Text('OOTD 达人')
            .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#333')
        }
        .margin({ top: 80, bottom: 40 })

        // --- 2. 功能列表 ---
        List({ space: 1 }) {
          // 入口：我的收藏
          this.buildMenuListItem('我的收藏穿搭', '❤️', () => {
            router.pushUrl({ url: 'pages/FavoriteOutfitPage' })
          })

          // 入口：衣橱统计 (预留)
          this.buildMenuListItem('衣橱数据分析', '📊', () => {
            // TODO: 跳转统计页
          })

          // 入口：设置
          this.buildMenuListItem('设置', '⚙️', () => {
            // TODO: 跳转设置页
          })
        }
        .width('90%').borderRadius(16).backgroundColor(Color.White).shadow({ radius: 10, color: '#10000000' })

        Blank()

        Text('OOTDBox v1.0').fontSize(12).fontColor('#CCC').margin({ bottom: 30 })
      }
      .width('100%').height('100%')

      // 返回按钮
      Button('←')
        .position({ x: 20, y: 50 })
        .width(40).height(40).backgroundColor('rgba(0,0,0,0.1)').fontColor('#333')
        .onClick(() => router.back())
    }
  }

  @Builder buildMenuListItem(title: string, icon: string, action: () => void) {
    ListItem() {
      Row() {
        Text(icon).fontSize(20).margin({ right: 15 })
        Text(title).fontSize(16).layoutWeight(1).fontColor('#444')
        Text('>').fontSize(16).fontColor('#CCC')
      }
      .width('100%').padding(20)
      .onClick(action)
    }
  }
}