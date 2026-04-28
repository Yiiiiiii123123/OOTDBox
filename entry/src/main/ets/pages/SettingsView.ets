import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import dataPreferences from '@ohos.data.preferences';
import { APP_WALLPAPERS } from '../utils/BackgroundList';
import { ClothingService } from '../service/ClothingService';
import { PreferenceRepo } from '../repository/PreferenceRepo';

//设置页面

@Entry
@Component
struct SettingsView {
  // 当前选中的壁纸索引 (0代表默认背景)
  @State selectedWallpaperIndex: number = 0;
  // 缓存大小实时显示
  @State cacheSize: string = '计算中...';

  // 获取应用上下文，用于访问缓存目录
  private context = getContext(this) as common.UIAbilityContext;

  private service: ClothingService = new ClothingService();



  // 🌟 页面加载时自动计算缓存大小
  async aboutToAppear() {
    this.calculateCacheSize();

    // 读取保存的壁纸索引
    let prefs = await dataPreferences.getPreferences(this.context, 'app_settings');
    let savedIndex = await prefs.get('wallpaper_index', 0) as number;
    this.selectedWallpaperIndex = savedIndex;
  }

  // ================= 业务逻辑 =================

  // 1. 计算真实缓存大小
  calculateCacheSize() {
    try {
      let cacheDir = this.context.cacheDir;
      let files = fs.listFileSync(cacheDir);
      let sizeBytes = 0;
      for (let file of files) {
        let stat = fs.statSync(cacheDir + '/' + file);
        sizeBytes += stat.size;
      }
      // 转化为 MB 并保留两位小数
      let sizeMB = sizeBytes / (1024 * 1024);
      this.cacheSize = sizeMB > 0 ? sizeMB.toFixed(2) + ' MB' : '0.00 MB';
    } catch (e) {
      this.cacheSize = '0.00 MB';
    }
  }

  // 2. 执行清理缓存
  clearAppCache() {
    try {
      let cacheDir = this.context.cacheDir;
      let files = fs.listFileSync(cacheDir);
      for (let file of files) {
        fs.unlinkSync(cacheDir + '/' + file); // 删除文件
      }
      this.cacheSize = '0.00 MB';
      promptAction.showToast({ message: '✨ 缓存清理完成' });
    } catch (e) {
      promptAction.showToast({ message: '清理失败' });
    }
  }

  // 3. 清空衣橱数据的弹窗警告
  showClearDataDialog() {
    AlertDialog.show({
      title: '⚠️ 危险操作',
      message: '确定要清空所有衣橱数据吗？\n清空后将无法找回，此操作不可逆！',
      autoCancel: true, // 点击遮罩层可取消
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '取消',
        fontColor: '#007AFF', // 安全色
        action: () => {
          // 用户取消，无事发生
        }
      },
      secondaryButton: {
        value: '确定清空',
        fontColor: '#FF4B4B', // 警告红色
        action: () => {
          this.executeClearData();
        }
      }
    });
  }

  // 4. 执行清空数据库
  async executeClearData() {
    try {
      // 1. 调用底层的删除全表方法
      let success = await this.service.deleteAllClothes();

      if (success) {

        // 3. 顺手触发一下我们刚才写的清缓存方法，释放物理空间
        this.clearAppCache();

        promptAction.showToast({ message: '🗑️ 衣橱数据已彻底清空' });
      } else {
        promptAction.showToast({ message: '清空失败，请检查数据库状态' });
      }
    } catch (e) {
      console.error('SettingsView', '清空异常: ' + JSON.stringify(e));
      promptAction.showToast({ message: '清空异常，请重试' });
    }
  }

  // 5. 新增：清除穿着记录的弹窗警告
  showResetHistoryDialog() {
    AlertDialog.show({
      title: '提示',
      message: '确定要清除所有衣物的历史穿着数据吗？\n此操作会将衣物穿着次数与时间清零，从而重置算法的推荐偏好。',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '取消',
        fontColor: '#999',
        action: () => {}
      },
      secondaryButton: {
        value: '确定清除',
        fontColor: '#007AFF', // 使用常规强调色，因为这不是毁灭性操作
        action: () => {
          this.executeResetHistory();
        }
      }
    });
  }

  // 6. 新增：执行清除穿着记录
  async executeResetHistory() {
    try {
      // 获取所有衣服
      let count = await this.service.resetAllWearHistory();
      if (count > 0) {
        promptAction.showToast({ message: `✨ 成功重置 ${count} 件衣物的推荐偏好` });
      } else {
        promptAction.showToast({ message: '暂无穿搭记录，无需清除~' });
      }
    } catch (e) {
      console.error('SettingsView', '重置穿着记录异常: ' + JSON.stringify(e));
      promptAction.showToast({ message: '重置异常，请重试' });
    }
  }

  // 抽离出来的壁纸切换统筹方法
  async handleWallpaperSelect(index: number) {
    // 1. UI 状态更新：存入全局内存，让当前页面和其他存活页面立刻变色
    this.selectedWallpaperIndex = index;
    AppStorage.setOrCreate('wallpaper_index', index);

    // 2. 底层持久化：交给 Service 去写硬盘
    let context = getContext(this) as common.UIAbilityContext;
    await PreferenceRepo.saveWallpaper(context, index);

    // 3. 用户反馈
    promptAction.showToast({ message: '✨ 壁纸已全局切换' });
  }

  // ================= UI 渲染 =================

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

        Text('系统设置')
          .fontSize(24)
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

      Scroll() {
        Column({ space: 24 }) {
          // --- 板块 1：个性化 (壁纸切换) ---
          this.buildPersonalizationCard()

          // --- 板块 2：数据与存储 ---
          this.buildStorageCard()

          // --- 板块 3：关于我们 ---
          this.buildAboutCard()

          Blank().height(40)
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
  }

  // 🎨 板块 1: 个性化 (已移除相册选择功能)
  @Builder buildPersonalizationCard() {
    Column() {
      Text('个性化').fontSize(13).fontColor('#888').width('100%').margin({ bottom: 8, left: 4 })

      Column() {
        Row() {
          Text('内置背景壁纸').fontSize(16).fontColor('#333')
          Blank()
          // 删除了“从相册选择”的 Text
        }.width('100%').padding({ top: 16, left: 16, right: 16, bottom: 12 })

        // 壁纸横向画廊
        List({ space: 12 }) {
          ForEach(APP_WALLPAPERS, (img: ResourceStr, index: number) => {
            ListItem() {
              Stack({ alignContent: Alignment.Center }) {
                Image(img)
                  .width(90).height(140)
                  .borderRadius(8)
                  .objectFit(ImageFit.Cover)
                  .opacity(this.selectedWallpaperIndex === index ? 1 : 0.6)

                if (this.selectedWallpaperIndex === index) {
                  Row().width(90).height(140).borderRadius(8).border({ width: 2, color: '#007AFF' })
                  Circle({ width: 24, height: 24 }).fill('#007AFF')
                  Text('✓').fontColor(Color.White).fontSize(14).fontWeight(FontWeight.Bold)
                }
              }
              .onClick(() => {
                this.handleWallpaperSelect(index);
              })
            }
          })
        }
        .listDirection(Axis.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 20 })
      }
      .backgroundColor(Color.White)
      .borderRadius(16)
      .shadow({ radius: 8, color: 'rgba(0,0,0,0.03)', offsetY: 2 })
    }
  }

  // 💾 板块 2: 数据与存储 (接入真实业务逻辑)
  @Builder buildStorageCard() {
    Column() {
      Text('数据与存储').fontSize(13).fontColor('#888').width('100%').margin({ bottom: 8, left: 4 })

      Column() {
        this.buildSettingRow('清理缓存', this.cacheSize, true, () => {
          // 调用真正的清理缓存逻辑
          this.clearAppCache();
        })

        Divider().color('#F0F0F0').margin({ left: 16, right: 16 })

        // 🌟 新增：清除穿着记录项
        this.buildSettingRow('清除历史穿着记录', '', false, () => {
          this.showResetHistoryDialog();
        })

        Divider().color('#F0F0F0').margin({ left: 16, right: 16 })

        this.buildSettingRow('清空衣橱数据', '', false, () => {
          // 调用弹窗逻辑
          this.showClearDataDialog();
        }, '#FF4B4B')
      }
      .backgroundColor(Color.White)
      .borderRadius(16)
      .shadow({ radius: 8, color: 'rgba(0,0,0,0.03)', offsetY: 2 })
    }
  }

  // ℹ️ 板块 3: 关于我们
  @Builder buildAboutCard() {
    Column() {
      Text('关于').fontSize(13).fontColor('#888').width('100%').margin({ bottom: 8, left: 4 })

      Column() {
        this.buildSettingRow('意见反馈', '', true, () => {
          router.pushUrl({ url: 'pages/FeedbackView' });
        })
        Divider().color('#F0F0F0').margin({ left: 16, right: 16 })

        this.buildSettingRow('隐私政策', '', true, () => {
          router.pushUrl({ url: 'pages/PrivacyPolicyView' })
        })
        Divider().color('#F0F0F0').margin({ left: 16, right: 16 })

        this.buildSettingRow('当前版本', 'V 1.0.0', false)
      }
      .backgroundColor(Color.White)
      .borderRadius(16)
      .shadow({ radius: 8, color: 'rgba(0,0,0,0.03)', offsetY: 2 })
    }
  }

  // 🛠️ 通用的列表项组件
  @Builder buildSettingRow(title: string, value: string = '', showArrow: boolean = true, onClick?: () => void, titleColor: string = '#333') {
    Row() {
      Text(title).fontSize(16).fontColor(titleColor)
      Blank()
      if (value !== '') {
        Text(value).fontSize(14).fontColor('#999').margin({ right: showArrow ? 8 : 0 })
      }
      if (showArrow) {
        Text('>').fontSize(16).fontColor('#CCC').fontWeight(FontWeight.Medium)
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .onClick(() => {
      if (onClick) onClick();
    })
  }
}