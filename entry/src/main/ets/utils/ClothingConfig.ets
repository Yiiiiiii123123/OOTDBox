// =======================================================
// 1. 全局核心枚举定义 (由 Model 层迁移至此统一管理)
// =======================================================

export enum MainCategory {
  TOP = 'top',               // 上装
  BOTTOM = 'bottom',         // 下装
  ONE_PIECE = 'one_piece',   // 连体 (算法中与上下装互斥)
  OUTERWEAR = 'outerwear',   // 外套 (调节保暖指数的核心)
  SHOES = 'shoes',           // 鞋子
  ACCESSORY = 'accessory'    // 配饰 (可选)
}

export enum SubCategory {
  // 1. 上装
  T_SHIRT = 't_shirt', SHIRT = 'shirt', POLO = 'polo', SWEATER = 'sweater', HOODIE = 'hoodie', CAMISOLE = 'camisole', BASE_SHIRT = 'base_shirt',
  // 2. 下装
  JEANS = 'jeans', CASUAL_PANTS = 'casual_pants', SUIT_PANTS = 'suit_pants', SWEATPANTS = 'sweatpants', SHORTS = 'shorts', SKIRT = 'skirt',
  // 3. 外套
  JACKET = 'jacket', BLAZER = 'blazer', TRENCH_COAT = 'trench_coat', COAT = 'coat', DOWN_JACKET = 'down_jacket', COTTON_JACKET = 'cotton_jacket', VEST = 'vest', SUN_PROTECTIVE = 'sun_protective', STORM_JACKET = 'storm_jacket',
  // 4. 连体
  DRESS = 'dress', JUMPSUIT = 'jumpsuit', SUIT = 'suit',
  // 5. 鞋子
  SNEAKERS = 'sneakers', CASUAL_SHOES = 'casual_shoes', LEATHER_SHOES = 'leather_shoes', BOOTS = 'boots', HIGH_HEELS = 'high_heels', SANDALS = 'sandals',
  // 6. 配饰
  JEWELRY = 'jewelry', BAG = 'bag', HAT = 'hat', SCARF = 'scarf', GLASSES = 'glasses', BELT = 'belt'
}

export enum ClothingColor {
  BLACK = 'black', WHITE = 'white', GRAY = 'gray', RED = 'red', PINK = 'pink', ORANGE = 'orange', YELLOW = 'yellow', KHAKI = 'khaki', BROWN = 'brown', GREEN = 'green', CYAN = 'cyan', BLUE = 'blue', NAVY = 'navy', PURPLE = 'purple'
}

// 二级到一级分类的一对多映射字典
export const SubToMainCategoryMap: Record<SubCategory, MainCategory> = {
  [SubCategory.T_SHIRT]: MainCategory.TOP, [SubCategory.SHIRT]: MainCategory.TOP, [SubCategory.POLO]: MainCategory.TOP, [SubCategory.SWEATER]: MainCategory.TOP, [SubCategory.HOODIE]: MainCategory.TOP, [SubCategory.CAMISOLE]: MainCategory.TOP, [SubCategory.BASE_SHIRT]: MainCategory.TOP,
  [SubCategory.JEANS]: MainCategory.BOTTOM, [SubCategory.CASUAL_PANTS]: MainCategory.BOTTOM, [SubCategory.SUIT_PANTS]: MainCategory.BOTTOM, [SubCategory.SWEATPANTS]: MainCategory.BOTTOM, [SubCategory.SHORTS]: MainCategory.BOTTOM, [SubCategory.SKIRT]: MainCategory.BOTTOM,
  [SubCategory.JACKET]: MainCategory.OUTERWEAR, [SubCategory.BLAZER]: MainCategory.OUTERWEAR, [SubCategory.TRENCH_COAT]: MainCategory.OUTERWEAR, [SubCategory.COAT]: MainCategory.OUTERWEAR, [SubCategory.DOWN_JACKET]: MainCategory.OUTERWEAR, [SubCategory.COTTON_JACKET]: MainCategory.OUTERWEAR, [SubCategory.VEST]: MainCategory.OUTERWEAR, [SubCategory.SUN_PROTECTIVE]: MainCategory.OUTERWEAR, [SubCategory.STORM_JACKET]: MainCategory.OUTERWEAR,
  [SubCategory.DRESS]: MainCategory.ONE_PIECE, [SubCategory.JUMPSUIT]: MainCategory.ONE_PIECE, [SubCategory.SUIT]: MainCategory.ONE_PIECE,
  [SubCategory.SNEAKERS]: MainCategory.SHOES, [SubCategory.CASUAL_SHOES]: MainCategory.SHOES, [SubCategory.LEATHER_SHOES]: MainCategory.SHOES, [SubCategory.BOOTS]: MainCategory.SHOES, [SubCategory.HIGH_HEELS]: MainCategory.SHOES, [SubCategory.SANDALS]: MainCategory.SHOES,
  [SubCategory.JEWELRY]: MainCategory.ACCESSORY, [SubCategory.BAG]: MainCategory.ACCESSORY, [SubCategory.HAT]: MainCategory.ACCESSORY, [SubCategory.SCARF]: MainCategory.ACCESSORY, [SubCategory.GLASSES]: MainCategory.ACCESSORY, [SubCategory.BELT]: MainCategory.ACCESSORY
};


// =======================================================
// 2. UI 数据源
// =======================================================

export interface ColorOption {
  label: string;
  value: ClothingColor;
  hex: string;
}

export const COLOR_OPTIONS: ColorOption[] = [
  { label: '黑色', value: ClothingColor.BLACK, hex: '#2C2C2C' },
  { label: '白色', value: ClothingColor.WHITE, hex: '#F5F5F5' },
  { label: '灰色', value: ClothingColor.GRAY, hex: '#9E9E9E' },
  { label: '红色', value: ClothingColor.RED, hex: '#D32F2F' },
  { label: '粉色', value: ClothingColor.PINK, hex: '#F48FB1' },
  { label: '橙色', value: ClothingColor.ORANGE, hex: '#FF9800' },
  { label: '黄色', value: ClothingColor.YELLOW, hex: '#FFEB3B' },
  { label: '卡其', value: ClothingColor.KHAKI, hex: '#D7CCC8' },
  { label: '棕色', value: ClothingColor.BROWN, hex: '#795548' },
  { label: '绿色', value: ClothingColor.GREEN, hex: '#4CAF50' },
  { label: '青色', value: ClothingColor.CYAN, hex: '#00BCD4' },
  { label: '蓝色', value: ClothingColor.BLUE, hex: '#1976D2' },
  { label: '藏青', value: ClothingColor.NAVY, hex: '#1A237E' },
  { label: '紫色', value: ClothingColor.PURPLE, hex: '#9C27B0' }
];

export interface WarmthOption {
  label: string;
  value: number;
}

export const WARMTH_OPTIONS: WarmthOption[] = [
  { label: '极薄', value: 2 },
  { label: '微凉', value: 4 },
  { label: '适中', value: 6 },
  { label: '偏厚', value: 8 },
  { label: '极厚', value: 10 }
];

export const CATEGORY_UI_DATA: TextCascadePickerRangeContent[] = [
  { text: '上装', children: [{ text: 'T恤' }, { text: '衬衫' }, { text: 'Polo衫' }, { text: '毛衣' }, { text: '卫衣' }, { text: '吊带/背心' }, { text: '打底衫' }] },
  { text: '下装', children: [{ text: '牛仔裤' }, { text: '休闲裤' }, { text: '西装裤' }, { text: '运动裤' }, { text: '短裤' }, { text: '半身裙' }] },
  { text: '外套', children: [{ text: '短外套 / 夹克' }, { text: '西装外套' }, { text: '风衣' }, { text: '大衣' }, { text: '羽绒服' }, { text: '棉服' }, { text: '马甲' }, { text: '防晒衣' }, { text: '冲锋衣' }] },
  { text: '连体', children: [{ text: '连衣裙' }, { text: '连体裤' }, { text: '套装' }] },
  { text: '鞋子', children: [{ text: '运动鞋' }, { text: '休闲鞋' }, { text: '皮鞋' }, { text: '靴子' }, { text: '高跟鞋' }, { text: '凉鞋' }] },
  { text: '配饰', children: [{ text: '首饰' }, { text: '包包' }, { text: '帽子' }, { text: '围巾/披肩' }, { text: '眼镜/墨镜' }, { text: '腰带' }] }
];

// =======================================================
// 3. 工具方法
// =======================================================

export class ClothingUtils {
  static getMainCategoryLabel(main: string): string {
    const map: Record<string, string> = { 'top': '上装', 'bottom': '下装', 'one_piece': '连体', 'outerwear': '外套', 'shoes': '鞋子', 'accessory': '配饰' };
    return map[main.toString()] || '单品';
  }

  static getSubCategoryByLabel(label: string): SubCategory {
    const map: Record<string, SubCategory> = {
      'T恤': SubCategory.T_SHIRT, '衬衫': SubCategory.SHIRT, 'Polo衫': SubCategory.POLO, '毛衣': SubCategory.SWEATER, '卫衣': SubCategory.HOODIE, '吊带/背心': SubCategory.CAMISOLE, '打底衫': SubCategory.BASE_SHIRT,
      '牛仔裤': SubCategory.JEANS, '休闲裤': SubCategory.CASUAL_PANTS, '西装裤': SubCategory.SUIT_PANTS, '运动裤': SubCategory.SWEATPANTS, '短裤': SubCategory.SHORTS, '半身裙': SubCategory.SKIRT,
      '短外套 / 夹克': SubCategory.JACKET, '西装外套': SubCategory.BLAZER, '风衣': SubCategory.TRENCH_COAT, '大衣': SubCategory.COAT, '羽绒服': SubCategory.DOWN_JACKET, '棉服': SubCategory.COTTON_JACKET, '马甲': SubCategory.VEST, '防晒衣': SubCategory.SUN_PROTECTIVE, '冲锋衣': SubCategory.STORM_JACKET,
      '连衣裙': SubCategory.DRESS, '连体裤': SubCategory.JUMPSUIT, '套装': SubCategory.SUIT,
      '运动鞋': SubCategory.SNEAKERS, '休闲鞋': SubCategory.CASUAL_SHOES, '皮鞋': SubCategory.LEATHER_SHOES, '靴子': SubCategory.BOOTS, '高跟鞋': SubCategory.HIGH_HEELS, '凉鞋': SubCategory.SANDALS,
      '首饰': SubCategory.JEWELRY, '包包': SubCategory.BAG, '帽子': SubCategory.HAT, '围巾/披肩': SubCategory.SCARF, '眼镜/墨镜': SubCategory.GLASSES, '腰带': SubCategory.BELT
    };
    return map[label] || SubCategory.T_SHIRT;
  }

  static getLabelBySubCategory(sub: SubCategory | string): string {
    const map: Record<string, string> = {
      't_shirt': 'T恤', 'shirt': '衬衫', 'polo': 'Polo衫', 'sweater': '毛衣', 'hoodie': '卫衣', 'camisole': '吊带/背心', 'base_shirt': '打底衫',
      'jeans': '牛仔裤', 'casual_pants': '休闲裤', 'suit_pants': '西装裤', 'sweatpants': '运动裤', 'shorts': '短裤', 'skirt': '半身裙',
      'jacket': '短外套 / 夹克', 'blazer': '西装外套', 'trench_coat': '风衣', 'coat': '大衣', 'down_jacket': '羽绒服', 'cotton_jacket': '棉服', 'vest': '马甲', 'sun_protective': '防晒衣', 'storm_jacket': '冲锋衣',
      'dress': '连衣裙', 'jumpsuit': '连体裤', 'suit': '套装',
      'sneakers': '运动鞋', 'casual_shoes': '休闲鞋', 'leather_shoes': '皮鞋', 'boots': '靴子', 'high_heels': '高跟鞋', 'sandals': '凉鞋',
      'jewelry': '首饰', 'bag': '包包', 'hat': '帽子', 'scarf': '围巾/披肩', 'glasses': '眼镜/墨镜', 'belt': '腰带'
    };
    return map[sub.toString()] || '未知款式';
  }

  /**
   * 获取所有属于“配饰”的二级分类 Key
   * 用于饰品选择页左侧菜单的静态展示
   */
  static getAccessorySubCategories(): SubCategory[] {
    return [
      SubCategory.JEWELRY,
      SubCategory.BAG,
      SubCategory.HAT,
      SubCategory.SCARF,
      SubCategory.GLASSES,
      SubCategory.BELT
    ];
  }

  static getColorHex(color: string): string {
    const target = COLOR_OPTIONS.find(c => c.value === color);
    return target ? target.hex : '#CCCCCC';
  }

  static getColorLabel(color: string): string {
    const target = COLOR_OPTIONS.find(c => c.value === color);
    return target ? target.label : '未知';
  }
}