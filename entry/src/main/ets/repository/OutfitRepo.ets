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
        'accessoryIds': item.accessoryIds.join(','), // 🌟 修复：第一次落库时，必须把配饰也带上！
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
   * 删一条
   */
  public async deleteOutfit(outfitId: string): Promise<number> {
    let predicates = new relationalStore.RdbPredicates('Outfit');
    predicates.equalTo('id', outfitId);
    return await this.rdbStore.delete(predicates);
  }

  /**
   * 删全部
   */
  public async deleteAll(): Promise<boolean> {
    try {
      // 1. 获取数据库实例 (根据你实际的数据库获取方式调整)
      let store = this.rdbStore;

      if (!store) {
        console.error('OutfitRepo', '数据库实例未初始化');
        return false;
      }

      // 2. 创建空谓词：只指定表名，不加任何 equalTo() 限制条件
      const predicates = new relationalStore.RdbPredicates('Outfit');

      // 3. 执行删除操作
      const rowsAffected = await store.delete(predicates);

      console.info('OutfitRepo', `成功清空穿搭表，共删除了 ${rowsAffected} 条记录`);
      return true;

    } catch (error) {
      console.error('OutfitRepo', '清空穿搭表异常: ' + JSON.stringify(error));
      return false;
    }
  }

  /**
   * 【关键查询】：找出所有包含了某件单品（衣服或配饰）的组合
   */
  public async getOutfitsContainingClothing(itemId: string): Promise<Outfit[]> {
    let outfits: Outfit[] = [];

    // 1. 🌟 组合 OR 查询条件：两张“网”一起撒
    let predicates = new relationalStore.RdbPredicates('Outfit');
    predicates.beginWrap()
      .like('clothingIds', `%${itemId}%`)
      .or()
      .like('accessoryIds', `%${itemId}%`)
      .endWrap();

    let resultSet = await this.rdbStore.query(predicates);

    try {
      // 提前锁定列索引
      const colId = resultSet.getColumnIndex('id');
      const colClothingIds = resultSet.getColumnIndex('clothingIds');
      const colAccessoryIds = resultSet.getColumnIndex('accessoryIds'); // 🌟 获取配饰列
      const colAvgTemp = resultSet.getColumnIndex('averageTemp');
      const colRecCount = resultSet.getColumnIndex('recommendCount');
      const colAccCount = resultSet.getColumnIndex('acceptCount');
      const colLastWorn = resultSet.getColumnIndex('lastWornDate');
      const colFavTime = resultSet.getColumnIndex('favoriteTime');

      while (resultSet.goToNextRow()) {
        const clothingIdsStr = resultSet.getString(colClothingIds) || '';
        const accessoryIdsStr = resultSet.getString(colAccessoryIds) || ''; // 防御空值

        // 2. 🌟 内存级精确过滤（解决子串匹配的“误伤陷阱”）
        // 把字符串切成数组，进行严格的全等验证
        const clothingIdsArr = clothingIdsStr ? clothingIdsStr.split(',') : [];
        const accessoryIdsArr = accessoryIdsStr ? accessoryIdsStr.split(',') : [];

        if (!clothingIdsArr.includes(itemId) && !accessoryIdsArr.includes(itemId)) {
          continue; // 如果只是名字很像（比如 A1 匹配了 A10），直接丢弃，看下一行！
        }

        const id = resultSet.getString(colId);
        const avgTemp = resultSet.getDouble(colAvgTemp);

        // 3. 🌟 修复参数错位：完美适配最新版的 Outfit 构造函数
        const outfit = new Outfit(clothingIdsArr, accessoryIdsArr, avgTemp, id);

        outfit.recommendCount = resultSet.getLong(colRecCount);
        outfit.acceptCount = resultSet.getLong(colAccCount);
        outfit.lastWornDate = resultSet.getLong(colLastWorn);
        outfit.favoriteTime = resultSet.getLong(colFavTime);

        outfits.push(outfit);
      }
    } catch (error) {
      console.error('ClothingRepo', '按单品查询组合失败: ' + JSON.stringify(error));
    } finally {
      // 4. 🌟 终极防线：无论发生什么错误，游标必须关闭，绝不漏水！
      if (resultSet) {
        resultSet.close();
      }
    }

    return outfits;
  }

  /**
   * 获取所有收藏的搭配记录
   */
  public async getFavoriteOutfits(): Promise<Outfit[]> {
    let predicates = new relationalStore.RdbPredicates('Outfit');
    predicates.greaterThan('favoriteTime', 0);
    predicates.orderByDesc('favoriteTime');

    let resultSet = await this.rdbStore.query(predicates);
    let results: Outfit[] = [];

    try {
      // 1. 提前锁定所有列索引，包括新增的配饰列
      const colId = resultSet.getColumnIndex('id');
      const colClothingIds = resultSet.getColumnIndex('clothingIds');
      const colAccessoryIds = resultSet.getColumnIndex('accessoryIds'); // 🌟 新增读取配饰列
      const colAvgTemp = resultSet.getColumnIndex('averageTemp');
      const colRecCount = resultSet.getColumnIndex('recommendCount');
      const colAccCount = resultSet.getColumnIndex('acceptCount');
      const colLastWorn = resultSet.getColumnIndex('lastWornDate');
      const colFavTime = resultSet.getColumnIndex('favoriteTime');

      while (resultSet.goToNextRow()) {
        const clothingIdsStr = resultSet.getString(colClothingIds) || '';
        const accessoryIdsStr = resultSet.getString(colAccessoryIds) || ''; // 防御空值

        // 切割成数组
        const clothingIdsArr = clothingIdsStr ? clothingIdsStr.split(',') : [];
        const accessoryIdsArr = accessoryIdsStr ? accessoryIdsStr.split(',') : [];

        const initialTemp = resultSet.getDouble(colAvgTemp);
        const id = resultSet.getString(colId);

        // 2. 🌟 修复参数错位：完美适配最新版构造函数，把衣服和配饰分开传入！
        const item = new Outfit(clothingIdsArr, accessoryIdsArr, initialTemp, id);

        // 还原数据
        item.recommendCount = resultSet.getLong(colRecCount);
        item.acceptCount = resultSet.getLong(colAccCount);
        item.lastWornDate = resultSet.getLong(colLastWorn);
        item.favoriteTime = resultSet.getLong(colFavTime);

        results.push(item);
      }
    } catch (error) {
      console.error('ClothingService', '获取收藏搭配记录失败: ' + JSON.stringify(error));
    } finally {
      // 3. 🌟 终极防线：在 finally 中关闭游标
      if (resultSet) {
        resultSet.close();
      }
    }

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
        // 🌟 新增：分别读取核心衣服和配饰，并做空值防御
        const clothingIdsStr = resultSet.getString(resultSet.getColumnIndex('clothingIds')) || '';
        const accessoryIdsStr = resultSet.getString(resultSet.getColumnIndex('accessoryIds')) || '';
        const averageTemp = resultSet.getDouble(resultSet.getColumnIndex('averageTemp'));

        // 切割成数组
        const clothingIdsArr = clothingIdsStr ? clothingIdsStr.split(',') : [];
        const accessoryIdsArr = accessoryIdsStr ? accessoryIdsStr.split(',') : [];

        // 🌟 修复核心痛点：实例化 Outfit 对象时，把衣服和配饰分开传给构造函数！
        const outfit = new Outfit(clothingIdsArr, accessoryIdsArr, averageTemp, id);

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
        'clothingIds': item.clothingIds.join(','),
        // 🌟 终极修复：把配饰也变成字符串装进桶里，一起发给数据库！
        'accessoryIds': item.accessoryIds.join(','),
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