export class Outfit {
  id: string;                     // 唯一标识——采用衣物id排序拼接法
  clothingIds: string[];          // 衣物组合以id数组储存
  accessoryIds: string[];         // 新增：独立存放配饰ID

  recommendCount: number;         // 推荐次数
  acceptCount: number;            // 接受次数
  averageTemp: number;            // 平均气温
  lastWornDate: number;           // 最后穿着日期
  favoriteTime: number;           // 收藏时间戳

  // 1：构造函数，让它自动生成指纹 ID
  constructor(clothingIds: string[], accessoryIds: string[] = [], initialTemp: number, id?: string) {
    this.clothingIds = [...clothingIds].sort();
    this.accessoryIds = [...accessoryIds].sort(); // 配饰单独保存

    // 如果外面传了 id（比如从数据库读取数据时），就用传进来的；
    // 如果没传（生成全新穿搭时），就自动调用下方的规则生成指纹 ID！
    this.id = id ? id : Outfit.generateFingerprint(this.clothingIds);

    this.recommendCount = 0;
    this.acceptCount = 0;
    this.averageTemp = initialTemp;
    this.lastWornDate = 0;
    this.favoriteTime = 0;
  }

  //2：提供一个静态的“暗号生成器”
  // 作用：当在 Service 层拿到了几件衣服，想去数据库查有没有这套组合时，
  // 直接调用 Outfit.generateFingerprint([id1, id2...]) 就能瞬间算出正确的暗号！
  static generateFingerprint(ids: string[]): string {
    return [...ids].sort().join(',');
  }

  /**
   * 核心属性：动态获取用户满意度得分
   */
  get preferenceScore(): number {
    let baseScore = 0;
    if (this.recommendCount === 0) {
      baseScore = 0.5; // 新组合的探索分
    } else {
      baseScore = this.acceptCount / this.recommendCount;
    }

    if (this.isFavorited()) {
      return baseScore + 2.0;
    }
    return baseScore;
  }

  public isFavorited(): boolean {
    return this.favoriteTime > 0;
  }

  public toggleFavorite(): void {
    if (this.isFavorited()) {
      this.favoriteTime = 0;
    } else {
      this.favoriteTime = new Date().getTime();
    }
  }

}