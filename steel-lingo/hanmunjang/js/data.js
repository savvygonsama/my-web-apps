/* 한문장 — 캐릭터와 고정 대사
   스틸 그레이드 가챠 친구들. 맡는 일과 말투는 스틸링고 입문과 같다.
   포오 = 시작과 끝 / 씨알 = 숫자·횟수 / 이지 = 해설·함정 / 타래 = 문장이 늘어날 때(스프링) / 도금이 = 격려 */
window.NY = window.NY || {};

NY.CHARS = {
  poo:    { name: "포오",  faces: ["basic","relief","surprise","tired"] },
  ssial:  { name: "씨알",  faces: ["basic","shock","fire","happy"] },
  eg:     { name: "이지",  faces: ["polite","calm","work","off"] },
  tarae:  { name: "타래",  faces: ["happy","puzzled","surprised","serious"] },
  dogeum: { name: "도금이", faces: ["relaxed","happy","curious","grin"] }
};

/* 블록 역할 — 색과 이름. 완성 화면의 범례에도 쓴다. */
NY.ROLES = {
  subj:   { name: "주제",   c: "navy" },
  subjga: { name: "주어",   c: "navy" },
  topic:  { name: "화제",   c: "navy" },
  obj:    { name: "목적어", c: "red" },
  name:   { name: "이름",   c: "red" },
  plan:   { name: "예정",   c: "red" },
  verb:   { name: "동사",   c: "ink" },
  pred:   { name: "서술",   c: "ink" },
  time:   { name: "때",     c: "blue" },
  clause: { name: "때(절)", c: "blue" },
  seq:    { name: "이어짐", c: "blue" },
  comp:   { name: "비교",   c: "blue" },
  cond:   { name: "조건",   c: "blue" },
  place:  { name: "장소",   c: "teal" },
  dest:   { name: "가는 곳", c: "teal" },
  from:   { name: "출발점", c: "teal" },
  aim:    { name: "목적",   c: "teal" },
  way:    { name: "수단",   c: "plum" },
  mod:    { name: "꾸밈",   c: "plum" },
  tgt:    { name: "대상",   c: "plum" },
  with:   { name: "함께",   c: "gold" },
  qty:    { name: "수량",   c: "gold" },
  list:   { name: "나열",   c: "gold" },
  deg:    { name: "정도",   c: "gold" },
  reason: { name: "이유",   c: "gold" },
  pre:    { name: "쿠션말", c: "gold" }
};

/* {n}=끝낸 날 수, {t}=전체 날 수, {k}=오늘 단계 수, {b}=완성 블록 수 */
NY.LINES = {
  intro: [
    { who: "poo", face: "basic", text: "포오. 하루 한 문장. 시작이랑 끝은 내가 맡아." },
    { who: "ssial", face: "basic", text: "씨알이다. 한 단계에 세 번. 횟수는 내가 센다." },
    { who: "eg", face: "polite", text: "이지예요. 한국어대로 옮기면 틀리는 곳은 제가 짚어 드릴게요." },
    { who: "tarae", face: "happy", text: "타래예요! 문장이 늘어날 때마다 저도 늘어나요. 뾰잉~" },
    { who: "dogeum", face: "relaxed", text: "도금이야~ 길어져도 괜찮잖아~ 하나씩 붙인 거잖아~" }
  ],
  start: [
    { who: "poo", face: "basic", text: "왔네. 오늘은 한 문장, {k}단계. 10분이면 돼." },
    { who: "poo", face: "basic", text: "시작하자. 짧은 데서 출발해." }
  ],
  back: [
    { who: "poo", face: "relief", text: "왔네. 멈춘 데서부터 하자." }
  ],
  warm: [
    { who: "poo", face: "relief", text: "어제 문장부터 한 번. 입 풀고 가자." }
  ],
  read3: [
    { who: "ssial", face: "basic", text: "마지막 세 번째. 소리랑 동시에 읽어라." }
  ],
  quiz: [
    { who: "eg", face: "work", text: "블록을 순서대로 눌러 주세요. 자연스러운 순서면 다 정답이에요." }
  ],
  wrong: [
    { who: "dogeum", face: "relaxed", text: "괜찮잖아~ 끝은 동사잖아~ 뒤에서부터 생각해 봐~" },
    { who: "dogeum", face: "curious", text: "비슷하잖아~ 아까 붙인 순서 떠올려 봐~" }
  ],
  quizOk: [
    { who: "dogeum", face: "happy", text: "다 맞췄잖아~ 이제 한 번에 읽어 보자~" }
  ],
  final: [
    { who: "ssial", face: "fire", text: "블록 {b}개짜리 문장이다. 처음부터 끝까지 세 번." }
  ],
  done: [
    { who: "poo", face: "relief", text: "오늘 끝. 퇴근." },
    { who: "poo", face: "basic", text: "됐어. 더 하고 싶으면 다음 문장도 열려 있어." }
  ],
  progress: [
    { who: "ssial", face: "happy", text: "{t}일 중 {n}일. 완성한 문장 {n}개는 아래 목록에서 언제든 다시." }
  ],
  wait: [
    { who: "poo", face: "tired", text: "오늘 한 문장은 끝났어. 더 하고 싶으면 다음 문장도 바로 열려 있어." },
    { who: "dogeum", face: "grin", text: "하루 한 문장이 딱 좋긴 한데~ 더 하고 싶으면 해도 되잖아~" }
  ],
  all: [
    { who: "poo", face: "relief", text: "서른 문장 끝. 수고했어." },
    { who: "dogeum", face: "happy", text: "다 했잖아~ 처음 문장이랑 비교해 봐~ 대단하잖아~" }
  ],
  locked: [
    { who: "eg", face: "calm", text: "다음 문장은 지금 만드는 중이에요. 조금만 기다려 주세요." }
  ]
};
