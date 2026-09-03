#!/usr/bin/env node
/*
 * 스틸링고 회차 검증기 — Lite / 트레이닝 공용
 *
 *   node check_day.js --lite     day21.js
 *   node check_day.js --training unit16.js
 *
 * 회차 객체 하나(또는 여러 개가 든 배열)가 담긴 파일을 받아,
 * 앱에 붙였을 때 깨질 만한 곳을 미리 잡아낸다.
 *
 * 사람 눈으로 잡기 어려운 것 — 조각을 이어 붙인 결과가 원문과 한 글자 다른 것,
 * 대괄호가 한자 아닌 곳에 붙은 것, 예문이 가리키는 단어가 어긋난 것 — 이 주된 표적이다.
 * 번역이 맞는지, 설명이 통하는지는 여기서 알 수 없다. 그건 읽어서 봐야 한다.
 */

const fs = require("fs");

const BRACE = /\{([^{}]+)\}\[([^\[\]]+)\]/g;          // {9時}[くじ]
const KANJI = /([一-鿿々〆ヶ]+)\[([ぁ-ゟ゠-ヿー]+)\]/g;  // 場所[ばしょ]
const MARK  = /《([\s\S]*?)》/g;

const errors = [];
const warns  = [];
const err  = (m) => errors.push(m);
const warn = (m) => warns.push(m);

/* ---------- 인자 ---------- */

const args = process.argv.slice(2);
const mode = args.includes("--training") ? "training"
           : args.includes("--lite")     ? "lite"
           : null;
const file = args.find(a => !a.startsWith("--"));

if (!mode || !file) {
  console.error("쓰는 법:\n  node check_day.js --lite     <파일>\n  node check_day.js --training <파일>");
  process.exit(2);
}

let src = fs.readFileSync(file, "utf8").trim();
src = src.replace(/^\s*(?:const|let|var)\s+[A-Za-z_$][\w$]*\s*=\s*/, "");
src = src.replace(/[;,]\s*$/, "");

let parsed;
try {
  parsed = new Function("return (" + src + ")")();
} catch (e) {
  console.error("문법 오류로 읽을 수 없습니다. 이 상태로 앱에 붙이면 앱 전체가 멈춥니다.\n  " + e.message);
  process.exit(1);
}

const days = Array.isArray(parsed) ? parsed : [parsed];

/* ---------- 공통 검사 ---------- */

function notation(label, s) {
  if (typeof s !== "string") { err(`${label}: 글자열이 아닙니다`); return; }

  const pair = (open, close, name) => {
    const a = (s.match(new RegExp("\\" + open, "g")) || []).length;
    const b = (s.match(new RegExp("\\" + close, "g")) || []).length;
    if (a !== b) err(`${label}: ${name} 짝이 맞지 않습니다 (${open}${a}개, ${close}${b}개) — ${s}`);
  };
  pair("[", "]", "대괄호");
  pair("《", "》", "겹화살괄호");
  pair("{", "}", "중괄호");

  const stripped = s.replace(BRACE, "$1").replace(KANJI, "$1");
  if (/[\[\]]/.test(stripped)) {
    err(`${label}: 대괄호가 한자나 {} 뒤에 붙어 있지 않습니다. `
      + `오쿠리가나는 괄호 밖에 둡니다 — 降[ふ]る (○) / 降る[ふる] (×) — ${s}`);
  }

  const noBrace = s.replace(BRACE, "");
  if (/[0-9０-９]/.test(noBrace)) {
    warn(`${label}: 숫자에 읽기가 없습니다. {9時}[くじ] 처럼 달아 주세요 — ${s}`);
  }
}

function need(obj, key, label) {
  if (obj == null || obj[key] === undefined || obj[key] === "") {
    err(`${label}.${key} 가 비어 있습니다`);
    return false;
  }
  return true;
}

/* 조각을 이어 붙이면 원문과 같아야 한다 */
function joinMatch(label, joined, jp, what) {
  if (joined !== jp) {
    err(`${label}: ${what} 를 이어 붙인 결과가 원문과 다릅니다.\n`
      + `      원문: ${jp}\n      결합: ${joined}`);
  }
}

function partsMatch(label, parts, jp) {
  if (!Array.isArray(parts) || !parts.length) { err(`${label}: parts 가 없습니다`); return; }
  parts.forEach((p, i) => {
    ["p", "r", "w", "why"].forEach(k => {
      if (typeof p[k] !== "string") err(`${label}.parts[${i}]: ${k} 가 없습니다`);
    });
    if (typeof p.p === "string") notation(`${label}.parts[${i}].p`, p.p);
  });
  joinMatch(label, parts.map(p => p.p || "").join(""), jp, "parts");
}

function checkQuizOpts(lab, q, count) {
  const o = q.opts || [];
  if (o.length !== count) err(`${lab}.opts 는 ${count}개여야 합니다 (지금 ${o.length}개)`);
  o.forEach((x, j) => notation(`${lab}.opts[${j}]`, x));
  const key = q.ans !== undefined ? "ans" : "a";
  const v = q[key];
  if (!Number.isInteger(v) || v < 0 || v >= o.length) {
    err(`${lab}.${key} 는 0부터 ${Math.max(o.length - 1, 0)} 사이의 번호여야 합니다 (지금 ${v})`);
  }
}

function checkColumn(c, tag) {
  if (!c) { err(`${tag}.column 이 없습니다`); return; }
  ["word", "kana", "ko", "title", "note"].forEach(k => need(c, k, `${tag}.column`));
  if (typeof c.word === "string") notation(`${tag}.column.word`, c.word);
  const b = c.body || [];
  if (b.length !== 3) err(`${tag}.column.body 는 3문단이어야 합니다 (지금 ${b.length}문단)`);
}

/* ---------- Lite ---------- */

function checkLite(d, tag) {
  if (typeof d.no !== "number") err(`${tag}: no 는 숫자여야 합니다`);
  if (need(d, "title", tag)) notation(`${tag}.title`, d.title);
  need(d, "titleKo", tag);

  const st = d.story;
  if (!st) err(`${tag}.story 가 없습니다`);
  else {
    need(st, "topic", `${tag}.story`);
    const L = st.lines || [];
    if (L.length !== 4) err(`${tag}.story.lines 는 4줄이어야 합니다 (지금 ${L.length}줄)`);
    L.forEach((l, i) => {
      if (need(l, "jp", `${tag}.story.lines[${i}]`)) notation(`${tag}.story.lines[${i}].jp`, l.jp);
      need(l, "ko", `${tag}.story.lines[${i}]`);
    });
  }

  const W = d.words || [];
  if (W.length !== 6) err(`${tag}.words 는 6개여야 합니다 (지금 ${W.length}개)`);
  W.forEach((w, i) => {
    const lab = `${tag}.words[${i}]`;
    ["jp", "disp", "kana", "mean", "note"].forEach(k => need(w, k, lab));
    if (typeof w.jp === "string" && /[\[\]《》]/.test(w.jp)) {
      err(`${lab}.jp 에는 표기 기호를 넣지 않습니다. 후리가나는 disp 에만 — 지금: ${w.jp}`);
    }
    if (typeof w.disp === "string") notation(`${lab}.disp`, w.disp);
  });

  const S = d.sentences || [];
  if (S.length !== W.length) {
    err(`${tag}.sentences 는 words 와 같은 개수여야 합니다 (words ${W.length} / sentences ${S.length})`);
  }
  S.forEach((s, i) => {
    const lab = `${tag}.sentences[${i}]`;
    ["for", "jp", "ko", "frame"].forEach(k => need(s, k, lab));
    if (W[i] && s.for !== W[i].jp) {
      err(`${lab}.for 가 words[${i}].jp 와 다릅니다. 이러면 이 예문이 화면에서 사라집니다.\n`
        + `      words: ${W[i].jp}\n      for  : ${s.for}`);
    }
    if (typeof s.jp === "string") { notation(`${lab}.jp`, s.jp); partsMatch(lab, s.parts, s.jp); }
    const why = s.why || [];
    if (why.length !== 3) err(`${lab}.why 는 3개여야 합니다 (지금 ${why.length}개)`);
    if (!s.swap || !s.swap.jp || !s.swap.ko) err(`${lab}.swap 에 jp/ko 가 있어야 합니다`);
    else notation(`${lab}.swap.jp`, s.swap.jp);
  });

  const dl = d.dialogue;
  if (!dl) err(`${tag}.dialogue 가 없습니다`);
  else {
    need(dl, "situation", `${tag}.dialogue`);
    const T = dl.turns || [];
    if (T.length !== 6) err(`${tag}.dialogue.turns 는 6턴이어야 합니다 (지금 ${T.length}턴)`);
    T.forEach((t, i) => {
      const lab = `${tag}.dialogue.turns[${i}]`;
      if (typeof t.me !== "boolean") err(`${lab}.me 는 true/false 여야 합니다`);
      else if (t.me !== (i % 2 === 1)) warn(`${lab}.me 가 번갈아 나오지 않습니다`);
      ["jp", "ko", "tip"].forEach(k => need(t, k, lab));
      if (typeof t.jp === "string") { notation(`${lab}.jp`, t.jp); partsMatch(lab, t.parts, t.jp); }
    });
  }

  const Q = d.quiz || [];
  if (Q.length !== 8) err(`${tag}.quiz 는 8문항이어야 합니다 (지금 ${Q.length}문항)`);
  const front = Q.slice(0, 4);
  if (front.length === 4 && front.every(q => q.ans === front[0].ans)) {
    warn(`${tag}.quiz: 앞 네 문항의 정답이 모두 ${front[0].ans}번입니다. `
       + `학습자가 낱말이 아니라 자리를 외웁니다 — 보기 순서를 섞어 주세요`);
  }
  /* 뜻을 몰라도 가장 긴 보기를 누르면 맞는 문항을 잡는다 */
  const cols = s => [...String(s).replace(BRACE, "$1").replace(KANJI, "$1")]
    .reduce((a, c) => a + (/[\u3000-\u9fff\uff00-\uffef]/.test(c) ? 2 : 1), 0);
  Q.forEach((q, i) => {
    const w = (q.opts || []).map(cols);
    if (!w.length) return;
    if (w[q.ans] === Math.max(...w) && Math.max(...w) - Math.min(...w) >= 14) {
      warn(`${tag}.quiz[${i}]: 정답이 눈에 띄게 가장 긴 보기입니다. `
         + `오답도 비슷한 길이의 실제로 쓰이는 표현으로 채워 주세요`);
    }
  });
  Q.forEach((q, i) => {
    const lab = `${tag}.quiz[${i}]`;
    need(q, "q", lab); need(q, "msg", lab);
    checkQuizOpts(lab, q, 3);
  });

  checkColumn(d.column, tag);
}

/* ---------- 트레이닝 ---------- */

function checkTraining(d, tag) {
  if (typeof d.no !== "number") err(`${tag}: no 는 숫자여야 합니다`);
  ["date", "theme"].forEach(k => need(d, k, tag));
  if (typeof d.minutes !== "number") err(`${tag}.minutes 는 숫자여야 합니다`);

  const T = d.terms || [];
  if (T.length !== 8) err(`${tag}.terms 는 8개여야 합니다 (지금 ${T.length}개)`);
  T.forEach((t, i) => {
    const lab = `${tag}.terms[${i}]`;
    ["jp", "kana", "mean", "note", "where"].forEach(k => need(t, k, lab));
    if (typeof t.jp === "string" && /[\[\]《》]/.test(t.jp)) {
      err(`${lab}.jp 에는 표기 기호를 넣지 않습니다 — 지금: ${t.jp}`);
    }
    if (t.ez !== undefined) {
      if (!Array.isArray(t.ez) || t.ez.length !== 2) {
        err(`${lab}.ez 는 [일본어, 한국어] 두 칸 배열이어야 합니다`);
      } else notation(`${lab}.ez[0]`, t.ez[0]);
    }
  });

  const S = d.sentences || [];
  if (S.length !== T.length) {
    err(`${tag}.sentences 는 terms 와 같은 개수여야 합니다 (terms ${T.length} / sentences ${S.length})`);
  }
  S.forEach((s, i) => {
    const lab = `${tag}.sentences[${i}]`;
    ["drill", "jp", "ko", "tip"].forEach(k => need(s, k, lab));
    if (T[i] && s.drill !== T[i].jp) {
      err(`${lab}.drill 이 terms[${i}].jp 와 다릅니다. 이러면 이 예문이 용어와 연결되지 않습니다.\n`
        + `      terms: ${T[i].jp}\n      drill: ${s.drill}`);
    }
    if (typeof s.jp === "string") notation(`${lab}.jp`, s.jp);
  });

  const a = d.article;
  if (!a) err(`${tag}.article 이 없습니다`);
  else {
    if (typeof a.real !== "boolean") err(`${tag}.article.real 은 true/false 여야 합니다`);
    if (a.real) {
      ["source", "url", "note"].forEach(k => need(a, k, `${tag}.article`));
      if (typeof a.url === "string" && !/^https?:\/\//.test(a.url)) {
        err(`${tag}.article.url 이 주소 형태가 아닙니다 — ${a.url}`);
      }
    } else {
      warn(`${tag}.article.real 이 false 입니다. 지문 안에 가상 사례임을 밝혔는지 확인하세요`);
    }
    if (need(a, "body", `${tag}.article`)) notation(`${tag}.article.body`, a.body);
    const L = a.lines || [];
    if (!L.length) err(`${tag}.article.lines 가 비어 있습니다`);
    L.forEach((l, i) => {
      const lab = `${tag}.article.lines[${i}]`;
      ["jp", "ko"].forEach(k => need(l, k, lab));
      if (typeof l.jp === "string" && /[\[\]《》]/.test(l.jp)) {
        warn(`${lab}.jp 는 후리가나 없는 원문이어야 합니다 — 지금: ${l.jp}`);
      }
    });
  }

  const dl = d.dialogue;
  if (!dl) err(`${tag}.dialogue 가 없습니다`);
  else {
    need(dl, "situation", `${tag}.dialogue`);
    const TU = dl.turns || [];
    if (TU.length < 6) err(`${tag}.dialogue.turns 는 6턴 이상이어야 합니다 (지금 ${TU.length}턴)`);
    if (TU.length % 2) warn(`${tag}.dialogue.turns 가 홀수입니다. 보통 내 턴으로 끝냅니다`);
    TU.forEach((t, i) => {
      const lab = `${tag}.dialogue.turns[${i}]`;
      if (typeof t.me !== "boolean") err(`${lab}.me 는 true/false 여야 합니다`);
      else if (t.me !== (i % 2 === 1)) warn(`${lab}.me 가 번갈아 나오지 않습니다`);
      ["jp", "ko"].forEach(k => need(t, k, lab));
      if (typeof t.jp === "string") notation(`${lab}.jp`, t.jp);

      if (t.me === true) {
        if (!Array.isArray(t.ch) || !t.ch.length) {
          err(`${lab}: 내 턴에는 ch(한국어→일본어 조각)가 있어야 합니다`);
        } else {
          t.ch.forEach((pair, j) => {
            if (!Array.isArray(pair) || pair.length !== 2) {
              err(`${lab}.ch[${j}] 는 [한국어, 일본어] 두 칸이어야 합니다`);
            } else notation(`${lab}.ch[${j}][1]`, pair[1]);
          });
          joinMatch(lab, t.ch.map(p => (p && p[1]) || "").join(""), t.jp, "ch의 일본어 조각");
        }
      } else if (t.ch) {
        warn(`${lab}: 상대 턴에는 보통 ch를 붙이지 않습니다`);
      }
    });

    const W = dl.warns || [];
    if (W.length < 2) warn(`${tag}.dialogue.warns 가 ${W.length}개입니다. 보통 2~3개 넣습니다`);
    W.forEach((w, i) => {
      const lab = `${tag}.dialogue.warns[${i}]`;
      if (typeof w.hard !== "boolean") err(`${lab}.hard 는 true/false 여야 합니다`);
      ["head", "body"].forEach(k => need(w, k, lab));
    });
  }

  const Q = d.quiz || [];
  if (Q.length !== 6) err(`${tag}.quiz 는 6문항이어야 합니다 (지금 ${Q.length}문항)`);
  let subjective = 0;
  Q.forEach((q, i) => {
    const lab = `${tag}.quiz[${i}]`;
    need(q, "q", lab);
    const hasOpts = Array.isArray(q.opts);
    const hasAns  = typeof q.answer === "string" && q.answer !== "";
    if (hasOpts && hasAns) err(`${lab}: opts 와 answer 를 함께 쓰지 않습니다. 객관식이면 opts+ans, 주관식이면 answer 하나`);
    else if (hasOpts) checkQuizOpts(lab, q, 3);
    else if (hasAns) subjective++;
    else err(`${lab}: opts+ans (객관식) 또는 answer (주관식) 중 하나가 있어야 합니다`);
  });
  if (Q.length === 6 && subjective === 0) {
    warn(`${tag}.quiz 가 전부 객관식입니다. 2~3문항은 직접 쓰게 하는 편이 좋습니다`);
  }

  checkColumn(d.column, tag);
}

/* ---------- 실행 ---------- */

const check = mode === "lite" ? checkLite : checkTraining;
const label = mode === "lite" ? "Lite" : "트레이닝";

days.forEach((d, i) => check(d, days.length > 1 ? `[${i + 1}번째 객체]` : `${d.no}회차`));

if (warns.length) {
  console.log(`\n확인해 보세요 (${warns.length}건)`);
  warns.forEach(w => console.log("  · " + w));
}

if (errors.length) {
  console.log(`\n고쳐야 합니다 (${errors.length}건)`);
  errors.forEach(e => console.log("  ✗ " + e));
  console.log("\n이대로 앱에 붙이면 화면이 깨지거나 앱이 멈춥니다.");
  process.exit(1);
}

console.log(`\n통과했습니다. ${label} 회차 ${days.length}개, 형식 문제 없음.`);
console.log("남은 것은 사람이 볼 몫입니다 — 번역이 자연스러운지, 설명이 읽는 사람에게 통하는지.");
