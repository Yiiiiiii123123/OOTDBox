// utils/TemperatureRuleUtils.ets

export class TemperatureRuleUtils {

  // 1. 获取外套适宜的保暖指数
  public static getOuterWarmths(T: number): number[] {
    if (T >= 25) return []; // 25度以上按理不需要常规外套（防晒服在业务逻辑里单独判断）
    if (T >= 20 && T < 25) return [4, 6];
    if (T >= 15 && T < 20) return [4, 6, 8];
    if (T >= 10 && T < 15) return [6, 8, 10];
    return [8, 10]; // T <= 10
  }

  // 2. 获取上装适宜的保暖指数 (只返回数组，纯粹干练！)
  public static getTopWarmths(T: number): number[] {
    if (T >= 25) return [2, 4];
    if (T >= 20 && T < 25) return [4, 6];
    if (T >= 15 && T < 20) return [4, 6, 8];
    if (T >= 10 && T < 15) return [6, 8];
    return [8, 10];
  }

  // 🌟 独立出来的方法：判断是否需要打底衫 (极度优雅，只有一行！)
  public static isBaseLayerNeeded(T: number): boolean {
    return T < 15;
  }

  // 3. 获取下装适宜的保暖指数
  public static getBottomWarmths(T: number): number[] {
    if (T >= 25) return [2, 4];
    if (T >= 15 && T < 25) return [4, 6];
    return [6, 8, 10]; // T <= 15
  }

  // 4. 获取连体衣适宜的保暖指数
  public static getOnePieceWarmths(T: number): number[] {
    if (T >= 30) return [2];
    if (T >= 25 && T < 30) return [2, 4];
    if (T >= 20 && T < 25) return [4, 6];
    if (T >= 15 && T < 20) return [4, 6, 8];
    if (T >= 10 && T < 15) return [6, 8, 10];
    return [8, 10]; // T <= 10
  }

  // 5. 获取鞋子适宜的保暖指数
  public static getShoeWarmths(T: number): number[] {
    if (T >= 25) return [2, 4, 6];
    if (T >= 20 && T < 25) return [4, 6];
    if (T >= 15 && T < 20) return [4, 6, 8];
    return [6, 8, 10];
  }
}