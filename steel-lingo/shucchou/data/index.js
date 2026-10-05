// 이 앱의 설정과 콘텐츠 파일 목록 — 앱과 오프라인 저장(service worker)이 함께 읽는다.
// 같은 엔진으로 다른 편(여행편 등)을 만들 때는 이 파일의 SH_APP과 data/ 폴더만 바꾸면 된다.
self.SH_APP = {
  storeKey: "shucchou.v1",          // 기기 저장 이름. 편마다 달라야 서로 기록이 섞이지 않는다
  cachePrefix: "shucchou-",          // 오프라인 저장 이름. 편마다 달라야 한다
  titleText: "出張編",
  titleHTML: "<ruby>出張<rt>しゅっちょう</rt></ruby><ruby>編<rt>へん</rt></ruby>",
  tagline: "철강맨의 일본 출장 서바이벌",
  from: "GMP",
  to: "HND",
  passenger: "金リンゴ / ミレ製鉄",
  cls: "영업 · 3박 4일",
  trip: "출장",                       // '출장 일정표', '출장 떠나기' 같은 버튼 문구
  scoreLabel: "출장 점수",
  noteName: "出張ノート",
  mapTitle: "出張スケジュール",
  itin: "ITINERARY · 3박 4일",
  mascotLabel: "출장 가는 코일 마스코트"
};

// 콘텐츠 파일 목록. 새 챕터를 붙일 때: data/ 에 chapterN.js 를 만들고 아래 목록에 파일 이름 한 줄을 추가한다.
self.SH_DATA_FILES = [
  "chapter1.js",
  "chapter2.js",
  "chapter3.js",
  "chapter4.js",
  "chapter5.js",
  "chapter6.js",
  "chapter7.js",
  "chapter8.js",
  "season.js"
];
