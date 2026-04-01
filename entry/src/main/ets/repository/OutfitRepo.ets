import { relationalStore } from "@kit.ArkData";
import { RdbManager } from "../database/RdbManager";

interface ImpactedOutfit {
  id: string;
  clothingIds: string;
}

export class OutfitRepo {
  private rdbStore: relationalStore.RdbStore;

  constructor() {
    this.rdbStore = RdbManager.getInstance().getStore();
  }

  public async insert(valueBucket: relationalStore.ValuesBucket): Promise<boolean> {
    try {
      // 这里的 'OutfitCombination' 必须和你建表时的名字一模一样
      const rowId = await this.rdbStore.insert('OutfitCombination', valueBucket);
      return rowId > 0;
    } catch (err) {
      console.error('OutfitRepo', '数据库插入出错: ' + JSON.stringify(err));
      return false;
    }
  }

  // 纯粹的删除组合
  public async deleteOutfit(outfitId: string): Promise<number> {
    let predicates = new relationalStore.RdbPredicates('OutfitCombination');
    predicates.equalTo('id', outfitId);
    return await this.rdbStore.delete(predicates);
  }

  // 【关键查询】：找出所有包含了某件衣服的组合
  public async getOutfitsContainingClothing(clothingId: string): Promise<ImpactedOutfit[]> {
    let predicates = new relationalStore.RdbPredicates('OutfitCombination');
    predicates.like('clothingIds', `%${clothingId}%`);

    let resultSet = await this.rdbStore.query(predicates, ['id', 'clothingIds']);

    // 🌟 明确声明数组类型
    let outfits: ImpactedOutfit[] = [];

    while (resultSet.goToNextRow()) {
      outfits.push({
        id: resultSet.getString(resultSet.getColumnIndex('id')),
        clothingIds: resultSet.getString(resultSet.getColumnIndex('clothingIds'))
      });
    }
    resultSet.close();
    return outfits;
  }

  /**
   * 🌟 获取所有收藏的搭配记录
   */
  public async getFavoriteRecords(): Promise<relationalStore.ResultSet> {
    let predicates = new relationalStore.RdbPredicates('OutfitCombination');
    predicates.greaterThan('favoriteTime', 0); // 只要收藏时间大于0，就说明是收藏的
    predicates.orderByDesc('favoriteTime');    // 按收藏时间倒序，最新的在前面

    return await this.rdbStore.query(predicates);
  }
}