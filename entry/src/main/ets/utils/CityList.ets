export interface City {
  city: string;
  adcode: string;
}

export interface CityGroup {
  letter: string;
  cities: City[];
}

// 🌟 1. 新增：专门为包含拼音的原始数据定义一个接口
interface RawCity {
  city: string;
  adcode: string;
  pinyin: string;
}

const rawCityList: RawCity[] = [
// A
  { city: '鞍山', adcode: '210300', pinyin: 'A' },
  // B
  { city: '北京', adcode: '110000', pinyin: 'B' },
  { city: '保定', adcode: '130200', pinyin: 'B' },
  { city: '宝鸡', adcode: '610300', pinyin: 'B' },
  { city: '包头', adcode: '150200', pinyin: 'B' },
  // C
  { city: '成都', adcode: '510100', pinyin: 'C' },
  { city: '重庆', adcode: '500000', pinyin: 'C' },
  { city: '长沙', adcode: '430100', pinyin: 'C' },
  { city: '长春', adcode: '220100', pinyin: 'C' },
  { city: '常州', adcode: '320400', pinyin: 'C' },
  { city: '常德', adcode: '430700', pinyin: 'C' },
  { city: '沧州', adcode: '130900', pinyin: 'C' },
  // D
  { city: '大连', adcode: '210200', pinyin: 'D' },
  { city: '东莞', adcode: '441900', pinyin: 'D' },
  { city: '大庆', adcode: '230600', pinyin: 'D' },
  { city: '大同', adcode: '140200', pinyin: 'D' },
  { city: '德阳', adcode: '510600', pinyin: 'D' },
  { city: '德州', adcode: '371400', pinyin: 'D' },
  // E
  { city: '鄂尔多斯', adcode: '150600', pinyin: 'E' },
  // F
  { city: '福州', adcode: '350100', pinyin: 'F' },
  { city: '佛山', adcode: '440600', pinyin: 'F' },
  { city: '抚顺', adcode: '210400', pinyin: 'F' },
  { city: '阜阳', adcode: '341200', pinyin: 'F' },
  // G
  { city: '广州', adcode: '440100', pinyin: 'G' },
  { city: '贵阳', adcode: '520100', pinyin: 'G' },
  { city: '桂林', adcode: '450300', pinyin: 'G' },
  { city: '赣州', adcode: '360700', pinyin: 'G' },
  // H
  { city: '杭州', adcode: '330100', pinyin: 'H' },
  { city: '哈尔滨', adcode: '230100', pinyin: 'H' },
  { city: '合肥', adcode: '340100', pinyin: 'H' },
  { city: '海口', adcode: '460100', pinyin: 'H' },
  { city: '呼和浩特', adcode: '150100', pinyin: 'H' },
  { city: '惠州', adcode: '441300', pinyin: 'H' },
  { city: '邯郸', adcode: '130400', pinyin: 'H' },
  { city: '湖州', adcode: '330500', pinyin: 'H' },
  // J
  { city: '济南', adcode: '370100', pinyin: 'J' },
  { city: '嘉兴', adcode: '330400', pinyin: 'J' },
  { city: '金华', adcode: '330700', pinyin: 'J' },
  { city: '江门', adcode: '440700', pinyin: 'J' },
  { city: '吉林', adcode: '220200', pinyin: 'J' },
  { city: '九江', adcode: '360400', pinyin: 'J' },
  // K
  { city: '昆明', adcode: '530100', pinyin: 'K' },
  { city: '开封', adcode: '410200', pinyin: 'K' },
  // L
  { city: '兰州', adcode: '620100', pinyin: 'L' },
  { city: '洛阳', adcode: '410300', pinyin: 'L' },
  { city: '临沂', adcode: '371300', pinyin: 'L' },
  { city: '廊坊', adcode: '131000', pinyin: 'L' },
  { city: '连云港', adcode: '320700', pinyin: 'L' },
  { city: '柳州', adcode: '450200', pinyin: 'L' },
  // M
  { city: '绵阳', adcode: '510700', pinyin: 'M' },
  { city: '马鞍山', adcode: '340500', pinyin: 'M' },
  // N
  { city: '南京', adcode: '320100', pinyin: 'N' },
  { city: '宁波', adcode: '330200', pinyin: 'N' },
  { city: '南宁', adcode: '450100', pinyin: 'N' },
  { city: '南昌', adcode: '360100', pinyin: 'N' },
  { city: '南通', adcode: '320600', pinyin: 'N' },
  { city: '南阳', adcode: '411300', pinyin: 'N' },
  // Q
  { city: '青岛', adcode: '370200', pinyin: 'Q' },
  { city: '泉州', adcode: '350500', pinyin: 'Q' },
  { city: '秦皇岛', adcode: '130300', pinyin: 'Q' },
  // R
  { city: '日照', adcode: '371100', pinyin: 'R' },
  // S
  { city: '上海', adcode: '310000', pinyin: 'S' },
  { city: '深圳', adcode: '440300', pinyin: 'S' },
  { city: '苏州', adcode: '320500', pinyin: 'S' },
  { city: '沈阳', adcode: '210100', pinyin: 'S' },
  { city: '石家庄', adcode: '130100', pinyin: 'S' },
  { city: '绍兴', adcode: '330600', pinyin: 'S' },
  { city: '汕头', adcode: '440500', pinyin: 'S' },
  { city: '宿迁', adcode: '321300', pinyin: 'S' },
  { city: '三亚', adcode: '460200', pinyin: 'S' },
  // T
  { city: '天津', adcode: '120000', pinyin: 'T' },
  { city: '太原', adcode: '140100', pinyin: 'T' },
  { city: '唐山', adcode: '130200', pinyin: 'T' },
  { city: '台州', adcode: '331000', pinyin: 'T' },
  { city: '泰安', adcode: '370900', pinyin: 'T' },
  // W
  { city: '武汉', adcode: '420100', pinyin: 'W' },
  { city: '无锡', adcode: '320200', pinyin: 'W' },
  { city: '温州', adcode: '330300', pinyin: 'W' },
  { city: '潍坊', adcode: '370700', pinyin: 'W' },
  { city: '威海', adcode: '371000', pinyin: 'W' },
  { city: '芜湖', adcode: '340200', pinyin: 'W' },
  { city: '乌鲁木齐', adcode: '650100', pinyin: 'W' },
  // X
  { city: '厦门', adcode: '350200', pinyin: 'X' },
  { city: '西安', adcode: '610100', pinyin: 'X' },
  { city: '徐州', adcode: '320300', pinyin: 'X' },
  { city: '咸阳', adcode: '610400', pinyin: 'X' },
  { city: '襄阳', adcode: '420600', pinyin: 'X' },
  { city: '新乡', adcode: '410700', pinyin: 'X' },
  // Y
  { city: '烟台', adcode: '370600', pinyin: 'Y' },
  { city: '银川', adcode: '640100', pinyin: 'Y' },
  { city: '扬州', adcode: '321000', pinyin: 'Y' },
  { city: '盐城', adcode: '320900', pinyin: 'Y' },
  { city: '宜昌', adcode: '420500', pinyin: 'Y' },
  { city: '岳阳', adcode: '430600', pinyin: 'Y' },
  // Z
  { city: '郑州', adcode: '410100', pinyin: 'Z' },
  { city: '珠海', adcode: '440400', pinyin: 'Z' },
  { city: '中山', adcode: '442000', pinyin: 'Z' },
  { city: '镇江', adcode: '321100', pinyin: 'Z' },
  { city: '淄博', adcode: '370300', pinyin: 'Z' },
  { city: '漳州', adcode: '350600', pinyin: 'Z' }
];

export const groupedCities: CityGroup[] = [];
export const alphabets: string[] = [];

// 🌟 将扁平数组转换为分组结构，供 UI 渲染使用
rawCityList.forEach(item => {
  let group = groupedCities.find(g => g.letter === item.pinyin);
  if (!group) {
    group = { letter: item.pinyin, cities: [] };
    groupedCities.push(group);
    alphabets.push(item.pinyin); // 提取出 [B, C, D, G...] 供右侧导航条使用
  }
  group.cities.push({ city: item.city, adcode: item.adcode });
});