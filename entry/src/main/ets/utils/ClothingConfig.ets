import { SubCategory, ClothingColor } from '../model/Clothing';

// =======================================================
// 1. UI 数据源 (唯一数据源，以后修改/添加只改这里)
// =======================================================

// 颜色配置
// 1. 严格限定 value 必须是 ClothingColor 枚举
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

// 保暖度配置
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

// 级联选择器数据
export const CATEGORY_UI_DATA: TextCascadePickerRangeContent[] = [
  { text: '上装', children: [{ text: 'T恤' }, { text: '衬衫' }, { text: 'Polo衫' }, { text: '毛衣' }, { text: '卫衣' }, { text: '吊带/背心' }, { text: '打底衫' }] },
  { text: '下装', children: [{ text: '牛仔裤' }, { text: '休闲裤' }, { text: '西装裤' }, { text: '运动裤' }, { text: '短裤' }, { text: '半身裙' }] },
  { text: '外套', children: [{ text: '短外套 / 夹克' }, { text: '西装外套' }, { text: '风衣' }, { text: '大衣' }, { text: '羽绒服' }, { text: '棉服' }, { text: '马甲' }, { text: '防晒衣' }, { text: '冲锋衣' }] },
  { text: '连体', children: [{ text: '连衣裙' }, { text: '连体裤' }, { text: '套装' }] },
  { text: '鞋子', children: [{ text: '运动鞋' }, { text: '休闲鞋' }, { text: '皮鞋' }, { text: '靴子' }, { text: '高跟鞋' }, { text: '凉鞋' }] },
  { text: '配饰', children: [{ text: '首饰' }, { text: '包包' }, { text: '帽子' }, { text: '围巾/披肩' }, { text: '眼镜/墨镜' }, { text: '腰带' }] }
];


// =======================================================
// 2. 工具方法 (直接读取上方的数据源，绝不重复写死)
// =======================================================

export class ClothingUtils {

  /**
   * 将主类别枚举转为中文标签
   */
  static getMainCategoryLabel(main: string): string {
    const map: Record<string, string> = {
      'top': '上装',
      'bottom': '下装',
      'one_piece': '连体',
      'outerwear': '外套',
      'shoes': '鞋子',
      'accessory': '配饰'
    };
    return map[main.toString()] || '单品';
  }

  /**
   * 中文标签转枚举 (UI -> 数据库)
   */
  static getSubCategoryByLabel(label: string): SubCategory {
    const map: Record<string, SubCategory> = {
      // 上装
      'T恤': SubCategory.T_SHIRT, '衬衫': SubCategory.SHIRT, 'Polo衫': SubCategory.POLO,
      '毛衣': SubCategory.SWEATER, '卫衣': SubCategory.HOODIE, '吊带/背心': SubCategory.CAMISOLE, '打底衫': SubCategory.BASE_SHIRT,
      // 下装
      '牛仔裤': SubCategory.JEANS, '休闲裤': SubCategory.CASUAL_PANTS, '西装裤': SubCategory.SUIT_PANTS,
      '运动裤': SubCategory.SWEATPANTS, '短裤': SubCategory.SHORTS, '半身裙': SubCategory.SKIRT,
      // 外套
      '短外套 / 夹克': SubCategory.JACKET, '西装外套': SubCategory.BLAZER, '风衣': SubCategory.TRENCH_COAT,
      '大衣': SubCategory.COAT, '羽绒服': SubCategory.DOWN_JACKET, '棉服': SubCategory.COTTON_JACKET,
      '马甲': SubCategory.VEST, '防晒衣': SubCategory.SUN_PROTECTIVE, '冲锋衣': SubCategory.STORM_JACKET,
      // 连体
      '连衣裙': SubCategory.DRESS, '连体裤': SubCategory.JUMPSUIT, '套装': SubCategory.SUIT,
      // 鞋子
      '运动鞋': SubCategory.SNEAKERS, '休闲鞋': SubCategory.CASUAL_SHOES, '皮鞋': SubCategory.LEATHER_SHOES,
      '靴子': SubCategory.BOOTS, '高跟鞋': SubCategory.HIGH_HEELS, '凉鞋': SubCategory.SANDALS,
      // 配饰
      '首饰': SubCategory.JEWELRY, '包包': SubCategory.BAG, '帽子': SubCategory.HAT,
      '围巾/披肩': SubCategory.SCARF, '眼镜/墨镜': SubCategory.GLASSES, '腰带': SubCategory.BELT
    };
    return map[label] || SubCategory.T_SHIRT; // 默认兜底
  }

  /**
   * 枚举转中文标签 (数据库 -> UI)
   */
  static getLabelBySubCategory(sub: SubCategory | string): string {
    const map: Record<string, string> = {
      // 上装
      't_shirt': 'T恤', 'shirt': '衬衫', 'polo': 'Polo衫',
      'sweater': '毛衣', 'hoodie': '卫衣', 'camisole': '吊带/背心', 'base_shirt': '打底衫',
      // 下装
      'jeans': '牛仔裤', 'casual_pants': '休闲裤', 'suit_pants': '西装裤',
      'sweatpants': '运动裤', 'shorts': '短裤', 'skirt': '半身裙',
      // 外套
      'jacket': '短外套 / 夹克', 'blazer': '西装外套', 'trench_coat': '风衣',
      'coat': '大衣', 'down_jacket': '羽绒服', 'cotton_jacket': '棉服',
      'vest': '马甲', 'sun_protective': '防晒衣', 'storm_jacket': '冲锋衣',
      // 连体
      'dress': '连衣裙', 'jumpsuit': '连体裤', 'suit': '套装',
      // 鞋子
      'sneakers': '运动鞋', 'casual_shoes': '休闲鞋', 'leather_shoes': '皮鞋',
      'boots': '靴子', 'high_heels': '高跟鞋', 'sandals': '凉鞋',
      // 配饰
      'jewelry': '首饰', 'bag': '包包', 'hat': '帽子',
      'scarf': '围巾/披肩', 'glasses': '眼镜/墨镜', 'belt': '腰带'
    };
    return map[sub.toString()] || '未知款式';
  }

  /**
   * 🌟 优化：颜色枚举转十六进制 (直接从 COLOR_OPTIONS 数组里找，不重复写)
   */
  static getColorHex(color: string): string {
    const target = COLOR_OPTIONS.find(c => c.value === color);
    return target ? target.hex : '#CCCCCC';
  }

  /**
   * 🌟 优化：内部颜色名映射 (直接从 COLOR_OPTIONS 数组里找，不重复写)
   */
  static getColorLabel(color: string): string {
    const target = COLOR_OPTIONS.find(c => c.value === color);
    return target ? target.label : '未知';
  }
}