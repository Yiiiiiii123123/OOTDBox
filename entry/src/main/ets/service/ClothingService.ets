import { ClothingInput } from '../model/Clothing'
import { ClothingRepo } from '../repository/ClothingRepo'
import { SegmentationService } from './SegmentationService'

export class ClothingService {

  private repo: ClothingRepo = new ClothingRepo()
  private segmentationService: SegmentationService = new SegmentationService()

  async addClothing(uri: string): Promise<void> {
    try {

      console.log('开始处理衣物:', uri)

      // ✅ 1. 抠图（假AI）
      const cutoutUri = await this.segmentationService.segmentClothing(uri)

      // ✅ 2. 假AI分类
      const category = this.fakeCategory()

      // ✅ 3. 假AI颜色识别
      const color = this.fakeColor()

      console.log('AI识别结果:', category, color)

      // ✅ 4. 入库
      const item: ClothingInput = {
        category: category,
        color: color,
        imageUri: uri,
        cutoutUri: cutoutUri
      }

      await this.repo.insert(item)

      console.log('衣物入库完成')

    } catch (e) {
      console.error('添加衣物失败', e)
    }
  }

  async deleteClothing(id: number): Promise<void> {
    await this.repo.deleteById(id)
  }

  // ======================
  // 假AI：分类
  // ======================
  private fakeCategory(): string {
    const categories = ['上衣', '裤子', '鞋子', '外套']
    return categories[Math.floor(Math.random() * categories.length)]
  }

  // ======================
  // 假AI：颜色
  // ======================
  private fakeColor(): string {
    const colors = ['黑色', '白色', '蓝色', '灰色', '红色']
    return colors[Math.floor(Math.random() * colors.length)]
  }
}