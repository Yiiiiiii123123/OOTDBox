import { SubCategory } from '../model/Clothing';

export class ClothingUtils {

  /**
   * 🌟 新增：将主类别枚举转为中文标签
   * @param main 主类别枚举值 (如 'top')
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

    // 这里的 toString() 是为了兼容某些情况下传进来的是枚举类型
    return map[main.toString()] || '单品';
  }

  /**
   * 中文标签转枚举 (用于保存数据)
   */
  static getSubCategoryByLabel(label: string): SubCategory {
    const map: Record<string, SubCategory> = {
      'T恤': SubCategory.T_SHIRT, '衬衫': SubCategory.SHIRT, '毛衣/卫衣': SubCategory.SWEATER,
      '牛仔裤': SubCategory.JEANS, '短裤': SubCategory.SHORTS, '休闲裤': SubCategory.CASUAL_PANTS, '半身裙': SubCategory.SKIRT,
      '连衣裙': SubCategory.DRESS, '连体裤': SubCategory.JUMPSUIT,
      '夹克': SubCategory.JACKET, '大衣': SubCategory.COAT, '羽绒服': SubCategory.DOWN_JACKET,
      '运动鞋': SubCategory.SNEAKERS, '靴子': SubCategory.BOOTS,
      '围巾': SubCategory.SCARF, '帽子': SubCategory.HAT
    };
    return map[label] || SubCategory.T_SHIRT;
  }

  /**
   * 枚举转中文标签 (用于详情页显示或编辑回填)
   */
  static getLabelBySubCategory(sub: SubCategory | string): string {
    const map: Record<string, string> = {
      't_shirt': 'T恤', 'shirt': '衬衫', 'sweater': '毛衣/卫衣',
      'jeans': '牛仔裤', 'shorts': '短裤', 'casual_pants': '休闲裤', 'skirt': '半身裙',
      'dress': '连衣裙', 'jumpsuit': '连体裤',
      'jacket': '夹克', 'coat': '大衣', 'down_jacket': '羽绒服',
      'sneakers': '运动鞋', 'boots': '靴子', 'scarf': '围巾', 'hat': '帽子'
    };
    return map[sub.toString()] || '未知款式';
  }

  /**
   * 颜色枚举转十六进制 (用于 UI 渲染)
   */
  static getColorHex(color: string): string {
    const hexMap: Record<string, string> = {
      'black': '#2C2C2C', 'white': '#FFFFFF', 'gray': '#808080','pink': '#ffff96e1',
      'navy': '#000080', 'khaki': '#F0E68C', 'red': '#FF0000', 'blue': '#0000FF'
    };
    return hexMap[color] || '#CCCCCC';
  }

  // 内部简单的颜色名映射（或者也可以搬到 Utils 里）
  static getColorLabel(color: string): string {
    const colorMap: Record<string, string> = {
      'black': '黑色', 'white': '白色', 'gray': '灰色','pink':'粉红',
      'navy': '藏青', 'khaki': '卡其', 'red': '红色', 'blue': '蓝色'
    };
    return colorMap[color] || '未知';
  }
}