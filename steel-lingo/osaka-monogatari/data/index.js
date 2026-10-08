// 이 앱의 설정과 콘텐츠 파일 목록 — 앱과 오프라인 저장(service worker)이 함께 읽는다.
// 大阪物語는 大阪編(steel-lingo/osaka)과 같은 여행을 정답 없는 분기 이야기로 다시 쓴 별도 앱이다.
// 기록이 섞이지 않게 저장 이름과 오프라인 저장 이름을 大阪編과 다르게 둔다.
self.SH_APP = {
  storeKey: "osakamono.v2",         // 기기 저장 이름 (v2: 바뀐 캐리어 이야기로 새로 씀)
  cachePrefix: "osakamono-",        // 오프라인 저장 이름
  titleText: "大阪物語",
  titleHTML: "<ruby>大阪<rt>おおさか</rt></ruby><ruby>物語<rt>ものがたり</rt></ruby>",
  tagline: "바뀐 캐리어의 주인을 찾아라. 말 한마디로 갈라지는 오사카 2박 3일",
  from: "GMP",
  to: "KIX",
  passenger: "金リンゴ / 休暇中",
  trip: "여행",
  noteName: "旅ノート",
  mapTitle: "旅のしおり",
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
