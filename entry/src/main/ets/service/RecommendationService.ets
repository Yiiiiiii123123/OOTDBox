import { Clothing } from '../model/Clothing';
import { Outfit } from '../model/Outfit'; // 引入你的原生模型
import { ClothingRepo } from '../repository/ClothingRepo';
import { ColorMatchUtil } from '../utils/ColorMatchUtil';
import { util } from '@kit.ArkTS';
import { OutfitRepo } from '../repository/OutfitRepo';
import { TemperatureRuleUtils } from '../utils/TemperatureRuleUtils';

// 内部临时接口，用于在计算过程中绑定衣服和分数
interface CandidateOutfit {
  items: Clothing[];
  score: number;
}

export class RecommendationResult {
  combination: Outfit;
  clothes: Clothing[];

  constructor(combination: Outfit, clothes: Clothing[]) {
    this.combination = combination;
    this.clothes = clothes;
  }
}

export class RecommendationService {
  private repo = new ClothingRepo();
  private outfitRepo = new OutfitRepo();

  /**
   * 顶层调用：生成并推荐最佳穿搭
   * 返回一个对象，包含组合模型（存库用）和实际衣服数组（UI展示用）
   */
  public async getBestRecommendation(temperature: number): Promise<RecommendationResult | null> {
    const allClothes = await this.repo.getAll();
    if (!allClothes || allClothes.length === 0) return null;

    let bestCandidate: CandidateOutfit | null = null;
    let highestScore = -1;

    // 🌟 先生成 10 套候选方案并打分
    for (let i = 0; i < 10; i++) {
      let candidateItems = this.generateCombination(allClothes, temperature);
      let score = 100 * await this.calculateScore(candidateItems, temperature); // 注意这里应该是 temperature，不是写死的 26

      // 只有分数 > 0（没被专家规则击毙的），才有资格竞选
      if (score > 0 && score > highestScore) {
        highestScore = score;
        bestCandidate = { items: candidateItems, score: score };
      }
    }

    if (!bestCandidate) return null;

    // 🌟 将胜出的衣服数组，转换为你原有的 OutfitCombination 模型
    let clothingIds = bestCandidate.items.map(c => c.id);
    let fingerprint = Outfit.generateFingerprint(clothingIds);

    // 查一下账本，这套衣服以前推过没有？
    let existingOutfit = await this.outfitRepo.getById(fingerprint);
    let winningCombination: Outfit;

    if (existingOutfit) {
      // 场景 A：老熟人
      existingOutfit.recommendCount += 1; // 🌟 推荐次数真实 +1！
      await this.outfitRepo.update(existingOutfit); // 更新账本
      winningCombination = existingOutfit;
    } else {
      // 场景 B：第一次被算法临幸的新面孔
      winningCombination = new Outfit(clothingIds, [], temperature, fingerprint);
      winningCombination.recommendCount = 1; // 🌟 诞生即获得 1 次推荐
      winningCombination.acceptCount = 0;    // 还没被打卡，接受次数必须是 0
      await this.outfitRepo.insert(winningCombination); // 录入新账
    }

    return new RecommendationResult(winningCombination, bestCandidate.items);// 顺便返回实体数组，方便 UI 页面直接渲染图片

  }

  // ==================== 🛠️ 步骤 1：按规则随机生成搭配 ====================

  private generateCombination(clothes: Clothing[], T: number): Clothing[] {
    let result: Clothing[] = [];

    const pickRandom = (items: Clothing[]) => items.length > 0 ? items[Math.floor(Math.random() * items.length)] : null;
    const safePush = (item: Clothing | null) => { if (item) result.push(item); };

    // 1. 🧥 选外套
    if (T >= 25) {
      if (Math.random() > 0.7) {
        let sunCoats = clothes.filter(c => c.mainCategory === 'outerwear' && c.subCategory === 'sun_protective');
        safePush(pickRandom(sunCoats));
      }
    } else {
      // 🌟 一行代码搞定！
      let validOuter = clothes.filter(c => c.mainCategory === 'outerwear' && TemperatureRuleUtils.getOuterWarmths(T).includes(c.warmthIndex));
      safePush(pickRandom(validOuter));
    }

    // 2. 👗 核心部分：选主体
    let allBottoms = clothes.filter(c => c.mainCategory === 'bottom');
    let allOnePieces = clothes.filter(c => c.mainCategory === 'one_piece');
    let allTops = clothes.filter(c => c.mainCategory === 'top' && c.subCategory !== 'base_shirt'); // 听你的，排除内耗
    let allBaseLayers = clothes.filter(c => c.mainCategory === 'top' && c.subCategory === 'base_shirt');

    // 听你的！完美的连体衣概率计算！
    let totalMain = allBottoms.length + allOnePieces.length;
    let onePieceProb = totalMain > 0 ? (allOnePieces.length / totalMain) : 0;

    if (Math.random() < onePieceProb) {
      // 🌟 走【连体衣】路线 (极度清爽)
      safePush(pickRandom(allOnePieces.filter(c => TemperatureRuleUtils.getOnePieceWarmths(T).includes(c.warmthIndex))));
    } else {
      // 🌟 走【上下装】路线
      let topWarmths = TemperatureRuleUtils.getTopWarmths(T);
      safePush(pickRandom(allTops.filter(c => topWarmths.includes(c.warmthIndex))));

      // 🌟 语义化极强：如果当前温度需要打底衫，就加一件！
      if (TemperatureRuleUtils.isBaseLayerNeeded(T)) {
        safePush(pickRandom(allBaseLayers));
      }

      safePush(pickRandom(allBottoms.filter(c => TemperatureRuleUtils.getBottomWarmths(T).includes(c.warmthIndex))));
    }

    // 3. 👟 选鞋子
    let validShoes = clothes.filter(c => c.mainCategory === 'shoes' && TemperatureRuleUtils.getShoeWarmths(T).includes(c.warmthIndex));
    safePush(pickRandom(validShoes));

    // 🌟 兜底：防止裸奔 (刚才咱们讨论过的防暴毙策略)
    const hasShoes = result.some(c => c.mainCategory === 'shoes');
    const hasOnePiece = result.some(c => c.mainCategory === 'one_piece');
    const hasTopAndBottom = result.some(c => c.mainCategory === 'top') && result.some(c => c.mainCategory === 'bottom');

    if (!hasShoes || (!hasOnePiece && !hasTopAndBottom)) return [];

    return result;
  }

  // ==================== 📏 步骤 2：对单套穿搭进行评分 ====================

  /**
   * 🌟 终极 MCDA 多准则决策打分引擎
   * @param items 当前生成的这一套候选穿搭单品
   * @param currentTemp 今日气温
   * @param maxWearWardrobe 用户衣橱里穿过最多次的衣服次数（用于归一化，默认设为 30）
   * @returns 综合得分 (0 ~ 1.0)
   */
  private async calculateScore(items: Clothing[], currentTemp: number, maxWearWardrobe: number = 30): Promise<number> {

    if (!this.passExpertRules(items, currentTemp)) {
      return -1; // 🌟 触发灾难规则，直接给负分，让它绝对选不上！
    }

    const now = new Date().getTime();

    // ==========================================
    // 准备工作：获取或估算 Outfit 组合数据
    // ==========================================
    const ids = items.map(i => i.id);
    const fingerprint = Outfit.generateFingerprint(ids);//穿搭指纹——根据排列出来的ids组成的穿搭id
    // 从数据库查询这套组合的历史记录
    const outfitRecord: Outfit | null = await this.outfitRepo.getById(fingerprint);

    // ==========================================
    // 维度 1：偏好指数 (S_pref) - 贝叶斯平滑
    // ==========================================
    let s_pref = 0.2; // 如果是全新的搭配，给一个 20% 的基础探索分
    if (outfitRecord) {
      const alpha = 1.0; // 虚拟接受次数
      const beta = 4.0;  // 虚拟拒绝次数
      s_pref = (outfitRecord.acceptCount + alpha) / (outfitRecord.recommendCount + alpha + beta);

      // 收藏特权加分
      if (outfitRecord.favoriteTime > 0) {
        s_pref = Math.min(1.0, s_pref + 0.2); // 最高不超过 1.0
      }
    }

    // ==========================================
    // 维度 2：气温拟合度 (S_temp) - 算法自进化反馈
    // ==========================================
    let s_temp = 0.8; // 新搭配默认 0.8，鼓励探索

    if (outfitRecord && outfitRecord.acceptCount > 0) {
      // 只有真正被用户穿过（打卡过）的衣服，才拥有真实的平均温度记忆
      const deltaT = Math.abs(outfitRecord.averageTemp - currentTemp);

      const comfortZone = 2.0; // 🌟 绝对舒适区：上下 2 度以内，人体感觉不明显，给满分！
      const maxDelta = 8.0;    // 🌟 极限容忍度：偏离记忆温度 8 度以上，绝不推荐，给 0 分

      if (deltaT <= comfortZone) {
        s_temp = 1.0; // 完美契合
      } else {
        // 超过舒适区后，开始极其丝滑的线性扣分
        s_temp = Math.max(0, 1.0 - ((deltaT - comfortZone) / (maxDelta - comfortZone)));
      }
    }

    // ==========================================
    // 维度 3：新鲜度指数 (S_fresh) - 防连穿机制
    // ==========================================
    let maxLastWorn = 0; // 找出这套衣服里“最近”穿过的那件的时间戳
    let totalWearCount = 0; // 顺便统计总穿戴次数供后续使用

    for (const item of items) {
      if (item.lastWornDate > maxLastWorn) {
        maxLastWorn = item.lastWornDate;
      }
      totalWearCount += (item.wearCount || 0);
    }

    let s_fresh = 1.0; // 默认满分（都没穿过）
    if (maxLastWorn > 0) {
      // 换算成距离今天的天数
      const daysSinceWorn = Math.max(0, (now - maxLastWorn) / (1000 * 3600 * 24));//防止测试时出现未来衣物数据导致出错
      const lambdaFresh = 0.5; // 衰减系数，大概 3 天能恢复到 80% 新鲜度
      s_fresh = 1.0 - Math.exp(-lambdaFresh * daysSinceWorn);
    }

    // ==========================================
    // 维度 4：单品探索与利用 (S_item) - U型曲线破解吃灰
    // ==========================================
    const avgWear = totalWearCount / items.length;
    // 力量 A：利用 (喜爱度)
    const exploitScore = Math.min(1.0, avgWear / maxWearWardrobe);
    // 力量 B：探索 (扶贫吃灰衣服)
    const lambdaExplore = 0.5;
    const exploreScore = Math.exp(-lambdaExplore * avgWear);

    // 取两者最大值，形成完美的 U 型打分！
    const s_item = Math.max(exploitScore, exploreScore);

    // ==========================================
    // 维度 5：美学与规则协同 (S_aesthetic)
    // ==========================================
    const s_aesthetic = this.calculateAestheticScore(items);

    // ==========================================
    // 终极 MCDA 加权聚合
    // ==========================================
    const W_pref = 0.25;
    const W_fresh = 0.20;
    const W_temp = 0.25;
    const W_aesthetic = 0.15;
    const W_item = 0.15;

    const finalScore =
      (W_pref * s_pref) +
        (W_fresh * s_fresh) +
        (W_temp * s_temp) +
        (W_aesthetic * s_aesthetic) +
        (W_item * s_item);

    return finalScore;
  }

  /**
   * 🎨 美学启发式打分器
   */
  private calculateAestheticScore(items: Clothing[]): number {
    if (items.length === 0) return 0;

    let score = 0.7; // 设定一个合理的及格基础分

    // 1. 提取全量颜色数组
    let allColors = items.map(c => c.color.toString());

    // 2. 过滤出所有的“有彩色” (剔除掉黑白灰等基础安全色)
    let vividColors = allColors.filter(color => !ColorMatchUtil.NEUTRAL_COLORS.includes(color));
    // 去重，只看颜色的种类数量
    let uniqueVividColors = Array.from(new Set(vividColors));

    // 3. 核心规则 A：有彩色数量控制
    if (uniqueVividColors.length < 3) {
      score += 0.15; // 对应旧版的 +10 分（克制且高级）
    } else if (uniqueVividColors.length > 3) {
      score -= 0.45; // 对应旧版的 -30 分（打翻调色盘，重罚！）
    }
    // 等于 3 种时，不多不少，不加不扣

    // 4. 核心规则 B：相配色检查
    // 只要系统判定这套颜色的组合是和谐的，额外给奖励分
    if (ColorMatchUtil.hasMatchingColors(allColors)) {
      score += 0.15; // 对应旧版的 +10 分
    }

    // 5. 终极防线：将分数死死限制在 0.0 ~ 1.0 之间
    return Math.max(0, Math.min(1.0, score));
  }

  /**
   * 🚨 专家规则检查器 (安检门)
   * 返回 true 表示通过，返回 false 表示是灾难穿搭（直接击毙）
   */
  private passExpertRules(items: Clothing[], T: number): boolean {
    const outerwear = items.find(c => c.mainCategory === 'outerwear');
    const top = items.find(c => c.mainCategory === 'top' && c.subCategory !== 'base_shirt');
    const baseLayer = items.find(c => c.mainCategory === 'top' && c.subCategory === 'base_shirt');

    // 如果没有外套，就不存在外套相关的冲突，直接放行
    if (!outerwear) return true;

    // 获取上装（普通上装或打底衫都算里面的衣服）
    const innerTop = top || baseLayer;

    // 🔴 灾难 1：低温天乱穿防晒衣
    // (虽然生成时尽量避免了，但防止漏网之鱼，这里直接锁死)
    if (T < 20 && outerwear.subCategory === 'sun_protective') {
      return false; // 低于20度绝对不推防晒衣！
    }

    // 🔴 灾难 2：长袖外面套防晒衣 (臃肿且没必要)
    if (outerwear.subCategory === 'sun_protective' && innerTop) {
      // 假设我们认为卫衣(hoodie)、毛衣(sweater)和打底衫(base_shirt)都是长袖
      const longSleeveTypes = ['hoodie', 'sweater', 'base_shirt'];
      // 或者你的模型里如果有 sleeveLength 字段就更好了：innerTop.sleeveLength === 'long'
      if (longSleeveTypes.includes(innerTop.subCategory)) {
        return false;
      }
    }

    // 🔴 灾难 3：厚马甲配短袖 (冰火两重天)
    if (outerwear.subCategory === 'vest') {
      // 假设保暖指数 >= 6 的马甲是“棉马甲”，<= 4 的是“轻薄马甲”
      const isThickVest = outerwear.warmthIndex >= 6;

      if (isThickVest && innerTop) {
        // 假设保暖指数 <= 4 的上衣是短袖（或 subCategory === 't_shirt'）
        const isShortSleeve = innerTop.warmthIndex <= 4 || innerTop.subCategory === 't_shirt';

        if (isShortSleeve) {
          return false; // 棉马甲配短袖，毙掉！
        }
      }
    }

    // 通过所有安检
    return true;
  }

}