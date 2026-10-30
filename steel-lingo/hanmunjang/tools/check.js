/* 한문장 — 원고 검사
   실행: node tools/check.js   (앱 폴더에서)
   - 후리가나 [읽기]가 한자 바로 뒤에 붙었는지, { } 짝이 맞는지, 역할 이름이 맞는지
   - 단계마다 새 블록이 하나 이상 있고, 새 단어 해설이 있는지
   - 조립 퀴즈 블록을 이으면 완성 문장(쉼표·마침표 뺀 것)과 같은지, 정답 순서가 블록을 한 번씩 다 쓰는지
   - 말풍선 캐릭터·표정이 캐릭터 시트에 있는 것인지 */
const fs = require("fs"), path = require("path"), vm = require("vm");
const root = path.join(__dirname, "..");
const ctx = {}; ctx.window = ctx.self = ctx; vm.createContext(ctx);
["js/data.js", "js/days.js"].forEach((f) => vm.runInContext(fs.readFileSync(path.join(root, f), "utf8"), ctx));
const NY = ctx.NY;
const errs = [];
const plain = (r) => r.replace(/\{\w+:/g, "").replace(/\}/g, "").replace(/([一-龯々〆ヶ]+)\[([^\]]+)\]/g, "$1");
const sayOk = (s, where) => {
  if (!s) return;
  const c = NY.CHARS[s.who];
  if (!c || !c.faces.includes(s.face)) errs.push(`${where}: 말풍선 ${s.who}_${s.face} 없음`);
};
NY.DAYS.forEach((D, di) => {
  if (D.day !== di + 1) errs.push(`${D.day}일차: 순서가 ${di + 1}번째`);
  D.steps.forEach((s, i) => {
    const w = `${D.day}일차 ${i + 1}단계`;
    s.r.replace(/\[/g, (m, at) => { if (!/[一-龯々〆ヶ]/.test(s.r[at - 1])) errs.push(`${w}: [ 앞에 한자가 없음 (${s.r.slice(Math.max(0, at - 3), at + 4)})`); });
    const opens = (s.r.match(/\{/g) || []).length, closes = (s.r.match(/\}/g) || []).length;
    if (opens !== closes) errs.push(`${w}: { } 짝`);
    if (!opens) errs.push(`${w}: 새 블록 표시 {역할:…} 없음`);
    (s.r.match(/\{(\w+):/g) || []).forEach((m) => { const r = m.slice(1, -1); if (!NY.ROLES[r]) errs.push(`${w}: 역할 ${r} 없음`); });
    const bare = s.r.replace(/[一-龯々〆ヶ]+\[[^\]]+\]/g, "");
    if (/[一-龯]/.test(bare)) errs.push(`${w}: 읽기가 없는 한자 (${bare.match(/[一-龯]+/)[0]})`);
    if (!s.ko) errs.push(`${w}: 한국어 뜻 없음`);
    if (!(s.words || []).length) errs.push(`${w}: 단어 해설 없음`);
    if (!(s.gram || []).length) errs.push(`${w}: 문법 해설 없음`);
    sayOk(s.say, w);
  });
  const fin = plain(D.steps[D.steps.length - 1].r).replace(/[、。]/g, "");
  const joined = D.quiz.blocks.join("");
  if (fin !== joined) errs.push(`${D.day}일차 퀴즈: 블록 「${joined}」 ≠ 완성 문장 「${fin}」`);
  D.quiz.orders.forEach((o) => {
    if (o.length !== D.quiz.blocks.length || [...o].sort((a, b) => a - b).some((x, k) => x !== k)) errs.push(`${D.day}일차 퀴즈: 순서 ${o} 가 블록을 한 번씩 쓰지 않음`);
  });
});
Object.keys(NY.LINES).forEach((k) => NY.LINES[k].forEach((l, i) => sayOk(l, `LINES.${k}[${i}]`)));
Object.entries(NY.CHARS).forEach(([k, c]) => c.faces.forEach((f) => { if (!fs.existsSync(path.join(root, "char", `${k}_${f}.webp`))) errs.push(`char/${k}_${f}.webp 없음`); }));
if (errs.length) { console.log("문제 " + errs.length + "개\n- " + errs.join("\n- ")); process.exit(1); }
console.log(`통과: ${NY.DAYS.length}일치, 단계 ${NY.DAYS.reduce((a, d) => a + d.steps.length, 0)}개`);
