import { formBindingData, FormExtensionAbility, formInfo } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import dataPreferences from '@ohos.data.preferences';

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    // 1. 准备一个最基础的初始数据（防止读取失败或太慢）
    let formData: Record<string, string> = {
      'images': '',
      'temp': '--℃'
    };

    // 2. 异步读取首选项（不使用 await，而使用 .then 回调）
    dataPreferences.getPreferences(this.context, 'outfit_storage').then((preferences) => {
      return preferences.get('today_images', '');
    }).then((value) => {
      // 这里的 value 就是读取到的图片路径
      console.info('FormAbility', '数据读取成功，准备更新卡片');
      // 注意：这里的更新需要配合 formProvider.updateForm 使用，
      // 因为 onAddForm 已经执行完了。
    }).catch((err: Error) => {
      console.error('FormAbility', '读取失败: ' + err.message);
    });

    // 3. 🌟 关键：立即返回初始绑定数据，让卡片先显示出来（哪怕是空状态）
    return formBindingData.createFormBindingData(formData);
  }

  onCastToNormalForm(formId: string) {
    // Called when the form provider is notified that a temporary form is successfully
    // converted to a normal form.
  }

  onUpdateForm(formId: string) {
    // Called to notify the form provider to update a specified form.
  }

  onFormEvent(formId: string, message: string) {
    // Called when a specified message event defined by the form provider is triggered.
  }

  onRemoveForm(formId: string) {
    // Called to notify the form provider that a specified form has been destroyed.
  }

  onAcquireFormState(want: Want) {
    // Called to return a {@link FormState} object.
    return formInfo.FormState.READY;
  }
}