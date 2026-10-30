/* 스틸링고 입문 — 화면

   하루 흐름(매일 같은 순서): 시작 → 복습 → 원리 → 새 글자(또는 줄·묶음) → 비교 → 단어장 → 읽기 → 확인 퀴즈 → 완료
   - 회차를 시작하면 그날 할 화면 목록(plan)을 만들어 저장한다. 중간에 닫았다 열면 그 자리에서 이어진다.
   - 틀려도 다시 하라고 하지 않는다. 틀린 글자는 다음 복습에 자동으로 들어간다.
   - 점수로 회차를 잠그지 않는다. 통과·미달 판정이 없다.
   - 연속 기록이 없다. 이틀 넘게 쉬었다가 열면 2분짜리 복귀 복습만 하고 이어 간다.
   회차 원고는 js/lessons.js (tools/content.py 에서 생성). 이 파일은 화면만 다룬다. */
(function () {
  "use strict";
  const $app = document.getElementById("app");
  const KEY = "steel-lingo-nyumon-v1";
  const DAY = 86400000;
  const HIRA = "あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん";
  const TABLE = ["あいうえお","かきくけこ","さしすせそ","たちつてと","なにぬねの","はひふへほ","まみむめも","や ゆ よ","らりるれろ","わ   を","ん    "];
  const HINT_VISIBLE_UNTIL = 5;      // 1~5회차는 한글 소리가 보이고, 6회차부터는 눌러야 보인다
  const MIX_FROM = 8;                // 8회차(2주째)부터 복습을 섞는다. 그 전에는 전날 글자만
  const REVIEW_MAX = 5, BACK_MAX = 5, KANA_Q = 5;
  const LITE_URL = "../lite/";
  const STAGE_DONE = {
    1: "히라가나 46자를 다 배웠어요",
    2: "점·작은 글자·긴 소리까지. 이제 히라가나 문장을 읽을 수 있어요",
    3: "가타카나 절반, ア부터 ノ까지 왔어요",
    4: "가타카나 46자를 다 배웠어요",
    5: "졸업했어요"
  };

  /* ── 저장 ── */
  const blank = () => ({ done: [], wrong: {}, cur: null, last: 0, intro: false });
  let S = blank();
  try { S = Object.assign(blank(), JSON.parse(localStorage.getItem(KEY) || "{}")); } catch (e) {}
  const save = () => { try { localStorage.setItem(KEY, JSON.stringify(S)); } catch (e) {} };

  /* ── 도우미 ── */
  const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
  const pick = (a) => a[Math.floor(Math.random() * a.length)];
  const shuffle = (a) => { a = a.slice(); for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; };
  const lesson = (no) => NY.LESSONS.find((l) => l.no === no);
  const upTo = (no) => NY.LESSONS.filter((l) => l.no <= no);
  const learnedUpTo = (no) => upTo(no).flatMap((l) => l.new);           // 배운 글자 단위(あ, が, きゃ, ア …)
  const nextNo = () => { for (let i = 1; i <= NY.TOTAL; i++) if (!S.done.includes(i)) return i; return NY.TOTAL + 1; };
  const wrongCount = () => Object.keys(S.wrong).length;
  const isKata = (s) => /[゠-ヿ]/.test(s);
  const toHira = (s) => s.replace(/[ァ-ヶ]/g, (c) => String.fromCharCode(c.charCodeAt(0) - 0x60));
  const toKata = (s) => s.replace(/[ぁ-ゖ]/g, (c) => String.fromCharCode(c.charCodeAt(0) + 0x60));
  const ko = (k) => NY.KANA[k] || "";
  function fill(t, v) { return t.replace(/\{(\w)\}/g, (_, k) => (v && v[k] != null ? v[k] : "")); }

  /* ── 읽을 수 있는 글자인가: 배운 글자 + 그날까지 배운 규칙(゛ 小 ー) ── */
  const SMALL = { "ぁ":"あ","ぃ":"い","ぅ":"う","ぇ":"え","ぉ":"お","っ":"つ","ゃ":"や","ゅ":"ゆ","ょ":"よ",
                  "ァ":"ア","ィ":"イ","ゥ":"ウ","ェ":"エ","ォ":"オ","ッ":"ツ","ャ":"ヤ","ュ":"ユ","ョ":"ヨ" };
  const knownCache = {};
  function known(no) {
    if (knownCache[no]) return knownCache[no];
    const s = new Set();
    upTo(no).forEach((l) => {
      l.new.forEach((u) => [...u.normalize("NFD")].forEach((c) => { if (c !== "゙" && c !== "゚") s.add(SMALL[c] || c); }));
      (l.extra || []).forEach((x) => s.add(x));
    });
    return (knownCache[no] = s);
  }
  function canRead(ch, no) {
    const set = known(no);
    if (ch === "ー") return set.has("ー");
    if (ch === "ッ") return set.has("小") && set.has("ッ");   // 작은 ッ는 14회차에 기호로 배운다
    let c = ch;
    if (SMALL[c]) { if (!set.has("小")) return false; c = SMALL[c]; }
    const d = c.normalize("NFD");
    if (d.length > 1 && !set.has("゛")) return false;
    return set.has(d[0]);
  }

  /* ── 소리: 미리 만든 파일만 쓴다(기기 음성은 쓰지 않는다) ── */
  const player = new Audio();
  function play(text, btn) {
    const f = NY.AUDIO[text];
    if (!f) return;
    player.pause(); player.src = "audio/" + f; player.currentTime = 0;
    document.querySelectorAll(".snd.on,.on-snd").forEach((b) => b.classList.remove("on", "on-snd"));
    if (btn) { btn.classList.add(btn.classList.contains("snd") ? "on" : "on-snd"); player.onended = () => btn.classList.remove("on", "on-snd"); }
    player.play().catch(() => {});
  }
  const kanaSound = (k) => "@" + k;

  /* ── 캐릭터 말풍선 ── */
  function sayHTML(line, vars) {
    if (!line) return '<div class="say"></div>';
    const c = NY.CHARS[line.who];
    return `<div class="say pop"><img src="char/${line.who}_${line.face}.webp" alt="${c.name}"><div class="b"><em>${c.name}</em>${esc(fill(line.text, vars))}</div></div>`;
  }
  const line = (kind) => pick(NY.LINES[kind]);

  /* ── 퀴즈 보기 만들기: 같은 글자 종류(히라가나·가타카나), 같은 길이, 모양이 비슷한 글자부터 ── */
  function distractors(k, pool, n) {
    const same = pool.filter((x) => x !== k && isKata(x) === isKata(k) && ko(x) !== ko(k));
    const near = same.filter((x) => x.length === k.length);
    const out = [];
    const group = NY.LOOKALIKE.find((g) => g.includes(k)) || [];
    shuffle(group).forEach((x) => { if (same.includes(x) && !out.includes(x)) out.push(x); });
    shuffle(near).concat(shuffle(same)).forEach((x) => { if (!out.includes(x)) out.push(x); });
    return out.slice(0, n);
  }
  function quizItem(k, pool, mode) {
    // 한글로 옮기면 소리가 틀리게 굳는 글자(つ·ん)는 '소리 보기' 문제로 내지 않는다
    if (mode === "see") {
      if (NY.NO_HANGUL.includes(toHira(k))) mode = "listen";
      else pool = pool.filter((x) => !NY.NO_HANGUL.includes(toHira(x)));
    }
    if (mode === "pair") {
      const ds = distractors(k, pool, 3).map(toHira);
      return { t: "quiz", mode, k, ans: toHira(k), opts: shuffle([toHira(k)].concat(ds)) };
    }
    return { t: "quiz", mode, k, opts: shuffle([k].concat(distractors(k, pool, 3))) };
  }

  /* 그 회차까지 나온 단어(읽기·단어장·묶음) — 단어 듣기·뜻 문제에 쓴다 */
  function wordBank(no) {
    const m = new Map();
    upTo(no).forEach((l) => {
      (l.read || []).concat(l.words || []).concat((l.groups || []).flatMap((g) => g.items)).forEach(([w, k]) => { if (!w.includes(" ")) m.set(w, k); });
    });
    return [...m.entries()];
  }
  function hearItem(no, w) {
    const bank = wordBank(no).map((x) => x[0]).filter((x) => x !== w && isKata(x) === isKata(w));
    const near = shuffle(bank.filter((x) => Math.abs(x.length - w.length) <= 1));
    const rest = shuffle(bank.filter((x) => !near.includes(x)));
    return { t: "quiz", mode: "hear", ans: w, opts: shuffle([w].concat(near.concat(rest).slice(0, 3))) };
  }
  function meanItem(no, w, m) {
    const others = shuffle([...new Set(wordBank(no).map((x) => x[1]))].filter((x) => x !== m));
    return { t: "quiz", mode: "word", w, ans: m, opts: shuffle([m].concat(others.slice(0, 3))) };
  }

  /* ── 회차 계획 만들기 ── */
  function buildPlan(no, back) {
    const L = lesson(no);
    const before = learnedUpTo(no - 1);
    const pool = learnedUpTo(no);
    const plan = [{ t: "start", back: !!back }];

    // 복습: 1주차는 전날 글자만, 2주째부터 섞어서. 전날 틀린 글자는 언제나 먼저.
    if (before.length) {
      const wrong = Object.keys(S.wrong).filter((k) => before.includes(k));
      const prev = lesson(no - 1);
      let base = no < MIX_FROM && prev && prev.new.length ? prev.new.slice() : shuffle(before);
      let items = wrong.concat(base.filter((k) => !wrong.includes(k)));
      items = shuffle(items.slice(0, back ? BACK_MAX : REVIEW_MAX));
      items.forEach((k) => plan.push(Object.assign(quizItem(k, before, "listen"), { phase: "review" })));
    }
    // 원리 → 새 글자(종류별) → 비교 → 단어장 → 읽기 → 이어 읽기
    if (L.rule) plan.push({ t: "rule" });
    if (L.kind === "kana") L.new.forEach((k) => plan.push({ t: "card", k }));
    if (L.kind === "rows") L.rows.forEach((r, i) => plan.push({ t: "rowcard", i }));
    if (L.kind === "examples") L.groups.forEach((g, i) => plan.push({ t: "group", i }));
    (L.compare || []).forEach(([a, b, tip]) => plan.push({ t: "compare", a, b, tip }));
    if ((L.words || []).length) plan.push({ t: "vocab" });
    (L.read || []).forEach(([w, ko2]) => plan.push({ t: "read", w, ko: ko2 }));
    (L.phrases || []).forEach(([w, ko2]) => plan.push({ t: "phrase", w, ko: ko2 }));
    if (L.kind === "grad") plan.push({ t: "litefull" });

    // 확인 퀴즈
    const q = [];
    if (L.new.length) {
      // 오늘 글자 5문제. 가타카나 날은 '같은 소리 히라가나 찾기'를 섞는다.
      let today = shuffle(L.new);
      if (today.length < 3) today = today.concat(shuffle(pool.filter((k) => !L.new.includes(k) && isKata(k) === isKata(L.new[0]))).slice(0, KANA_Q - today.length));
      for (let i = 0; q.length < KANA_Q && i < 20; i++) {
        const k = today[i % today.length];
        q.push(quizItem(k, pool, i % 2 ? (L.script === "kata" ? "pair" : "see") : "listen"));
      }
      const rowItem = L.script === "hira" && L.kind === "kana" ? buildRowQuiz(no, L, pool) : null;
      q.push(rowItem || quizItem(pick(L.new), pool, L.script === "kata" ? "pair" : "see"));
    } else {
      // 새 글자가 없는 날: 지금까지 배운 글자 섞어 3문제(+졸업 날은 5문제)
      const mix = shuffle(pool).slice(0, L.kind === "grad" ? 5 : 3);
      mix.forEach((k, i) => q.push(quizItem(k, pool, isKata(k) && i % 2 ? "pair" : "listen")));
    }
    // 단어: 소리 듣고 고르기 + 뜻 고르기
    const src = (L.read || []).length ? L.read : wordBank(no).slice(-12);
    const hw = shuffle(src);
    const wordQ = L.new.length ? 1 : 2;
    for (let i = 0; i < wordQ && i < hw.length; i++) q.push(hearItem(no, hw[i][0]));
    for (let i = 0; i < wordQ && i < hw.length; i++) { const r = hw[hw.length - 1 - i]; q.push(meanItem(no, r[0], r[1])); }
    shuffle(q).forEach((x) => plan.push(Object.assign(x, { phase: "quiz" })));
    plan.push({ t: "done" });
    return plan;
  }

  function rowOf(k) { return Object.keys(NY.ROWS).find((r) => NY.ROWS[r].kana.includes(k)); }
  function buildRowQuiz(no, L, pool) {
    if (no < 2) return null;
    const regular = (k) => k.length === 1 && !NY.IRREGULAR.includes(k) && rowOf(k) && rowOf(k) !== "あ";
    const cand = shuffle(L.new.filter(regular));
    if (!cand.length) return null;
    const k = cand[0], row = rowOf(k), dan = NY.ROWS[row].kana.indexOf(k);
    // 오답: 같은 줄의 다른 글자, 같은 단의 다른 줄 글자
    const hp = pool.filter((x) => x !== k && regular(x));
    const others = shuffle(hp.filter((x) => rowOf(x) === row || NY.ROWS[rowOf(x)].kana.indexOf(x) === dan));
    const fill2 = shuffle(hp.filter((x) => !others.includes(x)));
    return { t: "quiz", mode: "row", k, row, dan, opts: shuffle([k].concat(others.concat(fill2).slice(0, 3))) };
  }

  function startLesson(no) {
    const back = S.last && Date.now() - S.last >= 2 * DAY && S.done.length > 0;
    S.cur = { no, i: 0, plan: buildPlan(no, back), right: 0, wrongToday: [] };
    save(); render("lesson");
  }
  function step(n) { S.cur.i = Math.max(0, Math.min(S.cur.plan.length - 1, S.cur.i + n)); save(); render("lesson"); }

  /* 스틸링고 시리즈 공통 머리: 코일 로고 + 「스틸링고」 + 앱 이름 꼬리표, 위에 기획과 구성 줄 (Lite와 같은 짜임) */
  const LOGO = `<svg class="logo" viewBox="0 0 76 58" role="img" aria-label="스틸링고 로고">
      <ellipse cx="56" cy="29" rx="10" ry="19" class="lg-body"/><rect x="20" y="10" width="36" height="38" class="lg-fill"/>
      <line x1="20" y1="10" x2="56" y2="10" class="lg-edge"/><line x1="20" y1="48" x2="56" y2="48" class="lg-edge"/>
      <ellipse cx="20" cy="29" rx="10" ry="19" class="lg-face"/><path d="M20 16 a7 13 0 1 1 -6.2 12.6 a4.2 7.6 0 1 0 6.2 -6.6" class="lg-spiral"/>
      <circle cx="36" cy="26" r="2.7" class="lg-eye"/><circle cx="47" cy="26" r="2.7" class="lg-eye"/>
      <path d="M37.5 34.5 q4 3.6 8 0" class="lg-smile"/><ellipse cx="31" cy="33" rx="2.8" ry="1.9" class="lg-cheek"/><ellipse cx="52" cy="33" rx="2.8" ry="1.9" class="lg-cheek"/>
    </svg>`;
  const mast = () => `<header class="masthead">
      <div class="mast-top"><p class="byline"><span class="c">&copy; 2026</span>기획과 구성 by 곤사마 @POSCO</p><button class="pill" id="installBtn" hidden>📲 설치</button></div>
      <div class="brand">${LOGO}<h1>스틸링고<span class="tag">입문</span></h1></div>
    </header>`;
  const credit = () => `<div class="cr"><b>스틸링고 입문 · 기획과 구성 by 곤사마 @POSCO</b><span>캐릭터 스틸 그레이드 가챠 · 음성 VOICEVOX:No.7</span></div>`;

  /* ── 화면: 첫 소개 ── */
  function viewIntro() {
    const imgs = NY.LINES.intro.map((l) => `<img src="char/${l.who}_${l.face}.webp" alt="${NY.CHARS[l.who].name}">`).join("");
    let i = 0;
    $app.innerHTML = `
      ${mast()}
      <div class="main">
        <div class="card center">
          <h2>히라가나부터, 기초 오브 기초</h2>
          <p class="lead" style="margin-top:10px">하루 10분씩 25회면, 일본 간판·메뉴의 히라가나·가타카나를 읽고 기초 인사를 할 수 있어요. 그다음은 스틸링고 Lite.</p>
        </div>
        <div class="friends">${imgs}</div>
        <p class="small center" style="margin:0">스틸 그레이드 가챠 친구들이 같이 가요</p>
        <div id="introSay">${sayHTML(NY.LINES.intro[0])}</div>
      </div>
      <div class="foot">
        <button class="btn" id="next">다음 친구</button>
        <button class="btn primary big" id="go">1회차 시작<small>약 10분</small></button>
        ${credit()}
      </div>`;
    document.getElementById("next").onclick = () => {
      i = (i + 1) % NY.LINES.intro.length;
      document.getElementById("introSay").innerHTML = sayHTML(NY.LINES.intro[i]);
    };
    document.getElementById("go").onclick = () => { S.intro = true; save(); startLesson(1); };
    Install.attach();
  }

  /* ── 화면: 홈 ── */
  function viewHome() {
    const n = S.done.length, nx = nextNo();
    const open = nx <= NY.OPEN_UNTIL;
    const stages = NY.STAGES.map((s) => {
      const tot = s.to - s.from + 1, got = S.done.filter((d) => d >= s.from && d <= s.to).length;
      return `<div><i><u style="width:${(got / tot) * 100}%"></u></i>${s.name}</div>`;
    }).join("");
    let list = "";
    for (let i = 1; i <= NY.TOTAL; i++) {
      const done = S.done.includes(i), locked = i > NY.OPEN_UNTIL;
      list += `<button data-no="${i}" class="${done ? "done" : ""} ${i === nx && !locked ? "next" : ""}" ${locked ? "disabled" : ""}>${i}</button>`;
    }
    const resume = S.cur && S.cur.plan[S.cur.i].t !== "done";
    const nl = lesson(nx);
    const mainBtn = resume
      ? `<button class="btn primary big" id="go">이어하기<small>${S.cur.no}회차 · 하던 자리부터</small></button>`
      : open && nl
        ? `<button class="btn primary big" id="go">오늘 할 것 시작<small>${nx}회차 · ${esc(nl.title)} · 약 10분</small></button>`
        : `<a class="btn primary big" href="${LITE_URL}">스틸링고 Lite로 가기<small>25회 모두 끝 · 다음 단계</small></a>`;
    const bub = nx > NY.TOTAL ? line("done") : n ? NY.LINES.progress[wrongCount() ? 0 : 1] : line("start");
    $app.innerHTML = `
      ${mast()}
      <div class="main">
        <div class="card">
          <div class="prog"><b>${n}</b><span class="lead">/ 25회 완료</span></div>
          <div class="stages">${stages}</div>
        </div>
        ${mainBtn}
        <div class="card">
          <div class="row" style="justify-content:space-between;align-items:center;margin-bottom:10px"><b>회차</b><button class="pill" id="table">글자 표 보기</button></div>
          <div class="list">${list}</div>
          <p class="small" style="margin:10px 0 0">끝낸 회차는 눌러서 다시 할 수 있어요.</p>
        </div>
        ${sayHTML(bub, { n, w: wrongCount(), k: nl ? nl.new.length : 0 })}
      </div>
      <div class="foot">${credit()}</div>`;
    const go = document.getElementById("go");
    if (go) go.onclick = () => (resume ? render("lesson") : startLesson(nx));
    document.getElementById("table").onclick = () => render("table");
    $app.querySelectorAll(".list button[data-no]").forEach((b) => b.onclick = () => {
      const no = +b.dataset.no;
      if (no > NY.OPEN_UNTIL) return;
      if (S.done.includes(no) || no === nx) startLesson(no);
    });
    Install.attach();
  }

  /* ── 화면: 글자 표 (히라가나·가타카나) ── */
  function tableHTML(learned, today, showKo, kata) {
    return `<div class="table">${TABLE.join("").split("").map((h) => {
      if (h === " ") return '<div class="empty"></div>';
      const ch = kata ? toKata(h) : h;
      const cls = today.includes(ch) ? "today" : learned.includes(ch) ? "got" : "";
      return `<div class="${cls}" data-k="${ch}">${ch}${showKo && learned.includes(ch) ? `<small>${ko(ch)}</small>` : ""}</div>`;
    }).join("")}</div>`;
  }
  function viewTable() {
    const learned = S.done.flatMap((no) => (lesson(no) ? lesson(no).new : []));
    const hira = learned.filter((k) => k.length === 1 && HIRA.includes(k));
    const kata = learned.filter((k) => k.length === 1 && isKata(k));
    $app.innerHTML = `
      <div class="top"><button class="x" id="back">← 홈</button><h1>글자 표</h1></div>
      <div class="main" style="justify-content:flex-start">
        <p class="lead">배운 글자는 진하게 보여요. 눌러서 소리를 들을 수 있어요.</p>
        <h3 class="tt">히라가나 ${hira.length} / 46</h3>
        ${tableHTML(hira, [], true, false)}
        <h3 class="tt">가타카나 ${kata.length} / 46</h3>
        ${tableHTML(kata, [], true, true)}
      </div>`;
    document.getElementById("back").onclick = () => render("home");
    $app.querySelectorAll(".table div[data-k]").forEach((d) => {
      const ch = d.dataset.k;
      if (learned.includes(ch)) d.onclick = () => play(kanaSound(ch));
    });
  }

  /* ── Lite 문장: 그 회차까지 읽을 수 있는 글자만 진하게 ── */
  function liteHTML(no, all) {
    const ok = (c) => all || canRead(c, no);
    return `<div class="lite">${NY.LITE_LINE.parts.map((p) => {
      const mark = (s) => s.split("").map((c) => `<span class="${ok(c) ? "k" : "u"}">${c}</span>`).join("");
      if (p.kanji) return `<ruby><span class="${p.r.split("").every(ok) ? "k" : "u"}">${p.t}</span><rt>${mark(p.r)}</rt></ruby>`;
      if (!p.r) return p.t;
      return mark(p.t);
    }).join("")}</div>`;
  }
  const LITE_PARTS = [["切符(きっぷ)", "표"], ["は", "~는 (조사라서 '와')"], ["インターネット", "인터넷"], ["で", "~으로"], ["予約(よやく)", "예약"], ["することも できます", "할 수도 있어요"]];

  /* ── 화면: 회차 진행 ── */
  function viewLesson() {
    const C = S.cur, it = C.plan[C.i], L = lesson(C.no);
    const total = C.plan.length - 1;
    const phase = it.t === "start" ? -1 : it.t === "rule" ? 1
      : ["card", "rowcard", "group", "compare", "vocab"].includes(it.t) ? 2
      : ["read", "phrase", "litefull"].includes(it.t) ? 3 : it.phase === "quiz" ? 4 : it.t === "done" ? 5 : 0;
    const names = ["복습", "원리", "새 글자", "읽기", "확인", "끝"];
    const head = it.t === "done" ? "" : `
      <div class="top"><button class="x" id="home" aria-label="저장하고 나가기">✕</button><h1>${C.no}회차 · ${esc(L.title)}</h1></div>
      <div class="bar"><i style="width:${(C.i / total) * 100}%"></i></div>
      <div class="steps">${names.map((n, i) => (i === phase ? `<b>${n}</b>` : n)).join("<span>·</span>")}</div>`;
    const showKo = C.no <= HINT_VISIBLE_UNTIL;
    let body = "", foot = "", say = null, vars = { k: L.new.length, n: S.done.length, w: wrongCount() };
    const nextBtn = (label) => `<button class="btn primary big" id="nx">${label || "다음"}</button>`;

    if (it.t === "start") {
      say = it.back ? line("back") : line("start");
      const show = L.new.length && L.new.length <= 6 ? L.new.join(" ") : L.title;
      body = `<div class="card center">
          <p class="lead">${it.back ? "오랜만이에요. 짧은 복습 다음에 이어 가요." : L.new.length ? "오늘 새로 배울 글자" : "오늘 배울 것"}</p>
          <div class="jp start-k${show.length > 12 ? " sm" : ""}">${esc(show)}</div>
          <p class="small" style="margin:0">약 10분 · 틀려도 다시 하라고 하지 않아요</p>
        </div>`;
      foot = nextBtn("시작");
    }

    else if (it.t === "rule") {
      const R = L.rule, row = R.row && NY.ROWS[R.row];
      const tr = (s) => (L.script === "kata" ? toKata(s) : s);
      const cells = (str, cls) => tr(str).split("").map((c) => c === " " ? '<span class="gap"></span>' : `<span class="${cls}${NY.IRREGULAR.includes(toHira(c)) ? " irr" : ""}">${c}</span>`).join("");
      const vow = NY.VOWELS.map((v) => `<span class="v">${v}</span>`).join("");
      let grid = "";
      if (row && R.row === "あ") grid = `<div class="rowgrid"><div class="r big">${cells("あいうえお", "k")}</div><div class="r">${vow}</div></div>`;
      else if (row && L.script === "kata") grid = `<div class="rowgrid"><div class="r mut">${row.kana.split("").map((c) => c === " " ? '<span class="gap"></span>' : `<span class="k">${c}</span>`).join("")}</div><div class="plus">같은 소리 · 다른 모양</div><div class="r big">${cells(row.kana, "k")}</div></div>`;
      else if (row) grid = `<div class="rowgrid"><div class="r mut">${cells("あいうえお", "k")}</div><div class="r">${vow}</div>
             <div class="plus">${esc(row.c)} + 모음</div><div class="r big">${cells(row.kana, "k")}</div></div>`;
      body = `<div class="card rule"><p class="eyebrow">오늘의 원리</p><h2>${esc(R.title)}</h2>${grid}
          ${R.lines.map((x) => `<p>${esc(x)}</p>`).join("")}</div>`;
      foot = nextBtn(L.kind === "grad" ? "문장 읽으러 가기" : L.kind === "examples" ? "예시 보기" : "글자 배우기");
    }

    else if (it.t === "card") {
      const [w, m] = L.cards[it.k];
      const first = L.new[0] === it.k;
      const kata = isKata(it.k);
      say = NY.NOTE[toHira(it.k)] && !kata ? { who: "eg", face: "work", text: NY.NOTE[toHira(it.k)] } : first && L.say ? L.say : null;
      const origin = kata
        ? (NY.ORIGIN_KATA[it.k] ? `${NY.ORIGIN_KATA[it.k]} → ${it.k} <span>한자의 한 부분을 떼어 온 모양</span>` : `<span>점 두 개와 긴 획으로 만든 기호에서 왔다는 설이 있어요</span>`)
        : `${NY.ORIGIN[it.k]} → ${it.k} <span>한자를 흘려 쓴 모양</span>`;
      body = `<div class="card center">
          <div class="kana-big">${it.k}</div>
          <button class="snd" id="s1">🔊 소리</button>
          <div class="hint" style="margin-top:10px">${showKo ? esc(ko(it.k)) : '<button id="hk">읽는 법 보기</button>'}</div>
          ${kata ? `<p class="pairline">히라가나 <b class="jp">${toHira(it.k)}</b> 와 같은 소리</p>` : ""}
          <p class="origin">${origin}</p>
          <div class="word"><span class="w">${esc(w)}</span><span class="m">${esc(m)}</span><button class="snd" id="s2">🔊</button></div>
        </div>`;
      foot = nextBtn();
    }

    else if (it.t === "rowcard") {
      const R = L.rows[it.i];
      const units = R.units.map((u) => `<button class="unit" data-u="${u}"><span>${u}</span><small>${esc(ko(u))}</small></button>`).join("");
      body = `<div class="card center"><p class="lead">${esc(R.label)}</p>
          ${units ? `<div class="units${R.units.length > 6 ? " many" : ""}${R.units.some((u) => u.length > 1) ? " wide" : ""}">${units}</div><p class="small" style="margin:8px 0 0">글자를 누르면 소리가 나요</p>` : `<div class="kana-big" style="font-size:96px">っ</div><p style="margin:0">소리 없이 한 박자 쉬어요</p>`}
          <div class="word"><span class="w">${esc(R.ex[0])}</span><span class="m">${esc(R.ex[1])}</span><button class="snd" id="s2">🔊</button></div></div>`;
      foot = nextBtn();
    }

    else if (it.t === "group") {
      const G = L.groups[it.i];
      body = `<div class="card"><p class="eyebrow">${it.i + 1} / ${L.groups.length}</p><h2 class="gt">${esc(G.title)}</h2><p class="small" style="margin:4px 0 10px">${esc(G.note)}</p>
          <div class="glist">${G.items.map(([w, m]) => `<button class="gi" data-w="${esc(w)}"><span class="jp">${esc(w)}</span><small>${esc(m)}</small><i>🔊</i></button>`).join("")}</div></div>`;
      foot = nextBtn();
    }

    else if (it.t === "compare") {
      const org = (k) => NY.ORIGIN[k] || NY.ORIGIN_KATA[k] || "";
      const lab = (k) => [NY.NO_HANGUL.includes(toHira(k)) ? "" : ko(k), org(k)].filter(Boolean).join(" · ");
      const wide = it.a.length > 1 || it.b.length > 1 ? " wide" : "";
      body = `<div class="card center"><p class="lead">헷갈리기 쉬운 두 글자</p>
          <div class="cmp${wide}"><button class="cmpk" id="ca"><span>${it.a}</span><small>${esc(lab(it.a))}</small></button>
          <button class="cmpk" id="cb"><span>${it.b}</span><small>${esc(lab(it.b))}</small></button></div>
          <p style="margin:12px 0 0">${esc(it.tip)}</p><p class="small" style="margin:4px 0 0">글자를 누르면 소리가 나요</p></div>`;
      foot = nextBtn();
    }

    else if (it.t === "vocab") {
      body = `<div class="card"><p class="eyebrow">오늘의 단어장 · ${L.words.length}개</p>
          <p class="small" style="margin:4px 0 10px">모두 외울 필요는 없어요. 눌러서 들어 보고, 읽히는지만 확인해요.</p>
          <div class="glist">${L.words.map(([w, m]) => `<button class="gi" data-w="${esc(w)}"><span class="jp">${esc(w)}</span><small>${esc(m)}</small><i>🔊</i></button>`).join("")}</div></div>`;
      foot = nextBtn("읽기 연습");
    }

    else if (it.t === "read") {
      const chars = it.w.split("").map((c) => c === " " ? "&nbsp;" : `<span class="ch">${c}${showKo ? `<i>${NY.NO_HANGUL.includes(c) ? "&nbsp;" : esc(ko(c))}</i>` : ""}</span>`).join("");
      body = `<div class="card center">
          <p class="lead">소리 내어 읽어 보세요</p>
          <div class="read-w${it.w.length > 6 ? " long" : ""}">${chars}</div>
          <div class="reveal" id="rv"></div>
          <button class="btn" id="cmp" style="margin-top:8px">🔊 듣고 비교하기</button>
        </div>`;
      foot = nextBtn();
    }

    else if (it.t === "phrase") {
      body = `<div class="card center"><p class="lead">${it.w.length > 10 ? "문장 읽기" : "이어 읽기"}</p>
          <div class="read-w long">${esc(it.w)}</div>
          <p class="small" style="margin:0">띄어 쓴 곳에서 살짝 쉬어 읽어요</p>
          <div class="reveal" id="rv"></div>
          <button class="btn" id="cmp" style="margin-top:8px">🔊 듣고 비교하기</button></div>`;
      foot = nextBtn();
    }

    else if (it.t === "litefull") {
      body = `<div class="card center"><p class="lead">스틸링고 Lite 문장, 처음부터 끝까지</p>${liteHTML(25, true)}
          <button class="snd" id="ls" style="margin-top:8px">🔊 들어 보기</button>
          <div class="glist" style="margin-top:12px;text-align:left">${LITE_PARTS.map(([a, b]) => `<div class="gi st"><span class="jp">${esc(a)}</span><small>${esc(b)}</small></div>`).join("")}</div>
          <p style="margin:12px 0 0"><b>${esc(NY.LITE_LINE.ko)}</b></p></div>`;
      say = { who: "tarae", face: "surprised", text: "다 읽혀요! 10회차엔 몇 글자뿐이었는데요. 뾰잉?" };
      foot = nextBtn("마지막 확인");
    }

    else if (it.t === "quiz") {
      const answered = it.picked != null;
      // 말풍선은 한 회차에 2~3번만: 틀렸을 때 위로는 그날 처음 한 번만 나온다(정답은 색으로만 알린다)
      if (answered && it.picked !== (it.ans != null ? it.ans : it.k) && it.comfort) say = line("wrong");
      let q = "", optsHTML = "";
      if (it.mode === "listen") {
        q = `<p class="lead">소리를 듣고 글자를 고르세요</p><button class="snd" id="qs" style="font-size:20px;padding:12px 22px">🔊 다시 듣기</button>`;
        optsHTML = it.opts.map((o) => `<button class="opt jp" data-v="${o}">${o}</button>`).join("");
      } else if (it.mode === "see") {
        q = `<p class="lead">이 글자의 소리는?</p><div class="q-kana">${it.k}</div>`;
        optsHTML = it.opts.map((o) => `<button class="opt" data-v="${o}">${esc(ko(o))}</button>`).join("");
      } else if (it.mode === "pair") {
        q = `<p class="lead">같은 소리의 히라가나는?</p><div class="q-kana">${it.k}</div>`;
        optsHTML = it.opts.map((o) => `<button class="opt jp" data-v="${o}">${o}</button>`).join("");
      } else if (it.mode === "row") {
        const c = NY.ROWS[it.row].c;
        q = `<p class="lead">자음 + 모음으로 찾기</p><div class="rowq"><b>${it.row}행</b> · <b>${NY.DAN[it.dan]}</b></div><p class="small" style="margin:6px 0 0">${esc(c)} + ${NY.VOWELS[it.dan]}</p>`;
        optsHTML = it.opts.map((o) => `<button class="opt jp" data-v="${o}">${o}</button>`).join("");
      } else if (it.mode === "hear") {
        q = `<p class="lead">소리를 듣고 단어를 고르세요</p><button class="snd" id="qs" style="font-size:20px;padding:12px 22px">🔊 다시 듣기</button>`;
        optsHTML = it.opts.map((o) => `<button class="opt jp wordopt" data-v="${esc(o)}">${esc(o)}</button>`).join("");
      } else {
        q = `<p class="lead">이 단어의 뜻은?</p><div class="read-w long">${esc(it.w)}</div>`;
        optsHTML = it.opts.map((o) => `<button class="opt" style="font-size:17px" data-v="${esc(o)}">${esc(o)}</button>`).join("");
      }
      body = `<div class="card center">${q}</div><div class="opts">${optsHTML}</div>`;
      foot = `<button class="btn primary big" id="nx" ${answered ? "" : "hidden"}>다음</button>`;
      vars.k = C.plan.filter((p) => p.phase === "review").length;
    }

    else if (it.t === "done") return viewDone();

    $app.innerHTML = head + `<div class="main">${body}${sayHTML(say, vars)}</div><div class="foot">${foot}</div>`;

    /* 동작 연결 */
    const on = (id, fn) => { const el = document.getElementById(id); if (el) el.onclick = fn; };
    on("home", exitSheet);
    on("nx", () => step(1));
    if (it.t === "card") {
      const [w] = L.cards[it.k];
      on("s1", (e) => play(kanaSound(it.k), e.currentTarget));
      on("s2", (e) => play(w, e.currentTarget));
      on("hk", (e) => { e.currentTarget.parentNode.textContent = ko(it.k); });
      setTimeout(() => play(kanaSound(it.k), document.getElementById("s1")), 250);
    }
    if (it.t === "rowcard") {
      $app.querySelectorAll(".unit").forEach((b) => b.onclick = () => play(kanaSound(b.dataset.u), b));
      on("s2", (e) => play(L.rows[it.i].ex[0], e.currentTarget));
    }
    if (it.t === "group" || it.t === "vocab") $app.querySelectorAll(".gi[data-w]").forEach((b) => b.onclick = () => play(b.dataset.w, b));
    if (it.t === "compare") {
      on("ca", (e) => play(kanaSound(it.a), e.currentTarget));
      on("cb", (e) => play(kanaSound(it.b), e.currentTarget));
    }
    if (it.t === "litefull") on("ls", (e) => play(NY.LITE_LINE.audio, e.currentTarget));
    if (it.t === "read" || it.t === "phrase") on("cmp", () => {
      play(it.w);
      document.getElementById("rv").innerHTML = `<b class="jp">${esc(it.w)}</b> · ${esc(it.ko)}`;
    });
    if (it.t === "quiz") {
      const ans = it.ans != null ? it.ans : it.k;
      const sound = it.mode === "hear" ? it.ans : kanaSound(it.k);
      on("qs", (e) => play(sound, e.currentTarget));
      if ((it.mode === "listen" || it.mode === "hear") && it.picked == null) setTimeout(() => play(sound, document.getElementById("qs")), 250);
      const btns = $app.querySelectorAll(".opt");
      const mark = () => btns.forEach((b) => {
        b.disabled = true;
        if (b.dataset.v === ans) b.classList.add("ok");
        else if (b.dataset.v === it.picked) b.classList.add("ng");
      });
      if (it.picked != null) mark();
      btns.forEach((b) => b.onclick = () => {
        if (it.picked != null) return;
        it.picked = b.dataset.v;
        if (it.picked !== ans && !C.comforted) { it.comfort = true; C.comforted = true; }
        if (it.picked === ans) {
          C.right++;
          if (it.k && S.wrong[it.k]) { S.wrong[it.k]--; if (S.wrong[it.k] <= 0) delete S.wrong[it.k]; }
        } else if (it.k) {
          S.wrong[it.k] = (S.wrong[it.k] || 0) + 1;
          if (!C.wrongToday.includes(it.k)) C.wrongToday.push(it.k);
        }
        if (it.mode === "hear") play(it.ans); else if (it.mode !== "word") play(kanaSound(it.k));
        save(); viewLesson();
      });
    }
  }

  /* ── 저장하고 나가기: 진행은 화면마다 자동 저장된다. 나갈 때 그 사실을 알려 준다 ── */
  function exitSheet() {
    const C = S.cur;
    const left = C.plan.length - 1 - C.i;
    const box = document.createElement("div");
    box.className = "sheet";
    box.innerHTML = `<div class="sheet-box" role="dialog" aria-label="저장하고 나가기">
        <h3>💾 저장하고 나갈까요?</h3>
        <p>${C.no}회차, 지금 화면까지 이 휴대폰에 저장돼 있어요. 다음에 열면 홈에서 <b>이어하기</b>를 누르면 이 자리부터 시작해요.</p>
        <p class="small">남은 화면 ${left}개</p>
        <div class="row"><button class="btn" id="exGo">저장하고 나가기</button><button class="btn primary" id="exStay">계속하기</button></div>
      </div>`;
    document.body.appendChild(box);
    const close = () => box.remove();
    box.addEventListener("click", (e) => { if (e.target === box) close(); });
    box.querySelector("#exStay").onclick = close;
    box.querySelector("#exGo").onclick = () => { save(); close(); render("home"); };
  }

  /* ── 화면: 완료 ── */
  function viewDone() {
    const C = S.cur, L = lesson(C.no);
    if (!S.done.includes(C.no)) { S.done.push(C.no); S.done.sort((a, b) => a - b); }
    S.last = Date.now(); save();
    const stageEnd = NY.STAGES.find((s) => s.to === C.no);
    const preview = NY.LITE_LINE.previewAt.includes(C.no);
    const vars = { n: S.done.length, w: wrongCount(), k: L.new.length };
    const learned = learnedUpTo(C.no);
    const kataDay = L.script === "kata";
    const showTable = L.kind === "kana";
    const tbl = showTable ? `<div class="mini">${tableHTML(learned.filter((k) => k.length === 1 && isKata(k) === kataDay), L.new, false, kataDay)}</div>` : "";
    const reward = L.reward ? `<div class="card"><div class="reward">이제 이 단어를 읽을 수 있어요<span class="jp">${esc(L.reward[0])}</span><span class="small">${esc(L.reward[1])}</span></div></div>` : "";
    const tip = L.tip ? `<div class="card tipcard"><p class="eyebrow">오늘의 한마디</p><p>${esc(L.tip)}</p></div>` : "";
    const grad = L.kind === "grad" ? `<div class="card center grad"><b>🎓 스틸링고 입문 졸업</b>
        <p>히라가나·가타카나를 읽고, 후리가나를 보면서 Lite 문장을 끝까지 읽었어요.</p>
        <a class="btn primary" href="${LITE_URL}">스틸링고 Lite 열기</a>
        <p class="small" style="margin:8px 0 0">사내 일본어 동호회에서 Lite로 함께 공부해요. 모임 안내는 앱을 알려 준 사람에게 물어봐 주세요.</p></div>` : "";
    $app.innerHTML = `
      <div class="top"><h1>${C.no}회차 끝</h1></div>
      <div class="main">
        ${grad}${reward}${tbl}
        ${stageEnd && L.kind !== "grad" ? `<div class="card center"><b>🎉 ${stageEnd.name} 단계 완료</b><p class="small" style="margin:4px 0 0">${STAGE_DONE[stageEnd.id]}</p></div>` : ""}
        ${preview ? `<div class="card center"><p class="lead" style="margin-bottom:4px">스틸링고 Lite 문장 미리보기</p>${liteHTML(C.no)}<p class="small" style="margin:0">${esc(NY.LITE_LINE.ko)} · 진한 글자는 벌써 읽을 수 있어요. 25회차엔 전부 읽혀요.</p><button class="snd" id="ls" style="margin-top:8px">🔊 들어 보기</button></div>${sayHTML(line("preview"))}` : ""}
        ${tip}
        <p class="small center" style="margin:0">25회 중 ${S.done.length}회 완료</p>
        ${preview ? "" : sayHTML(wrongCount() ? NY.LINES.progress[0] : line("done"), vars)}
      </div>
      <div class="foot"><button class="btn primary big" id="hm">홈으로</button></div>`;
    S.cur = null; save();
    document.getElementById("hm").onclick = () => render("home");
    const ls = document.getElementById("ls");
    if (ls) ls.onclick = (e) => play(NY.LITE_LINE.audio, e.currentTarget);
  }

  /* ── 라우팅 ── */
  let view = "home";
  function render(v) {
    if (v) view = v;
    window.scrollTo(0, 0);
    if (!S.intro) return viewIntro();
    if (view === "lesson" && S.cur) return viewLesson();
    if (view === "table") return viewTable();
    view = "home";
    return viewHome();
  }
  function toast(msg) {
    const t = document.createElement("div"); t.className = "toast"; t.textContent = msg;
    document.body.appendChild(t); setTimeout(() => t.remove(), 3500);
  }

  /* ── 설치 안내 (스틸링고 Lite와 같은 방식) ──
     링크를 카카오톡·팀즈로 보내면 대개 그 앱 안의 브라우저로 열린다. 거기서는 설치가 안 되므로 먼저 잡는다. */
  const Install = (function () {
    const note = document.getElementById("installNote"), title = document.getElementById("installTitle");
    const steps = document.getElementById("installSteps"), nowBtn = document.getElementById("installNow");
    const ua = navigator.userAgent;
    const standalone = window.matchMedia("(display-mode: standalone)").matches || navigator.standalone === true;
    const isIOS = /iphone|ipad|ipod/i.test(ua) || (/Macintosh/.test(ua) && navigator.maxTouchPoints > 1);
    const isAndroid = /android/i.test(ua);
    const inApp = /KAKAOTALK|Teams|MSTeams|NAVER|Line\/|band|DaumApps|Instagram|FB_IAB|FBAN|FBAV|everytime/i.test(ua);
    const DONE = "steel-lingo-nyumon-installed", SEEN = "steel-lingo-nyumon-install-seen";
    const get = (k) => { try { return localStorage.getItem(k) === "1"; } catch (e) { return false; } };
    const set = (k) => { try { localStorage.setItem(k, "1"); } catch (e) {} };
    let deferred = null;
    window.addEventListener("beforeinstallprompt", (e) => { e.preventDefault(); deferred = e; if (!note.hidden) open(); });
    window.addEventListener("appinstalled", () => { set(DONE); note.hidden = true; const b = document.getElementById("installBtn"); if (b) b.hidden = true; });
    function build() {
      if (inApp) {
        title.textContent = "📲 먼저 브라우저로 열어 주세요";
        return '<p><b>지금 카카오톡·팀즈 같은 앱 안에서 열려 있습니다.</b> 여기서는 설치가 되지 않습니다.</p><ol>' +
          '<li>화면 <b>오른쪽 위 메뉴</b>(⋯ 또는 ⋮)를 누릅니다</li><li><b>「다른 브라우저로 열기」</b>를 고릅니다' +
          (isIOS ? " — 아이폰은 <b>Safari</b>" : isAndroid ? " — 안드로이드는 <b>Chrome</b>" : "") + "</li></ol>";
      }
      if (isIOS) {
        title.textContent = "📲 홈 화면에 추가하기";
        return "<p><b>아이폰 · 아이패드 (Safari)</b></p><ol><li>화면 <b>아래쪽 공유 버튼</b>(□ 위에 화살표)을 누릅니다</li>" +
          "<li>목록을 내려 <b>「홈 화면에 추가」</b>를 고릅니다</li><li>오른쪽 위 <b>「추가」</b>를 누르면 끝입니다</li></ol>";
      }
      if (isAndroid) {
        title.textContent = "📲 앱으로 설치하기";
        return "<p><b>안드로이드 (Chrome)</b></p><ol>" + (deferred ? "<li>아래 <b>「지금 설치」</b> 버튼을 누릅니다</li>" :
          "<li>화면 <b>오른쪽 위 메뉴(⋮)</b>를 누릅니다</li><li><b>「앱 설치」</b> 또는 <b>「홈 화면에 추가」</b>를 고릅니다</li>") + "</ol>";
      }
      title.textContent = "📲 앱으로 설치하기";
      return "<p><b>컴퓨터 (Chrome · Edge)</b></p><ol>" + (deferred ? "<li>아래 <b>「지금 설치」</b> 버튼을 누릅니다</li>" : "") +
        "<li>주소창 오른쪽 끝의 <b>설치 아이콘</b>을 누릅니다</li><li>없으면 메뉴 → <b>「앱 설치」</b></li></ol>";
    }
    function open() {
      steps.innerHTML = build() + "<p>설치하면 아이콘을 눌러 앱처럼 열리고, 인터넷이 끊겨도 계속 쓸 수 있습니다.</p>";
      nowBtn.hidden = !deferred; note.hidden = false;
    }
    document.getElementById("installClose").onclick = () => { note.hidden = true; };
    nowBtn.onclick = async () => { if (!deferred) return; deferred.prompt(); const r = await deferred.userChoice; deferred = null; if (r.outcome === "accepted") set(DONE); note.hidden = true; };
    return {
      attach() {
        const b = document.getElementById("installBtn");
        if (!b || standalone || get(DONE)) return;
        b.hidden = false; b.onclick = open;
        let shown = false;
        try { shown = sessionStorage.getItem(SEEN) === "1"; sessionStorage.setItem(SEEN, "1"); } catch (e) {}
        if (!shown) setTimeout(() => { if (note.hidden) open(); }, 700);
      }
    };
  })();

  /* ── 오프라인 저장 ── */
  if ("serviceWorker" in navigator) {
    window.addEventListener("load", () => {
      navigator.serviceWorker.register("./sw.js").then(() => {
        if (navigator.serviceWorker.controller) navigator.serviceWorker.controller.postMessage({ type: "ensure-cache" });
      }).catch(() => {});
    });
  }

  // 하던 회차가 있으면 홈에서 '이어하기'로 보인다
  render("home");
  window.__ny = { S, render, toast };
})();
