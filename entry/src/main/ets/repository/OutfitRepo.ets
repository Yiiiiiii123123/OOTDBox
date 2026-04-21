import { relationalStore } from "@kit.ArkData";
import { RdbManager } from "../database/RdbManager";
import { Outfit } from "../model/Outfit";

export class OutfitRepo {
  private get rdbStore(): relationalStore.RdbStore {
    return RdbManager.getInstance().getStore();
  }

  /**
   * 插入
   */
  public async insert(item: Outfit): Promise<boolean> {
    try {
      const valueBucket: relationalStore.ValuesBucket = {
        'id': item.id,
        'clothingIds': item.clothingIds.join(','), // 存入数据库前转为逗号字符串
        'recommendCount': item.recommendCount,
        'acceptCount': item.acceptCount,
        'averageTemp': item.averageTemp,
        'lastWornDate': item.lastWornDate,
        'favoriteTime': item.favoriteTime
      };
      const rowId = await this.rdbStore.insert('Outfit', valueBucket);
      return rowId > 0;
    } catch (err) {
      console.error('OutfitRepo', '数据库插入出错: ' + JSON.stringify(err));
      return false;
    }
  }

  /**
   * 删
   */
  public async deleteOutfit(outfitId: string): Promise<number> {
    let predicates = new relationalStore.RdbPredicates('Outfit');
    predicates.equalTo('id', outfitId);
    return await this.rdbStore.delete(predicates);
  }

  /**
   * 【关键查询】：找出所有包含了某件衣服的组合
   */
  public async getOutfitsContainingClothing(clothingId: string): Promise<Outfit[]> {
    let predicates = new relationalStore.RdbPredicates('Outfit');
    // 核心逻辑：在 clothingIds 字符串字段中模糊匹配包含该单品 ID 的记录
    predicates.like('clothingIds', `%${clothingId}%`);

    // 注意：这里不要限制列，查询所有字段以便还原完整对象
    let resultSet = await this.rdbStore.query(predicates);
    let outfits: Outfit[] = [];

    // 1. 提前锁定列索引，提升读取性能
    const colId = resultSet.getColumnIndex('id');
    const colIdsStr = resultSet.getColumnIndex('clothingIds');
    const colAvgTemp = resultSet.getColumnIndex('averageTemp');
    const colRecCount = resultSet.getColumnIndex('recommendCount');
    const colAccCount = resultSet.getColumnIndex('acceptCount');
    const colLastWorn = resultSet.getColumnIndex('lastWornDate');
    const colFavTime = resultSet.getColumnIndex('favoriteTime');

    // 2. 遍历结果集
    while (resultSet.goToNextRow()) {
      const id = resultSet.getString(colId);
      const idsStr = resultSet.getString(colIdsStr);
      const avgTemp = resultSet.getDouble(colAvgTemp);

      // 实例化 Outfit 对象
      // 注意：构造函数需要数组，所以要用 split(',') 切割
      const outfit = new Outfit(idsStr.split(','), avgTemp, id);

      // 还原统计数据和状态
      outfit.recommendCount = resultSet.getLong(colRecCount);
      outfit.acceptCount = resultSet.getLong(colAccCount);
      outfit.lastWornDate = resultSet.getLong(colLastWorn);
      outfit.favoriteTime = resultSet.getLong(colFavTime);

      outfits.push(outfit);
    }

    // 3. 释放资源
    resultSet.close();
    return outfits;
  }

  /**
   * 获取所有收藏的搭配记录
   */
  public async getFavoriteOutfits(): Promise<Outfit[]> {
    let predicates = new relationalStore.RdbPredicates('Outfit'); // 🌟 修复表名
    predicates.greaterThan('favoriteTime', 0);
    predicates.orderByDesc('favoriteTime');

    let resultSet = await this.rdbStore.query(predicates);
    let results: Outfit[] = [];

    while (resultSet.goToNextRow()) {
      const idsStr = resultSet.getString(resultSet.getColumnIndex('clothingIds'));
      const initialTemp = resultSet.getDouble(resultSet.getColumnIndex('averageTemp'));
      const id = resultSet.getString(resultSet.getColumnIndex('id'));

      const item = new Outfit(idsStr.split(','), initialTemp, id);
      item.recommendCount = resultSet.getLong(resultSet.getColumnIndex('recommendCount'));
      item.acceptCount = resultSet.getLong(resultSet.getColumnIndex('acceptCount'));
      item.lastWornDate = resultSet.getLong(resultSet.getColumnIndex('lastWornDate'));
      item.favoriteTime = resultSet.getLong(resultSet.getColumnIndex('favoriteTime'));

      results.push(item);
    }
    resultSet.close(); // 在这里统一关闭，调用者再也不用担心忘记关闭游标了
    return results;
  }

  /**
   * 根据 ID 精准获取单条组合
   * 场景：用于检查某套穿搭是否已经在数据库中存在
   */
  public async getById(id: string): Promise<Outfit | null> {
    let predicates = new relationalStore.RdbPredicates('Outfit');
    // 锁定准星：只找 ID 匹配的那一行
    predicates.equalTo('id', id);

    let resultSet: relationalStore.ResultSet | null = null;

    try {
      resultSet = await this.rdbStore.query(predicates);

      // 检查是否真的查到了数据，并且将游标移动到第一行
      if (resultSet.rowCount > 0 && resultSet.goToFirstRow()) {
        // --- 开始解析数据 ---
        const idsStr = resultSet.getString(resultSet.getColumnIndex('clothingIds'));
        const averageTemp = resultSet.getDouble(resultSet.getColumnIndex('averageTemp'));

        // 实例化 Outfit 对象 (🌟 注意要把字符串切割回数组)
        const outfit = new Outfit(idsStr.split(','), averageTemp, id);

        // 还原统计与状态字段
        outfit.recommendCount = resultSet.getLong(resultSet.getColumnIndex('recommendCount'));
        outfit.acceptCount = resultSet.getLong(resultSet.getColumnIndex('acceptCount'));
        outfit.lastWornDate = resultSet.getLong(resultSet.getColumnIndex('lastWornDate'));
        outfit.favoriteTime = resultSet.getLong(resultSet.getColumnIndex('favoriteTime'));

        return outfit;
      }
      // 没查到就返回 null
      return null;
    } catch (error) {
      console.error('OutfitRepo', '根据ID获取组合失败: ' + JSON.stringify(error));
      return null;
    } finally {
      // 🌟 终极安全措施：无论查询是否报错，都要在 finally 里把游标关掉，防止内存泄漏！
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  /**
   * 更新已存在的组合
   * 场景：更新收藏时间、增加穿戴次数、更新保暖评分等
   */
  public async update(item: Outfit): Promise<number> {
    try {
      // 1. 把对象的最新状态装进“数据桶”里
      const valueBucket: relationalStore.ValuesBucket = {
        // 注意：ID 通常是不可变的，所以不需要放进桶里更新
        'clothingIds': item.clothingIds.join(','), // 存入时把数组变回字符串
        'averageTemp': item.averageTemp,
        'recommendCount': item.recommendCount,
        'acceptCount': item.acceptCount,
        'lastWornDate': item.lastWornDate,
        'favoriteTime': item.favoriteTime
      };

      // 2. 瞄准目标：告诉数据库要改哪一行
      let predicates = new relationalStore.RdbPredicates('Outfit');
      predicates.equalTo('id', item.id);

      // 3. 执行更新，返回受影响的行数（正常情况下应该是 1）
      const affectedRows = await this.rdbStore.update(valueBucket, predicates);
      return affectedRows;
    } catch (error) {
      console.error('OutfitRepo', '更新组合失败: ' + JSON.stringify(error));
      return 0; // 如果出错，返回 0 行被更新
    }
  }
}