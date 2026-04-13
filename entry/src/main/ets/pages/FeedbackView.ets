import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct FeedbackView {
  // --- 状态数据 ---
  @State content: string = '';              // 用户输入的反馈内容
  @State contact: string = '';              // 用户的联系方式

  private maxContentLength: number = 200;   // 限制最大字数

  // 模拟提交动作
  submitFeedback() {
    // 表单基础校验
    if (this.content.trim().length === 0) {
      promptAction.showToast({ message: '请简要描述您遇到的问题或建议~' });
      return;
    }

    // 模拟网络请求过程的 Toast
    promptAction.showToast({ message: '提交中...' });

    // 模拟 800ms 后提交成功并返回
    setTimeout(() => {
      promptAction.showToast({ message: '感谢您的反馈，我们会尽快优化！' });
      router.back();
    }, 800);
  }

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

        Text('意见反馈')
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
      // 加上一条极细的底边框，让导航栏和下方内容有更好的层次感
      .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })

      // --- 主体表单内容 ---
      Scroll() {
        // 🌟 优化：把内部大容器的间距调小，让排版更紧凑
        Column({ space: 20 }) {

          // 1. 问题描述输入框
          Column({ space: 10 }) {
            Text('问题描述')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333')
              .width('100%')

            Stack({ alignContent: Alignment.BottomEnd }) {
              TextArea({ placeholder: '请详细描述您遇到的问题或想给出的建议...', text: this.content })
                .height(160) // 稍微加高了一点输入框，视觉上更饱满
                .backgroundColor('#F9F9F9')
                .fontSize(14)
                .fontColor('#333')
                .borderRadius(12)
                .maxLength(this.maxContentLength)
                .onChange((value: string) => {
                  this.content = value;
                })

              // 右下角的字数统计提示
              Text(`${this.content.length}/${this.maxContentLength}`)
                .fontSize(12)
                .fontColor('#AAA')
                .margin({ right: 12, bottom: 12 })
            }
            .width('100%')
          }
          .width('100%')
          // 🌟 优化：精确控制顶部的留白距离（top: 16），避免悬空感
          .padding({ left: 20, right: 20, top: 16 })

          // 2. 联系方式输入框 (选填)
          Column({ space: 10 }) {
            Text('联系方式 (选填)')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333')
              .width('100%')

            TextInput({ placeholder: '留下您的微信/QQ/邮箱，方便我们联系您', text: this.contact })
              .height(48)
              .backgroundColor('#F9F9F9')
              .fontSize(14)
              .fontColor('#333')
              .borderRadius(12)
              .onChange((value: string) => {
                this.contact = value;
              })
          }
          .width('100%')
          .padding({ left: 20, right: 20 })

          // 3. 提交按钮
          Button('提交反馈')
            .width('90%')
            .height(48)
            .backgroundColor(this.content.trim().length > 0 ? '#007AFF' : '#CCC')
            .fontColor(Color.White)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .borderRadius(24)
            .margin({ top: 20, bottom: 40 }) // 🌟 优化：收紧了按钮距离上方输入框的间距
            .stateEffect(this.content.trim().length > 0)
            .onClick(() => {
              this.submitFeedback();
            })

        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }
}