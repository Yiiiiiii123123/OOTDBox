import { MainCategory, SubCategory, ClothingColor, SubToMainCategoryMap } from '../utils/ClothingConfig';

/**
 * Clothing 单品数据模型定义
 * 说明：使用 ArkUI 进行界面绑定，可以在 class 前方加上 @Observed 装饰器，使之随时可被监控
 */
@Observed
export class Clothing {
  id: string;                      // 唯一标识
  imageUri: string;                // 鸿蒙沙盒中的图片文件路径

  mainCategory: MainCategory;      // 一级分类
  subCategory: SubCategory;        // 二级分类

  warmthIndex: number;             // 保暖指数
  color: ClothingColor;            // 主色调

  wearCount: number;               // 穿戴总次数
  lastWornDate: number;            // 上次穿戴时间戳

  constructor(
    id: string,
    imageUri: string,
    subCategory: SubCategory,
    warmthIndex: number,
    color: ClothingColor
  ) {
    this.id = id;
    this.imageUri = imageUri;

    // 【核心赋值】：通过字典，自动将传入的二级分类转换为对应的一级分类并保存
    this.subCategory = subCategory;
    this.mainCategory = SubToMainCategoryMap[subCategory];

    this.warmthIndex = warmthIndex;
    this.color = color;

    this.wearCount = 0;
    this.lastWornDate = 0;
  }

  /**
   * 实例方法：打卡穿戴记录
   */
  public markAsWorn(): void {
    this.wearCount += 1;
    this.lastWornDate = new Date().getTime();
  }
}

