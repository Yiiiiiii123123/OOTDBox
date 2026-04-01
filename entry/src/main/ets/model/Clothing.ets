/**
 * 1. 定义一级分类枚举 (MainCategory)
 * 作用：用于推荐算法的“穿搭槽位”硬性规则组合
 */
export enum MainCategory {
  TOP = 'top',               // 上装
  BOTTOM = 'bottom',         // 下装
  ONE_PIECE = 'one_piece',   // 连体 (算法中与上下装互斥)
  OUTERWEAR = 'outerwear',   // 外套 (调节保暖指数的核心)
  SHOES = 'shoes',           // 鞋子
  ACCESSORY = 'accessory'    // 配饰 (可选)
}

/**
 * 2. 定义二级分类枚举 (SubCategory)
 * 作用：用户实际选择的具体款式，用于精细化搭配排斥规则
 * 扩展说明：后期新增衣服种类，请优先在此处添加枚举值
 */
export enum SubCategory {
  // --- 上装类 ---
  T_SHIRT = 't_shirt',       // T恤
  SHIRT = 'shirt',           // 衬衫
  SWEATER = 'sweater',       // 毛衣/卫衣

  // --- 下装类 ---
  JEANS = 'jeans',           // 牛仔裤
  SHORTS = 'shorts',         // 短裤
  CASUAL_PANTS = 'casual_pants', // 休闲裤
  SKIRT = 'skirt',           // 半身裙

  // --- 连体类 ---
  DRESS = 'dress',           // 连衣裙
  JUMPSUIT = 'jumpsuit',     // 连体裤

  // --- 外套类 ---
  JACKET = 'jacket',         // 夹克
  COAT = 'coat',             // 大衣
  DOWN_JACKET = 'down_jacket', // 羽绒服

  // --- 鞋子类 ---
  SNEAKERS = 'sneakers',     // 运动鞋
  BOOTS = 'boots',           // 靴子

  // --- 配饰类 ---
  SCARF = 'scarf',           // 围巾
  HAT = 'hat'                // 帽子
}

/**
 * 3. 颜色枚举 (保持规范，方便后续的色彩搭配算法)
 */
export enum ClothingColor {
  BLACK = 'black',
  WHITE = 'white',
  GRAY = 'gray',
  NAVY = 'navy',
  KHAKI = 'khaki',
  RED = 'red',
  BLUE = 'blue',
  PINK = 'pink'
  // 扩展说明：可根据前端 UI 的色块选择器继续丰富
}

/**
 * 4. 【核心逻辑】：二级到一级的一对多映射字典
 * 原理：将 SubCategory 作为键 (Key)，MainCategory 作为值 (Value)
 * 作用：录入衣服时，只要知道它是“T恤”，系统瞬间查字典就知道它是“上装”
 */
export const SubToMainCategoryMap: Record<SubCategory, MainCategory> = {
  // 上装映射
  [SubCategory.T_SHIRT]: MainCategory.TOP,
  [SubCategory.SHIRT]: MainCategory.TOP,
  [SubCategory.SWEATER]: MainCategory.TOP,

  // 下装映射
  [SubCategory.JEANS]: MainCategory.BOTTOM,
  [SubCategory.SHORTS]: MainCategory.BOTTOM,
  [SubCategory.CASUAL_PANTS]: MainCategory.BOTTOM,
  [SubCategory.SKIRT]: MainCategory.BOTTOM,

  // 连体映射
  [SubCategory.DRESS]: MainCategory.ONE_PIECE,
  [SubCategory.JUMPSUIT]: MainCategory.ONE_PIECE,

  // 外套映射
  [SubCategory.JACKET]: MainCategory.OUTERWEAR,
  [SubCategory.COAT]: MainCategory.OUTERWEAR,
  [SubCategory.DOWN_JACKET]: MainCategory.OUTERWEAR,

  // 鞋子映射
  [SubCategory.SNEAKERS]: MainCategory.SHOES,
  [SubCategory.BOOTS]: MainCategory.SHOES,

  // 配饰映射
  [SubCategory.SCARF]: MainCategory.ACCESSORY,
  [SubCategory.HAT]: MainCategory.ACCESSORY,
};

/**
 * 5. Clothing 单品数据模型定义
 * 说明：如果你使用 ArkUI 进行界面绑定，可以在 class 前方加上 @Observed 装饰器
 */
export class Clothing {
  id: string;                      // 唯一标识 (建议在创建时使用 util.generateRandomUUID())
  imageUri: string;                // 鸿蒙沙盒中的图片文件路径

  mainCategory: MainCategory;      // 一级分类 (由系统自动推导，不需用户输入)
  subCategory: SubCategory;        // 二级分类 (用户实际选择的分类)

  warmthIndex: number;             // 保暖指数 (叠加法核心数据，建议设定为 1-10 的整数)
  color: ClothingColor;            // 主色调

  wearCount: number;               // 穿戴总次数 (用于分析偏好)
  lastWornDate: number;            // 上次穿戴时间戳 (用于硬性过滤近期穿过的衣服)

  /**
   * 构造函数
   * 注意点：参数里【不需要】传入 mainCategory。
   */
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

    // 初始化使用轨迹数据（新录入的衣服肯定是没穿过的）
    this.wearCount = 0;
    this.lastWornDate = 0;
  }

  /**
   * 实例方法：打卡穿戴记录
   * 作用：当用户今天确认穿了这件衣服时，调用此方法更新数据
   */
  public markAsWorn(): void {
    this.wearCount += 1;
    this.lastWornDate = new Date().getTime(); // 记录当前毫秒级时间戳
  }
}