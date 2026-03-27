export class SegmentationService {

  /**
   * 假AI抠图
   * 输入：原图URI
   * 输出：抠图后URI
   */
  async segmentClothing(imageUri: string): Promise<string> {
    console.log('AI抠图开始:', imageUri)

    // 模拟耗时（让你以后替换真实模型时不用改结构）
    await this.fakeDelay(300)

    // ❗假装处理过（实际直接返回）
    const resultUri = imageUri

    console.log('AI抠图完成:', resultUri)

    return resultUri
  }

  private async fakeDelay(ms: number): Promise<void> {
    return new Promise(resolve => {
      setTimeout(resolve, ms)
    })
  }
}