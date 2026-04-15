import { Clothing } from '../model/Clothing';
import { OutfitCombination } from '../model/Outfit'; // 引入你的原生模型
import { ClothingRepo } from '../repository/ClothingRepo';
import { ColorMatchUtil } from '../utils/ColorMatchUtil';
import { util } from '@kit.ArkTS';

// 内部临时接口，用于在计算过程中绑定衣服和分数
interface CandidateOutfit {
  items: Clothing[];
  score: number;
}

export class RecommendationResult {
  combination: OutfitCombination;
  clothes: Clothing[];

  constructor(combination: OutfitCombination, clothes: Clothing[]) {
    this.combination = combination;
    this.clothes = clothes;
  }
}

export class RecommendationService {
  private repo = new ClothingRepo();

  /**
   * 🎯 顶层调用：生成并推荐最佳穿搭
   * 返回一个对象，包含组合模型（存库用）和实际衣服数组（UI展示用）
   */
  public async getBestRecommendation(temperature: number): Promise<RecommendationResult | null> {
    const allClothes = await this.repo.getAll();
    if (!allClothes || allClothes.length === 0) return null;

    let bestCandidate: CandidateOutfit | null = null;
    let highestScore = -1;

    // 🌟 先生成 3 套候选方案并打分
    for (let i = 0; i < 3; i++) {
      let candidateItems = this.generateCombination(allClothes, temperature);
      let score = this.calculateScore(candidateItems);

      if (score > highestScore) {
        highestScore = score;
        bestCandidate = { items: candidateItems, score: score };
      }
    }

    if (!bestCandidate) return null;

    // 🌟 将胜出的衣服数组，转换为你原有的 OutfitCombination 模型
    // 这里使用鸿蒙 util 生成唯一 UUID 作为组合 ID
    let uuid = util.generateRandomUUID();
    let clothingIds = bestCandidate.items.map(c => c.id);
    let winningCombination = new OutfitCombination(uuid, clothingIds, temperature);

    return new RecommendationResult(winningCombination, bestCandidate.items);// 顺便返回实体数组，方便 UI 页面直接渲染图片

  }

  // ==================== 🛠️ 步骤 1：按规则随机生成搭配 ====================

  private generateCombination(clothes: Clothing[], T: number): Clothing[] {
    let result: Clothing[] = [];

    // 辅助闭包：安全地从数组中随机抽一件
    const pickRandom = (items: Clothing[]) => items.length > 0 ? items[Math.floor(Math.random() * items.length)] : null;
    const safePush = (item: Clothing | null) => { if (item) result.push(item); };

    // 1. 🧥 选外套 (可选)
    let outerWarmths: number[] = [];
    if (T >= 20) {
      if (Math.random() > 0.7) { // 30% 概率防晒
        let sunCoats = clothes.filter(c => c.mainCategory === 'outerwear' && c.subCategory === 'sun_protective');
        safePush(pickRandom(sunCoats));
      }
    } else {
      if (T >= 15 && T < 20) outerWarmths = [4, 6, 8];
      else if (T >= 10 && T < 15) outerWarmths = [6, 8, 10];
      else outerWarmths = [8, 10]; // T <= 10
      let validOuter = clothes.filter(c => c.mainCategory === 'outerwear' && outerWarmths.includes(c.warmthIndex));
      safePush(pickRandom(validOuter));
    }

    // 2. 👗 核心部分：选主体 (上下装 or 连体)
    let allBottoms = clothes.filter(c => c.mainCategory === 'bottom');
    let allOnePieces = clothes.filter(c => c.mainCategory === 'one_piece');
    let allTops = clothes.filter(c => c.mainCategory === 'top'); // 普通上装
    let allBaseLayers = clothes.filter(c => c.mainCategory === 'top' && c.subCategory === 'base_shirt'); // 打底衫

    let totalMain = allBottoms.length + allOnePieces.length;
    // 按照连体衣占比作为进入连体逻辑的概率 (防止死循环)
    let onePieceProb = totalMain > 0 ? (allOnePieces.length / totalMain) : 0;

    if (Math.random() < onePieceProb) {
      // 🌟 走【连体衣】路线
      let opWarmths: number[] = [];
      if (T >= 30) opWarmths = [2];
      else if (T >= 25 && T < 30) opWarmths = [2, 4];
      else if (T >= 20 && T < 25) opWarmths = [4, 6];
      else if (T >= 15 && T < 20) opWarmths = [4, 6, 8];
      else if (T >= 10 && T < 15) opWarmths = [6, 8, 10];
      else opWarmths = [8, 10]; // T <= 10
      safePush(pickRandom(allOnePieces.filter(c => opWarmths.includes(c.warmthIndex))));

    } else {
      // 🌟 走【上下装】路线
      // 2.1 选上装
      let topWarmths: number[] = [];
      let needBaseLayer = false;

      if (T >= 25) topWarmths = [2, 4];
      else if (T >= 20 && T < 25) topWarmths = [4, 6];
      else if (T >= 15 && T < 20) topWarmths = [4, 6, 8];
      else if (T >= 10 && T < 15) { topWarmths = [6, 8]; needBaseLayer = true; }
      else { topWarmths = [8, 10]; needBaseLayer = true; } // T <= 10

      safePush(pickRandom(allTops.filter(c => topWarmths.includes(c.warmthIndex))));

      if (needBaseLayer) { // 天冷加上打底衫
        safePush(pickRandom(allBaseLayers));
      }

      // 2.2 选下装
      let bottomWarmths: number[] = [];
      if (T >= 25) bottomWarmths = [2, 4];
      else if (T >= 15 && T < 25) bottomWarmths = [4, 6];
      else bottomWarmths = [6, 8, 10]; // T <= 15
      safePush(pickRandom(allBottoms.filter(c => bottomWarmths.includes(c.warmthIndex))));
    }

    // 3. 👟 选鞋子 (必选)
    let shoeWarmths: number[] = [];
    if (T >= 25) shoeWarmths = [2, 4, 6];
    else if (T >= 20 && T < 25) shoeWarmths = [4, 6];
    else if (T >= 15 && T < 20) shoeWarmths = [4, 6, 8];
    else shoeWarmths = [6, 8, 10]; // T <= 15

    let validShoes = clothes.filter(c => c.mainCategory === 'shoes' && shoeWarmths.includes(c.warmthIndex));
    safePush(pickRandom(validShoes));

    return result;
  }

  // ==================== 📏 步骤 2：对单套穿搭进行评分 ====================

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
}