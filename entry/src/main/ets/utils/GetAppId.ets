import { bundleManager } from '@kit.AbilityKit'

export function getAppIdForDebug(): string {
  try {
    let flag = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_SIGNATURE_INFO;
    let bundleInfo = bundleManager.getBundleInfoForSelfSync(flag)
    let appId = bundleInfo.signatureInfo.appId
    console.info('获取到的AppID:', appId)
    return appId
  } catch (err) {
    console.error('获取AppID失败:', JSON.stringify(err))
    return ''
  }
}
// 获取到的AppID: com.example.ootdbox_BHtJF10rdWjOcVATjad8in6B1sJ+gfLz/U058Xdfrx6Ae4W1ZqqJRCslADe65jkDiadsaB2yApglvA1lQGbHcYA=


