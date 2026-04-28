import relationalStore from '@ohos.data.relationalStore';
import { RdbManager } from '../database/RdbManager';
import { Clothing } from '../model/Clothing';
import { ClothingRepo} from '../repository/ClothingRepo';
import { OutfitRepo } from '../repository/OutfitRepo';
import { util } from '@kit.ArkTS';
import { Outfit } from '../model/Outfit';
import { common } from '@kit.AbilityKit';
import { PreferenceRepo } from '../repository/PreferenceRepo';

//穿搭和衣物服务层

export class OutfitViewData {
  outfit: Outfit;          // 原始的数据库模型（包含 ID, 分数, 时间等）
  clothes: Clothing[];     // 抓取出来的衣服实物对象

  constructor(outfit: Outfit, clothes: Clothing[]) {
    this.outfit = outfit;
    this.clothes = clothes;
  }
}

export class ClothingService {
  private clothingRepo: ClothingRepo;
  private outfitRepo: OutfitRepo;

  // 使用 Getter 避免构造函数时的数据库未初始化报错
  private get rdbStore(): relationalStore.RdbStore {
    return RdbManager.getInstance().getStore();
  }

  constructor() {
    this.clothingRepo = new ClothingRepo();
    this.outfitRepo = new OutfitRepo();
  }

  /**
   * 添加新衣物到衣橱
   */
  public async addClothing(item: Clothing): Promise<boolean> {
    const rowId = await this.clothingRepo.insert(item);
    return rowId > -1;
  }

  /**
   * 清空全部（包含衣物和穿搭
   */
  public async deleteAllClothes(): Promise<boolean> {
    try {
      // 1. 清空所有衣服单品
      let clothesCleared = await this.clothingRepo.deleteAll();

      // 2. 级联清空所有收藏的穿搭
      // (假设你在 Service 里已经引入了 outfitRepo)
      let outfitsCleared = await this.outfitRepo.deleteAll();

      // 只有两个表都清空成功，才算真正的彻底重置
      return clothesCleared && outfitsCleared;
    } catch (error) {
      console.error('ClothingService', '级联清空失败: ' + JSON.stringify(error));
      return false;
    }
  }

  /**
   * 重置所有穿着记录
   */
  public async resetAllWearHistory(): Promise<number> {
    let clothes = await this.clothingRepo.getAll();
    if (!clothes) return 0;

    let updateCount = 0;
    for (let item of clothes) {
      if (item.wearCount > 0 || item.lastWornDate > 0) {
        item.wearCount = 0;
        item.lastWornDate = 0;
        await this.clothingRepo.update(item);
        updateCount++;
      }
    }
    return updateCount;
  }

  /**
   * 衣物更新
   */
  public async updateClothing(item: Clothing): Promise<boolean> {
    const affectedRows = await this.clothingRepo.update(item);
    return affectedRows > 0;
  }

  /**
   * 获取所有衣物
   */
  public async getAllClothes(): Promise<Clothing[]> {
    return await this.clothingRepo.getAll();
  }

  /**
   * 根据id找衣物
   */
  public async getClothingById(id: string): Promise<Clothing | null> {
    return await this.clothingRepo.getById(id);
  }

  /**
   * 核心业务：安全删除一件衣物（包含级联删除）
   */
  public async deleteClothingSafely(clothingId: string): Promise<boolean> {
    try {
      this.rdbStore.beginTransaction();
      const deletedRows = await this.clothingRepo.delete(clothingId);
      if (deletedRows === 0) throw new Error("找不到该衣物");
      //删除包含此衣物的Outfit
      const impactedOutfits = await this.outfitRepo.getOutfitsContainingClothing(clothingId);
      for (const outfit of impactedOutfits) {
        await this.outfitRepo.deleteOutfit(outfit.id);
      }
      this.rdbStore.commit();
      return true;
    } catch (error) {
      console.error("级联删除失败: ", error);
      this.rdbStore.rollBack();
      return false;
    }
  }

  /**
   * 业务逻辑：获取所有饰品及其对应的二级分类
   */
  async getAccessories(): Promise<Clothing[]> {
    const allClothes = await this.clothingRepo.getAll();
    return allClothes.filter(c => c.mainCategory === 'accessory');
  }

  /**
   * 获取收藏穿搭dto
   */
  public async getFavoriteOutfits(): Promise<OutfitViewData[]> {
    let outfits = await this.outfitRepo.getFavoriteOutfits();
    let result: OutfitViewData[] = [];

    for (let outfit of outfits) {
      // 1. 🌟 用 Promise.all 并发查出所有基础衣物
      let baseClothesRaw = await Promise.all(outfit.clothingIds.map(id => this.clothingRepo.getById(id)));
      let baseClothes: Clothing[] = baseClothesRaw.filter(item => item !== null) as Clothing[];

      // 2. 🌟 并发查出所有配饰
      let accessories: Clothing[] = [];
      if (outfit.accessoryIds && outfit.accessoryIds.length > 0) {
        let accRaw = await Promise.all(outfit.accessoryIds.map(id => this.clothingRepo.getById(id)));
        accessories = accRaw.filter(item => item !== null) as Clothing[];
      }

      // 3. 世纪大融合
      let allItems: Clothing[] = [...baseClothes, ...accessories];

      // 4. 🌟 绝对规范的实例化：使用 new 关键字完美调用你的 constructor
      result.push(new OutfitViewData(outfit, allItems));
    }

    return result;
  }

  /**
   * 根据id移除收藏穿搭
   */
  public async deleteFavoriteOutfit(outfitId: string): Promise<boolean> {
    const deletedRows = await this.outfitRepo.deleteOutfit(outfitId);
    return deletedRows > 0;
  }

  /**
   * 业务逻辑：确认穿戴这套衣服（打卡）
   */
  public async confirmDailyOutfit(
    baseClothes: Clothing[],
    accessories: Clothing[],
    currentTemp: number,
    isSelfRecommended: boolean = false // 🌟 新增参数，默认 false 防破坏原有调用
  ): Promise<void> {
    const now = new Date().getTime();

    // 1. 单品经验值增加 (保持不变)
    const allItems = [...baseClothes, ...accessories];
    for (let item of allItems) {
      item.wearCount = (item.wearCount || 0) + 1;
      item.lastWornDate = now;
      await this.clothingRepo.update(item);
    }

    // 2. 组合数据回流
    const coreIds = baseClothes.map(item => item.id);
    const accIds = accessories.map(item => item.id);
    const outfitFingerprint = Outfit.generateFingerprint(coreIds);

    let outfitRecord = await this.outfitRepo.getById(outfitFingerprint);

    if (outfitRecord) {
      // --- 场景 A：老熟人 ---
      outfitRecord.lastWornDate = now;
      outfitRecord.averageTemp = Math.round(
        (outfitRecord.averageTemp * outfitRecord.acceptCount + currentTemp) / (outfitRecord.acceptCount + 1)
      );

      outfitRecord.acceptCount += 1;

      // 🌟 听你的！如果是用户主动去收藏页翻牌子，推荐次数也理直气壮地 +1！
      if (isSelfRecommended) {
        outfitRecord.recommendCount += 1;
      }

      // (保留之前的安全底线作为终极防御，防止别的未知异常)
      if (outfitRecord.recommendCount < outfitRecord.acceptCount) {
        outfitRecord.recommendCount = outfitRecord.acceptCount;
      }

      outfitRecord.accessoryIds = accIds;
      await this.outfitRepo.update(outfitRecord);
    } else {
      // --- 场景 B：新大陆 ---
      // (通常是用户自己乱搭的，算法没推过，所以诞生即代表用户向自己推荐了 1 次)
      let newOutfit = new Outfit(coreIds, accIds, currentTemp, outfitFingerprint);
      newOutfit.acceptCount = 1;
      newOutfit.recommendCount = isSelfRecommended ? 1 : 0;
      newOutfit.lastWornDate = now;
      await this.outfitRepo.insert(newOutfit);
    }

    // 3. 贴冰箱贴供首页展示 (保持不变)
    let context = getContext(this) as common.UIAbilityContext;
    const allIds = allItems.map(item => item.id);
    await PreferenceRepo.putTodayOutfitIds(context, allIds);
  }

  /**
   * 业务逻辑：智能保存/更新收藏组合
   */
  public async saveToFavorite(baseClothes: Clothing[], temp: number, accessories: Clothing[] = []): Promise<boolean> {
    try {
      if (!baseClothes || baseClothes.length === 0) return false;

      // 1. 分别提取核心衣物和配饰的 ID
      const coreIds = baseClothes.map(c => c.id);
      const accIds = accessories.map(c => c.id);

      // 坚守底线：指纹 ID 绝对只用基础衣物生成！
      const outfitId = Outfit.generateFingerprint(coreIds);

      // 2. 去数据库里查一下，这套核心组合以前出现过吗
      let existingOutfit = await this.outfitRepo.getById(outfitId);

      if (existingOutfit) {
        // --- 情况 A：组合已存在 ---
        // 更新收藏时间
        existingOutfit.favoriteTime = new Date().getTime();

        // 🌟 极其重要的细节：配饰保护机制
        // 如果这次收藏带了配饰（accIds 有值），我们就更新它；
        // 如果没带配饰（比如在推荐页直接点击了红心），我们要保留数据库里原有的配饰，绝不能把它清空！
        if (accIds.length > 0) {
          existingOutfit.accessoryIds = accIds;
        }

        const affectedRows = await this.outfitRepo.update(existingOutfit);
        return affectedRows > 0;
      } else {
        // --- 情况 B：全新组合 ---
        // 按照新版 Outfit 的构造函数传入：核心衣服、配饰、温度
        const newOutfit = new Outfit(coreIds, accIds, temp, outfitId);
        newOutfit.favoriteTime = new Date().getTime();

        const isSuccess = await this.outfitRepo.insert(newOutfit);
        return isSuccess;
      }
    } catch (error) {
      console.error('ClothingService', '智能保存收藏失败: ' + JSON.stringify(error));
      return false;
    }
  }
}