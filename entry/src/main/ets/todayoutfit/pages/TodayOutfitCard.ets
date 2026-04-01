@Entry
@Component
struct TodayOutfitCard {
  // 🌟 从 EntryFormAbility 传入的本地存储数据
  @LocalStorageProp('images') images: string = '';
  @LocalStorageProp('temp') temp: string = '--℃';

  // 🌟 计算属性：将逗号分隔的字符串安全地转换为数组
  private get imageList(): string[] {
    if (!this.images || this.images.trim() === '') {
      return [];
    }
    return this.images.split(',');
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      // --- 情况 1：没有数据时显示空状态 ---
      if (this.imageList.length === 0) {
        Column({ space: 8 }) {
          Text('👔').fontSize(32)
          Text('今日穿搭待选定').fontSize(12).fontColor('#666').fontWeight(FontWeight.Medium)
          Text('请前往 App 确认一套穿搭').fontSize(10).fontColor('#999')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#F9F9F9')
      }
      else {
        // --- 情况 2：展示拼贴穿搭 ---
        Row({ space: 4 }) {
          // 1. 左侧大图 (显示第一张图)
          Image(this.imageList[0])
            .width(this.imageList.length === 1 ? '100%' : '58%') // 如果只有一张图则铺满
            .height('100%')
            .borderRadius(8)
            .objectFit(ImageFit.Cover)

          // 2. 右侧副图列 (如果有更多图片)
          if (this.imageList.length > 1) {
            Column({ space: 4 }) {
              // 第二张图
              Image(this.imageList[1])
                .width('100%')
                .layoutWeight(1)
                .borderRadius(6)
                .objectFit(ImageFit.Cover)

              // 第三张图 (如果有)
              if (this.imageList.length > 2) {
                Image(this.imageList[2])
                  .width('100%')
                  .layoutWeight(1)
                  .borderRadius(6)
                  .objectFit(ImageFit.Cover)
              }
            }
            .width('38%')
            .height('100%')
          }
        }
        .width('100%')
        .height('100%')
        .padding(6)
        .backgroundColor(Color.White)
      }

      // --- 右下角气温标签 ---
      Text(this.temp)
        .fontSize(11)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .backgroundColor('rgba(0,0,0,0.5)') // 半透明背景确保文字清晰
        .borderRadius({ topLeft: 10 })
    }
    .width('100%')
    .height('100%')
  }
}