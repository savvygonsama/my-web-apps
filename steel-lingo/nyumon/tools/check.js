/* 스틸링고 입문 — 데이터 점검
   실행: node tools/check.js  (앱 폴더에서)
   1) 연습 단어가 그 회차까지 배운 글자로만 되어 있는가
   2) 모든 글자·단어에 음성 파일이 있는가
   3) 글자마다 한글 소리가 있는가 */
const fs = require("fs"), vm = require("vm"), path = require("path");
const root = path.join(__dirname, "..");
const ctx = {}; ctx.window = ctx; ctx.self = ctx; vm.createContext(ctx);
vm.runInContext(fs.readFileSync(path.join(root, "js/data.js"), "utf8"), ctx);
const amPath = path.join(root, "audio/manifest.js");
if (fs.existsSync(amPath)) vm.runInContext(fs.readFileSync(amPath, "utf8"), ctx);
const NY = ctx.window.NY, A = NY.AUDIO || {};
const errors = [], learned = new Set();
for (const L of NY.LESSONS) {
  L.new.forEach((k) => { learned.add(k); if (!NY.KANA[k]) errors.push(`${L.no}회차: ${k} 한글 소리 없음`); });
  const words = [...Object.values(L.cards).map((c) => c[0]), ...L.read.map((r) => r[0]), L.reward[0]];
  for (const w of words) {
    for (const ch of w.replace(/\s/g, "")) if (!learned.has(ch)) errors.push(`${L.no}회차: 「${w}」의 「${ch}」는 아직 안 배운 글자`);
    if (!A[w]) errors.push(`${L.no}회차: 「${w}」 음성 파일 없음`);
  }
  L.new.forEach((k) => { if (!L.cards[k]) errors.push(`${L.no}회차: ${k} 카드 단어 없음`); });
  L.new.forEach((k) => { if (!NY.ORIGIN[k]) errors.push(`${L.no}회차: ${k} 유래 한자 없음`); });
  if (!L.rule || !NY.ROWS[L.rule.row]) errors.push(`${L.no}회차: 원리 카드 없음`);
  if (L.read.length < 4) errors.push(`${L.no}회차: 읽기 단어 4개 미만`);
  (L.compare || []).forEach(([x, y]) => [x, y].forEach((ch) => { if (!learned.has(ch)) errors.push(`${L.no}회차: 비교 글자 ${ch}는 아직 안 배움`); }));
  if (L.phrase) {
    for (const ch of L.phrase[0].replace(/\s/g, "")) if (!learned.has(ch)) errors.push(`${L.no}회차: 이어 읽기 「${L.phrase[0]}」의 「${ch}」는 아직 안 배운 글자`);
    if (!A[L.phrase[0]]) errors.push(`${L.no}회차: 이어 읽기 음성 없음`);
  }
  for (const k of Object.keys(NY.KANA)) if (!A["@" + k]) errors.push(`글자 ${k} 음성 없음`);
}
for (const f of Object.values(A)) if (!fs.existsSync(path.join(root, "audio", f))) errors.push(`파일 없음: audio/${f}`);
const lines = Object.values(NY.LINES).reduce((s, a) => s + a.length, 0);
if (lines > 30) errors.push(`고정 대사 ${lines}줄 — 30줄 상한 초과`);
const uniq = [...new Set(errors)];
console.log(uniq.length ? "❌ 오류 " + uniq.length + "건\n" + uniq.join("\n") : `✅ 오류 0건 (회차 ${NY.LESSONS.length}, 고정 대사 ${lines}줄, 음성 ${Object.keys(A).length}개)`);
process.exit(uniq.length ? 1 : 0);
