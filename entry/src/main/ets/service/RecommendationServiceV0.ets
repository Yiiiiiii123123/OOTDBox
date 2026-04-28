import { Clothing} from '../model/Clothing';
import { MainCategory } from '../utils/ClothingConfig';

export class RecommendationServiceV0 {

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




  //原评分计算
  /*
  private calculateScore(items: Clothing[]): number {
    let score = 100; // 初始 100 分

    // 1. ❌ 完整度检查 (直接零分机制)
    let hasShoes = items.some(c => c.mainCategory === 'shoes');
    let hasTop = items.some(c => c.mainCategory === 'top');
    let hasBottom = items.some(c => c.mainCategory === 'bottom');
    let hasOnePiece = items.some(c => c.mainCategory === 'one_piece');

    if (!hasShoes) return 0; // 没鞋子
    if (!hasOnePiece && (!hasTop || !hasBottom)) return 0; // 既没有连体，也没有完整的上下装组合

    // 2. 🎨 颜色检查
    let allColors = items.map(c => c.color.toString());
    let vividColors = allColors.filter(color => !ColorMatchUtil.NEUTRAL_COLORS.includes(color));
    let uniqueVividColors = Array.from(new Set(vividColors));

    if (uniqueVividColors.length < 3) {
      score += 10;
    } else if (uniqueVividColors.length > 3) {
      score -= 30;
    } // 等于3种不加分也不扣分

    // 3. 🤝 相配色检查
    if (ColorMatchUtil.hasMatchingColors(allColors)) {
      score += 10;
    }

    // 4. 📅 穿戴记录检查
    let now = new Date().getTime();
    for (let item of items) {
      if (item.lastWornDate && item.lastWornDate > 0) {
        // 计算天数差
        let diffDays = Math.floor((now - item.lastWornDate) / (1000 * 3600 * 24));

        if (diffDays <= 1) score -= 5;
        else if (diffDays === 2) score -= 3;
        else if (diffDays === 3) score -= 1;
        else if (diffDays > 15) score += 5;
      } else {
        // 从未穿过，加 5 分鼓励尝试
        score += 5;
      }
    }

    // 🌟 5. 新增：款式冲突与温度违和检查 (Expert Rules)
    let outerwear = items.find(c => c.mainCategory === 'outerwear');
    // 找出是否有非打底衫的普通上装
    let normalTop = items.find(c => c.mainCategory === 'top' && c.subCategory !== 'base_shirt');

    if (outerwear) {
      // 细则 1：外套为马甲，且上装中有打底衫之外的其他种类
      if (outerwear.subCategory === 'vest' && normalTop) {
        score -= 30;
      }

      // 防晒衣专属冲突检查
      if (outerwear.subCategory === 'sun_protective') {
        // 细则 2：如果上衣（无论打底还是普通上装）保暖度 >= 6
        let hasThickTop = items.some(c => c.mainCategory === 'top' && c.warmthIndex >= 6);
        if (hasThickTop) {
          score -= 30;
        }

        // 细则 3：如果上装中有衬衫
        let hasShirt = items.some(c => c.mainCategory === 'top' && c.subCategory === 'shirt');
        if (hasShirt) {
          score -= 30;
        }
      }
    }

    return score;
  }
  * */
}