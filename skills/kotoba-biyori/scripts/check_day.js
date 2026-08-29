#!/usr/bin/env node
/*
 * ことば日和 회차 검증기
 *
 *   node check_day.js day31.js
 *
 * 개수·필드 같은 형식과 함께, 이 앱에서 가장 자주 깨지는 것을 잡는다:
 * 표기(ja)와 읽기(kana)가 맞물리는지. 맞물리지 않으면 앱이 후리가나를 붙이지 못하고
 * 한자가 맨몸으로 나온다. 아래 align()은 앱에 들어 있는 것과 같은 알고리즘이다.
 */

const fs = require("fs");

const HAN = /[㐀-䶿一-鿿豈-﫿々〇]/;
const isHan = c => c !== "〇" && HAN.test(c);

/* 표기와 읽기를 맞춰 한자 덩어리마다 읽기를 나눈다. 맞물리지 않으면 null. */
function align(word, reading) {
  const segs = [];
  let i = 0;
  while (i < word.length) {
    const han = isHan(word[i]);
    let j = i;
    while (j < word.length && isHan(word[j]) === han) j++;
    segs.push({ t: word.slice(i, j), han });
    i = j;
  }
  const out = [];
  let r = 0;
  for (let k = 0; k < segs.length; k++) {
    const s = segs[k];
    if (!s.han) {
      if (!reading.startsWith(s.t, r)) return null;
      r += s.t.length;
      out.push({ t: s.t, r: "" });
      continue;
    }
    const next = segs[k + 1];
    let end;
    if (!next) end = reading.length;
    else { end = reading.indexOf(next.t, r + 1); if (end < 0) return null; }
    const rd = reading.slice(r, end);
    if (!rd) return null;
    out.push({ t: s.t, r: rd });
    r = end;
  }
  return r === reading.length ? out : null;
}

const errors = [];
const warns  = [];
const err  = m => errors.push(m);
const warn = m => warns.push(m);

/* ---------- 파일 읽기 ---------- */

const file = process.argv[2];
if (!file) { console.error("쓰는 법: node check_day.js <회차파일.js>"); process.exit(2); }

let src = fs.readFileSync(file, "utf8").trim();
src = src.replace(/^\s*(?:const|let|var)\s+[A-Za-z_$][\w$]*\s*=\s*/, "").replace(/[;,]\s*$/, "");

let parsed;
try { parsed = new Function("return (" + src + ")")(); }
catch (e) {
  console.error("문법 오류로 읽을 수 없습니다. 이 상태로 앱에 붙이면 앱 전체가 멈춥니다.\n  " + e.message);
  process.exit(1);
}
const days = Array.isArray(parsed) ? parsed : [parsed];

function need(obj, key, label) {
  if (obj == null || obj[key] === undefined || obj[key] === "") { err(`${label}.${key} 가 비어 있습니다`); return false; }
  return true;
}

/* 후리가나 표기를 실수로 넣지 않았는지 */
function noRuby(label, s) {
  if (typeof s === "string" && /[\[\]《》]/.test(s)) {
    err(`${label}: 이 앱은 후리가나를 직접 달지 않습니다. 気になる (○) / 気[き]になる (×) — 지금: ${s}`);
  }
}

/* 표기·읽기 정렬 */
function checkAlign(label, ja, kana) {
  if (typeof ja !== "string" || typeof kana !== "string") return;
  if (!HAN.test(ja)) return;                       // 한자가 없으면 볼 것이 없다

  /* 「元気 / 人気」처럼 슬래시로 둘을 묶은 경우는 각각 본다 */
  const jas = ja.split("/").map(s => s.trim());
  const kns = kana.split("/").map(s => s.trim());
  if (jas.length !== kns.length) {
    err(`${label}: ja 와 kana 의 「/」 개수가 다릅니다 — ${ja} / ${kana}`);
    return;
  }
  jas.forEach((j, i) => {
    if (!HAN.test(j)) return;
    if (!align(j, kns[i])) {
      err(`${label}: 표기와 읽기가 맞물리지 않아 후리가나가 붙지 않습니다.\n`
        + `      표기: ${j}\n      읽기: ${kns[i]}\n`
        + `      → 읽기에 표기의 가나(오쿠리가나)가 그대로 들어 있는지 확인하세요.`);
    }
  });
}

/* ---------- 회차 검사 ---------- */

function checkDay(d, tag) {
  if (typeof d.no !== "number") err(`${tag}: no 는 숫자여야 합니다`);
  ["theme", "themeKo", "lv"].forEach(k => need(d, k, tag));
  noRuby(`${tag}.theme`, d.theme);

  /* words */
  const W = d.words || [];
  if (W.length !== 10) err(`${tag}.words 는 10개여야 합니다 (지금 ${W.length}개)`);
  W.forEach((w, i) => {
    const lab = `${tag}.words[${i}] (${w && w.ja})`;
    ["ja", "kana", "ko", "note"].forEach(k => need(w, k, lab));
    noRuby(`${lab}.ja`, w.ja);
    checkAlign(lab, w.ja, w.kana);

    const E = w.exs || [];
    if (E.length < 2 || E.length > 3) err(`${lab}.exs 는 2~3개여야 합니다 (지금 ${E.length}개)`);
    E.forEach((e, j) => {
      const el = `${lab}.exs[${j}]`;
      ["s", "t"].forEach(k => need(e, k, el));
      noRuby(`${el}.s`, e.s);
      /* 예문이 그 단어를 담고 있는지 — 활용형까지 감안해 한자 덩어리로 느슨하게 본다 */
      if (typeof e.s === "string" && typeof w.ja === "string") {
        const runs = w.ja.match(/[㐀-䶿一-鿿豈-﫿々]+/g) || [];
        const stem = runs.sort((a, b) => b.length - a.length)[0];
        if (stem && !e.s.includes(stem)) {
          warn(`${el}: 예문에 「${w.ja}」가 보이지 않습니다 (「${stem}」로 확인). 일부러 그런 것이 아니면 고치세요`);
        }
      }
    });
  });

  /* root / branches */
  if (need(d, "root", tag) && (typeof d.root !== "string" || [...d.root].length !== 1)) {
    err(`${tag}.root 는 한자 한 글자여야 합니다 (지금: ${d.root})`);
  }
  need(d, "rootKo", tag);

  const B = d.branches || [];
  if (B.length < 4 || B.length > 8) warn(`${tag}.branches 가 ${B.length}개입니다. 보통 6개입니다`);
  const wordSet = new Set(W.map(w => w && w.ja));
  B.forEach((b, i) => {
    const lab = `${tag}.branches[${i}] (${b && b.ja})`;
    ["ja", "kana", "ko", "note"].forEach(k => need(b, k, lab));
    noRuby(`${lab}.ja`, b.ja);
    checkAlign(lab, b.ja, b.kana);
    if (wordSet.has(b.ja)) warn(`${lab}: words 에 이미 나온 말입니다. 가지는 새로 뻗는 말로 채우세요`);
    if (typeof b.ja === "string" && typeof d.root === "string" && !b.ja.includes(d.root)) {
      warn(`${lab}: 뿌리 한자 「${d.root}」가 들어 있지 않습니다`);
    }
  });

  /* quiz */
  const Q = d.quiz || [];
  if (Q.length !== 6) err(`${tag}.quiz 는 6문항이어야 합니다 (지금 ${Q.length}문항)`);
  Q.forEach((q, i) => {
    const lab = `${tag}.quiz[${i}]`;
    need(q, "q", lab);
    const o = q.opts || [];
    if (o.length !== 3) err(`${lab}.opts 는 3개여야 합니다 (지금 ${o.length}개)`);
    if (q.ans !== undefined) err(`${lab}: 이 앱의 정답 필드는 a 입니다 (ans 아님)`);
    if (!Number.isInteger(q.a) || q.a < 0 || q.a >= o.length) {
      err(`${lab}.a 는 0부터 ${Math.max(o.length - 1, 0)} 사이의 번호여야 합니다 (지금 ${q.a})`);
    }
  });

  /* bunka */
  const b = d.bunka;
  if (!b) err(`${tag}.bunka 가 없습니다`);
  else {
    ["cap", "title", "titleKo", "vs", "sign"].forEach(k => need(b, k, `${tag}.bunka`));
    const body = b.body || [], body2 = b.body2 || [];
    if (body.length !== 2)  err(`${tag}.bunka.body 는 2문단이어야 합니다 (지금 ${body.length}문단)`);
    if (body2.length !== 2) err(`${tag}.bunka.body2 는 2문단이어야 합니다 (지금 ${body2.length}문단)`);
    if (typeof b.vs === "string" && !b.vs.includes("<br>")) {
      warn(`${tag}.bunka.vs 에 <br> 가 없습니다. 두 줄을 나란히 놓는 자리입니다`);
    }
  }
}

days.forEach((d, i) => checkDay(d, days.length > 1 ? `[${i + 1}번째 객체]` : `${d.no}일차`));

/* ---------- 결과 ---------- */

if (warns.length) {
  console.log(`\n확인해 보세요 (${warns.length}건)`);
  warns.forEach(w => console.log("  · " + w));
}

if (errors.length) {
  console.log(`\n고쳐야 합니다 (${errors.length}건)`);
  errors.forEach(e => console.log("  ✗ " + e));
  console.log("\n이대로 앱에 붙이면 화면이 깨지거나 후리가나가 빠집니다.");
  process.exit(1);
}

console.log(`\n통과했습니다. 회차 ${days.length}개, 형식과 표기·읽기 정렬 모두 문제 없음.`);
console.log("다만 정렬이 맞는다고 읽기가 옳다는 뜻은 아닙니다. 어긋난 자리를 찾을 뿐,");
console.log("「着」를 「づ」로 읽어도 모양만 맞으면 통과합니다. 읽기 자체는 사람이 봐야 합니다.");
console.log("\n남은 것 —");
console.log("  1) 앱에 넣은 뒤 브라우저 콘솔에서 kbAudit() 를 실행해 FDICT 에 없는 한자를 채울 것");
console.log("  2) 읽기·예문·칼럼이 자연스럽고 사실인지 읽어서 확인할 것");
