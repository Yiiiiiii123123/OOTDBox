import { Clothing, MainCategory } from '../model/Clothing';

export class RecommendService {

  /**
   * 🌟 核心推荐算法
   * @param temp 当前气温
   * @param allClothes 衣橱里的所有衣服
   */
  public generate(temp: number, allClothes: Clothing[]): Clothing[] {
    if (allClothes.length === 0) return [];

    // 1. 计算目标总保暖值 (Target Warmth Index)
    // 这是一个简单的线性公式示例：气温越高，需要的保暖值越低
    // 假设：30度需要 4, 10度需要 18, 0度需要 25
    const targetWarmth = Math.max(4, 30 - temp);

    // 2. 筛选出近期没穿过的候选单品 (硬过滤)
    const now = new Date().getTime();
    const threeDaysMs = 3 * 24 * 60 * 60 * 1000;
    const candidates = allClothes.filter(item => (now - item.lastWornDate) > threeDaysMs);

    // 如果过滤后没衣服了，就用全部衣服，防止没得推
    const pool = candidates.length > 0 ? candidates : allClothes;

    // 3. 按照“槽位”挑选衣服
    let result: Clothing[] = [];

    // --- 第一步：选上装 (TOP) ---
    const tops = pool.filter(i => i.mainCategory === MainCategory.TOP);
    if (tops.length === 0) return []; // 连上衣都没有就推不了
    const selectedTop = tops[Math.floor(Math.random() * tops.length)];
    result.push(selectedTop);

    // --- 第二步：选下装 (BOTTOM) ---
    const bottoms = pool.filter(i => i.mainCategory === MainCategory.BOTTOM);
    if (bottoms.length > 0) {
      const selectedBottom = bottoms[Math.floor(Math.random() * bottoms.length)];
      result.push(selectedBottom);
    }

    // --- 第三步：判断是否需要外套 (OUTERWEAR) ---
    // 计算当前已选组合的保暖总和
    let currentWarmth = result.reduce((sum, item) => sum + item.warmthIndex, 0);

    if (currentWarmth < targetWarmth) {
      const outerwears = pool.filter(i => i.mainCategory === MainCategory.OUTERWEAR);
      if (outerwears.length > 0) {
        // 找一件保暖度最接近差值的外套
        const diff = targetWarmth - currentWarmth;
        const bestOuter = outerwears.sort((a, b) =>
        Math.abs(a.warmthIndex - diff) - Math.abs(b.warmthIndex - diff)
        )[0];
        result.push(bestOuter);
      }
    }

    // --- 第四步：加双鞋 (SHOES) ---
    const shoes = pool.filter(i => i.mainCategory === MainCategory.SHOES);
    if (shoes.length > 0) {
      result.push(shoes[Math.floor(Math.random() * shoes.length)]);
    }

    return result;
  }
}