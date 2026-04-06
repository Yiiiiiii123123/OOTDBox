import relationalStore from '@ohos.data.relationalStore';
import { RdbManager } from '../database/RdbManager';
import { Clothing, ClothingColor, SubCategory } from '../model/Clothing';

export class ClothingRepo {
  private rdbStore: relationalStore.RdbStore;

  // 1. 构造函数不再需要传参
  constructor() {
    // 2. 自己去管家那里拿数据库实例
    this.rdbStore = RdbManager.getInstance().getStore();
  }

  // 纯粹的删除单品
  public async delete(clothingId: string): Promise<number> {
    let predicates = new relationalStore.RdbPredicates('Clothing');
    predicates.equalTo('id', clothingId);
    return await this.rdbStore.delete(predicates);
  }

  /**
   * 清空衣橱所有数据
   */
  async deleteAll(): Promise<boolean> {
    try {
      // 🌟 1. 构建操作谓词，传入你的表名（请确保 'Clothing' 是你真实的表名）
      let predicates = new relationalStore.RdbPredicates('Clothing');

      // 🌟 2. 执行删除。因为 predicates 没有加 any equalTo 条件，所以会删除整表
      let deletedRows = await this.rdbStore.delete(predicates);

      console.info('ClothingRepo', `成功清空衣橱，共删除 ${deletedRows} 条数据`);
      return true;
    } catch (err) {
      console.error('ClothingRepo', '清空衣橱失败: ' + JSON.stringify(err));
      return false; // 删除失败返回 false
    }
  }

  /**
   * 🌟 新增：获取衣橱中的所有衣物
   * 返回值类型明确指定为 Promise<Clothing[]>，彻底解决 ArkTS 的 any 报错
   */
  public async getAll(): Promise<Clothing[]> {
    // 1. 创建查询条件：查询 Clothing 表里的所有数据
    let predicates = new relationalStore.RdbPredicates('Clothing');

    // 2. 执行查询
    let resultSet = await this.rdbStore.query(predicates);
    let clothes: Clothing[] = [];

    // 3. 遍历查询结果（游标逐行读取）
    while (resultSet.goToNextRow()) {
      // 取出每一列的数据
      let id = resultSet.getString(resultSet.getColumnIndex('id'));
      let imageUri = resultSet.getString(resultSet.getColumnIndex('imageUri'));
      let subCategory = resultSet.getString(resultSet.getColumnIndex('subCategory')) as SubCategory;
      let warmthIndex = resultSet.getLong(resultSet.getColumnIndex('warmthIndex'));
      let color = resultSet.getString(resultSet.getColumnIndex('color')) as ClothingColor;

      // 实例化 Clothing 对象
      let item = new Clothing(id, imageUri, subCategory, warmthIndex, color);

      // 💡 注意：还需要从数据库中还原穿戴次数和上次穿戴时间
      // （因为在 new Clothing() 时，这两个值默认会被设为 0）
      item.wearCount = resultSet.getLong(resultSet.getColumnIndex('wearCount'));
      item.lastWornDate = resultSet.getLong(resultSet.getColumnIndex('lastWornDate'));

      // 塞入数组
      clothes.push(item);
    }

    // 4. 务必关闭游标，释放内存
    resultSet.close();

    return clothes;
  }

  /**
   * 🌟 新增：将单品数据插入到 SQLite 数据库中
   */
  public async insert(item: Clothing): Promise<number> {
    // 构造符合关系型数据库要求的数据桶 (ValuesBucket)
    // 这里的 key 必须和我们建表时的列名一模一样
    const valueBucket: relationalStore.ValuesBucket = {
      'id': item.id,
      'imageUri': item.imageUri,
      'mainCategory': item.mainCategory,
      'subCategory': item.subCategory,
      'warmthIndex': item.warmthIndex,
      'color': item.color,
      'wearCount': item.wearCount,
      'lastWornDate': item.lastWornDate
    };

    // 调用 insert 方法，参数分别是：表名，冲突解决策略(可选)，数据桶
    // 返回值是新插入行的 rowId，如果失败会抛出异常或返回 -1
    return await this.rdbStore.insert('Clothing', valueBucket);
  }

  public async update(item: Clothing): Promise<number> {
    const valueBucket: relationalStore.ValuesBucket = {
      'imageUri': item.imageUri,
      'mainCategory': item.mainCategory,
      'subCategory': item.subCategory,
      'warmthIndex': item.warmthIndex,
      'color': item.color,
      // wearCount 和 lastWornDate 通常在详情页编辑时不修改，保持原样
    };

    let predicates = new relationalStore.RdbPredicates('Clothing');
    predicates.equalTo('id', item.id); // 根据 ID 锁定要修改的那件衣服

    return await this.rdbStore.update(valueBucket, predicates);
  }

  /**
   * 🌟 新增：根据 ID 查询单件衣物
   */
  public async getById(id: string): Promise<Clothing | null> {
    let predicates = new relationalStore.RdbPredicates('Clothing');
    predicates.equalTo('id', id);

    let resultSet = await this.rdbStore.query(predicates);

    // 检查是否有结果并移动到第一行
    if (resultSet.rowCount > 0 && resultSet.goToFirstRow()) {
      const item = new Clothing(
        resultSet.getString(resultSet.getColumnIndex('id')),
        resultSet.getString(resultSet.getColumnIndex('imageUri')),
        resultSet.getString(resultSet.getColumnIndex('subCategory')) as SubCategory,
        resultSet.getLong(resultSet.getColumnIndex('warmthIndex')),
        resultSet.getString(resultSet.getColumnIndex('color')) as ClothingColor
      );

      // 恢复统计数据
      item.wearCount = resultSet.getLong(resultSet.getColumnIndex('wearCount'));
      item.lastWornDate = resultSet.getLong(resultSet.getColumnIndex('lastWornDate'));

      resultSet.close(); // 记得关闭
      return item;
    }

    resultSet.close();
    return null;
  }
}


