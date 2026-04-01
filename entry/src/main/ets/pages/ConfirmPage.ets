import router from '@ohos.router';
import util from '@ohos.util';
import { Clothing, ClothingColor } from '../model/Clothing';
import { ClothingService } from '../service/ClothingService';
// 🌟 引入提取出来的工具类和配置常量
import { COLOR_OPTIONS, WARMTH_OPTIONS, CATEGORY_UI_DATA } from '../utils/ClothingConfig';
import { ClothingUtils } from '../utils/ClothingUtils';
import { ColorOption, WarmthOption } from '../utils/ClothingConfig';

@Entry
@Component
struct ConfirmPage {
  // 1. 获取路由参数
  private params = router.getParams() as Record<string, Object>;
  @State imageUri: string = this.params?.['imageUri'] as string || '';
  @State isEditMode: boolean = this.params?.['editMode'] as boolean || false;
  @State oldId: string = this.params?.['oldId'] as string || '';

  // 2. 响应式表单状态
  @State selectedSubLabel: string = 'T恤';
  @State selectedColor: ClothingColor = ClothingColor.BLACK;
  @State selectedWarmth: number = 6;

  private service: ClothingService = new ClothingService();

  aboutToAppear() {
    // 🌟 编辑模式下，使用工具类自动回填数据
    if (this.isEditMode && this.params?.['clothingItem']) {
      const item = this.params['clothingItem'] as Clothing;
      this.selectedSubLabel = ClothingUtils.getLabelBySubCategory(item.subCategory);
      this.selectedColor = item.color;
      this.selectedWarmth = item.warmthIndex;
    }
  }

  /**
   * 保存按钮点击事件
   */
  async handleSave() {
    // 使用工具类将中文标签转回枚举
    const subEnum = ClothingUtils.getSubCategoryByLabel(this.selectedSubLabel);

    if (this.isEditMode) {
      // 编辑模式：更新现有记录
      const updatedItem = new Clothing(this.oldId, this.imageUri, subEnum, this.selectedWarmth, this.selectedColor);
      const success = await this.service.updateClothing(updatedItem);
      if (success) router.back();
    } else {
      // 新增模式：生成新 UUID 并插入
      const newId = util.generateRandomUUID();
      const newItem = new Clothing(newId, this.imageUri, subEnum, this.selectedWarmth, this.selectedColor);
      const success = await this.service.addClothing(newItem);
      if (success) router.back();
    }
  }

  build() {
    Column() {
      // --- 顶部导航栏 ---
      Row() {
        Text('取消')
          .fontSize(16).fontColor('#666')
          .onClick(() => router.back())

        Text(this.isEditMode ? '修改衣物信息' : '录入新衣物')
          .fontSize(18).fontWeight(FontWeight.Bold)

        Text('完成')
          .fontSize(16).fontColor('#007AFF').fontWeight(FontWeight.Bold)
          .onClick(() => this.handleSave())
      }
      .width('100%').padding(16).justifyContent(FlexAlign.SpaceBetween)

      Scroll() {
        Column({ space: 25 }) {
          // --- 图片预览区 ---
          Image(this.imageUri)
            .width(200).height(200)
            .borderRadius(16).objectFit(ImageFit.Cover)
            .shadow({ radius: 10, color: '#15000000' })
            .margin({ top: 10 })

          // --- 选项 1：款式选择 (使用配置常量) ---
          Column({ space: 8 }) {
            Text('款式分类').fontSize(14).fontColor('#999').width('90%')
            TextPicker({ range: CATEGORY_UI_DATA })
              .height(120).width('100%')
              .onChange((value: string | string[]) => {
                if (Array.isArray(value)) {
                  this.selectedSubLabel = value[1]; // 获取二级分类中文名
                }
              })
          }.width('95%')

          // --- 选项 2：主色调 (使用配置常量) ---
          Column({ space: 12 }) {
            Text('主色调').fontSize(14).fontColor('#999').width('100%')
            Row() {
              ForEach(COLOR_OPTIONS, (item: ColorOption) => {
                Column({ space: 6 }) {
                  Circle({ width: 34, height: 34 })
                    .fill(item.hex)
                    .border({
                      width: this.selectedColor === item.value ? 3 : 1,
                      color: this.selectedColor === item.value ? '#007AFF' : '#EEEEEE'
                    })
                    .onClick(() => this.selectedColor = item.value)
                  Text(item.label).fontSize(12).fontColor('#666')
                }
              })
            }.width('100%').justifyContent(FlexAlign.SpaceBetween)
          }.width('90%')

          // --- 选项 3：保暖指数 (使用配置常量) ---
          Column({ space: 12 }) {
            Text('保暖厚度描述').fontSize(14).fontColor('#999').width('100%')
            Flex({ justifyContent: FlexAlign.SpaceBetween }) {
              ForEach(WARMTH_OPTIONS, (item: WarmthOption) => {
                Button(item.label)
                  .fontSize(13)
                  .height(36).layoutWeight(1).margin({ left: 4, right: 4 })
                  .backgroundColor(this.selectedWarmth === item.value ? '#007AFF' : '#F5F5F5')
                  .fontColor(this.selectedWarmth === item.value ? Color.White : '#333')
                  .onClick(() => this.selectedWarmth = item.value)
              })
            }.width('100%')
          }.width('90%')

          Blank().height(60) // 底部缓冲
        }
        .width('100%')
      }.layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(Color.White)
  }
}