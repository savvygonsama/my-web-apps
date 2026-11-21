/* BUILD-UP — 공통 설정
   역할(role)은 문장에 새로 붙은 덩어리가 어떤 일을 하는지 알려 주는 이름표다. 색과 이름은 여기서 정한다.
   한 단계에 새 덩어리는 하나가 원칙이다. 나중에 가운데에 끼워 넣을 자리가 있으면 처음부터 덩어리를 나눠 둔다
   ({core:The port was} {core:congested} → 다음 단계에서 so를 사이에 넣어도 앞 덩어리가 깨지지 않는다).
   원고는 js/days-w1.js ~ days-w4.js (BU.DAYS.push). 원고를 고친 뒤에는 node tools/check.js 로 검사한다. */
window.BU = window.BU || {};
BU.TOTAL = 30;
BU.DAYS = BU.DAYS || [];
BU.ROLES = {
  core:     { name: "뼈대",       c: "ink" },
  obj:      { name: "목적어",     c: "red" },
  mod:      { name: "꾸밈",       c: "plum" },
  quant:    { name: "수치·정도",  c: "gold" },
  time:     { name: "때",         c: "blue" },
  place:    { name: "범위·장소",  c: "teal" },
  reason:   { name: "이유",       c: "gold" },
  cond:     { name: "조건",       c: "blue" },
  contrast: { name: "양보·대조",  c: "plum" },
  purpose:  { name: "목적",       c: "teal" },
  result:   { name: "결과",       c: "gold" },
  rel:      { name: "관계절",     c: "plum" },
  part:     { name: "분사구",     c: "teal" },
  hedge:    { name: "완곡",       c: "plum" },
  focus:    { name: "강조",       c: "red" },
  link:     { name: "연결어",     c: "blue" },
  compl:    { name: "보어",       c: "teal" },
  clause:   { name: "명사절",     c: "teal" },
  compare:  { name: "비교",       c: "blue" },
  add:      { name: "덧붙임",     c: "red" }
};
/* 표현 노트 분류 — ROUNDTABLE과 같은 이름 */
BU.KINDS = { idiom: "관용", colloquial: "구어", phrasal: "구동사", collocation: "연어", business: "실무어", grammar: "문법" };
