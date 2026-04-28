import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { RdbManager } from '../database/RdbManager';
import dataPreferences from '@ohos.data.preferences'; // 导入首选项模块

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {

    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
    RdbManager.getInstance().initRdb(this.context);

    // 晨读逻辑：在加载页面前，先去冰箱贴上读数据
    dataPreferences.getPreferences(this.context, 'app_settings').then((prefs) => {
      // 读出壁纸索引，默认给 0 (这里用 getSync 同步读取更干脆)
      let savedWallpaperIndex = prefs.getSync('wallpaper_index', 0) as number;
      // 把读出来的值强行塞进全局内存，让所有页面都能拿到
      AppStorage.setOrCreate('wallpaper_index', savedWallpaperIndex);

      // 新增：读城市信息 (如果没存过，默认给厦门的代码 350200)
      let savedCityName = prefs.getSync('city_name', '厦门') as string;
      let savedCityCode = prefs.getSync('city_code', '350200') as string;
      AppStorage.setOrCreate('currentCityName', savedCityName);
      AppStorage.setOrCreate('currentCityCode', savedCityCode);



      // 3. 等数据塞好之后，再加载首页，保证绝不闪屏！
      windowStage.loadContent('pages/HomePage', (err) => {
        if (err.code) {
          hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
          return;
        }
        hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
      });
    }).catch((err: Error) => {
      // 兜底：如果读文件失败，也保证能正常进首页
      hilog.error(DOMAIN, 'testTag', 'Failed to read preferences: %{public}s', err.message);
      windowStage.loadContent('pages/HomePage');
    });


  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}