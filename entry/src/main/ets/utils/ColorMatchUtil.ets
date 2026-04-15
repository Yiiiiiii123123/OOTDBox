export class ColorMatchUtil {
  // 基础百搭色（黑白灰、卡其、藏青），计算色彩数量时忽略这些
  public static readonly NEUTRAL_COLORS: string[] = [];
  //'black', 'gray', 'khaki', 'navy'， 'white'

  // 相配色表（你可以根据自己的审美继续往里加）
  // 只要搭配中同时出现了数组里的这两个颜色，就判定为相配色
  public static readonly MATCHING_PAIRS: string[][] = [
    ['blue', 'white'],    // 蓝白搭
    ['black', 'red'],     // 黑红经典
    ['green', 'white'],   // 绿白清新
    ['yellow', 'blue'],   // 黄蓝撞色
    ['pink', 'gray']      // 粉灰高级
  ];

  /**
   * 检查衣服数组中是否包含相配色
   */
  public static hasMatchingColors(colors: string[]): boolean {
    for (let pair of ColorMatchUtil.MATCHING_PAIRS) {
      if (colors.includes(pair[0]) && colors.includes(pair[1])) {
        return true;
      }
    }
    return false;
  }
}