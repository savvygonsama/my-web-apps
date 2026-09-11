#!/usr/bin/env node
/* ハングリンゴ Lite 회차 검증기
 *
 *   node check_day.js day6.js          회차 객체 하나만 담은 파일
 *   node check_day.js ../../hangul-lingo/lite/index.html   앱 전체
 *
 * 사람 눈으로 잘 안 잡히는 것만 본다 — 대괄호·《》 짝, parts 결합 일치,
 * 필드 대응, 개수 규칙, 퀴즈 정답 범위, 가타카나 섞임.
 * 번역이 맞는지, 설명이 초보자에게 통하는지는 스크립트가 못 잡는다. */

const fs = require("fs");
const path = process.argv[2];
if (!path) { console.error("파일을 지정하세요: node check_day.js day6.js"); process.exit(2); }

let src = fs.readFileSync(path, "utf8");
if (/\.html?$/i.test(path)) {
  const m = src.match(/const DATA = \[[\s\S]*?\n\];/);
  if (!m) { console.error("index.html 안에서 const DATA = [ ... ]; 를 찾지 못했습니다."); process.exit(2); }
  src = m[0];
}

let DATA;
try {
  DATA = /const DATA\s*=/.test(src)
    ? new Function(src + "; return DATA;")()
    : new Function("return (" + src.trim().replace(/[;,]\s*$/, "") + ");")();
} catch (e) {
  console.error("문법 오류입니다 — 앱에 넣으면 화면이 하얗게 됩니다.\n  " + e.message);
  process.exit(1);
}
const days = Array.isArray(DATA) ? DATA : [DATA];

const BRACE  = /\{([^{}]+)\}\[([^\[\]]+)\]/g;
const HANGUL = /([가-힣]+)\[([ァ-ヿ]+)\]/g;
const KATA   = /^[ァ-ヿ]+$/;

const errs = [];
const bad = (where, msg) => errs.push(`${where} — ${msg}`);

/* 표기 자체를 본다. 남은 대괄호가 있으면 후리가나가 깨진 자리다. */
function checkText(where, s) {
  if (typeof s !== "string") return;
  const open = (s.match(/《/g) || []).length, close = (s.match(/》/g) || []).length;
  if (open !== close) bad(where, `《 ${open}개 · 》 ${close}개 — 짝이 맞지 않습니다`);

  const rest = s.replace(BRACE, "").replace(HANGUL, "");
  if (/[\[\]]/.test(rest)) bad(where, `풀리지 않은 대괄호가 남았습니다: 「${rest.replace(/\s+/g, " ").slice(0, 60)}」`);

  let m;
  const re = new RegExp(HANGUL.source, "g");
  while ((m = re.exec(s))) if (!KATA.test(m[2])) bad(where, `「${m[1]}」의 읽기가 가타카나가 아닙니다: ${m[2]}`);

  const rb = new RegExp(BRACE.source, "g");
  while ((m = rb.exec(s))) {
    if (!m[2].includes("/")) bad(where, `{${m[1]}} 의 읽기에 슬래시가 없습니다 — {표기}[한글읽기/カナ] 형식이어야 합니다`);
    else {
      const [ko, kana] = m[2].split("/");
      if (!/[가-힣]/.test(ko)) bad(where, `{${m[1]}} 의 음성용 읽기에 한글이 없습니다: ${ko}`);
      if (!KATA.test(kana)) bad(where, `{${m[1]}} 의 루비가 가타카나가 아닙니다: ${kana}`);
    }
  }
}

/* 화면에 그려지는 모든 문자열을 훑는다. */
function walk(where, v) {
  if (typeof v === "string") checkText(where, v);
  else if (Array.isArray(v)) v.forEach((x, i) => walk(`${where}[${i}]`, x));
  else if (v && typeof v === "object") Object.keys(v).forEach(k => walk(`${where}.${k}`, v[k]));
}

const plain = s => s.replace(BRACE, "$1").replace(HANGUL, "$1").replace(/《|》/g, "").replace(/<[^>]+>/g, "");

for (const d of days) {
  const D = `${d.no}과`;
  walk(D, d);

  for (const f of ["no", "title", "titleJa", "story", "words", "sentences", "dialogue", "quiz", "column"])
    if (d[f] === undefined) bad(D, `${f} 가 없습니다`);
  if (!d.story || !Array.isArray(d.story.lines)) { bad(D, "story.lines 가 없습니다"); continue; }

  if (d.story.lines.length !== 4) bad(D, `story.lines 는 4줄이어야 합니다 (지금 ${d.story.lines.length}줄)`);
  d.story.lines.forEach((l, i) => {
    if (!l.ko || !l.ja) bad(`${D} story[${i}]`, "ko 와 ja 가 모두 있어야 합니다");
  });

  if (d.words.length !== 6) bad(D, `words 는 6개여야 합니다 (지금 ${d.words.length}개)`);
  if (d.sentences.length !== 6) bad(D, `sentences 는 6개여야 합니다 (지금 ${d.sentences.length}개)`);

  d.words.forEach((w, i) => {
    const W = `${D} words[${i}] ${w.ko}`;
    if (/[\[\]{}《》]/.test(w.ko || "")) bad(W, "ko 에는 대괄호나 《》를 넣지 않습니다 — 순수 표기여야 합니다");
    for (const f of ["ko", "disp", "kana", "mean", "note"]) if (!w[f]) bad(W, `${f} 가 비어 있습니다`);
    if (w.disp && plain(w.disp) !== w.ko) bad(W, `disp 에서 표기를 걷어내면 ko 와 같아야 합니다: 「${plain(w.disp)}」 ≠ 「${w.ko}」`);
  });

  d.sentences.forEach((s, i) => {
    const S = `${D} sentences[${i}] (${s.for})`;
    const w = d.words[i];
    if (w && s.for !== w.ko) bad(S, `words[${i}] 와 순서가 어긋났습니다 — for 는 「${w.ko}」여야 합니다`);
    if (!d.words.some(x => x.ko === s.for)) bad(S, `for 「${s.for}」 에 해당하는 단어가 words 에 없습니다`);
    for (const f of ["ko", "ja", "frame", "parts", "why", "swap"]) if (!s[f]) bad(S, `${f} 가 비어 있습니다`);
    if (Array.isArray(s.why) && s.why.length !== 3) bad(S, `why 는 3개여야 합니다 (지금 ${s.why.length}개)`);
    if (Array.isArray(s.parts)) {
      const joined = s.parts.map(p => p.p).join(" ");
      if (joined !== s.ko) bad(S, `parts 를 띄어쓰기로 이으면 ko 와 한 글자도 달라선 안 됩니다\n      parts: ${joined}\n      ko   : ${s.ko}`);
      s.parts.forEach((p, j) => { for (const f of ["p", "r", "w"]) if (!p[f]) bad(`${S} parts[${j}]`, `${f} 가 비어 있습니다`); });
    }
    if (s.swap && (!s.swap.ko || !s.swap.ja)) bad(S, "swap 에는 ko 와 ja 가 모두 있어야 합니다");
  });

  const turns = (d.dialogue && d.dialogue.turns) || [];
  if (!d.dialogue || !d.dialogue.situation) bad(D, "dialogue.situation 이 없습니다");
  if (turns.length !== 6) bad(D, `dialogue.turns 는 6턴이어야 합니다 (지금 ${turns.length}턴)`);
  turns.forEach((t, i) => {
    const T = `${D} turn[${i}]`;
    if (typeof t.me !== "boolean") bad(T, "me 는 true/false 여야 합니다");
    if (t.me !== (i % 2 === 1)) bad(T, "상대(false)와 나(true)가 번갈아 나와야 합니다 — 0번은 상대로 시작합니다");
    if (!t.ko || !t.ja) bad(T, "ko 와 ja 가 모두 있어야 합니다");
    if (Array.isArray(t.parts)) {
      const joined = t.parts.map(p => p.p).join(" ");
      if (joined !== t.ko) bad(T, `parts 를 띄어쓰기로 이으면 ko 와 같아야 합니다\n      parts: ${joined}\n      ko   : ${t.ko}`);
    }
    if (t.me && (!t.parts || t.parts.length < 2)) bad(T, "내 대사는 조각이 2개 이상이어야 조각 맞추기가 열립니다");
  });

  if (d.quiz.length !== 8) bad(D, `quiz 는 8문항이어야 합니다 (지금 ${d.quiz.length}문항)`);
  const tally = [0, 0, 0];
  d.quiz.forEach((q, i) => {
    const Q = `${D} quiz[${i + 1}]`;
    if (!Array.isArray(q.opts) || q.opts.length !== 3) bad(Q, "opts 는 항상 3개입니다");
    if (!(q.ans >= 0 && q.ans <= 2)) bad(Q, `ans 는 0~2 여야 합니다 (지금 ${q.ans})`);
    else tally[q.ans]++;
    if (!q.q || !q.msg) bad(Q, "q 와 msg 가 모두 있어야 합니다");
    if (Array.isArray(q.opts) && new Set(q.opts).size !== q.opts.length) bad(Q, "같은 보기가 두 번 들어 있습니다");
    if (Array.isArray(q.opts) && q.ans >= 0 && q.ans <= 2) {
      const len = q.opts.map(o => plain(o).length);
      if (len[q.ans] > Math.max(...len.filter((_, j) => j !== q.ans)))
        bad(Q, "가장 긴 보기가 정답입니다 — 뜻을 몰라도 맞힐 수 있는 문항이 됩니다");
    }
  });
  if (Math.max(...tally) - Math.min(...tally) > 3)
    bad(D, `정답이 한쪽에 쏠렸습니다 — 첫 보기 ${tally[0]} · 둘째 ${tally[1]} · 셋째 ${tally[2]}`);

  const c = d.column;
  if (c) for (const f of ["word", "kana", "ja", "title", "body", "note"]) if (!c[f]) bad(`${D} column`, `${f} 가 비어 있습니다`);
  if (c && Array.isArray(c.body) && c.body.length !== 3) bad(`${D} column`, `body 는 3문단이어야 합니다 (지금 ${c.body.length}문단)`);
}

if (errs.length) {
  console.error(`\n✗ ${errs.length}곳이 걸렸습니다.\n`);
  errs.forEach(e => console.error("  " + e));
  console.error("");
  process.exit(1);
}
console.log(`✓ ${days.length}개 회차, 이상 없습니다.`);
