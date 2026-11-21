/* BUILD-UP — 원고 검사
   실행: node tools/check.js   (buildup 폴더에서)
   - 회차 번호가 1부터 차례대로인지, 단계마다 새 덩어리 {역할:…} 가 있고 역할 이름이 맞는지
   - 각 단계에 한국어 뜻·해설(gram)이 있는지, 표현 노트 분류(k)가 맞는지
   - 앞 단계에서 붙인 덩어리가 다음 단계 문장에 그대로 남아 있는지(빠지면 '늘려 가기'가 아니다)
   - 조립 퀴즈 블록을 띄어쓰기로 이으면 완성 문장과 같은지, 정답 순서가 블록을 한 번씩 다 쓰는지 */
const fs = require("fs"), path = require("path"), vm = require("vm");
const root = path.join(__dirname, "..");
const ctx = {}; ctx.window = ctx.self = ctx; vm.createContext(ctx);
["js/data.js", "js/days-w1.js", "js/days-w2.js", "js/days-w3.js", "js/days-w4.js"].forEach((f) => {
  const p = path.join(root, f); if (fs.existsSync(p)) vm.runInContext(fs.readFileSync(p, "utf8"), ctx);
});
const BU = ctx.BU, errs = [], warn = [];
const plain = (r) => r.replace(/\{\w+:/g, "").replace(/\}/g, "");
const fresh = (r) => [...r.matchAll(/\{(\w+):([^}]*)\}/g)].map((m) => ({ role: m[1], t: m[2] }));
BU.DAYS.forEach((D, di) => {
  const w = `DAY ${D.day}`;
  if (D.day !== di + 1) errs.push(`${w}: 순서가 ${di + 1}번째`);
  ["title", "titleKo", "cat", "gist"].forEach((k) => { if (!D[k]) errs.push(`${w}: ${k} 없음`); });
  D.steps.forEach((s, i) => {
    const ws = `${w} ${i + 1}단계`;
    const o = (s.r.match(/\{/g) || []).length, c = (s.r.match(/\}/g) || []).length;
    if (o !== c) errs.push(`${ws}: { } 짝`);
    const fr = fresh(s.r);
    if (!fr.length) errs.push(`${ws}: 새 덩어리 {역할:…} 없음`);
    fr.forEach((f) => { if (!BU.ROLES[f.role]) errs.push(`${ws}: 역할 ${f.role} 없음`); });
    if (!s.ko) errs.push(`${ws}: 한국어 뜻 없음`);
    if (!(s.gram || []).length) errs.push(`${ws}: 해설(gram) 없음`);
    (s.notes || []).forEach((n) => { if (!BU.KINDS[n.k]) errs.push(`${ws}: 노트 분류 ${n.k} 없음`); if (!n.t || !n.m) errs.push(`${ws}: 노트 t/m 없음`); });
    if (/\s{2,}|\s[,.]/.test(plain(s.r))) errs.push(`${ws}: 띄어쓰기 이상 「${plain(s.r)}」`);
    if (i > 0) {
      // 앞 단계의 새 덩어리가 이 단계 문장에 남아 있는가(바뀌었으면 경고만)
      fresh(D.steps[i - 1].r).forEach((f) => { if (!plain(s.r).includes(f.t)) warn.push(`${ws}: 앞 단계 덩어리 「${f.t}」가 바뀜`); });
    }
  });
  const fin = plain(D.steps[D.steps.length - 1].r);
  const joined = D.quiz.blocks.join(" ");
  if (fin !== joined) errs.push(`${w} 퀴즈: 블록 「${joined}」\n      ≠ 완성 「${fin}」`);
  D.quiz.orders.forEach((o) => {
    if (o.length !== D.quiz.blocks.length || [...o].sort((a, b) => a - b).some((x, k) => x !== k)) errs.push(`${w} 퀴즈: 순서 ${o} 이상`);
  });
});
if (warn.length) console.log("참고 " + warn.length + "개 (단계에서 덩어리 모양이 바뀐 곳)\n- " + warn.join("\n- "));
if (errs.length) { console.log("문제 " + errs.length + "개\n- " + errs.join("\n- ")); process.exit(1); }
if (BU.DAYS.length !== BU.TOTAL) console.log(`경고: ${BU.DAYS.length}회차뿐입니다(전체 ${BU.TOTAL})`);
console.log(`통과: ${BU.DAYS.length}회차, 단계 ${BU.DAYS.reduce((a, d) => a + d.steps.length, 0)}개`);
