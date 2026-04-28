import router from '@ohos.router';

//隐私政策

// 定义条款数据结构
interface PolicySection {
  title: string;
  content: string;
}

@Entry
@Component
struct PrivacyPolicyView {
  //文案
  private policies: PolicySection[] = [
    {
      title: '一、 收集的信息及使用目的',
      content: '1. 本地图片与衣橱数据：当您使用“添加衣物”功能时，系统会将图片保存在您设备的本地沙箱中。我们承诺，您的衣物照片、穿搭频次、体感温度等个人偏好数据【仅存储于您的本地设备】，我们不会将其上传至任何云端服务器，最大程度保护您的隐私。\n\n2. 城市与天气数据：为了向您提供精准的每日穿搭推荐，我们会获取您选择的“城市代码”，并将其发送至第三方天气服务商以获取气温数据。此过程仅包含城市代码，不包含您的精确 GPS 定位或任何个人身份信息。'
    },
    {
      title: '二、 数据的存储与删除',
      content: '您的所有核心数据均通过设备本地的数据库（RDB）和首选项（Preferences）进行存储。您随时可以在“系统设置”中通过“清理缓存”或“清空衣橱数据”功能，彻底且不可逆地删除您设备上的所有相关信息。'
    },
    {
      title: '三、 第三方服务说明',
      content: '本应用在获取天气信息时，可能会接入合法合规的第三方天气 API 接口。该接口仅用于请求公开的气象数据，我们严格限制第三方服务商获取您的设备其他隐私权限。'
    },
    {
      title: '四、 用户行为规范',
      content: '您理解并同意，本应用提供的“智能穿搭推荐”结果仅基于算法与气温生成，供您日常参考。应用不对因天气突变导致的穿搭不适承担直接责任，请您结合实际体感进行调整。'
    },
    {
      title: '五、 未成年人保护',
      content: '本应用非常重视未成年人的隐私保护。本应用的功能纯为本地工具性质，不包含任何社交、诱导消费或公开展示功能，未成年人可在家长的指导下安全使用。'
    },
    {
      title: '六、 政策的修订与联系我们',
      content: '我们可能会适时对本隐私政策进行修订。如果您对本政策或本应用的数据处理有任何疑问、意见或建议，可通过应用内的“意见反馈”功能与开发者取得联系。'
    }
  ];

  build() {
    Column() {
      // --- 顶部导航栏 ---
      Row() {
        Button('< 返回')
          .backgroundColor(Color.Transparent)
          .fontColor('#333')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .padding({ left: 0 })
          .onClick(() => router.back())

        Blank()

        Text('用户协议与隐私政策')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')

        Blank()

        Text('').width(60) // 占位，保证标题居中
      }
      .width('100%')
      .height(56)
      .padding({ left: 20, right: 20 })
      .backgroundColor(Color.White)
      // 底部加一条极细的分割线，让导航栏有独立感
      .border({ width: { bottom: 0.5 }, color: '#EAEAEA' })

      // --- 长文本滚动区 ---
      Scroll() {
        Column({ space: 24 }) {
          // 头部引言
          Text('欢迎使用我们的穿搭推荐服务！我们深知个人隐私对您的重要性，并会尽全力保护您的个人信息安全可靠。在您使用本应用前，请仔细阅读本《用户协议与隐私政策》。')
            .fontSize(14)
            .fontColor('#666')
            .lineHeight(22)
            .width('100%')

          // 遍历渲染各个条款段落
          ForEach(this.policies, (item: PolicySection) => {
            Column({ space: 8 }) {
              Text(item.title)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333')
                .width('100%')

              Text(item.content)
                .fontSize(14)
                .fontColor('#666')
                .lineHeight(24) // 较大的行高，阅读更舒适
                .width('100%')
                  // 允许文本自动换行
                .maxLines(99)
            }
            .width('100%')
          })

          // 底部留白和声明
          Column() {
            Text('更新日期：2026年4月')
              .fontSize(12)
              .fontColor('#999')
            Text('生效日期：2026年4月')
              .fontSize(12)
              .fontColor('#999')
              .margin({ top: 4 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.End)
          .margin({ top: 20, bottom: 40 })

        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 24 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto) // 开启滚动条，方便用户知道篇幅长度
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA') // 阅读类页面推荐使用极浅的护眼灰底色
  }
}