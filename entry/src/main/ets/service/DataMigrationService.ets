import fs from '@ohos.file.fs';
import zlib from '@ohos.zlib';
import picker from '@ohos.file.picker';
import common from '@ohos.app.ability.common';
import { Clothing } from '../model/Clothing';
import { ClothingRepo } from '../repository/ClothingRepo';
import { util } from '@kit.ArkTS';
import { promptAction } from '@kit.ArkUI';
import { ClothingColor, SubCategory } from '../utils/ClothingConfig';

//负责导入数据和导出数据（数据迁移）

// 🌟 专为 JSON 序列化准备的严格类型结构
export interface ExportClothingData {
  id: string;
  imageUri: string;
  mainCategory: string;
  subCategory: string;
  warmthIndex: number;
  color: string;
  wearCount: number;
  lastWornDate: number;
}

export interface MigrationResult {
  success: boolean;
  msg: string;
}

export class DataMigrationService {
  private repo: ClothingRepo = new ClothingRepo();

  /**
   * 导出并打包数据
   */
  public async exportData(context: common.UIAbilityContext): Promise<MigrationResult> {
    const cacheDir = context.cacheDir;
    const timestamp = new Date().getTime();
    const stagingDir = `${cacheDir}/WardrobeExport_${timestamp}`;
    const imagesDir = `${stagingDir}/images`;
    const zipPath = `${cacheDir}/WardrobeBackup_${timestamp}.zip`;

    try {
      // 1. 获取所有衣物数据
      const clothes = await this.repo.getAll();
      if (!clothes || clothes.length === 0) {
        return { success: false, msg: '衣橱是空的，没有什么可以导出的哦' };
      }

      // 2. 创建临时打包目录
      fs.mkdirSync(stagingDir);
      fs.mkdirSync(imagesDir);

      // 3. 组装数据并拷贝图片
      let exportDataList: ExportClothingData[] = [];
      for (const item of clothes) {
        const fileName = item.imageUri.split('/').pop() || 'unknown.jpg';
        const destImagePath = `${imagesDir}/${fileName}`;

        try {
          // 🌟 双重读取策略：兼容图库照片和沙盒图片
          let srcFile: fs.File;
          try {
            srcFile = fs.openSync(item.imageUri, fs.OpenMode.READ_ONLY);
          } catch (e1) {
            const realPath = item.imageUri.replace('file://', '');
            srcFile = fs.openSync(realPath, fs.OpenMode.READ_ONLY);
          }

          // 🌟 终极修复：直接从源文件 FD 拷贝到目标路径字符串！
          // 绝不能提前打开目标文件，否则会导致 0 字节锁死！
          fs.copyFileSync(srcFile.fd, destImagePath);
          fs.closeSync(srcFile);

        } catch (imgErr) {
          promptAction.showDialog({
            title: '⚠️ 单张图片打包跳过',
            message: `路径: ${item.imageUri}\n该图片可能已损坏或丢失，打包将略过此图继续。`
          });
        }

        // 组装 JSON
        let exportItem: ExportClothingData = {
          id: item.id,
          imageUri: `images/${fileName}`,
          mainCategory: item.mainCategory.toString(),
          subCategory: item.subCategory.toString(),
          warmthIndex: item.warmthIndex,
          color: item.color.toString(),
          wearCount: item.wearCount || 0,
          lastWornDate: item.lastWornDate || 0
        };
        exportDataList.push(exportItem);
      }

      // 4. 将对象数组写入 data.json
      const jsonContent = JSON.stringify(exportDataList);
      const jsonFile = fs.openSync(`${stagingDir}/data.json`, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      fs.writeSync(jsonFile.fd, jsonContent);
      fs.closeSync(jsonFile);

      // 5. 压缩为 ZIP
      await zlib.compressFile(stagingDir, zipPath, {
        level: zlib.CompressLevel.COMPRESS_LEVEL_DEFAULT_COMPRESSION
      });

      // 6. 呼出系统保存面板
      const documentSaveOptions = new picker.DocumentSaveOptions();
      documentSaveOptions.newFileNames = ['MyWardrobeBackup.zip'];
      const documentPicker = new picker.DocumentViewPicker();

      const saveUris = await documentPicker.save(documentSaveOptions);
      if (!saveUris || saveUris.length === 0) {
        return { success: false, msg: '您取消了保存' };
      }

      // 7. 保存到公共目录
      const targetUri = saveUris[0];
      const targetFile = fs.openSync(targetUri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      fs.copyFileSync(zipPath, targetFile.fd);
      fs.closeSync(targetFile);

      return { success: true, msg: '导出成功！已保存到手机' };

    } catch (e) {
      console.error('DataMigrationService', '导出崩溃: ' + JSON.stringify(e));
      return { success: false, msg: `系统异常: ${e.message || JSON.stringify(e)}` };
    } finally {
      // 8. 清理沙盒
      this.cleanUpPath(stagingDir);
      this.cleanUpPath(zipPath);
    }
  }

  /**
   * 载入并恢复数据
   * 包含智能合并、打破 UI 缓存、纯净文件名生成，彻底解决乱码路径不显示图片的问题
   */
  public async importData(context: common.UIAbilityContext): Promise<MigrationResult> {
    const cacheDir = context.cacheDir;
    const filesDir = context.filesDir;
    const tempZipPath = `${cacheDir}/ImportTemp.zip`;
    const extractDir = `${cacheDir}/WardrobeImport_${new Date().getTime()}`;

    try {
      // 1. 呼出选择面板
      const documentPicker = new picker.DocumentViewPicker();
      const documentSelectOptions = new picker.DocumentSelectOptions();
      documentSelectOptions.fileSuffixFilters = ['.zip', '.wdrobe'];

      const selectUris = await documentPicker.select(documentSelectOptions);
      if (!selectUris || selectUris.length === 0) {
        return { success: false, msg: '您取消了选择' };
      }

      // 2. 拷贝进沙盒
      this.cleanUpPath(tempZipPath);
      this.cleanUpPath(extractDir);
      fs.mkdirSync(extractDir);

      const sourceUri = selectUris[0];
      const sourceFile: fs.File = fs.openSync(sourceUri, fs.OpenMode.READ_ONLY);
      fs.copyFileSync(sourceFile.fd, tempZipPath);
      fs.closeSync(sourceFile);

      // 3. 解压
      await zlib.decompressFile(tempZipPath, extractDir, {});

      // 4. 寻找并读取 JSON
      const jsonPath = `${extractDir}/data.json`;
      if (!fs.accessSync(jsonPath)) {
        return { success: false, msg: '压缩包内找不到 data.json，格式不对！' };
      }

      const jsonFile: fs.File = fs.openSync(jsonPath, fs.OpenMode.READ_ONLY);
      const stat = fs.statSync(jsonFile.fd);
      const buffer = new ArrayBuffer(stat.size);
      fs.readSync(jsonFile.fd, buffer);
      fs.closeSync(jsonFile);

      // 5. 解析数据
      let decoder: util.TextDecoder = util.TextDecoder.create('utf-8');
      let jsonString: string = decoder.decodeWithStream(new Uint8Array(buffer));
      let parsedObj: Object = JSON.parse(jsonString);
      let importDataList: ExportClothingData[] = parsedObj as ExportClothingData[];

      // 6. 还原循环
      let restoreCount = 0;
      for (const item of importDataList) {
        const relativeImgPath = item.imageUri;
        const sourceImgPath = `${extractDir}/${relativeImgPath}`;

        // 🌟 终极杀手锏：彻底抛弃原来带有 % 和中文的乱码文件名！
        // 1. 提取文件的真实后缀名 (比如 png, jpg)，如果没有默认给 png
        const ext = relativeImgPath.includes('.') ? relativeImgPath.split('.').pop() : 'png';

        // 2. 生成一个【纯字母+数字】的绝对安全文件名 (例如: img_1713000000_1234.png)
        const randomNum = Math.floor(Math.random() * 100000);
        const safeFileName = `img_${new Date().getTime()}_${randomNum}.${ext}`;

        // 3. 拼装出极其健康的沙盒路径
        const newImgPath = `${filesDir}/${safeFileName}`;

        // 🌟 直接用路径字符串拷贝最安全
        try {
          if (fs.accessSync(sourceImgPath)) {
            fs.copyFileSync(sourceImgPath, newImgPath);
          } else {
            promptAction.showDialog({
              title: '⚠️ 压缩包内图片缺失',
              message: `原始文件 ${relativeImgPath} 丢失。`
            });
          }
        } catch (imgErr) {
          promptAction.showDialog({
            title: '❌ 恢复图片发生异常',
            message: `源路径: ${sourceImgPath}\n错误信息: ${JSON.stringify(imgErr)}`
          });
        }

        // 🌟 补齐 UI 必需的协议头
        item.imageUri = `file://${newImgPath}`;

        const clothingObj = new Clothing(
          item.id,
          item.imageUri,
          item.subCategory as SubCategory,
          item.warmthIndex,
          item.color as ClothingColor
        );
        clothingObj.wearCount = item.wearCount || 0;
        clothingObj.lastWornDate = item.lastWornDate || 0;

        // 🌟 Upsert 智能合并更新
        const existingItem = await this.repo.getById(clothingObj.id);
        if (existingItem) {
          await this.repo.update(clothingObj);
        } else {
          await this.repo.insert(clothingObj);
        }

        restoreCount++;
      }

      return { success: true, msg: `导入成功！共恢复/更新 ${restoreCount} 件衣物` };

    } catch (e) {
      console.error('DataMigrationService', '导入崩溃详情: ' + JSON.stringify(e));
      return { success: false, msg: `恢复失败: ${e.message || JSON.stringify(e)}` };
    } finally {
      this.cleanUpPath(tempZipPath);
      this.cleanUpPath(extractDir);
    }
  }

  private cleanUpPath(path: string) {
    try {
      if (fs.accessSync(path)) {
        fs.rmdirSync(path);
      }
    } catch (e) { }
  }
}