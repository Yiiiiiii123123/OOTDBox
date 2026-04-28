import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';

// 1. 将我们刚才写的建表 SQL 定义为常量
const CREATE_TABLE_CLOTHING = `
CREATE TABLE IF NOT EXISTS Clothing (
    id TEXT PRIMARY KEY,
    imageUri TEXT NOT NULL,
    mainCategory TEXT NOT NULL,
    subCategory TEXT NOT NULL,
    warmthIndex INTEGER NOT NULL,
    color TEXT NOT NULL,
    wearCount INTEGER DEFAULT 0,
    lastWornDate INTEGER DEFAULT 0
);`;

const CREATE_TABLE_OUTFIT = `
CREATE TABLE IF NOT EXISTS Outfit (
    id TEXT PRIMARY KEY,
    clothingIds TEXT NOT NULL,
    accessoryIds TEXT,
    recommendCount INTEGER DEFAULT 0,
    acceptCount INTEGER DEFAULT 0,
    averageTemp REAL DEFAULT 0.0,
    lastWornDate INTEGER DEFAULT 0,
    favoriteTime INTEGER DEFAULT 0
);`;

export class RdbManager {
  // 单例模式，确保全局只有一个数据库管家
  private static instance: RdbManager;
  private rdbStore: relationalStore.RdbStore | null = null;

  private constructor() {}

  public static getInstance(): RdbManager {
    if (!RdbManager.instance) {
      RdbManager.instance = new RdbManager();
    }
    return RdbManager.instance;
  }

  /**
   * 初始化数据库并建表
   * @param context 应用的上下文环境
   */
  public async initRdb(context: common.UIAbilityContext): Promise<void> {
    // 数据库配置
    const config: relationalStore.StoreConfig = {
      name: 'MyWardrobe.db', // 数据库名字
      securityLevel: relationalStore.SecurityLevel.S1 // 安全级别，S1为基础级别
    };

    try {
      // 获取/创建数据库实例
      this.rdbStore = await relationalStore.getRdbStore(context, config);
      console.info('RdbManager', '数据库获取成功');

      // 执行建表 SQL (如果表已存在，IF NOT EXISTS 会自动跳过，不会报错)
      await this.rdbStore.executeSql(CREATE_TABLE_CLOTHING);
      await this.rdbStore.executeSql(CREATE_TABLE_OUTFIT);
      console.info('RdbManager', '建表/检查表结构成功');

    } catch (err) {
      console.error('RdbManager', `数据库初始化失败: ${JSON.stringify(err)}`);
    }
  }

  /**
   * 暴露获取 rdbStore 实例的方法，供 Repo 层使用
   */
  public getStore(): relationalStore.RdbStore {
    if (!this.rdbStore) {
      throw new Error("数据库尚未初始化！");
    }
    return this.rdbStore;
  }
}