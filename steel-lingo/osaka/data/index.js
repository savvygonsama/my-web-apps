// 이 앱의 설정과 콘텐츠 파일 목록 — 앱과 오프라인 저장(service worker)이 함께 읽는다.
// 여행편은 도시마다 폴더 하나. 새 도시를 만들 때는 이 폴더를 복사해 SH_APP과 data/ 대본만 바꾼다.
self.SH_APP = {
  storeKey: "osaka.v1",             // 기기 저장 이름. 편마다 달라야 서로 기록이 섞이지 않는다
  cachePrefix: "osaka-",            // 오프라인 저장 이름. 편마다 달라야 한다
  titleText: "大阪編",
  titleHTML: "<ruby>大阪<rt>おおさか</rt></ruby><ruby>編<rt>へん</rt></ruby>",
  tagline: "여행편 ① 링고의 오사카 먹방 2박 3일",
  from: "GMP",
  to: "KIX",
  passenger: "金リンゴ / 休暇中",
  cls: "여행 · 2박 3일",
  trip: "여행",
  scoreLabel: "현지 이해도",
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
