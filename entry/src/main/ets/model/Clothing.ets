// model/Clothing.ets

// 数据库查询结果使用（完整对象）
export class Clothing {
  id: number
  category: string
  color: string
  imageUri: string
  cutoutUri: string
  lastUsedAt: number
  createdAt: number

  constructor(
    id: number,
    category: string,
    color: string,
    imageUri: string,
    cutoutUri: string,
    lastUsedAt: number,
    createdAt: number
  ) {
    this.id = id
    this.category = category
    this.color = color
    this.imageUri = imageUri
    this.cutoutUri = cutoutUri
    this.lastUsedAt = lastUsedAt
    this.createdAt = createdAt
  }
}


// 插入数据库使用（无 id）
export interface ClothingInput {
  category: string
  color: string
  imageUri: string
  cutoutUri: string
}

export interface ClothingDraft {
  imageUri: string
  category: string
  color: string
  cutoutUri: string
}