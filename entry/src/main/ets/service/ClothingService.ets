import { Clothing, ClothingDraft, ClothingInput } from '../model/Clothing'
import { ClothingRepo } from '../repository/ClothingRepo'
import { SegmentationService } from './SegmentationService'

export class ClothingService {

  private repo: ClothingRepo = new ClothingRepo()
  private segmentationService: SegmentationService = new SegmentationService()

  async analyzeClothing(uri: string): Promise<ClothingDraft> {
    const cutoutUri = await this.segmentationService.segmentClothing(uri)

    return {
      imageUri: uri,
      cutoutUri: cutoutUri,
      category: this.fakeCategory(),
      color: this.fakeColor()
    }
  }

  async saveClothing(draft: ClothingInput) {
    await this.repo.insert(draft)
  }

  async deleteClothing(id: number): Promise<void> {
    await this.repo.deleteById(id)
  }

  // 更新衣物信息
  async updateClothing(clothing: Clothing): Promise<void> {
    try {
      await this.repo.update(clothing)
    } catch (e) {
      console.error('更新衣物失败', e)
      throw new Error('更新衣物失败: ' + JSON.stringify(e))
    }
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