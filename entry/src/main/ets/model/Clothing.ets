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
  // 1. 上装
  T_SHIRT = 't_shirt',//T恤
  SHIRT = 'shirt',//衬衫
  POLO = 'polo',//Polo衫
  SWEATER = 'sweater',//毛衣
  HOODIE = 'hoodie',//卫衣
  CAMISOLE = 'camisole',//吊带/背心
  BASE_SHIRT = 'base_shirt',//打底衫

  // 2. 下装
  JEANS = 'jeans',//牛仔裤
  CASUAL_PANTS = 'casual_pants',//休闲裤
  SUIT_PANTS = 'suit_pants',//西装裤
  SWEATPANTS = 'sweatpants',//运动裤
  SHORTS = 'shorts',//短裤
  SKIRT = 'skirt',//半身裙

  // 3. 外套
  JACKET = 'jacket',//短外套 / 夹克
  BLAZER = 'blazer',//西装外套
  TRENCH_COAT = 'trench_coat',//风衣
  COAT = 'coat',//大衣
  DOWN_JACKET = 'down_jacket',//羽绒服
  COTTON_JACKET = 'cotton_jacket',//棉服
  VEST = 'vest',//马甲
  SUN_PROTECTIVE = 'sun_protective',//防晒衣
  STORM_JACKET = 'storm_jacket',//冲锋衣

  // 4. 连体
  DRESS = 'dress',//连衣裙
  JUMPSUIT = 'jumpsuit',//连体裤
  SUIT = 'suit',//套装

  // 5. 鞋子
  SNEAKERS = 'sneakers',//运动鞋
  CASUAL_SHOES = 'casual_shoes',//休闲鞋
  LEATHER_SHOES = 'leather_shoes',//皮鞋
  BOOTS = 'boots',//靴子
  HIGH_HEELS = 'high_heels',//高跟鞋
  SANDALS = 'sandals',//凉鞋

  // 6. 配饰
  JEWELRY = 'jewelry',//首饰
  BAG = 'bag',//包包
  HAT = 'hat',//帽子
  SCARF = 'scarf',//围巾/披肩
  GLASSES = 'glasses',//眼镜/墨镜
  BELT = 'belt'//腰带
}

/**
 * 基础色系枚举 (用于算法推荐、标签分类)
 */
export enum ClothingColor {
  BLACK = 'black',     // 黑色
  WHITE = 'white',     // 白色
  GRAY = 'gray',       // 灰色
  RED = 'red',         // 红色
  PINK = 'pink',       // 粉色
  ORANGE = 'orange',   // 橙色 (新增)
  YELLOW = 'yellow',   // 黄色 (新增)
  KHAKI = 'khaki',     // 卡其/米色
  BROWN = 'brown',     // 棕色/咖啡色 (新增)
  GREEN = 'green',     // 绿色 (新增)
  CYAN = 'cyan',       // 青色/水蓝色 (新增)
  BLUE = 'blue',       // 蓝色
  NAVY = 'navy',       // 藏青/深蓝
  PURPLE = 'purple'    // 紫色 (新增)
}

/**
 * 4. 【核心逻辑】：二级到一级的一对多映射字典
 * 原理：将 SubCategory 作为键 (Key)，MainCategory 作为值 (Value)
 * 作用：录入衣服时，只要知道它是“T恤”，系统瞬间查字典就知道它是“上装”
 */
export const SubToMainCategoryMap: Record<SubCategory, MainCategory> = {
  // 1. 上装映射
  [SubCategory.T_SHIRT]: MainCategory.TOP,
  [SubCategory.SHIRT]: MainCategory.TOP,
  [SubCategory.POLO]: MainCategory.TOP,
  [SubCategory.SWEATER]: MainCategory.TOP,
  [SubCategory.HOODIE]: MainCategory.TOP,
  [SubCategory.CAMISOLE]: MainCategory.TOP,
  [SubCategory.BASE_SHIRT]: MainCategory.TOP,

  // 2. 下装映射
  [SubCategory.JEANS]: MainCategory.BOTTOM,
  [SubCategory.CASUAL_PANTS]: MainCategory.BOTTOM,
  [SubCategory.SUIT_PANTS]: MainCategory.BOTTOM,
  [SubCategory.SWEATPANTS]: MainCategory.BOTTOM,
  [SubCategory.SHORTS]: MainCategory.BOTTOM,
  [SubCategory.SKIRT]: MainCategory.BOTTOM,

  // 3. 外套映射
  [SubCategory.JACKET]: MainCategory.OUTERWEAR,
  [SubCategory.BLAZER]: MainCategory.OUTERWEAR,
  [SubCategory.TRENCH_COAT]: MainCategory.OUTERWEAR,
  [SubCategory.COAT]: MainCategory.OUTERWEAR,
  [SubCategory.DOWN_JACKET]: MainCategory.OUTERWEAR,
  [SubCategory.COTTON_JACKET]: MainCategory.OUTERWEAR,
  [SubCategory.VEST]: MainCategory.OUTERWEAR,
  [SubCategory.SUN_PROTECTIVE]: MainCategory.OUTERWEAR,
  [SubCategory.STORM_JACKET]: MainCategory.OUTERWEAR,

  // 4. 连体映射
  [SubCategory.DRESS]: MainCategory.ONE_PIECE,
  [SubCategory.JUMPSUIT]: MainCategory.ONE_PIECE,
  [SubCategory.SUIT]: MainCategory.ONE_PIECE,

  // 5. 鞋子映射
  [SubCategory.SNEAKERS]: MainCategory.SHOES,
  [SubCategory.CASUAL_SHOES]: MainCategory.SHOES,
  [SubCategory.LEATHER_SHOES]: MainCategory.SHOES,
  [SubCategory.BOOTS]: MainCategory.SHOES,
  [SubCategory.HIGH_HEELS]: MainCategory.SHOES,
  [SubCategory.SANDALS]: MainCategory.SHOES,

  // 6. 配饰映射
  [SubCategory.JEWELRY]: MainCategory.ACCESSORY,
  [SubCategory.BAG]: MainCategory.ACCESSORY,
  [SubCategory.HAT]: MainCategory.ACCESSORY,
  [SubCategory.SCARF]: MainCategory.ACCESSORY,
  [SubCategory.GLASSES]: MainCategory.ACCESSORY,
  [SubCategory.BELT]: MainCategory.ACCESSORY
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