import { relationalStore } from '@kit.ArkData'
import { Clothing, ClothingInput } from '../model/Clothing'
import { BusinessError } from '@kit.BasicServicesKit'
import { RdbHelper } from '../database/RdbStore'
import { common } from '@kit.AbilityKit'

const DATABASE_NAME: string = 'OOTDBox.db'
const TABLE_NAME: string = 'clothing'
const SQL_CREATE_TABLE: string = `CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    imageUri TEXT NOT NULL,
    category TEXT,
    color TEXT,
    brand TEXT,
    createTime TEXT
)`

export class ClothingRepo {
  private store: relationalStore.RdbStore | null = null
  private context: common.UIAbilityContext | null = null

  // 设置上下文（在 EntryAbility 中调用）
  setContext(context: common.UIAbilityContext) {
    this.context = context
  }

  // 初始化数据库
  async init(): Promise<void> {
    if (!this.context) {
      console.error('数据库初始化失败: context 未设置')
      return
    }

    try {
      const config: relationalStore.StoreConfig = {
        name: DATABASE_NAME,
        securityLevel: relationalStore.SecurityLevel.S1
      }

      // ✅ 正确：传入 context 和 config
      this.store = await new Promise<relationalStore.RdbStore>((resolve, reject) => {
        relationalStore.getRdbStore(this.context!, config, (err: BusinessError, rdbStore: relationalStore.RdbStore) => {
          if (err) {
            reject(err)
          } else {
            resolve(rdbStore)
          }
        })
      })

      await this.store.executeSql(SQL_CREATE_TABLE)
      console.info('数据库初始化成功')
    } catch (err) {
      let error = err as BusinessError
      console.error(`数据库初始化失败: ${error.message}`)
    }
  }

  // 确保数据库已初始化
  private async ensureInit(): Promise<relationalStore.RdbStore> {
    if (!this.store) {
      await this.init()
    }
    return this.store!
  }

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
        resultSet.getString(4),// cutout_uri
        resultSet.getLong(5),   // last_used_at
        resultSet.getLong(6)    // created_at
      )

      list.push(item)
    }

    resultSet.close()
    return list
  }

  // 根据id查询单件衣物
  async getById(id: number): Promise<Clothing | null> {
    const store = await this.ensureInit()
    const predicates = new relationalStore.RdbPredicates(TABLE_NAME)
    predicates.equalTo('id', id)
    const resultSet = await store.query(predicates)

    if (resultSet.goToNextRow()) {
      // ✅ 使用 new 创建 class 实例
      const clothing = new Clothing(
        resultSet.getLong(resultSet.getColumnIndex('id')),           // id: number
        resultSet.getString(resultSet.getColumnIndex('category')),  // category: string
        resultSet.getString(resultSet.getColumnIndex('color')),     // color: string
        resultSet.getString(resultSet.getColumnIndex('imageUri')),  // imageUri: string
        resultSet.getString(resultSet.getColumnIndex('cutoutUri')) || '',  // cutoutUri: string
        resultSet.getLong(resultSet.getColumnIndex('lastUsedAt')) || 0,    // lastUsedAt: number
        resultSet.getLong(resultSet.getColumnIndex('createTime')) || 0     // createdAt: number
      )
      clothing.id = resultSet.getLong(resultSet.getColumnIndex('id'))
      resultSet.close()
      return clothing
    }
    resultSet.close()
    return null
  }

  // ✅ 新增：更新衣物信息
  async update(clothing: Clothing): Promise<number> {
    const store = await this.ensureInit()

    // 构建更新数据
    const valueBucket: relationalStore.ValuesBucket = {
      'imageUri': clothing.imageUri,
      'category': clothing.category || null,
      'color': clothing.color || null,

    }

    // 构建查询条件
    const predicates = new relationalStore.RdbPredicates(TABLE_NAME)
    predicates.equalTo('id', clothing.id)

    // 执行更新
    const rowsAffected = await store.update(valueBucket, predicates)
    console.info(`更新成功，影响行数: ${rowsAffected}`)
    return rowsAffected
  }

  //删除
  async deleteById(id: number): Promise<void> {
    let store = RdbHelper.getStore()

    let predicates = new relationalStore.RdbPredicates('clothing')
    predicates.equalTo('id', id)

    await store.delete(predicates)
  }


  // 删除所有衣物
  async deleteAll(): Promise<number> {
    const store = await this.ensureInit()
    const predicates = new relationalStore.RdbPredicates(TABLE_NAME)
    const rowsAffected = await store.delete(predicates)
    console.info(`删除所有成功，影响行数: ${rowsAffected}`)
    return rowsAffected
  }
}