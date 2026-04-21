import relationalStore from '@ohos.data.relationalStore';
import { RdbManager } from '../database/RdbManager';
import { Clothing } from '../model/Clothing';
import { ClothingRepo} from '../repository/ClothingRepo';
import { OutfitRepo } from '../repository/OutfitRepo';
import { util } from '@kit.ArkTS';
import { Outfit } from '../model/Outfit';

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
   * 衣物更新
   */
  public async updateClothing(item: Clothing): Promise<boolean> {
    const affectedRows = await this.clothingRepo.update(item);
    return affectedRows > 0;
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
   * 获取收藏穿搭
   */
  public async getFavoriteOutfits(): Promise<OutfitViewData[]> {
    try {
      // 1. 从 Repo 拿到原始模型列表
      const baseOutfits = await this.outfitRepo.getFavoriteOutfits();
      if (!baseOutfits.length) return [];

      // 2. 准备装盒子
      const viewDataList: OutfitViewData[] = [];

      // 3. 并行处理每一套穿搭
      await Promise.all(baseOutfits.map(async (outfit) => {
        // 抓取衣服实物
        const fetchTasks = outfit.clothingIds.map(id => this.clothingRepo.getById(id));
        const clothingResults = await Promise.all(fetchTasks);
        const validClothes = clothingResults.filter(item => item !== null) as Clothing[];

        // 关键：不改 outfit 模型，而是创建包装盒
        viewDataList.push(new OutfitViewData(outfit, validClothes));
      }));

      return viewDataList;
    } catch (error) {
      console.error('ClothingService', '获取失败: ' + JSON.stringify(error));
      return [];
    }
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
  public async confirmDailyOutfit(items: Clothing[]): Promise<void> {
    const now = new Date().getTime();
    for (let item of items) {
      item.wearCount += 1;
      item.lastWornDate = now;
      await this.clothingRepo.update(item);
    }
  }

  /**
   * 业务逻辑：智能保存/更新收藏组合
   */
  public async saveToFavorite(items: Clothing[], temp: number): Promise<boolean> {
    try {
      if (!items || items.length === 0) return false;
      // 1. 利用指纹算法生成这套衣服的唯一 ID
      const clothingIds = items.map(c => c.id);
      const outfitId = Outfit.generateFingerprint(clothingIds);

      // 2. 去数据库里查一下，这套组合以前出现过吗
      let existingOutfit = await this.outfitRepo.getById(outfitId);

      if (existingOutfit) {
        // --- 情况 A：组合已存在 ---
        // 我们只需要把它的收藏时间更新一下即可，保留原有的穿戴次数等数据
        existingOutfit.favoriteTime = new Date().getTime();

        // 调用 update 而不是 insert
        const affectedRows = await this.outfitRepo.update(existingOutfit);
        return affectedRows > 0;
      } else {
        // --- 情况 B：全新组合 ---
        const newOutfit = new Outfit(clothingIds, temp, outfitId);
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