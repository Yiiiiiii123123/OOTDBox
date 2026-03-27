import { RdbHelper } from '../database/RdbStore'
import { Clothing, ClothingInput } from '../model/Clothing'
import relationalStore from '@ohos.data.relationalStore'

export class ClothingRepo {

  // 插入
  async insert(clothing: ClothingInput): Promise<void> {
    let store = RdbHelper.getStore()

    let valueBucket: relationalStore.ValuesBucket = {
      category: clothing.category,
      color: clothing.color,
      image_uri: clothing.imageUri,
      cutout_uri: clothing.cutoutUri,
      last_used_at: 0,
      created_at: Date.now()
    }

    await store.insert('clothing', valueBucket)
  }

  //删除
  async deleteById(id: number): Promise<void> {
    let store = RdbHelper.getStore()

    let predicates = new relationalStore.RdbPredicates('clothing')
    predicates.equalTo('id', id)

    await store.delete(predicates)
  }

  // 查询全部
  async getAll(): Promise<Clothing[]> {
    let store = RdbHelper.getStore()

    let resultSet = await store.querySql('SELECT * FROM clothing')

    let list: Clothing[] = []

    while (resultSet.goToNextRow()) {
      let item = new Clothing(
        resultSet.getLong(0),   // id
        resultSet.getString(1), // category
        resultSet.getString(2), // color
        resultSet.getString(3), // image_uri
        resultSet.getString(4), // cutout_uri
        resultSet.getLong(5),   // last_used_at
        resultSet.getLong(6)    // created_at
      )

      list.push(item)
    }

    resultSet.close()
    return list
  }
}