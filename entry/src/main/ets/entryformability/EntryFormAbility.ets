import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit'; // 🌟 引入 formProvider
import { Want } from '@kit.AbilityKit';
import dataPreferences from '@ohos.data.preferences';
import fs from '@ohos.file.fs'; // 🌟 必须引入文件系统

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    let formId = want.parameters?.['ohos.extra.param.key.form_id'] as string;

    let formData: Record<string, string> = {
      'images': '',
      'temp': '--℃'
    };

    dataPreferences.getPreferences(this.context, 'outfit_storage').then((preferences) => {
      if (formId) {
        preferences.putSync('bound_form_id', formId);
        preferences.flush();
      }

      let images = preferences.getSync('today_images', '') as string;
      let temp = preferences.getSync('today_temp', '--℃') as string;

      // 🌟 初始化时，也要将持久化的沙箱路径转为内存共享！
      if (images !== '') {
        let imagePaths = images.split(',');
        let memoryPaths: string[] = [];
        let formImages: Record<string, number> = {};

        for(let i = 0; i < imagePaths.length; i++) {
          try {
            let file = fs.openSync(imagePaths[i], fs.OpenMode.READ_ONLY);
            let memKey = 'pic_' + i;
            formImages[memKey] = file.fd;
            memoryPaths.push('memory://' + memKey);
          } catch(e) {
            console.error('FormAbility', '无法读取图片');
          }
        }

        let updateDataObj: Record<string, Object> = {
          'images': memoryPaths.join(','),
          'temp': temp,
          'formImages': formImages
        };

        let updateData = formBindingData.createFormBindingData(updateDataObj);
        formProvider.updateForm(formId, updateData);
      }
    }).catch((err: Error) => {
      console.error('FormAbility', '读取失败: ' + err.message);
    });

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