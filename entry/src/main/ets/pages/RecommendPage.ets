import { Clothing } from '../model/Clothing'
import { ClothingRepo } from '../repository/ClothingRepo'
import { RecommendService } from '../service/RecommendService'

@Entry
@Component
struct RecommPage {

  @State clothingList: Clothing[] = []
  @State outfit: Clothing[] = []

  private repo: ClothingRepo = new ClothingRepo()
  private recommendService: RecommendService = new RecommendService()

  // 页面加载
  aboutToAppear() {
    this.loadData()
  }

  async loadData() {
    try {
      const list = await this.repo.getAll()
      this.clothingList = list ?? []
      console.log('衣物数量:', this.clothingList.length)
    } catch (e) {
      console.error('加载失败', e)
    }
  }

  build() {
    Column() {

      Text('穿搭推荐')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })

      Button('生成推荐')
        .width('80%')
        .height(45)
        .margin({ bottom: 20 })
        .onClick(() => {
          this.generateOutfit()
        })

      // 推荐结果
      if (this.outfit.length === 0) {
        Text('暂无推荐，请先添加衣物')
          .fontColor('#999')
      } else {

        List() {
          ForEach(this.outfit, (item: Clothing) => {

            ListItem() {
              Row() {

                Image(item.imageUri ?? '')
                  .width(80)
                  .height(80)
                  .margin({ right: 15 })

                Column() {
                  Text(item.category ?? '')
                  Text(item.color ?? '')
                    .fontColor('#666')
                }

              }
              .padding(10)
            }

          }, (item: Clothing) => String(item.id ?? Math.random()))
        }

      }

    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }

  // ======================
  // 生成推荐
  // ======================
  generateOutfit() {
    const result = this.recommendService.generate(this.clothingList)
    this.outfit = result
  }
}