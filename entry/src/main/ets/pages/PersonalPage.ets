import router from '@ohos.router';
import { APP_WALLPAPERS } from '../utils/BackgroundList';

//个人页面

@Entry
@Component
struct PersonalPage {

  @StorageProp('wallpaper_index') wallpaperIndex: number = 0;

  build() {
    Stack({ alignContent: Alignment.Top }) {
      // --- 1. 底层：全局动态壁纸 ---
      Image(APP_WALLPAPERS[this.wallpaperIndex])
        .width('100%').height('100%').objectFit(ImageFit.Cover).opacity(0.2)

      // --- 2. 顶层：页面内容 ---
      Column() {
        //标准的顶部透明导航栏，与设置页/反馈页保持统一
        Row() {
          Button('< 返回')
            .backgroundColor(Color.Transparent)
            .fontColor('#333')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .padding({ left: 0 })
            .onClick(() => router.back())

          Blank()

        }
        .width('100%')
        .height(56)
        .padding({ left: 20, right: 20 })
        .margin({ top: 10 }) // 预留顶部安全距离

        // --- 个人信息简报 ---
        Column({ space: 10 }) {
          Image($r('app.media.icon_profile'))
            .width(80).height(80).borderRadius(40)
            .border({ width: 2, color: Color.White })
            .shadow({ radius: 10, color: 'rgba(0,0,0,0.1)', offsetY: 4 }) //优化：增加轻微的立体阴影

          Text('OOTD 达人')
            .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#333')
        }
        .margin({ top: 20, bottom: 40 }) // 调整了间距，承接上方的导航栏

        // --- 功能列表 ---
        List() {
          // 入口：我的收藏
          this.buildMenuListItem('我的收藏穿搭', '❤️', () => {
            router.pushUrl({ url: 'pages/FavoriteOutfitPage' })
              .catch((err: Error) => {
                console.error('RouterError', '跳转收藏页失败: ' + err.message);
              });
          })

          // 入口：衣橱统计
          this.buildMenuListItem('衣橱数据分析', '📊', () => {
            router.pushUrl({
              url: 'pages/DataAnalysisView'
            }).catch((err: Error) => {
              console.error('RouterError', '跳转数据分析页失败: ' + err.message);
            });
          })

          // 入口：设置
          this.buildMenuListItem('系统设置', '⚙️', () => {
            router.pushUrl({
              url: 'pages/SettingsView'
            }).catch((err: Error) => {
              console.error('RouterError', '跳转设置页失败: ' + err.message);
            });
          })
        }
        .width('90%')
        .borderRadius(16)
        .backgroundColor('rgba(255,255,255,0.95)') // 微透明卡片，透出背后的壁纸色彩
        .divider({ strokeWidth: 0.5, color: '#EEEEEE', startMargin: 20, endMargin: 20 })
        .shadow({ radius: 10, color: 'rgba(0,0,0,0.05)' })

        Blank()

        Text('OOTDBox v1.0').fontSize(12).fontColor('#CCC').margin({ bottom: 30 })
      }
      .width('100%').height('100%')
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
    }
    //优化：增加按压反馈，点击时背景微灰，松手恢复
    .stateStyles({
      pressed: { .backgroundColor('rgba(0,0,0,0.03)') },
      normal: { .backgroundColor(Color.Transparent) }
    })
    .onClick(action)
  }
}