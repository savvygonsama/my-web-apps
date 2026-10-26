/* 스틸링고 입문 — 화면

   하루 흐름(매일 같은 순서): 시작 → 복습 → 새 글자 카드 → 단어 읽기 → 확인 퀴즈 → 완료
   - 회차를 시작하면 그날 할 화면 목록(plan)을 만들어 저장한다. 중간에 닫았다 열면 그 자리에서 이어진다.
   - 틀려도 다시 하라고 하지 않는다. 틀린 글자는 다음 복습에 자동으로 들어간다.
   - 점수로 회차를 잠그지 않는다. 통과·미달 판정이 없다.
   - 연속 기록이 없다. 이틀 넘게 쉬었다가 열면 2분짜리 복귀 복습만 하고 이어 간다. */
(function () {
  "use strict";
  const $app = document.getElementById("app");
  const KEY = "steel-lingo-nyumon-v1";
  const DAY = 86400000;
  const HIRA = "あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん";
  const TABLE = ["あいうえお","かきくけこ","さしすせそ","たちつてと","なにぬねの","はひふへほ","まみむめも","や ゆ よ","らりるれろ","わ   を","ん    "];
  const HINT_VISIBLE_UNTIL = 5;      // 1~5회차는 한글 소리가 보이고, 6회차부터는 눌러야 보인다
  const MIX_FROM = 8;                // 8회차(2주째)부터 복습을 섞는다. 그 전에는 전날 글자만
  const REVIEW_MAX = 5, BACK_MAX = 5, KANA_Q = 5;   // 확인 퀴즈 8문제 = 글자 5 + 행·단 1 + 단어 듣기 1 + 단어 뜻 1

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
  const learnedUpTo = (no) => NY.LESSONS.filter((l) => l.no <= no).flatMap((l) => l.new);
  const nextNo = () => { for (let i = 1; i <= NY.TOTAL; i++) if (!S.done.includes(i)) return i; return NY.TOTAL + 1; };
  const wrongCount = () => Object.keys(S.wrong).length;
  function fill(t, v) { return t.replace(/\{(\w)\}/g, (_, k) => (v && v[k] != null ? v[k] : "")); }

  /* ── 소리: 미리 만든 파일만 쓴다(기기 음성은 쓰지 않는다) ── */
  const player = new Audio();
  function play(text, btn) {
    const f = NY.AUDIO[text];
    if (!f) return;
    player.pause(); player.src = "audio/" + f; player.currentTime = 0;
    document.querySelectorAll(".snd.on").forEach((b) => b.classList.remove("on"));
    if (btn) { btn.classList.add("on"); player.onended = () => btn.classList.remove("on"); }
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

  /* ── 오답 보기: 모양이 비슷한 글자부터 ── */
  function distractors(k, pool, n) {
    const out = [];
    const group = NY.LOOKALIKE.find((g) => g.includes(k)) || [];
    shuffle(group).forEach((x) => { if (x !== k && pool.includes(x) && !out.includes(x)) out.push(x); });
    shuffle(pool).forEach((x) => { if (x !== k && !out.includes(x) && NY.KANA[x] !== NY.KANA[k]) out.push(x); });
    return out.slice(0, n);
  }
  function quizItem(k, pool, mode) {
    // 한글로 옮기면 소리가 틀리게 굳는 글자(つ·ん)는 '소리 보기' 문제로 내지 않는다
    if (mode === "see") {
      if (NY.NO_HANGUL.includes(k)) mode = "listen";
      else pool = pool.filter((x) => !NY.NO_HANGUL.includes(x));
    }
    const opts = shuffle([k].concat(distractors(k, pool, 3)));
    return { t: "quiz", mode, k, opts };
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
      let base = no < MIX_FROM ? lesson(no - 1).new.slice() : shuffle(before);
      let items = wrong.concat(base.filter((k) => !wrong.includes(k)));
      items = items.slice(0, back ? BACK_MAX : REVIEW_MAX);
      shuffle(items).forEach((k) => plan.push(Object.assign(quizItem(k, before.length >= 4 ? before : pool, "listen"), { phase: "review" })));
    }
    // 원리 카드 → 새 글자 → 헷갈리는 글자 비교 → 단어 읽기 → 두 단어 이어 읽기
    if (L.rule) plan.push({ t: "rule" });
    L.new.forEach((k) => plan.push({ t: "card", k }));
    (L.compare || []).forEach(([a, b, tip]) => plan.push({ t: "compare", a, b, tip }));
    L.read.forEach(([w, ko]) => plan.push({ t: "read", w, ko }));
    if (L.phrase) plan.push({ t: "phrase", w: L.phrase[0], ko: L.phrase[1] });

    // 확인 퀴즈: 오늘 글자 5문제. 새 글자가 적은 날은 배운 글자에서 채운다.
    let today = shuffle(L.new);
    if (today.length < 3) today = today.concat(shuffle(pool.filter((k) => !L.new.includes(k))).slice(0, KANA_Q - today.length));
    const q = [];
    for (let i = 0; q.length < KANA_Q && i < 20; i++) {
      const k = today[i % today.length];
      q.push(quizItem(k, pool, i % 2 ? "see" : "listen"));
    }
    // 행·단 문제: 'か행의 い단 글자는?' — 규칙(자음 + 모음)으로 글자를 찾게 한다. 2회차부터.
    const rowItem = buildRowQuiz(no, L, pool);
    if (rowItem) q.push(rowItem); else q.push(quizItem(pick(L.new), pool, "listen"));
    // 단어 듣기: 소리를 듣고 여러 글자로 된 단어를 고른다
    const words = [...new Set(NY.LESSONS.filter((l) => l.no <= no).flatMap((l) => l.read.map((r) => r[0])))];
    const hw = pick(L.read)[0];
    const near = shuffle(words.filter((w) => w !== hw && Math.abs(w.length - hw.length) <= 1));
    q.push({ t: "quiz", mode: "hear", ans: hw, opts: shuffle([hw].concat(near.slice(0, 3))) });
    const rw = pick(L.read);
    const meanings = NY.LESSONS.filter((l) => l.no <= no).flatMap((l) => l.read.map((r) => r[1]).concat(Object.values(l.cards).map((c) => c[1])));
    const others = shuffle([...new Set(meanings)]).filter((m) => m !== rw[1]);
    q.push({ t: "quiz", mode: "word", w: rw[0], ans: rw[1], opts: shuffle([rw[1]].concat([...new Set(others)].slice(0, 3))) });
    shuffle(q).forEach((x) => plan.push(Object.assign(x, { phase: "quiz" })));
    plan.push({ t: "done" });
    return plan;
  }

  function rowOf(k) { return Object.keys(NY.ROWS).find((r) => NY.ROWS[r].kana.includes(k)); }
  function buildRowQuiz(no, L, pool) {
    if (no < 2) return null;
    const regular = (k) => !NY.IRREGULAR.includes(k) && rowOf(k) !== "あ";
    const cand = shuffle(L.new.filter(regular));
    if (!cand.length) return null;
    const k = cand[0], row = rowOf(k), dan = NY.ROWS[row].kana.indexOf(k);
    // 오답: 같은 줄의 다른 글자, 같은 단의 다른 줄 글자
    const others = shuffle(pool.filter((x) => x !== k && regular(x) && (rowOf(x) === row || NY.ROWS[rowOf(x)].kana.indexOf(x) === dan)));
    const fill2 = shuffle(pool.filter((x) => x !== k && !others.includes(x)));
    return { t: "quiz", mode: "row", k, row, dan, opts: shuffle([k].concat(others.concat(fill2).slice(0, 3))) };
  }

  function startLesson(no) {
    const back = S.last && Date.now() - S.last >= 2 * DAY && S.done.length > 0;
    S.cur = { no, i: 0, plan: buildPlan(no, back), right: 0, wrongToday: [] };
    save(); render("lesson");
  }
  function step(n) { S.cur.i = Math.max(0, Math.min(S.cur.plan.length - 1, S.cur.i + n)); save(); render("lesson"); }

  /* ── 화면: 첫 소개 ── */
  function viewIntro() {
    const imgs = NY.LINES.intro.map((l) => `<img src="char/${l.who}_${l.face}.webp" alt="${NY.CHARS[l.who].name}">`).join("");
    let i = 0;
    $app.innerHTML = `
      <div class="top"><h1>스틸링고 입문</h1><button class="pill" id="installBtn" hidden>📲 설치</button></div>
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
    const mainBtn = resume
      ? `<button class="btn primary big" id="go">이어하기<small>${S.cur.no}회차 · 하던 자리부터</small></button>`
      : open
        ? `<button class="btn primary big" id="go">오늘 할 것 시작<small>${nx}회차 · 약 10분</small></button>`
        : `<button class="btn big" disabled>${nx > NY.TOTAL ? "25회 모두 끝" : nx + "회차는 준비 중"}</button>`;
    const bub = !open && nx <= NY.TOTAL ? line("locked") : n ? NY.LINES.progress[wrongCount() ? 0 : 1] : line("start");
    $app.innerHTML = `
      <div class="top"><h1>스틸링고 입문</h1><button class="pill" id="installBtn" hidden>📲 설치</button></div>
      <div class="main">
        <div class="card">
          <div class="prog"><b>${n}</b><span class="lead">/ 25회 완료</span></div>
          <div class="stages">${stages}</div>
        </div>
        ${mainBtn}
        <div class="card">
          <div class="row" style="justify-content:space-between;align-items:center;margin-bottom:10px"><b>회차</b><button class="pill" id="table">글자 표 보기</button></div>
          <div class="list">${list}</div>
          <p class="small" style="margin:10px 0 0">지금은 베타라 1~10회차(히라가나)만 열려 있어요. 끝낸 회차는 눌러서 다시 할 수 있어요.</p>
        </div>
        ${sayHTML(bub, { n, w: wrongCount(), k: open && lesson(nx) ? lesson(nx).new.length : 0 })}
      </div>
      <div class="foot"><p class="note">기획과 구성 by 곤사마 · 음성 VOICEVOX:No.7 · 캐릭터 스틸 그레이드 가챠</p></div>`;
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

  /* ── 화면: 글자 표 ── */
  function tableHTML(learned, today, showKo) {
    return `<div class="table">${TABLE.join("").split("").map((ch) => {
      if (ch === " ") return '<div class="empty"></div>';
      const cls = today.includes(ch) ? "today" : learned.includes(ch) ? "got" : "";
      return `<div class="${cls}">${ch}${showKo && learned.includes(ch) ? `<small>${NY.KANA[ch]}</small>` : ""}</div>`;
    }).join("")}</div>`;
  }
  function viewTable() {
    const learned = S.done.flatMap((no) => (lesson(no) ? lesson(no).new : []));
    $app.innerHTML = `
      <div class="top"><button class="x" id="back">← 홈</button><h1>글자 표</h1></div>
      <div class="main" style="justify-content:flex-start">
        <p class="lead">배운 글자는 진하게 보여요. 눌러서 소리를 들을 수 있어요.</p>
        ${tableHTML(learned, [], true)}
        <p class="small">히라가나 ${learned.length} / ${HIRA.length}자</p>
      </div>`;
    document.getElementById("back").onclick = () => render("home");
    $app.querySelectorAll(".table div").forEach((d) => {
      const ch = d.firstChild && d.firstChild.nodeValue;
      if (ch && learned.includes(ch)) d.onclick = () => play(kanaSound(ch));
    });
  }

  /* ── Lite 문장 미리보기: 그 회차까지 읽을 수 있는 글자만 진하게 ── */
  function readable(ch, no) {
    if (HIRA.includes(ch)) return learnedUpTo(no).includes(ch);
    if (ch === "" ) return true;
    return false;      // 탁음·요음·장음·가타카나는 11회차 이후에 열린다
  }
  function liteHTML(no) {
    return `<div class="lite">${NY.LITE_LINE.parts.map((p) => {
      const mark = (s) => s.split("").map((c) => `<span class="${readable(c, no) ? "k" : "u"}">${c}</span>`).join("");
      if (p.kanji) return `<ruby><span class="${p.r.split("").every((c) => readable(c, no)) ? "k" : "u"}">${p.t}</span><rt>${mark(p.r)}</rt></ruby>`;
      if (!p.r) return p.t;
      return mark(p.t);
    }).join("")}</div>`;
  }

  /* ── 화면: 회차 진행 ── */
  function viewLesson() {
    const C = S.cur, it = C.plan[C.i], L = lesson(C.no);
    const total = C.plan.length - 1;
    const phase = it.t === "start" ? -1 : it.t === "rule" ? 1 : (it.t === "card" || it.t === "compare") ? 2 : (it.t === "read" || it.t === "phrase") ? 3 : it.phase === "quiz" ? 4 : it.t === "done" ? 5 : 0;
    const names = ["복습", "원리", "새 글자", "읽기", "확인", "끝"];
    const head = it.t === "done" ? "" : `
      <div class="top"><button class="x" id="home" aria-label="저장하고 나가기">✕</button><h1>${C.no}회차 · ${esc(L.title)}</h1></div>
      <div class="bar"><i style="width:${(C.i / total) * 100}%"></i></div>
      <div class="steps">${names.map((n, i) => (i === phase ? `<b>${n}</b>` : n)).join("<span>·</span>")}</div>`;
    const showKo = C.no <= HINT_VISIBLE_UNTIL;
    let body = "", foot = "", say = null, vars = { k: L.new.length, n: S.done.length, w: wrongCount() };

    if (it.t === "start") {
      say = it.back ? line("back") : line("start");
      body = `<div class="card center">
          <p class="lead">${it.back ? "오랜만이에요. 짧은 복습 다음에 이어 가요." : "오늘 새로 배울 글자"}</p>
          <div class="jp" style="font-size:52px;letter-spacing:8px;margin:8px 0">${L.new.join("")}</div>
          <p class="small" style="margin:0">약 10분 · 틀려도 다시 하라고 하지 않아요</p>
        </div>`;
      foot = `<button class="btn primary big" id="nx">시작</button>`;
    }

    else if (it.t === "rule") {
      const R = L.rule, row = NY.ROWS[R.row];
      const cells = (str, cls) => str.split("").map((c) => c === " " ? '<span class="gap"></span>' : `<span class="${cls}${NY.IRREGULAR.includes(c) ? " irr" : ""}">${c}</span>`).join("");
      const vow = NY.VOWELS.map((v) => `<span class="v">${v}</span>`).join("");
      const grid = R.row === "あ"
        ? `<div class="rowgrid"><div class="r big">${cells("あいうえお", "k")}</div><div class="r">${vow}</div></div>`
        : `<div class="rowgrid"><div class="r mut">${cells("あいうえお", "k")}</div><div class="r">${vow}</div>
             <div class="plus">${esc(row.c)} + 모음</div><div class="r big">${cells(row.kana, "k")}</div></div>`;
      body = `<div class="card rule"><p class="eyebrow">오늘의 원리</p><h2>${esc(R.title)}</h2>${grid}
          ${R.lines.map((x) => `<p>${esc(x)}</p>`).join("")}</div>`;
      foot = `<button class="btn primary big" id="nx">글자 배우기</button>`;
    }

    else if (it.t === "compare") {
      body = `<div class="card center"><p class="lead">헷갈리기 쉬운 두 글자</p>
          <div class="cmp"><button class="cmpk" id="ca"><span>${it.a}</span><small>${esc(NY.KANA[it.a])} · ${NY.ORIGIN[it.a]}</small></button>
          <button class="cmpk" id="cb"><span>${it.b}</span><small>${esc(NY.KANA[it.b])} · ${NY.ORIGIN[it.b]}</small></button></div>
          <p style="margin:12px 0 0">${esc(it.tip)}</p><p class="small" style="margin:4px 0 0">글자를 누르면 소리가 나요</p></div>`;
      foot = `<button class="btn primary big" id="nx">다음</button>`;
    }

    else if (it.t === "phrase") {
      body = `<div class="card center"><p class="lead">두 단어 이어 읽기</p>
          <div class="read-w" style="font-size:46px">${esc(it.w)}</div>
          <p class="small" style="margin:0">띄어 쓴 곳에서 살짝 쉬어 읽어요</p>
          <div class="reveal" id="rv"></div>
          <button class="btn" id="cmp" style="margin-top:8px">🔊 듣고 비교하기</button></div>`;
      foot = `<button class="btn primary big" id="nx">다음</button>`;
    }

    else if (it.t === "card") {
      const [w, m] = L.cards[it.k];
      const first = L.new[0] === it.k;
      say = NY.NOTE[it.k] ? { who: "eg", face: "work", text: NY.NOTE[it.k] } : first && L.say ? L.say : null;
      body = `<div class="card center">
          <div class="kana-big">${it.k}</div>
          <button class="snd" id="s1">🔊 소리</button>
          <div class="hint" style="margin-top:10px">${showKo ? esc(NY.KANA[it.k]) : '<button id="hk">읽는 법 보기</button>'}</div>
          <p class="origin">${NY.ORIGIN[it.k]} → ${it.k} <span>한자를 흘려 쓴 모양</span></p>
          <div class="word"><span class="w">${esc(w)}</span><span class="m">${esc(m)}</span><button class="snd" id="s2">🔊</button></div>
        </div>`;
      foot = `<button class="btn primary big" id="nx">다음</button>`;
    }

    else if (it.t === "read") {
      const chars = it.w.split("").map((c) => c === " " ? "&nbsp;" : `<span class="ch">${c}${showKo ? `<i>${NY.NO_HANGUL.includes(c) ? "&nbsp;" : esc(NY.KANA[c] || "")}</i>` : ""}</span>`).join("");
      body = `<div class="card center">
          <p class="lead">소리 내어 읽어 보세요</p>
          <div class="read-w">${chars}</div>
          <div class="reveal" id="rv"></div>
          <button class="btn" id="cmp" style="margin-top:8px">🔊 듣고 비교하기</button>
        </div>`;
      foot = `<button class="btn primary big" id="nx">다음</button>`;
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
        optsHTML = it.opts.map((o) => `<button class="opt" data-v="${o}">${esc(NY.KANA[o])}</button>`).join("");
      } else if (it.mode === "row") {
        const c = NY.ROWS[it.row].c;
        q = `<p class="lead">자음 + 모음으로 찾기</p><div class="rowq"><b>${it.row}행</b> · <b>${NY.DAN[it.dan]}</b></div><p class="small" style="margin:6px 0 0">${esc(c)} + ${NY.VOWELS[it.dan]}</p>`;
        optsHTML = it.opts.map((o) => `<button class="opt jp" data-v="${o}">${o}</button>`).join("");
      } else if (it.mode === "hear") {
        q = `<p class="lead">소리를 듣고 단어를 고르세요</p><button class="snd" id="qs" style="font-size:20px;padding:12px 22px">🔊 다시 듣기</button>`;
        optsHTML = it.opts.map((o) => `<button class="opt jp" style="font-size:26px" data-v="${esc(o)}">${esc(o)}</button>`).join("");
      } else {
        q = `<p class="lead">이 단어의 뜻은?</p><div class="read-w" style="font-size:48px">${esc(it.w)}</div>`;
        optsHTML = it.opts.map((o) => `<button class="opt" style="font-size:18px" data-v="${esc(o)}">${esc(o)}</button>`).join("");
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
      on("hk", (e) => { e.currentTarget.parentNode.textContent = NY.KANA[it.k]; });
      setTimeout(() => play(kanaSound(it.k), document.getElementById("s1")), 250);
    }
    if (it.t === "compare") {
      on("ca", (e) => play(kanaSound(it.a), e.currentTarget));
      on("cb", (e) => play(kanaSound(it.b), e.currentTarget));
    }
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
    const learned = learnedUpTo(C.no);
    const stageEnd = NY.STAGES.find((s) => s.to === C.no);
    const preview = NY.LITE_LINE.previewAt.includes(C.no);
    const vars = { n: S.done.length, w: wrongCount(), k: L.new.length };
    $app.innerHTML = `
      <div class="top"><h1>${C.no}회차 끝</h1></div>
      <div class="main">
        <div class="card">
          <div class="reward">이제 이 단어를 읽을 수 있어요<span class="jp">${esc(L.reward[0])}</span><span class="small">${esc(L.reward[1])}</span></div>
        </div>
        <div class="mini">${tableHTML(learned, L.new, false)}</div>
        ${stageEnd ? `<div class="card center"><b>🎉 ${stageEnd.name} 단계 완료</b><p class="small" style="margin:4px 0 0">히라가나 46자를 다 배웠어요</p></div>` : ""}
        ${preview ? `<div class="card center"><p class="lead" style="margin-bottom:4px">스틸링고 Lite 문장 미리보기</p>${liteHTML(C.no)}<p class="small" style="margin:0">${esc(NY.LITE_LINE.ko)} · 진한 글자는 벌써 읽을 수 있어요. 25회차엔 전부 읽혀요.</p><button class="snd" id="ls" style="margin-top:8px">🔊 들어 보기</button></div>${sayHTML(line("preview"))}` : ""}
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
