import { SubCategory, ClothingColor } from '../model/Clothing';

// 颜色配置
export interface ColorOption {
  label: string;
  value: ClothingColor;
  hex: string;
}

export const COLOR_OPTIONS: ColorOption[] = [
  { label: '黑', value: ClothingColor.BLACK, hex: '#2C2C2C' },
  { label: '白', value: ClothingColor.WHITE, hex: '#F5F5F5' },
  { label: '灰', value: ClothingColor.GRAY, hex: '#9E9E9E' },
  { label: '蓝', value: ClothingColor.BLUE, hex: '#1976D2' },
  { label: '红', value: ClothingColor.RED, hex: '#D32F2F' },
  { label: '粉红', value: ClothingColor.PINK, hex: '#ffff96e1' },
  { label: '卡其', value: ClothingColor.KHAKI, hex: '#D7CCC8' },
  { label: '藏青', value: ClothingColor.NAVY, hex: '#1A237E' }
];

// 保暖度描述
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
  { text: '上装', children: [{ text: 'T恤' }, { text: '衬衫' }, { text: '毛衣/卫衣' }] },
  { text: '下装', children: [{ text: '牛仔裤' }, { text: '短裤' }, { text: '休闲裤' }, { text: '半身裙' }] },
  { text: '连体', children: [{ text: '连衣裙' }, { text: '连体裤' }] },
  { text: '外套', children: [{ text: '夹克' }, { text: '大衣' }, { text: '羽绒服' }] },
  { text: '鞋子', children: [{ text: '运动鞋' }, { text: '靴子' }] },
  { text: '配饰', children: [{ text: '围巾' }, { text: '帽子' }] }
];