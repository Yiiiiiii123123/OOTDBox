import { Clothing } from '../model/Clothing'

export class RecommendService {

  /**
   * 生成推荐穿搭（返回一套）
   */
  generate(list: Clothing[]): Clothing[] {

    if (!list || list.length === 0) {
      return []
    }

    // 分类分组
    const tops = list.filter(i => i.category === '上衣')
    const bottoms = list.filter(i => i.category === '裤子')
    const shoes = list.filter(i => i.category === '鞋子')

    // 最小可用规则：必须有上衣+裤子
    if (tops.length === 0 || bottoms.length === 0) {
      console.log('衣物不足，无法推荐')
      return []
    }

    // 随机选
    let outfit: Clothing[] = []

    const top = this.randomPick(tops)
    const bottom = this.randomPick(bottoms)
    outfit.push(top, bottom)

    if (shoes.length > 0) {
      outfit.push(this.randomPick(shoes))
    }

    // 颜色规则过滤
    if (!this.isColorValid(outfit)) {
      return this.generate(list) // 递归重试
    }

    console.log('推荐结果:', outfit)

    return outfit
  }

  // ======================
  // 工具函数
  // ======================

  private randomPick(arr: Clothing[]): Clothing {
    const index = Math.floor(Math.random() * arr.length)
    return arr[index]
  }

  private isColorValid(outfit: Clothing[]): boolean {
    const colors = outfit.map(i => i.color)
    const uniqueColors = Array.from(new Set(colors))

    // 最多3种颜色
    return uniqueColors.length <= 3
  }
}