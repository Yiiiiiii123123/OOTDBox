export class OutfitCombination {
  id: string;
  clothingIds: string[];

  recommendCount: number;
  acceptCount: number;
  averageTemp: number;
  lastWornDate: number;

  // 【新增】：收藏时间戳
  // 作用 1：为 0 表示未收藏，大于 0 表示已收藏且记录了具体时间
  // 作用 2：“我的收藏”页面可以用此字段进行 DESC 降序排列
  favoriteTime: number;

  constructor(id: string, clothingIds: string[], initialTemp: number) {
    this.id = id;
    this.clothingIds = clothingIds;
    this.recommendCount = 0;
    this.acceptCount = 0;
    this.averageTemp = initialTemp;
    this.lastWornDate = 0;

    // 默认未收藏
    this.favoriteTime = 0;
  }

  /**
   * 核心属性：动态获取用户满意度得分
   * 【逻辑升级】：加入了收藏权重
   */
  get preferenceScore(): number {
    let baseScore = 0;

    if (this.recommendCount === 0) {
      baseScore = 0.5; // 新组合的探索分
    } else {
      baseScore = this.acceptCount / this.recommendCount; // 基础采纳率
    }

    // 【最高优先级】：如果是用户主动收藏的穿搭，直接给予超高加分 (例如 +2.0)
    // 这意味着只要今天温度合适，收藏夹里的衣服绝对会排在推荐列表的最前面！
    if (this.isFavorited()) {
      return baseScore + 2.0;
    }

    return baseScore;
  }

  /**
   * 辅助方法：判断是否已收藏
   */
  public isFavorited(): boolean {
    return this.favoriteTime > 0;
  }

  /**
   * 行为动作 4：用户点击了“心形/收藏”按钮
   * 作用：切换收藏状态
   */
  public toggleFavorite(): void {
    if (this.isFavorited()) {
      this.favoriteTime = 0; // 取消收藏
    } else {
      this.favoriteTime = new Date().getTime(); // 记录当前时间戳为收藏时间
    }
  }

  // ... (保留之前的 markAsRecommended, markAsAccepted, markAsDisliked 方法) ...
}