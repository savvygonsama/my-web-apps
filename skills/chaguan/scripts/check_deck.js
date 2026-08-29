#!/usr/bin/env node
/*
 * 쉐도잉 회차 검증기 — 茶馆(중국어) / ROUNDTABLE(영어) 공용
 *
 *   node check_deck.js --zh deck-c2d1.json
 *   node check_deck.js --en deck-w2d1.json
 *
 * 앱은 붙여넣은 내용을 JSON.parse 로 통째로 읽는다. 한 글자만 어긋나도
 * "형식이 맞지 않습니다"라고만 하고 어디가 문제인지는 알려 주지 않는다.
 * 이 스크립트가 그 자리를 대신한다.
 *
 * 중국어판에서 가장 자주 깨지는 두 곳을 특히 본다:
 *   - ck(끊어읽기)를 이었을 때 원문과 다른 것
 *   - 병음 음절 수가 한자 수와 맞지 않는 것
 */

const fs = require("fs");

const K_ZH = ["word", "expr", "grammar", "measure", "pron", "culture", "idiom"];
const K_EN = ["idiom", "colloquial", "phrasal", "collocation", "business", "grammar"];

const HANZI = /[一-鿿]/g;

const errors = [];
const warns  = [];
const err  = m => errors.push(m);
const warn = m => warns.push(m);

/* ---------- 인자 ---------- */

const args = process.argv.slice(2);
const lang = args.includes("--zh") ? "zh" : args.includes("--en") ? "en" : null;
const file = args.find(a => !a.startsWith("--"));

if (!lang || !file) {
  console.error("쓰는 법:\n  node check_deck.js --zh <파일.json>\n  node check_deck.js --en <파일.json>");
  process.exit(2);
}

const raw = fs.readFileSync(file, "utf8").trim();

if (!raw.startsWith("[")) {
  err("파일이 대괄호 [ 로 시작하지 않습니다. 앱은 JSON 배열만 받습니다. "
    + "설명 문장이나 ```json 표시가 앞에 붙어 있지 않은지 확인하세요.");
}

let deck;
try {
  deck = JSON.parse(raw);
} catch (e) {
  console.error("JSON 문법 오류입니다. 앱은 이 내용을 거부합니다.\n  " + e.message);
  process.exit(1);
}
if (!Array.isArray(deck)) { console.error("최상위가 배열이 아닙니다. [ { ... } ] 모양이어야 합니다."); process.exit(1); }

function need(o, k, label) {
  if (o == null || o[k] === undefined || o[k] === "") { err(`${label}.${k} 가 비어 있습니다`); return false; }
  return true;
}

/* 병음 음절 수 — 모음 덩어리 하나가 한 음절이다.
   성조 부호는 유니코드 분해로 떼어 낸 뒤 본다(ā → a + 결합기호). */
function syllables(py) {
  const flat = String(py).normalize("NFD").replace(/[̀-ͯ]/g, "");
  let n = 0, inV = false;
  for (const ch of flat) {
    const v = /[aeiouüv]/i.test(ch);
    if (v && !inV) n++;
    inV = v;
  }
  return n;
}

function hanziCount(s) { return (String(s).match(HANZI) || []).length; }

/* ---------- 회차 검사 ---------- */

function checkItem(d, tag) {
  ["id", "day", "cat", "level", "title", "titleKo"].forEach(k => need(d, k, tag));
  if (lang === "zh") need(d, "titlePy", tag);

  if (typeof d.day !== "number") err(`${tag}.day 는 숫자여야 합니다`);
  const wantPrefix = lang === "zh" ? "c" : "w";
  if (typeof d.id === "string" && !d.id.startsWith(wantPrefix)) {
    warn(`${tag}.id 가 "${wantPrefix}" 로 시작하지 않습니다 (지금: ${d.id}). `
       + `${lang === "zh" ? "茶馆은 c2d1" : "ROUNDTABLE은 w2d1"} 형태를 씁니다`);
  }

  if (!d.names || !d.names.A || !d.names.B) err(`${tag}.names 에 A 와 B 가 있어야 합니다`);

  const brief = d.brief || [];
  if (brief.length !== 4) err(`${tag}.brief 는 4문단이어야 합니다 (지금 ${brief.length}문단)`);

  if (lang === "zh") {
    const V = d.vocab || [];
    if (!V.length) err(`${tag}.vocab 가 비어 있습니다`);
    V.forEach((v, i) => ["w", "p", "m", "lv"].forEach(k => need(v, k, `${tag}.vocab[${i}]`)));
  } else if (d.vocab) {
    warn(`${tag}: ROUNDTABLE 에는 vocab 필드가 없습니다. 빼는 편이 깔끔합니다`);
  }

  /* lines */
  const L = d.lines || [];
  if (!L.length) { err(`${tag}.lines 가 비어 있습니다`); return; }
  if (L.length !== 20) warn(`${tag}.lines 가 ${L.length}줄입니다. 기준은 20줄입니다`);

  const KS = lang === "zh" ? K_ZH : K_EN;
  const textKey = lang === "zh" ? "zh" : "en";

  L.forEach((l, i) => {
    const lab = `${tag}.lines[${i}]`;
    if (l.s !== "A" && l.s !== "B") err(`${lab}.s 는 "A" 또는 "B" 여야 합니다 (지금: ${l.s})`);
    else if (i > 0 && L[i - 1].s === l.s) err(`${lab}.s 가 앞 줄과 같습니다. A/B 가 번갈아야 합니다`);

    need(l, textKey, lab);
    need(l, "ko", lab);

    const text = l[textKey];
    if (typeof text === "string") {
      if (lang === "zh") {
        const hz = hanziCount(text);
        if (hz < 15 || hz > 28) warn(`${lab}: 한자 ${hz}자입니다. 기준은 15~28자 — ${text}`);
      } else {
        const wc = text.trim().split(/\s+/).filter(Boolean).length;
        if (wc < 10 || wc > 18) warn(`${lab}: ${wc}단어입니다. 기준은 10~18단어 — ${text}`);
      }
    }

    if (lang === "zh") {
      /* 병음 */
      if (need(l, "py", lab) && typeof text === "string") {
        const syl = syllables(l.py);
        const hz  = hanziCount(text);
        const er  = (text.match(/儿/g) || []).length;      // 儿화면 음절이 줄어든다
        if (syl !== hz && syl !== hz - er) {
          warn(`${lab}: 병음 음절 ${syl}개, 한자 ${hz}자로 어긋납니다`
             + (er ? ` (儿 ${er}개 감안해도)` : "") + `\n      ${text}\n      ${l.py}`);
        }
      }

      /* 끊어읽기 */
      const ck = l.ck;
      if (!Array.isArray(ck) || !ck.length) err(`${lab}.ck 가 없습니다. 한 줄을 2~4덩어리로 나눠 주세요`);
      else {
        if (ck.length < 2 || ck.length > 4) warn(`${lab}.ck 가 ${ck.length}덩어리입니다. 2~4덩어리가 기준입니다`);
        let bad = false;
        ck.forEach((p, j) => {
          if (!Array.isArray(p) || p.length !== 2) { err(`${lab}.ck[${j}] 는 [한자, 병음] 두 칸이어야 합니다`); bad = true; }
        });
        if (!bad && typeof text === "string") {
          /* 실제 회차는 덩어리 사이의 쉼표와 끝의 마침표를 빼고 적는다.
             그러니 문장부호를 걷어 낸 뒤 글자만 견준다 — 빠지거나 더해진 글자를 잡는 것이 목적이다. */
          const bare = s => String(s).replace(/[，。、！？；：""''（）《》…·,.!?;:"'()\s]/g, "");
          const joined = ck.map(p => p[0]).join("");
          if (bare(joined) !== bare(text)) {
            err(`${lab}: ck 의 한자를 이어 붙인 결과가 원문과 다릅니다.\n`
              + `      원문: ${text}\n      결합: ${joined}`);
          }
        }
      }
    }

    /* notes */
    const N = l.notes || [];
    N.forEach((n, j) => {
      const nl = `${lab}.notes[${j}]`;
      ["t", "k", "m", "tip"].forEach(k => need(n, k, nl));
      if (lang === "zh") need(n, "p", nl);
      if (n.k && !KS.includes(n.k)) {
        err(`${nl}.k 가 "${n.k}" 입니다. 쓸 수 있는 값: ${KS.join(" / ")}`);
      }
    });
  });

  const noted = L.filter(l => (l.notes || []).length).length;
  if (noted < L.length / 2) {
    warn(`${tag}: notes 가 붙은 줄이 ${noted}/${L.length} 입니다. 새 표현이 나온 줄에는 붙여 주세요`);
  }

  /* keys */
  const KY = d.keys || [];
  if (!KY.length) err(`${tag}.keys 가 비어 있습니다`);
  else if (KY.length < 5) warn(`${tag}.keys 가 ${KY.length}개입니다. 6~8개가 기준입니다`);
  KY.forEach((k, i) => {
    const kl = `${tag}.keys[${i}]`;
    if (lang === "zh") ["zh", "py", "ko", "ex", "exPy", "exKo"].forEach(f => need(k, f, kl));
    else ["en", "ko", "ex"].forEach(f => need(k, f, kl));
  });

  /* out */
  const O = d.out || [];
  if (O.length !== 3) warn(`${tag}.out 이 ${O.length}개입니다. 3개가 기준입니다`);
  O.forEach((o, i) => ["q", "hint"].forEach(f => need(o, f, `${tag}.out[${i}]`)));
}

const ids = new Set();
deck.forEach((d, i) => {
  const tag = deck.length > 1 ? `[${i + 1}번째 회차 ${d.id || ""}]` : (d.id || "회차");
  if (d.id) {
    if (ids.has(d.id)) err(`${tag}: id 가 이 파일 안에서 겹칩니다`);
    ids.add(d.id);
  }
  checkItem(d, tag);
});

/* ---------- 결과 ---------- */

if (warns.length) {
  console.log(`\n확인해 보세요 (${warns.length}건)`);
  warns.forEach(w => console.log("  · " + w));
}

if (errors.length) {
  console.log(`\n고쳐야 합니다 (${errors.length}건)`);
  errors.forEach(e => console.log("  ✗ " + e));
  console.log("\n이대로 붙여넣으면 앱이 받지 않거나 화면이 어긋납니다.");
  process.exit(1);
}

console.log(`\n통과했습니다. ${lang === "zh" ? "茶馆" : "ROUNDTABLE"} 회차 ${deck.length}개, 형식 문제 없음.`);
console.log("남은 것은 사람이 볼 몫입니다 — 번역이 맞는지, 그 표현을 실제로 그렇게 쓰는지.");
console.log("앱의 '새 회화 추가 → 2단계 붙여넣기 칸'에 파일 내용을 통째로 붙여넣으면 됩니다.");
