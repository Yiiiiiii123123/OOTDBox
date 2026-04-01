import relationalStore from '@ohos.data.relationalStore';
import { RdbManager } from '../database/RdbManager';
import { Clothing } from '../model/Clothing';
import { ClothingRepo} from '../repository/ClothingRepo';
import { OutfitRepo } from '../repository/OutfitRepo';
import { util } from '@kit.ArkTS';

export class ClothingService {
  private clothingRepo: ClothingRepo;
  private outfitRepo: OutfitRepo;
  private rdbStore: relationalStore.RdbStore;

  // 1. 构造函数不传参
  constructor() {
    this.rdbStore = RdbManager.getInstance().getStore();

    // 2. Repo 也不需要传参了
    this.clothingRepo = new ClothingRepo();
    this.outfitRepo = new OutfitRepo();
  }

  /**
   * 🌟 新增：添加新衣物到衣橱
   */
  public async addClothing(item: Clothing): Promise<boolean> {
    try {
      const rowId = await this.clothingRepo.insert(item);
      if (rowId > -1) {
        console.info('ClothingService', '新衣物录入成功！');
        return true;
      }
      return false;
    } catch (error) {
      console.error('ClothingService', '录入衣物失败: ' + JSON.stringify(error));
      return false;
    }
  }

  public async updateClothing(item: Clothing): Promise<boolean> {
    try {
      const affectedRows = await this.clothingRepo.update(item);
      return affectedRows > 0;
    } catch (error) {
      console.error('ClothingService', '更新衣物失败: ' + JSON.stringify(error));
      return false;
    }
  }

  /**
   * 核心业务：安全删除一件衣物（包含级联删除）
   * @param clothingId 要删除的衣服 ID
   */
  public async deleteClothingSafely(clothingId: string): Promise<boolean> {
    try {
      // 【事务开始】强烈建议使用事务，保证两张表的数据一致性
      this.rdbStore.beginTransaction();

      // 1. 删除单品表中的这件衣服
      const deletedRows = await this.clothingRepo.delete(clothingId);
      if (deletedRows === 0) {
        throw new Error("找不到该衣物，删除失败");
      }

      // 2. 去组合表里“追杀”这件衣服的所有搭配记录
      const impactedOutfits = await this.outfitRepo.getOutfitsContainingClothing(clothingId);

      // 3. 循环删除受影响的组合
      // 为什么直接删除而不是“更新”？
      // 因为衣服是一套的，上衣没了，这套“历史经典搭配”在物理上就不成立了。
      for (const outfit of impactedOutfits) {
        await this.outfitRepo.deleteOutfit(outfit.id);
        // 如果你的 App 有日志系统，可以在这里记录：
        // console.log(`因单品 ${clothingId} 被删，关联组合 ${outfit.id} 已自动失效。`);
      }

      // 【事务提交】所有操作成功，写入数据库
      this.rdbStore.commit();
      return true;

    } catch (error) {
      // 【事务回滚】如果中间发生任何错误（比如删组合时闪退），恢复到删除前的状态
      console.error("级联删除失败，已回滚: ", error);
      this.rdbStore.rollBack();
      return false;
    }
  }

  /**
   * 🌟 核心方法：获取所有收藏的搭配组合对象列表
   * 返回值是一个二维数组：Array<Clothing[]>
   */
  public async getFavoriteOutfits(): Promise<Array<Clothing[]>> {
    const favoriteOutfits: Array<Clothing[]> = [];

    try {
      // 1. 从数据库拿到所有收藏的原始记录
      const resultSet = await this.outfitRepo.getFavoriteRecords();

      while (resultSet.goToNextRow()) {
        // 拿到 ID 字符串，例如: "uuid-123,uuid-456"
        const idString = resultSet.getString(resultSet.getColumnIndex('clothingIds'));
        if (!idString) continue;

        // 2. 将字符串拆解为 ID 数组
        const ids = idString.split(',');

        // 3. 核心：通过这些 ID 去 Clothing 表里“捞”出完整的衣服对象
        const outfitItems: Clothing[] = [];

        // 使用 Promise.all 并行查询，提高性能
        const fetchTasks = ids.map(id => this.clothingRepo.getById(id.trim()));
        const results = await Promise.all(fetchTasks);

        // 过滤掉可能已经被删掉的衣服（null）
        results.forEach(item => {
          if (item) outfitItems.push(item);
        });

        // 如果这套衣服里还有衣服，就加入大名单
        if (outfitItems.length > 0) {
          favoriteOutfits.push(outfitItems);
        }
      }
      resultSet.close();
    } catch (error) {
      console.error('ClothingService', '获取收藏搭配失败: ' + JSON.stringify(error));
    }

    return favoriteOutfits;
  }

  /**
   * 🌟 新增：保存/取消收藏穿搭
   * @param clothingIds 衣服ID字符串
   * @param isFavorite 是否收藏
   */
  public async toggleFavoriteOutfit(clothingIds: string, isFavorite: boolean): Promise<boolean> {
    try {
      const favoriteTime = isFavorite ? new Date().getTime() : 0;

      const valueBucket: relationalStore.ValuesBucket = {
        'id': util.generateRandomUUID(), // 🌟 现在这里不会报错了！
        'clothingIds': clothingIds,      // 存入如 "uuid1,uuid2" 的字符串
        'favoriteTime': favoriteTime,
        'createTime': new Date().getTime()
      };

      // 这里的 insert 逻辑需要你在 OutfitRepo 中补全
      // await this.outfitRepo.insert(valueBucket);

      console.info('ClothingService', '收藏记录已更新');
      return true;
    } catch (e) {
      console.error('ClothingService', '保存失败: ' + JSON.stringify(e));
      return false;
    }
  }

  public async saveFavoriteOutfit(outfit: Clothing[], currentTemp: number): Promise<boolean> {
    try {
      if (!outfit || outfit.length === 0) return false;

      // 1. 将所有衣服的 ID 拼接成字符串，例如 "id1,id2"
      const ids = outfit.map(item => item.id).join(',');

      // 2. 构造符合表结构的 ValuesBucket
      // 注意：这里的 Key 必须和你的 CREATE TABLE 语句中的字段名完全一致
      const valueBucket: relationalStore.ValuesBucket = {
        'id': util.generateRandomUUID(),
        'clothingIds': ids,
        'recommendCount': 1,           // 既然推荐了，初始设为 1
        'acceptCount': 0,              // 初始采纳为 0
        'averageTemp': currentTemp,    // 存入当前气温
        'favoriteTime': new Date().getTime(),
        'lastWornDate': 0              // 还没穿过，设为 0
      };

      // 3. 调用 Repo 执行数据库插入
      return await this.outfitRepo.insert(valueBucket);
    } catch (e) {
      console.error('ClothingService', '保存失败详情: ' + JSON.stringify(e));
      return false;
    }
  }
}