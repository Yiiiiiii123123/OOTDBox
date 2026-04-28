import dataPreferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';

export class PreferenceRepo {
  private static readonly PREF_NAME = 'app_settings';

  // 专门提供给外部调用的“保存城市”方法
  public static async saveCity(context: common.UIAbilityContext, cityName: string, cityCode: string) {
    try {
      let prefs = await dataPreferences.getPreferences(context, PreferenceRepo.PREF_NAME);
      prefs.put('city_name', cityName);
      prefs.put('city_code', cityCode);
      await prefs.flush();
    } catch (e) {
      console.error('PreferenceManager', '保存城市失败: ' + JSON.stringify(e));
    }
  }

  //保存壁纸
  public static async saveWallpaper(context: common.UIAbilityContext, index: number) {
    try {
      let prefs = await dataPreferences.getPreferences(context, PreferenceRepo.PREF_NAME);
      prefs.put('wallpaper_index', index);
      await prefs.flush();
    } catch (e) {
      console.error('PreferenceService', '保存壁纸失败: ' + JSON.stringify(e));
    }
  }

  //存：保存今日穿搭的 ID 列表和当天的时间戳
  public static async putTodayOutfitIds(context: common.UIAbilityContext, ids: string[]) {
    let prefs = await dataPreferences.getPreferences(context, PreferenceRepo.PREF_NAME);

    // 获取今天的日期字符串，例如 "2026-04-22"
    let todayDate = new Date().toDateString();

    // 把 ID 数组转成逗号分隔的字符串存进去
    prefs.put('today_outfit_ids', ids.join(','));
    prefs.put('today_outfit_date', todayDate); // 记录是哪一天的

    await prefs.flush();
  }

  //取：获取有效（仅限今天）的穿搭 ID 列表
  public static async getTodayOutfitIds(context: common.UIAbilityContext): Promise<string[]> {
    let prefs = await dataPreferences.getPreferences(context, PreferenceRepo.PREF_NAME);

    let savedDate = prefs.getSync('today_outfit_date', '') as string;
    let todayDate = new Date().toDateString();

    // 如果日期不是今天，直接返回空数组（自动过期）
    if (savedDate !== todayDate) {
      return [];
    }

    let idString = prefs.getSync('today_outfit_ids', '') as string;
    return idString ? idString.split(',') : [];
  }


}