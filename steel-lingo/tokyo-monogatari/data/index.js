// 이 앱의 설정과 콘텐츠 파일 목록 — 앱과 오프라인 저장(service worker)이 함께 읽는다.
// 東京物語는 大阪物語와 같은 분기형 엔진에 '한국어편 · 초급편 · 상급편' 세 판을 얹은 별도 앱이다.
// 판마다 기록이 따로 저장된다(storeKey + ".ko" / ".easy" / ".hard").
// v2: 이야기를 '하루토의 도쿄 안내'로 새로 썼다. 1판(자정의 골목 식당) 기록과 섞이지 않게 저장 이름을 올렸다.
self.SH_APP = {
  storeKey: "tokyomono.v2",         // 기기 저장 이름(뒤에 판 이름이 붙는다)
  cachePrefix: "tokyomono-",        // 오프라인 저장 이름
  titleText: "東京物語",
  titleHTML: "<ruby>東京<rt>とうきょう</rt></ruby><ruby>物語<rt>ものがたり</rt></ruby>",
  titleKo: "도쿄 이야기",
  tagline: "여행편 ② 열 살 안내인과 걷는 도쿄 2박 3일",
  from: "SEL",
  to: "TYO",
  passenger: "金リンゴ / 休暇中",
  passengerKo: "김링고 / 휴가 중",
  trip: "여행",
  noteName: "旅ノート",
  noteKo: "여행 노트",
  mapTitle: "旅のしおり",
  mapKo: "여행 일정표",
  itin: "ITINERARY · 2박 3일",
  mascotLabel: "여행 가는 코일 마스코트"
};

// 콘텐츠 파일 목록. 새 장을 붙일 때: data/ 에 chapterN.js 를 만들고 아래 목록에 한 줄 추가.
self.SH_DATA_FILES = [
  "chapter1.js",
  "chapter2.js",
  "chapter3.js",
  "chapter4.js",
  "chapter5.js",
  "chapter6.js",
  "season.js"
];
