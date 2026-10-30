/* 한문장 — 화면

   하루 흐름: 시작 → (어제 문장 한 번) → [단계마다 3번 따라 읽기 + 🔍 해설을 한 화면에] × 단계 수 → 조립 퀴즈 → 완성 문장 3번 → 끝
   - 해설은 따라 읽는 화면 아래에 바로 붙는다. 문장이나 뜻을 가리지 않는다.
   - 하루에 새 문장은 하나. 오늘 끝냈으면 다음 문장은 기기 날짜로 내일 열린다. 밀린 날을 몰아서 열 수는 없다.
   - 끝낸 문장은 보관함에서 언제든 다시 듣고 다시 할 수 있다(기록 날짜는 바뀌지 않는다).
   - 채점·녹음·음성 인식은 없다. 따라 읽었으면 「읽었어요」를 누른다.
   - 시작하면 그날 할 화면 목록(plan)을 저장한다. 닫았다 열면 그 자리에서 이어진다.
   원고는 js/days.js, 캐릭터와 대사는 js/data.js. 이 파일은 화면만 다룬다. */
(function () {
  "use strict";
  const $app = document.getElementById("app");
  const KEY = "steel-lingo-hanmunjang-v1";
  const READS = 3;
  const GUIDE = [
    ["1번째", "천천히 듣고 따라 읽기"],
    ["2번째", "보통 속도로 따라 읽기"],
    ["3번째", "소리와 동시에 겹쳐 읽기"]
  ];
  const FINAL_GUIDE = [
    ["1번째", "천천히, 블록마다 끊어 읽기"],
    ["2번째", "보통 속도로 이어 읽기"],
    ["3번째", "소리와 동시에 겹쳐 읽기"]
  ];

  /* ── 저장 ── */
  const blank = () => ({ intro: false, done: {}, cur: null });
  let S = blank();
  try { S = Object.assign(blank(), JSON.parse(localStorage.getItem(KEY) || "{}")); } catch (e) {}
  const save = () => { try { localStorage.setItem(KEY, JSON.stringify(S)); } catch (e) {} };

  /* ── 도우미 ── */
  const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
  const pick = (a) => a[Math.floor(Math.random() * a.length)];
  const shuffle = (a) => { a = a.slice(); for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; };
  const fill = (t, v) => t.replace(/\{(\w)\}/g, (_, k) => (v && v[k] != null ? v[k] : ""));
  const dayOf = (n) => NY.DAYS.find((d) => d.day === n);
  const today = () => { const d = new Date(); return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0"); };
  const doneDays = () => Object.keys(S.done).map(Number).sort((a, b) => a - b);
  const nextDay = () => { for (let i = 1; i <= NY.TOTAL; i++) if (!S.done[i]) return i; return NY.TOTAL + 1; };
  const doneToday = () => Object.values(S.done).includes(today());

  /* ── 문장 표기: 한자[읽기] 와 {역할:새 블록} ── */
  const KANJI = /([一-龯々〆ヶ]+)\[([^\]]+)\]/g;
  const plain = (raw) => raw.replace(/\{\w+:/g, "").replace(/\}/g, "").replace(KANJI, "$1");
  const rubyOf = (raw, show) => esc(raw).replace(KANJI, show ? "<ruby>$1<rt>$2</rt></ruby>" : "$1");
  // "私[わたし]は{time:毎朝[まいあさ]}…" → [{t:"私[わたし]は"}, {t:"毎朝[まいあさ]", role:"time", fresh:true}, …]
  function parse(raw) {
    const out = [], re = /\{(\w+):([^}]*)\}/g;
    let last = 0, m;
    while ((m = re.exec(raw))) {
      if (m.index > last) out.push({ t: raw.slice(last, m.index) });
      out.push({ t: m[2], role: m[1], fresh: true });
      last = re.lastIndex;
    }
    if (last < raw.length) out.push({ t: raw.slice(last) });
    return out;
  }
  // 완성 문장: 그날 붙은 블록을 모두 찾아 역할 색을 입힌다(긴 블록부터).
  function fullSegs(D) {
    const spans = [];
    D.steps.forEach((s) => parse(s.r).forEach((p) => { if (p.role) spans.push(p); }));
    spans.sort((a, b) => b.t.length - a.t.length);
    let segs = [{ t: plainRaw(D.steps[D.steps.length - 1].r) }];
    spans.forEach((sp) => {
      for (let i = 0; i < segs.length; i++) {
        const g = segs[i];
        if (g.role) continue;
        const at = g.t.indexOf(sp.t);
        if (at < 0) continue;
        const parts = [];
        if (at > 0) parts.push({ t: g.t.slice(0, at) });
        parts.push({ t: sp.t, role: sp.role });
        if (at + sp.t.length < g.t.length) parts.push({ t: g.t.slice(at + sp.t.length) });
        segs.splice(i, 1, ...parts);
        break;
      }
    });
    return segs;
  }
  const plainRaw = (raw) => raw.replace(/\{\w+:/g, "").replace(/\}/g, "");
  function sentHTML(segs, o) {
    o = o || {};
    return segs.map((p, i) => {
      const inner = rubyOf(p.t, o.ruby !== false);
      if (!p.role || (o.onlyFresh && !p.fresh)) return `<span>${inner}</span>`;
      const c = NY.ROLES[p.role].c;
      return `<span class="blk c-${c}${p.fresh && o.onlyFresh ? " grow" : ""}" data-i="${i}">${inner}</span>`;
    }).join("");
  }
  function legendHTML(segs) {
    const seen = [];
    segs.forEach((p) => { if (p.role && !seen.includes(p.role)) seen.push(p.role); });
    return `<div class="legend">${seen.map((r) => `<span class="chip c-${NY.ROLES[r].c}">${NY.ROLES[r].name}</span>`).join("")}</div>`;
  }

  /* ── 소리: 미리 만든 음성 파일(audio/)이 있으면 그것, 없으면 기기의 일본어 음성 ── */
  const player = new Audio();
  let voice = null, warned = false;
  function findVoice() {
    if (!("speechSynthesis" in window)) return;
    const vs = speechSynthesis.getVoices().filter((v) => /^ja/i.test(v.lang));
    voice = vs.find((v) => /Kyoko|O-ren|Nanami|Haruka|Google/i.test(v.name)) || vs[0] || null;
  }
  if ("speechSynthesis" in window) { findVoice(); speechSynthesis.onvoiceschanged = findVoice; }
  function stopSound() {
    player.pause();
    if ("speechSynthesis" in window) speechSynthesis.cancel();
    document.querySelectorAll(".on").forEach((b) => b.classList.remove("on"));
  }
  function play(text, slow, btn) {
    stopSound();
    const off = () => btn && btn.classList.remove("on");
    if (btn) btn.classList.add("on");
    const f = NY.AUDIO && NY.AUDIO[text];
    if (f) {
      player.src = "audio/" + f; player.playbackRate = slow ? 0.8 : 1; player.onended = off;
      player.play().catch(off);
      return;
    }
    if (!("speechSynthesis" in window)) { off(); return toast("이 브라우저는 음성을 재생할 수 없어요."); }
    if (!voice) findVoice();
    if (!voice && !warned) { warned = true; toast("일본어 음성이 없으면 소리가 안 날 수 있어요. 설정 → 음성에서 일본어를 추가해 주세요."); }
    const u = new SpeechSynthesisUtterance(text);
    u.lang = "ja-JP"; if (voice) u.voice = voice;
    u.rate = slow ? 0.7 : 0.95;
    u.onend = off; u.onerror = off;
    speechSynthesis.speak(u);
  }

  /* ── 캐릭터 말풍선 ── */
  function sayHTML(l, vars) {
    if (!l) return '<div class="say"></div>';
    const c = NY.CHARS[l.who];
    return `<div class="say pop"><img src="char/${l.who}_${l.face}.webp" alt="${c.name}"><div class="b"><em>${c.name}</em>${esc(fill(l.text, vars))}</div></div>`;
  }
  const line = (k) => pick(NY.LINES[k]);

  /* ── 하루 계획 ── */
  function buildPlan(D) {
    const plan = [{ t: "start" }];
    const prev = dayOf(D.day - 1);
    if (prev && S.done[prev.day]) plan.push({ t: "warm" });
    D.steps.forEach((_, i) => { plan.push({ t: "read", s: i }); });
    plan.push({ t: "quiz" }, { t: "final" }, { t: "done" });
    return plan;
  }
  function startDay(n, review) {
    const D = dayOf(n);
    if (!D) return;
    S.cur = { day: n, i: 0, r: 0, plan: buildPlan(D), review: !!review, picked: [], miss: 0 };
    save(); render("lesson");
  }
  function step(d) {
    stopSound();
    S.cur.i = Math.max(0, Math.min(S.cur.plan.length - 1, S.cur.i + d));
    S.cur.r = 0; S.cur.picked = []; save(); render("lesson");
  }

  const top = (title) => `<div class="top"><h1>${title}</h1><button class="pill" id="installBtn" hidden>📲 설치</button></div>`;
  /* 스틸링고 시리즈 공통 머리: 코일 로고 + 「스틸링고」 + 앱 이름 꼬리표, 위에 기획과 구성 줄 (Lite와 같은 짜임) */
  const LOGO = `<svg class="logo" viewBox="0 0 76 58" role="img" aria-label="스틸링고 로고">
      <ellipse cx="56" cy="29" rx="10" ry="19" class="lg-body"/><rect x="20" y="10" width="36" height="38" class="lg-fill"/>
      <line x1="20" y1="10" x2="56" y2="10" class="lg-edge"/><line x1="20" y1="48" x2="56" y2="48" class="lg-edge"/>
      <ellipse cx="20" cy="29" rx="10" ry="19" class="lg-face"/><path d="M20 16 a7 13 0 1 1 -6.2 12.6 a4.2 7.6 0 1 0 6.2 -6.6" class="lg-spiral"/>
      <circle cx="36" cy="26" r="2.7" class="lg-eye"/><circle cx="47" cy="26" r="2.7" class="lg-eye"/>
      <path d="M37.5 34.5 q4 3.6 8 0" class="lg-smile"/><ellipse cx="31" cy="33" rx="2.8" ry="1.9" class="lg-cheek"/><ellipse cx="52" cy="33" rx="2.8" ry="1.9" class="lg-cheek"/>
    </svg>`;
  const mast = () => `<header class="masthead">
      <div class="mast-top"><p class="byline"><span class="c">&copy; 2026</span>기획과 구성 by 곤사마</p><button class="pill" id="installBtn" hidden>📲 설치</button></div>
      <div class="brand">${LOGO}<h1>스틸링고<span class="tag">한문장</span></h1></div>
    </header>`;
  const credit = () => `<div class="cr"><b>스틸링고 한문장 · 기획과 구성 by 곤사마</b><span>캐릭터 스틸 그레이드 가챠 · 음성 ${Object.keys(NY.AUDIO || {}).length ? "VOICEVOX:No.7" : "기기 일본어 음성"}</span></div>`;

  /* ── 화면: 첫 소개 ── */
  function viewIntro() {
    const imgs = NY.LINES.intro.map((l) => `<img src="char/${l.who}_${l.face}.webp" alt="${NY.CHARS[l.who].name}">`).join("");
    const D = NY.DAYS[0];
    const demo = D.steps.slice(0, 3).map((s, i) => `<div class="demo-l jp" style="animation-delay:${i * 0.5}s">${sentHTML(parse(s.r), { onlyFresh: true })}</div>`).join("");
    let i = 0;
    $app.innerHTML = `
      ${mast()}
      <div class="main">
        <div class="card center">
          <p class="eyebrow">일본어 쉐도잉 · 하루 한 문장</p>
          <h2 style="margin-top:4px">하루 딱 한 문장,<br>늘려 가며 따라 읽기</h2>
          <div class="demo">${demo}<div class="demo-more">⋯ 블록 7개짜리 문장까지</div></div>
        </div>
        <div class="card how">
          <p class="eyebrow">이렇게 해요 · 하루 10분</p>
          <ol>
            <li><b>짧은 문장에서 출발</b> — 「밥을 먹습니다」부터 블록을 하나씩 붙여요</li>
            <li><b>단계마다 3번 따라 읽기</b> — 천천히 → 보통 속도 → 소리와 동시에</li>
            <li><b>🔍 뜯어보기</b> — 읽는 화면 바로 아래에 새로 붙은 단어·한자·문법·틀리기 쉬운 것</li>
            <li><b>조립하고 한 번에</b> — 완성 문장을 블록으로 맞추고 처음부터 끝까지 3번</li>
          </ol>
          <p class="small" style="margin:8px 0 0">새 문장은 하루에 하나만 열려요. 끝낸 문장은 보관함에서 언제든 다시.</p>
        </div>
        <div class="friends">${imgs}</div>
        <div id="introSay">${sayHTML(NY.LINES.intro[0])}</div>
      </div>
      <div class="foot">
        <button class="btn" id="next">다음 친구</button>
        <button class="btn primary big" id="go">1일차 시작<small>${esc(D.title)} · 약 10분</small></button>
        ${credit()}
      </div>`;
    document.getElementById("next").onclick = () => {
      i = (i + 1) % NY.LINES.intro.length;
      document.getElementById("introSay").innerHTML = sayHTML(NY.LINES.intro[i]);
    };
    document.getElementById("go").onclick = () => { S.intro = true; save(); startDay(1); };
    Install.attach();
  }

  /* ── 화면: 홈 ── */
  function viewHome() {
    const n = doneDays().length, nx = nextDay(), D = dayOf(nx);
    const resume = S.cur && S.cur.plan[S.cur.i].t !== "done";
    let main, bub;
    if (resume) {
      const C = dayOf(S.cur.day);
      main = `<button class="btn primary big" id="go">이어하기<small>${S.cur.day}일차 · ${esc(C.title)} · 하던 자리부터</small></button>`;
      bub = line("start");
    } else if (nx > NY.TOTAL) {
      main = `<div class="card center"><b>🎓 ${NY.TOTAL}일, ${NY.TOTAL}문장 완성</b><p class="small" style="margin:4px 0 0">보관함에서 다시 듣고 다시 읽어 보세요.</p></div>`;
      bub = line("done");
    } else if (doneToday()) {
      main = `<div class="card center todaydone"><b>✓ 오늘 문장 끝</b><p class="small" style="margin:4px 0 0">${D ? `내일 ${nx}일차 「${esc(D.title)}」가 열려요` : `내일 ${nx}일차가 열려요`}</p></div>`;
      bub = line("wait");
    } else if (D) {
      main = `<button class="btn primary big" id="go">오늘의 문장 시작<small>${nx}일차 · ${esc(D.title)} · ${D.steps.length}단계 · 약 10분</small></button>`;
      bub = n ? NY.LINES.progress[0] : line("start");
    } else {
      main = `<div class="card center"><b>${nx}일차 준비 중</b><p class="small" style="margin:4px 0 0">지금까지 나온 ${NY.DAYS.length}문장은 모두 끝냈어요.</p></div>`;
      bub = NY.LINES.locked[0];
    }
    const cells = Array.from({ length: NY.TOTAL }, (_, k) => {
      const d = k + 1;
      return `<i class="${S.done[d] ? "done" : d === nx && !doneToday() && dayOf(d) ? "next" : ""}" title="${d}일차"></i>`;
    }).join("");
    const shelf = doneDays().map((d) => {
      const X = dayOf(d); if (!X) return "";
      return `<div class="shelf-i">
        <div class="shelf-h"><b>${d}일차 · ${esc(X.title)}</b><span class="small">${esc(S.done[d])}</span></div>
        <p class="jp shelf-s">${esc(plain(X.steps[X.steps.length - 1].r))}</p>
        <div class="row"><button class="snd" data-say="${d}">🔊 듣기</button><button class="snd" data-redo="${d}">↻ 다시 하기</button></div>
      </div>`;
    }).join("");
    $app.innerHTML = `
      ${mast()}
      <div class="main">
        <div class="card">
          <div class="prog"><b>${n}</b><span class="lead">/ ${NY.TOTAL}일 · 한 문장씩</span></div>
          <div class="cal">${cells}</div>
        </div>
        ${main}
        ${sayHTML(bub, { n, t: NY.TOTAL, k: D ? D.steps.length : 0 })}
        <div class="card">
          <b>문장 보관함</b>
          ${shelf || '<p class="small" style="margin:6px 0 0">완성한 문장이 여기에 쌓여요.</p>'}
        </div>
      </div>
      <div class="foot">${credit()}</div>`;
    const go = document.getElementById("go");
    if (go) go.onclick = () => (resume ? render("lesson") : startDay(nx));
    $app.querySelectorAll("[data-say]").forEach((b) => b.onclick = () => { const X = dayOf(+b.dataset.say); play(plain(X.steps[X.steps.length - 1].r), false, b); });
    $app.querySelectorAll("[data-redo]").forEach((b) => b.onclick = () => startDay(+b.dataset.redo, true));
    Install.attach();
  }

  /* ── 화면: 학습 ── */
  function viewLesson() {
    const C = S.cur, D = dayOf(C.day), it = C.plan[C.i];
    if (it.t === "done") return viewDone();
    if (it.t === "expl") return step(1);   // 해설이 따로 있던 이전 판에서 저장된 계획
    const pct = (C.i / (C.plan.length - 1)) * 100;
    const stepNo = it.s != null ? it.s + 1 : it.t === "quiz" || it.t === "final" ? D.steps.length : 0;
    const tower = D.steps.map((_, k) => `<i class="${k < stepNo ? "on" : ""}${k === stepNo - 1 && it.t === "read" ? " now" : ""}"></i>`).join("");
    let body = "", foot = "", say = null, after = null;
    const vars = { k: D.steps.length, b: D.quiz.blocks.length };

    if (it.t === "start") {
      body = `<div class="card center">
        <p class="eyebrow">${C.day}일차${C.review ? " · 다시 하기" : ""}</p>
        <h2 style="margin:4px 0 6px">${esc(D.title)}</h2>
        <p class="lead">오늘의 동사 <span class="jp big-v">${esc(D.verb)}</span></p>
        <p class="small" style="margin:10px 0 0">${D.steps.length}단계 · 단계마다 3번 · 오늘 배울 것: ${esc(D.gist)}</p>
      </div>`;
      say = line("start");
      foot = `<button class="btn primary big" id="nx">첫 블록부터</button>`;
    }

    if (it.t === "warm") {
      const P = dayOf(C.day - 1);
      body = `<div class="card">
        <p class="eyebrow">어제 문장 · ${P.day}일차 ${esc(P.title)}</p>
        <p class="sent jp">${sentHTML(fullSegs(P), { ruby: true })}</p>
        <p class="ko">${esc(P.steps[P.steps.length - 1].ko)}</p>
        <div class="center"><button class="snd" id="ply">🔊 듣기</button></div>
      </div>`;
      say = NY.LINES.warm[0];
      foot = `<button class="btn primary big" id="nx">한 번 읽었어요</button>`;
      after = () => { const b = document.getElementById("ply"); b.onclick = () => play(plain(P.steps[P.steps.length - 1].r), false, b); };
    }

    if (it.t === "read") {
      const st = D.steps[it.s], segs = parse(st.r), r = C.r;
      const fresh = segs.filter((p) => p.fresh).map((p) => `<span class="chip c-${NY.ROLES[p.role].c}">${esc(plain(p.t))} · ${NY.ROLES[p.role].name}</span>`).join("");
      const words = st.words.map((w, k) => `<button class="wcard" data-w="${k}">
          <span class="jp ww">${esc(w.w)}</span><span class="wy jp">${esc(w.y)}</span>
          <span class="wk">${esc(w.ko)}</span><span class="wp">${esc(w.pos)}</span>
          ${w.kanji ? `<span class="wh">${esc(w.kanji)}</span>` : ""}
        </button>`).join("");
      const gram = st.gram.map((g) => `<div class="gram"><b>${esc(g.t)}</b><p>${esc(g.d)}</p></div>`).join("");
      const trap = (st.trap || []).map((t) => `<div class="trap"><p class="ng jp">❌ ${esc(t.ng)}</p><p>${esc(t.why)}</p></div>`).join("");
      const tsay = st.say && r === 0 ? st.say : it.s === 0 && r === 2 ? line("read3") : null;
      body = `<div class="card">
          <p class="eyebrow">${it.s === 0 ? "출발 문장" : "새로 붙은 블록"}</p>
          <div class="legend">${fresh}</div>
          <p class="sent jp">${sentHTML(segs, { onlyFresh: true })}</p>
          <p class="ko">${esc(st.ko)}</p>
          <div class="guide"><b>${GUIDE[r][0]}</b> ${GUIDE[r][1]}</div>
          <div class="dots">${Array.from({ length: READS }, (_, k) => `<i class="${k < r ? "on" : k === r ? "cur" : ""}"></i>`).join("")}</div>
          <div class="center"><button class="snd" id="ply">${r === 0 ? "🐢 천천히 듣기" : "🔊 듣기"}</button></div>
        </div>
        ${tsay ? sayHTML(tsay) : ""}
        <div class="expl">
          <p class="expl-h">🔍 뜯어보기</p>
          <div class="sec"><p class="eyebrow">단어 · 누르면 소리</p><div class="words">${words}</div></div>
          <div class="sec"><p class="eyebrow">문법</p>${gram}</div>
          ${trap ? `<div class="sec"><p class="eyebrow">틀리기 쉬운 것</p>${trap}</div>` : ""}
          ${st.more ? `<details class="more"><summary>한 걸음 더</summary><p>${esc(st.more)}</p></details>` : ""}
          ${st.point ? sayHTML({ who: "eg", face: "work", text: st.point }) : ""}
        </div>`;
      const last = it.s === D.steps.length - 1;
      foot = `<button class="btn primary big" id="rd">${r < READS - 1 ? "읽었어요" : last ? "읽었어요 · 조립 퀴즈로" : "읽었어요 · 다음 블록 붙이기"}<small>${r + 1} / ${READS}</small></button>`;
      after = () => {
        const text = plain(st.r), b = document.getElementById("ply");
        b.onclick = () => play(text, r === 0, b);
        if (C.autoplay) { C.autoplay = false; setTimeout(() => play(text, r === 0, b), 250); }
        $app.querySelectorAll(".wcard").forEach((w) => w.onclick = () => play(st.words[+w.dataset.w].w, false, w));
        document.getElementById("rd").onclick = () => {
          if (C.r < READS - 1) { C.r++; C.autoplay = true; save(); render("lesson"); }
          else step(1);
        };
      };
    }

    if (it.t === "quiz") {
      const Q = D.quiz;
      if (!C.order) { C.order = shuffle(Q.blocks.map((_, k) => k)); save(); }
      const picked = C.picked || [];
      const complete = picked.length === Q.blocks.length;
      body = `<div class="card">
          <p class="eyebrow">조립 퀴즈</p>
          <p class="ko" style="margin-top:2px">${esc(D.steps[D.steps.length - 1].ko)}</p>
          <div class="slots jp${complete ? " ok" : ""}">${picked.map((k) => `<span>${esc(Q.blocks[k])}</span>`).join("") || '<span class="ph">블록을 순서대로 눌러 주세요</span>'}${complete ? "。" : ""}</div>
        </div>
        <div class="pool">${C.order.map((k) => `<button class="opt jp" data-k="${k}" ${picked.includes(k) ? "disabled" : ""}>${esc(Q.blocks[k])}</button>`).join("")}</div>
        ${picked.length && !complete ? '<div class="center"><button class="peek" id="undo">↩ 하나 되돌리기</button></div>' : ""}`;
      say = complete ? NY.LINES.quizOk[0] : C.miss ? C.lastSay : NY.LINES.quiz[0];
      foot = complete ? `<button class="btn primary big" id="nx">완성 문장 읽기</button>` : "";
      after = () => {
        $app.querySelectorAll(".pool .opt").forEach((b) => b.onclick = () => {
          const k = +b.dataset.k, next = picked.concat(k);
          const okay = Q.orders.some((o) => next.every((x, j) => o[j] === x));
          if (okay) { C.picked = next; save(); render("lesson"); }
          else {
            b.classList.add("ng"); setTimeout(() => b.classList.remove("ng"), 450);
            if (!C.miss) { C.lastSay = line("wrong"); C.miss = 1; save(); render("lesson"); }
          }
        });
        const u = document.getElementById("undo");
        if (u) u.onclick = () => { C.picked = picked.slice(0, -1); save(); render("lesson"); };
      };
    }

    if (it.t === "final") {
      const segs = fullSegs(D), r = C.r, last = D.steps[D.steps.length - 1];
      body = `<div class="card">
        <p class="eyebrow">완성 문장 · 처음부터 끝까지</p>
        <p class="sent jp">${sentHTML(segs, { ruby: true })}</p>
        ${legendHTML(segs)}
        <p class="ko">${esc(last.ko)}</p>
        <div class="guide"><b>${FINAL_GUIDE[r][0]}</b> ${FINAL_GUIDE[r][1]}</div>
        <div class="dots">${Array.from({ length: READS }, (_, k) => `<i class="${k < r ? "on" : k === r ? "cur" : ""}"></i>`).join("")}</div>
        <div class="center"><button class="snd" id="ply">${r === 0 ? "🐢 천천히 듣기" : "🔊 듣기"}</button></div>
      </div>`;
      say = r === 0 ? NY.LINES.final[0] : null;
      foot = `<button class="btn primary big" id="rd">읽었어요<small>${r + 1} / ${READS}</small></button>`;
      after = () => {
        const text = plain(last.r), b = document.getElementById("ply");
        b.onclick = () => play(text, r === 0, b);
        if (C.autoplay) { C.autoplay = false; setTimeout(() => play(text, r === 0, b), 250); }
        document.getElementById("rd").onclick = () => {
          if (C.r < READS - 1) { C.r++; C.autoplay = true; save(); render("lesson"); }
          else step(1);
        };
      };
    }

    $app.innerHTML = `
      <div class="top"><button class="x" id="home">← 홈</button><h1>${C.day}일차 · ${esc(D.title)}</h1></div>
      <div class="bar"><i style="width:${pct}%"></i></div>
      <div class="tower" aria-label="블록 ${stepNo} / ${D.steps.length}">${tower}<span>${stepNo ? `블록 ${stepNo}/${D.steps.length}` : "준비"}</span></div>
      <div class="main">${body}${sayHTML(say, vars)}</div>
      <div class="foot${it.t === "read" || it.t === "final" ? " sticky" : ""}">${foot}${C.i > 0 && it.t !== "quiz" ? '<button class="x back" id="prev">← 앞 화면</button>' : ""}</div>`;
    document.getElementById("home").onclick = () => { stopSound(); render("home"); };
    const nx = document.getElementById("nx");
    if (nx) nx.onclick = () => { C.autoplay = true; step(1); };
    const pv = document.getElementById("prev");
    if (pv) pv.onclick = () => step(-1);
    if (after) after();
  }

  /* ── 화면: 하루 끝 ── */
  function viewDone() {
    const C = S.cur, D = dayOf(C.day);
    if (!C.review && !S.done[C.day]) S.done[C.day] = today();
    const segs = fullSegs(D), first = D.steps[0], last = D.steps[D.steps.length - 1];
    const n = doneDays().length;
    const reads = D.steps.length * READS + READS;
    $app.innerHTML = `
      ${top(`${C.day}일차 완성`)}
      <div class="main">
        <div class="card center">
          <p class="eyebrow">🎉 오늘의 한 문장</p>
          <p class="from jp">${esc(plain(first.r))}</p>
          <p class="arrow">↓ 블록 ${D.quiz.blocks.length - 2}개를 붙여서</p>
          <p class="sent jp">${sentHTML(segs, { ruby: true })}</p>
          ${legendHTML(segs)}
          <p class="ko">${esc(last.ko)}</p>
          <button class="snd" id="ply">🔊 다시 듣기</button>
        </div>
        <p class="small center" style="margin:0">따라 읽기 ${reads}번 · ${NY.TOTAL}일 중 ${n}일 완료</p>
        ${sayHTML(C.review ? NY.LINES.done[1] : NY.LINES.done[0])}
        ${C.review ? "" : sayHTML(NY.LINES.progress[0], { n, t: NY.TOTAL })}
      </div>
      <div class="foot"><button class="btn primary big" id="hm">홈으로</button></div>`;
    S.cur = null; save();
    document.getElementById("hm").onclick = () => render("home");
    const b = document.getElementById("ply");
    b.onclick = () => play(plain(last.r), false, b);
  }

  /* ── 라우팅 ── */
  let view = "home";
  function render(v) {
    if (v) view = v;
    window.scrollTo(0, 0);
    if (!S.intro) return viewIntro();
    if (view === "lesson" && S.cur) return viewLesson();
    view = "home";
    return viewHome();
  }
  function toast(msg) {
    const t = document.createElement("div"); t.className = "toast"; t.textContent = msg;
    document.body.appendChild(t); setTimeout(() => t.remove(), 3500);
  }

  /* ── 설치 안내 (스틸링고 입문과 같은 방식) ──
     링크를 카카오톡·팀즈로 보내면 대개 그 앱 안의 브라우저로 열린다. 거기서는 설치가 안 되므로 먼저 잡는다. */
  const Install = (function () {
    const note = document.getElementById("installNote"), title = document.getElementById("installTitle");
    const steps = document.getElementById("installSteps"), nowBtn = document.getElementById("installNow");
    const ua = navigator.userAgent;
    const standalone = window.matchMedia("(display-mode: standalone)").matches || navigator.standalone === true;
    const isIOS = /iphone|ipad|ipod/i.test(ua) || (/Macintosh/.test(ua) && navigator.maxTouchPoints > 1);
    const isAndroid = /android/i.test(ua);
    const inApp = /KAKAOTALK|Teams|MSTeams|NAVER|Line\/|band|DaumApps|Instagram|FB_IAB|FBAN|FBAV|everytime/i.test(ua);
    const DONE = "steel-lingo-hanmunjang-installed", SEEN = "steel-lingo-hanmunjang-install-seen";
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

  render("home");
  window.__hm = { S, render, toast, plain, fullSegs };
})();
