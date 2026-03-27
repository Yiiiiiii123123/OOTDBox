import relationalStore from '@ohos.data.relationalStore'
import common from '@ohos.app.ability.common'

const DB_NAME = 'closet.db'

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: DB_NAME,
  securityLevel: relationalStore.SecurityLevel.S1
}

const CREATE_CLOTHING_TABLE = `
CREATE TABLE IF NOT EXISTS clothing (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category TEXT,
  color TEXT,
  image_uri TEXT,
  cutout_uri TEXT,
  last_used_at INTEGER,
  created_at INTEGER
)
`

export class RdbHelper {
  private static rdbStore: relationalStore.RdbStore

  static async init(context: common.UIAbilityContext) {
    RdbHelper.rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG)
    await RdbHelper.rdbStore.executeSql(CREATE_CLOTHING_TABLE)
  }

  static getStore(): relationalStore.RdbStore {
    return RdbHelper.rdbStore
  }
}