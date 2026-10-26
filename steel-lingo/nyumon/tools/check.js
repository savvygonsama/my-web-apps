/* 스틸링고 입문 — 데이터 점검
   실행: node tools/check.js  (앱 폴더에서)
   1) 단어·문장이 그 회차까지 배운 글자와 규칙(゛ 小 ー)으로만 되어 있는가 (한자·문장부호는 제외)
   2) 모든 글자·단어·문장에 음성 파일이 있는가
   3) 글자마다 한글 소리·유래가 있는가, 회차마다 원리 카드가 있는가
   4) 캐릭터 고정 대사가 30줄 이하인가 */
const fs = require("fs"), vm = require("vm"), path = require("path");
const root = path.join(__dirname, "..");
const ctx = {}; ctx.window = ctx; ctx.self = ctx; vm.createContext(ctx);
for (const f of ["js/data.js", "js/lessons.js", "audio/manifest.js"]) {
  const p = path.join(root, f);
  if (fs.existsSync(p)) vm.runInContext(fs.readFileSync(p, "utf8"), ctx);
}
const NY = ctx.NY, A = NY.AUDIO || {};
const errors = [];
const SMALL = { "ぁ":"あ","ぃ":"い","ぅ":"う","ぇ":"え","ぉ":"お","っ":"つ","ゃ":"や","ゅ":"ゆ","ょ":"よ",
                "ァ":"ア","ィ":"イ","ゥ":"ウ","ェ":"エ","ォ":"オ","ッ":"ツ","ャ":"ヤ","ュ":"ユ","ョ":"ヨ" };
const known = new Set();
const canRead = (ch) => {
  if (ch === "ー") return known.has("ー");
  if (ch === "ッ") return known.has("小") && known.has("ッ");   // 작은 ッ는 14회차에 기호로 배운다
  let c = ch;
  if (SMALL[c]) { if (!known.has("小")) return false; c = SMALL[c]; }
  const d = c.normalize("NFD");
  if (d.length > 1 && !known.has("゛")) return false;
  return known.has(d[0]);
};
const isKana = (c) => /[ぁ-ゖァ-ヺー]/.test(c);
const checkText = (no, label, t) => {
  for (const ch of t) if (isKana(ch) && !canRead(ch)) errors.push(`${no}회차 ${label}: 「${t}」의 「${ch}」는 아직 안 배운 글자`);
  if (!A[t]) errors.push(`${no}회차 ${label}: 「${t}」 음성 없음`);
};
for (const L of NY.LESSONS) {
  L.new.forEach((u) => { [...u.normalize("NFD")].forEach((c) => { if (c !== "゙" && c !== "゚") known.add(SMALL[c] || c); }); });
  (L.extra || []).forEach((x) => known.add(x));
  L.new.forEach((u) => {
    if (!NY.KANA[u]) errors.push(`${L.no}회차: ${u} 한글 소리 없음`);
    if (!A["@" + u]) errors.push(`${L.no}회차: ${u} 글자 음성 없음`);
    if (L.kind === "kana" && L.script === "hira" && !NY.ORIGIN[u]) errors.push(`${L.no}회차: ${u} 유래 한자 없음`);
    if (L.kind === "kana" && !L.cards[u]) errors.push(`${L.no}회차: ${u} 카드 단어 없음`);
  });
  if (!L.rule || !L.rule.lines.length) errors.push(`${L.no}회차: 원리 카드 없음`);
  if (!L.tip) errors.push(`${L.no}회차: 오늘의 한마디 없음`);
  if (L.kind !== "grad" && (L.read || []).length < 4) errors.push(`${L.no}회차: 읽기 4개 미만`);
  Object.values(L.cards || {}).forEach(([w]) => { if (w !== "ヲ") checkText(L.no, "카드", w); });
  (L.rows || []).forEach((r) => { checkText(L.no, "줄 예시", r.ex[0]); r.units.forEach((u) => { if (!A["@" + u]) errors.push(`${L.no}회차: ${u} 음성 없음`); }); });
  (L.groups || []).forEach((g) => g.items.forEach(([w]) => checkText(L.no, "묶음", w)));
  ["words", "read", "phrases"].forEach((k) => (L[k] || []).forEach(([w]) => checkText(L.no, k, w)));
  (L.compare || []).forEach(([a, b]) => [a, b].forEach((c) => {
    for (const ch of c) if (!canRead(ch)) errors.push(`${L.no}회차: 비교 글자 ${c}는 아직 안 배움`);
    if (!A["@" + c]) errors.push(`${L.no}회차: 비교 글자 ${c} 음성 없음`);
  }));
}
// 마지막 회차에는 Lite 문장의 모든 가나를 읽을 수 있어야 한다
const liteKana = NY.LITE_LINE.parts.map((p) => p.r).join("");
for (const ch of liteKana) if (isKana(ch) && !canRead(ch)) errors.push(`25회차까지 배워도 Lite 문장의 「${ch}」를 못 읽음`);
if (!A[NY.LITE_LINE.audio]) errors.push("Lite 문장 음성 없음");
for (const f of Object.values(A)) if (!fs.existsSync(path.join(root, "audio", f))) errors.push(`파일 없음: audio/${f}`);
const lines = Object.values(NY.LINES).reduce((s, a) => s + a.length, 0);
if (lines > 30) errors.push(`고정 대사 ${lines}줄 — 30줄 상한 초과`);
const uniq = [...new Set(errors)];
const words = new Set(NY.LESSONS.flatMap((L) => (L.words || []).concat(L.read || []).concat((L.groups || []).flatMap((g) => g.items)).map((x) => x[0])));
console.log(uniq.length ? "❌ 오류 " + uniq.length + "건\n" + uniq.join("\n") : `✅ 오류 0건 (회차 ${NY.LESSONS.length}, 단어 ${words.size}개, 고정 대사 ${lines}줄, 음성 키 ${Object.keys(A).length}개)`);
process.exit(uniq.length ? 1 : 0);
