// model/Category.ets

// 分类枚举值
export enum ClothingCategory {
  ALL = 'all',
  TOP = '上装',
  BOTTOM = '下装',
  ONEPIECE = '连体',
  SHOES = '鞋子',
  ACCESSORY = '配饰'
}

// 分类项接口（新增！）
export interface Category {
  key: ClothingCategory
  label: string
}

// 分类列表配置
export const CATEGORY_LIST: Category[] = [
  { key: ClothingCategory.ALL, label: '全部' },
  { key: ClothingCategory.TOP, label: '上装' },
  { key: ClothingCategory.BOTTOM, label: '下装' },
  { key: ClothingCategory.ONEPIECE, label: '连体' },
  { key: ClothingCategory.SHOES, label: '鞋子' },
  { key: ClothingCategory.ACCESSORY, label: '配饰' }
]

// AI 识别映射：将常见叫法统一映射到标准分类
export function normalizeCategory(raw: string): string {
  const map: Record<string, string> = {
    '上衣': ClothingCategory.TOP,
    '上装': ClothingCategory.TOP,
    '外套': ClothingCategory.TOP,
    'T恤': ClothingCategory.TOP,
    '衬衫': ClothingCategory.TOP,
    '卫衣': ClothingCategory.TOP,
    '毛衣': ClothingCategory.TOP,

    '裤子': ClothingCategory.BOTTOM,
    '下装': ClothingCategory.BOTTOM,
    '短裤': ClothingCategory.BOTTOM,
    '裙子': ClothingCategory.BOTTOM,
    '半身裙': ClothingCategory.BOTTOM,

    '连衣裙': ClothingCategory.ONEPIECE,
    '连体裤': ClothingCategory.ONEPIECE,
    '连体': ClothingCategory.ONEPIECE,

    '鞋子': ClothingCategory.SHOES,
    '鞋': ClothingCategory.SHOES,
    '运动鞋': ClothingCategory.SHOES,
    '皮鞋': ClothingCategory.SHOES,

    '配饰': ClothingCategory.ACCESSORY,
    '包包': ClothingCategory.ACCESSORY,
    '帽子': ClothingCategory.ACCESSORY,
    '围巾': ClothingCategory.ACCESSORY,
    '首饰': ClothingCategory.ACCESSORY
  }
  return map[raw] || raw
}