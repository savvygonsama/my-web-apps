/* 스틸링고 出張編 — 화면과 진행.
   화면: 표지(title) → 일정표(map) → 플레이(play) → 챕터 결과(result) / 出張ノート(note) / 시즌 엔딩(ending) */
(function () {
  "use strict";
  const { ruby, esc, plain } = SH;
  const $ = (sel, root = document) => root.querySelector(sel);
  const app = $("#app");
  const html = document.documentElement;

  /* ═══════════ 상태 ═══════════ */
  const fresh = () => ({
    v: 1,
    settings: { easy: true, rate: 1 },
    exp: 0,
    chapters: {}, // id → { done, plays, delta, flags, grades, missed, bestCount }
    run: null, // { ch, at, hist:[{id,pick?}], delta, flags, grades, missed, order:{} }
    notes: {}, // "c3:moushimasu" → { t, ok, ng }
    seenIntro: false
  });
  let S = Object.assign(fresh(), SH.store.load() || {});
  S.settings = Object.assign(fresh().settings, S.settings);
  const save = () => { S.savedAt = Date.now(); return SH.store.save(S); };

  const STEP = 5; // 데이터의 효과 1점 = 게이지 5
  const clamp = (n) => Math.max(0, Math.min(100, n));
  function gauges() {
    let t = 0, l = 0;
    Object.entries(S.chapters).forEach(([id, c]) => {
      if (c.done && (!S.run || S.run.ch !== id)) { t += c.delta.trust || 0; l += c.delta.like || 0; }
    });
    if (S.run) { t += S.run.delta.trust || 0; l += S.run.delta.like || 0; }
    const lv = Math.floor(S.exp / 20) + 1;
    return { trust: clamp(50 + t * STEP), like: clamp(50 + l * STEP), jp: S.exp, lv, lvPct: ((S.exp % 20) / 20) * 100 };
  }
  function flags() {
    const f = new Set();
    Object.entries(S.chapters).forEach(([id, c]) => { if (c.done && (!S.run || S.run.ch !== id)) (c.flags || []).forEach((x) => f.add(x)); });
    if (S.run) S.run.flags.forEach((x) => f.add(x));
    return f;
  }
  /* 설정은 난이도 하나뿐이다.
     쉬움 = 대사 해석이 처음부터 보이고, 선택지 밑에도 한국어 뜻이 붙는다.
     어려움 = 해석은 '뜻' 버튼을 눌러야 보이고, 선택지는 일본어만 보고 고른다. 후리가나는 둘 다 켜 둔다. */
  const easy = () => !!S.settings.easy;
  function applySettings() {
    html.classList.toggle("easy", easy());
  }

  /* ═══════════ 음성 ═══════════ */
  const TTS = {
    voice: null,
    init() {
      if (!("speechSynthesis" in window) || typeof SpeechSynthesisUtterance === "undefined") return;
      const pick = () => {
        const vs = speechSynthesis.getVoices() || [];
        const v = vs.find((x) => /^ja[-_]JP$/i.test(x.lang)) || vs.find((x) => /^ja/i.test(x.lang));
        if (v) { this.voice = v; html.classList.add("has-tts"); }
      };
      pick();
      if (speechSynthesis.addEventListener) speechSynthesis.addEventListener("voiceschanged", pick);
      else speechSynthesis.onvoiceschanged = pick;
    },
    speak(text) {
      if (!this.voice) return;
      try {
        speechSynthesis.cancel();
        const u = new SpeechSynthesisUtterance(SH.speech(text));
        u.lang = "ja-JP"; u.voice = this.voice; u.rate = S.settings.rate;
        speechSynthesis.speak(u);
      } catch (e) { /* 음성 실패는 조용히 넘긴다 */ }
    }
  };
  const ttsBtn = (text) => `<button class="chip tts" data-say="${esc(text)}" aria-label="일본어 발음 듣기">🔊 듣기</button>`;
  const koBtn = () => `<button class="chip" data-ko aria-pressed="${easy()}">뜻</button>`;

  /* ═══════════ 공용 조각 ═══════════ */
  const ICON = {
    back: '<svg viewBox="0 0 24 24"><path d="M15 18l-6-6 6-6"/></svg>',
    gear: '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/></svg>',
    book: '<svg viewBox="0 0 24 24"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20V3H6.5A2.5 2.5 0 0 0 4 5.5z"/><path d="M4 19.5A2.5 2.5 0 0 0 6.5 22H20v-5"/></svg>'
  };
  const MASCOT = `<svg class="mascot" viewBox="0 0 100 80" role="img" aria-label="출장 가는 코일 마스코트">
    <g transform="translate(2 6)">
      <ellipse cx="56" cy="29" rx="10" ry="19" class="lg-body"/>
      <rect x="20" y="10" width="36" height="38" class="lg-fill"/>
      <line x1="20" y1="10" x2="56" y2="10" class="lg-edge"/>
      <line x1="20" y1="48" x2="56" y2="48" class="lg-edge"/>
      <ellipse cx="20" cy="29" rx="10" ry="19" class="lg-face"/>
      <path d="M20 16 a7 13 0 1 1 -6.2 12.6 a4.2 7.6 0 1 0 6.2 -6.6" class="lg-spiral"/>
      <circle cx="36" cy="24" r="2.7" class="lg-eye"/>
      <circle cx="47" cy="24" r="2.7" class="lg-eye"/>
      <path d="M37.5 31.5 q4 3.6 8 0" class="lg-smile"/>
      <ellipse cx="31" cy="30" rx="2.8" ry="1.9" class="lg-cheek"/>
      <ellipse cx="52" cy="30" rx="2.8" ry="1.9" class="lg-cheek"/>
      <path d="M39.3 38 h4.4 l-.8 3 h-2.8z M40 41 h3 l2 10 -3.5 4 -3.5 -4z" class="lg-tie"/>
      <rect x="70" y="44" width="24" height="20" rx="3" class="lg-bag"/>
      <path d="M77 44 v-4 h10 v4" fill="none" class="lg-bag"/>
      <line x1="70" y1="52" x2="94" y2="52" class="lg-bag"/>
    </g></svg>`;

  const GRADE = {
    best: { mark: "◎", title: "자연스러워요", sub: "현장에서 그대로 쓰는 말" },
    awkward: { mark: "△", title: "뜻은 통하지만 어색해요", sub: "조금만 바꾸면 완벽" },
    rude: { mark: "✕", title: "실례가 될 수 있어요", sub: "게임오버는 없어요. 여기서 배우면 됩니다" }
  };
  const GAUGE_NAME = { trust: "信頼度", like: "好感度" };

  function bar({ title, sub, back, right = "" }) {
    return `<header class="bar">
      ${back ? `<button class="icon-btn" data-act="${back}" aria-label="뒤로">${ICON.back}</button>` : '<span style="width:8px"></span>'}
      <h1>${title}${sub ? `<small>${sub}</small>` : ""}</h1>${right}</header>`;
  }
  const saveBtn = () => `<button class="save-btn" data-act="save" aria-label="지금까지 저장">💾 저장</button>`;

  function gaugeCards() {
    const g = gauges();
    const card = (k, name, ko, val, pct, cls) =>
      `<div class="gauge"><div class="gl"><b>${name}</b><span class="gv">${val}</span></div>
       <div class="meter ${cls}" role="meter" aria-label="${ko}" aria-valuenow="${Math.round(pct)}" aria-valuemin="0" aria-valuemax="100"><i style="width:${pct}%"></i></div>
       <div class="gl"><span>${ko}</span></div></div>`;
    return `<div class="gauges">
      ${card("trust", "信頼度", "고객 신뢰", g.trust, g.trust, "")}
      ${card("like", "好感度", "인간관계", g.like, g.like, "like")}
      ${card("jp", "日本語力", "경험치", "Lv." + g.lv, g.lvPct, "jp")}</div>`;
  }
  function miniGauges() {
    const g = gauges();
    return `<div class="mini-g" aria-label="신뢰 ${g.trust}, 호감 ${g.like}, 일본어 레벨 ${g.lv}">
      <span>信<span class="meter"><i style="width:${g.trust}%"></i></span></span>
      <span>好<span class="meter like"><i style="width:${g.like}%"></i></span></span>
      <span>Lv${g.lv}<span class="meter jp"><i style="width:${g.lvPct}%"></i></span></span></div>`;
  }

  let toastTimer = 0;
  function toast(htmlText) {
    const t = $("#toast");
    t.innerHTML = htmlText;
    t.classList.add("toast-on");
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => t.classList.remove("toast-on"), 2200);
  }

  /* ═══════════ 화면 이동(뒤로 가기 지원) ═══════════ */
  let view = { v: "title" };
  function go(v, params = {}, push = true) {
    view = Object.assign({ v }, params);
    if (push) try { history.pushState(view, ""); } catch (e) { /* file:// 등 */ }
    closeSheet();
    if ("speechSynthesis" in window) try { speechSynthesis.cancel(); } catch (e) {}
    ({ title: renderTitle, map: renderMap, play: renderPlay, result: renderResult, note: renderNote, ending: renderEnding }[v] || renderTitle)(params);
  }
  window.addEventListener("popstate", (e) => {
    const st = e.state || { v: "title" };
    if (sheetOpen()) { closeSheet(true); try { history.pushState(view, ""); } catch (x) {} return; }
    go(st.v, st, false);
  });

  /* ═══════════ 표지 ═══════════ */
  const levelDesc = () => easy()
    ? "대사 해석이 처음부터 보이고, 선택지 밑에 한국어 뜻이 붙어요."
    : "일본어만 보고 골라요. 해석은 '뜻' 버튼을 눌러야 보여요.";
  const fmtTime = (t) => {
    const d = new Date(t);
    return `${d.getMonth() + 1}월 ${d.getDate()}일 ${d.getHours()}:${String(d.getMinutes()).padStart(2, "0")}`;
  };
  function renderTitle() {
    const run = S.run && SH.getChapter(S.run.ch);
    const any = run || Object.keys(S.chapters).length || Object.keys(S.notes).length;
    const nNotes = Object.keys(S.notes).length;
    app.innerHTML = `<div class="screen">
      <div class="scroll title-scroll">
        <p class="byline">STEEL LINGO SERIES</p>
        <div class="ticket">
          <div class="ticket-top">${MASCOT}
            <div><h1 class="logo-title"><span class="series">스틸링고</span><span class="ja"><ruby>出張<rt>しゅっちょう</rt></ruby><ruby>編<rt>へん</rt></ruby></span></h1>
            <p class="tagline">철강맨의 일본 출장 서바이벌</p></div>
          </div>
          <div class="perf"></div>
          <div class="ticket-grid">
            <div class="route"><div class="tf"><b>FROM</b><span class="big">GMP</span></div><span class="plane" aria-hidden="true">✈</span><div class="tf" style="text-align:right"><b>TO</b><span class="big">HND</span></div></div>
            <div class="tf"><b>PASSENGER</b><span class="ja">金 / 漢江スチール</span></div>
            <div class="tf"><b>CLASS</b><span>영업 · 3박 4일</span></div>
          </div>
          <div class="barcode" aria-hidden="true"></div>
        </div>
        <div class="level">
          <span class="level-l">난이도</span>
          <div class="seg level-seg" role="radiogroup" aria-label="난이도">
            <button role="radio" data-level="easy" aria-checked="${easy()}" aria-pressed="${easy()}">쉬움</button>
            <button role="radio" data-level="hard" aria-checked="${!easy()}" aria-pressed="${!easy()}">어려움</button>
          </div>
        </div>
        <p class="level-desc" id="levelDesc">${levelDesc()}</p>
        <div class="title-actions btn-col">
          ${run
            ? `<button class="btn primary resume" data-act="resume"><span>이어하기 · <span class="ja">第${run.no}章 ${esc(plain(run.title))}</span></span>
                 ${S.savedAt ? `<small>마지막 저장 ${fmtTime(S.savedAt)}</small>` : ""}</button>
               <div class="btn-row"><button class="btn" data-act="map">출장 일정표</button>
                 <button class="btn" data-act="note"><span class="ja">出張ノート</span><small>${nNotes}</small></button></div>`
            : `<button class="btn primary" data-act="map">${any ? "출장 일정표" : "출장 떠나기"}</button>
               <button class="btn" data-act="note"><span class="ja">出張ノート</span><small>${nNotes}</small></button>`}
          ${any ? '<button class="btn ghost" data-act="reset">처음부터 다시하기</button>' : ""}
        </div>
        <p class="install-hint" id="installHint" hidden>앱처럼 쓰려면 <button data-act="install">📲 홈 화면에 설치</button></p>
        <p class="credit">기획과 구성 by 곤사마</p>
      </div></div>`;
    Install.hint();
  }

  /* ═══════════ 일정표 ═══════════ */
  function renderMap() {
    const items = SH.chapters.map((c) => {
      const st = S.chapters[c.id];
      const running = S.run && S.run.ch === c.id;
      const cls = c.status !== "open" ? "soon" : st && st.done ? "done" : "open";
      const pill = c.status !== "open" ? '<span class="pill">준비 중</span>'
        : running ? '<span class="pill mid">진행 중</span>'
        : st && st.done ? `<span class="pill done">◎ ${st.bestCount}/${st.total}</span>`
        : '<span class="pill go">플레이</span>';
      return `<li class="stop ${cls}">
        <span class="dot" aria-hidden="true">${st && st.done ? "✓" : c.no}</span>
        <button class="card" data-ch="${c.id}">
          <div class="cd"><span>${esc(c.day)} · ${ruby(c.place)}</span>${pill}</div>
          <p class="ct ja">${ruby(c.title)}<small>${esc(c.ko)}</small></p>
          <p class="cs">${ruby(c.summary)}</p>
        </button></li>`;
    }).join("");
    app.innerHTML = `<div class="screen">
      ${bar({ title: '<span class="ja">出張スケジュール</span>', sub: "출장 일정표", back: "title", right: `<button class="icon-btn" data-act="note" aria-label="出張ノート">${ICON.book}</button>` })}
      <div class="scroll">${gaugeCards()}<p class="sec-h">ITINERARY · 3박 4일</p><ol class="itin">${items}</ol></div></div>`;
  }

  /* ═══════════ 플레이 ═══════════ */
  const scene = (ch, id) => {
    const s = ch.byId[id];
    if (!s) return null;
    const f = flags();
    const alt = (s.alt || []).find((a) => f.has(a.flag));
    return alt ? Object.assign({}, s, alt) : s;
  };

  function startChapter(id) {
    const ch = SH.getChapter(id);
    if (!ch || ch.status !== "open") return;
    S.run = { ch: id, at: ch.start, hist: [], delta: { trust: 0, like: 0 }, flags: [], grades: { best: 0, awkward: 0, rude: 0 }, missed: [], got: [], order: {} };
    save();
    go("play");
  }

  function lineHTML(s, isNew) {
    if (s.narr && !s.ja) return `<p class="narr ${isNew ? "new" : ""}">${ruby(s.narr)}</p>`;
    if (!s.ja) return "";
    const me = s.speaker === "自分";
    return `<div class="msg ${me ? "me" : "them"} ${isNew ? "new" : ""}">
      <span class="who">${me ? "나 · <span class='ja'>金</span>" : ruby(s.speaker || "")}</span>
      ${s.act ? `<span class="act">${ruby(s.act)}</span>` : ""}
      <div class="bubble"><p class="ja">${ruby(s.ja)}</p>
        <p class="ko" ${easy() ? "" : "hidden"}>${esc(s.ko)}</p>
        <div class="tools">${ttsBtn(s.ja)}${koBtn()}${glossBtn(s.parts)}</div>${glossHTML(s.parts)}</div>
      ${s.hint ? `<div class="hint"><b>💡 포인트</b> ${ruby(s.hint)}</div>` : ""}
    </div>`;
  }
  function pickHTML(c, isNew) {
    return `<div class="msg me ${isNew ? "new" : ""}">
      <span class="who">나 · <span class="ja">金</span> <span class="grade-tag g-${c.grade}">${GRADE[c.grade].mark}</span></span>
      <div class="bubble"><p class="ja">${ruby(c.ja)}</p>
        <p class="ko" ${easy() ? "" : "hidden"}>${esc(c.ko)}</p>
        <div class="tools">${ttsBtn(c.ja)}${koBtn()}${glossBtn(c.parts)}</div>${glossHTML(c.parts)}</div></div>`;
  }

  /* 🔍 뜯어보기 — 스틸링고와 같은 조각 · 읽기 · 뜻과 역할 표. 초보자용이라 기본은 접어 둔다 */
  const glossBtn = (parts) => (parts && parts.length ? `<button class="chip" data-gloss aria-expanded="false">🔍 뜯어보기</button>` : "");
  function glossHTML(parts) {
    if (!parts || !parts.length) return "";
    return `<div class="gbody" hidden><table class="parts">
      <tr><th>조각 · 읽기</th><th>뜻과 역할</th></tr>
      ${parts.map((p) => `<tr><td class="p"><span class="ja">${ruby(p.p)}</span><span class="r ja">${esc(p.r)}</span></td>
        <td class="w"><b>${esc(p.w)}</b>${p.why ? `<span class="why">${ruby(p.why)}</span>` : ""}</td></tr>`).join("")}
    </table></div>`;
  }

  function collect(chId, keys, list) {
    const added = [];
    (keys || []).forEach((k) => {
      const id = chId + ":" + k;
      if (!S.notes[id]) { S.notes[id] = { t: Date.now(), ok: 0, ng: 0 }; S.exp += 1; added.push(k); }
      if (list && !list.includes(k)) list.push(k);
    });
    return added;
  }

  function renderPlay() {
    const run = S.run;
    const ch = run && SH.getChapter(run.ch);
    if (!ch) return go("map", {}, false);
    const logParts = run.hist.map((h) => {
      const s = scene(ch, h.id);
      if (!s) return "";
      return lineHTML(s, false) + (h.pick != null ? pickHTML(s.choices[h.pick], false) : "");
    });
    app.innerHTML = `<div class="screen" id="play">
      ${bar({ title: `<span class="ja">第${ch.no}章 ${ruby(ch.title)}</span>`, sub: esc(ch.ko + " · " + ch.day), back: "map", right: miniGauges() + saveBtn() })}
      <div class="scroll" id="logScroll"><div class="log" id="log">${logParts.join("")}</div></div>
      <div class="dock" id="dock"></div></div>`;
    showCurrent(false);
  }

  function refreshMini() {
    const g = $(".mini-g");
    if (g) g.outerHTML = miniGauges();
  }

  function scrollDown(smooth) {
    const sc = $("#logScroll");
    if (!sc) return;
    requestAnimationFrame(() => sc.scrollTo({ top: sc.scrollHeight, behavior: smooth ? "smooth" : "auto" }));
  }

  function showCurrent(animate = true) {
    const run = S.run, ch = SH.getChapter(run.ch);
    const s = scene(ch, run.at);
    const log = $("#log"), dock = $("#dock");
    if (!s) { dock.innerHTML = '<p class="empty">장면을 찾을 수 없습니다.</p>'; return; }
    log.insertAdjacentHTML("beforeend", lineHTML(s, animate));
    const got = collect(ch.id, s.learn, run.got);
    if (got.length && animate) noteToast(ch, got);
    save();

    if (s.choices) {
      if (!run.order[s.id]) run.order[s.id] = shuffle(s.choices.map((_, i) => i));
      save();
      const order = run.order[s.id];
      dock.innerHTML = `<div class="choices-wrap">
        <div class="ask"><span>${ruby(s.ask || "어떻게 말할까?")}</span><span class="pill easy-pill">쉬움 모드</span></div>
        <div class="choices">${order.map((i, n) => {
          const c = s.choices[i];
          // 선택지에는 동작 설명·뜻을 보이지 않는다(일본어만 보고 고르게). 쉬움 모드에서만 뜻을 단다
          return `<button class="choice" data-pick="${i}"><span class="n">${n + 1}</span><span class="cb">
            <span class="ja">${ruby(c.ja)}</span><span class="ck">${esc(c.ko)}</span></span></button>`;
        }).join("")}</div></div>`;
    } else if (s.end) {
      dock.innerHTML = `<button class="btn primary" data-act="finish">챕터 결과 보기</button>`;
    } else {
      dock.innerHTML = `<button class="btn primary" data-act="next">다음 <span aria-hidden="true">›</span></button>`;
    }
    scrollDown(animate);
  }

  function advance() {
    const run = S.run, ch = SH.getChapter(run.ch);
    const s = ch.byId[run.at];
    if (!s || s.choices || s.end) return;
    run.hist.push({ id: s.id });
    // route: 이 챕터에서 지금까지 고른 성적·플래그로 다음 장면이 갈린다
    const r = (s.route || []).find((x) =>
      (x.best == null || (run.grades.best || 0) >= x.best) &&
      (x.rude == null || (run.grades.rude || 0) >= x.rude) &&
      (x.ifFlag == null || flags().has(x.ifFlag)));
    if (r && r.flag && !run.flags.includes(r.flag)) run.flags.push(r.flag);
    run.at = r ? r.next : s.next;
    save();
    showCurrent(true);
  }

  function pick(i) {
    const run = S.run, ch = SH.getChapter(run.ch);
    const s = ch.byId[run.at];
    if (!s || !s.choices || !s.choices[i]) return;
    const c = s.choices[i];
    const best = s.choices.find((x) => x.grade === "best") || c;
    run.hist.push({ id: s.id, pick: i });
    Object.entries(c.effects || {}).forEach(([k, v]) => (run.delta[k] = (run.delta[k] || 0) + v));
    if (c.flag && !run.flags.includes(c.flag)) run.flags.push(c.flag);
    run.grades[c.grade] = (run.grades[c.grade] || 0) + 1;
    const xp = c.grade === "best" ? 3 : 1;
    S.exp += xp;
    if (c.grade !== "best") (best.learn || []).forEach((k) => { if (!run.missed.includes(k)) run.missed.push(k); });
    const got = collect(ch.id, [...(best.learn || []), ...(c.learn || [])], run.got);
    run.at = c.next;
    save();

    $("#dock").innerHTML = "";
    $("#log").insertAdjacentHTML("beforeend", pickHTML(c, true));
    scrollDown(true);
    refreshMini();
    feedbackSheet(ch, c, best, xp, got);
  }

  function feedbackSheet(ch, c, best, xp, got) {
    const g = GRADE[c.grade];
    const effs = Object.entries(c.effects || {}).filter(([, v]) => v)
      .map(([k, v]) => `<span class="eff ${v > 0 ? "up" : "down"}">${GAUGE_NAME[k]} ${(v > 0 ? "▲" : "▼").repeat(Math.min(3, Math.abs(v)))}</span>`).join("");
    const gotList = got.map((k) => plain(ch.expressions[k].ja)).join(" · ");
    openSheet(`
      <div class="verdict v-${c.grade}"><span class="mark" aria-hidden="true">${g.mark}</span>
        <div><h2>${g.title}</h2><p>${g.sub}</p></div></div>
      <div class="effects">${effs}<span class="eff up">日本語力 +${xp}</span></div>
      <p class="note">${ruby(c.note)}</p>
      ${c.grade !== "best" ? `<div class="model"><b>원어민이라면</b>
        <p class="ja">${ruby(best.ja)}</p><p class="k">${esc(best.ko)}</p>
        <div class="tools">${ttsBtn(best.ja)}${glossBtn(best.parts)}</div>${glossHTML(best.parts)}</div>` : ""}
      ${gotList ? `<p class="got">📒 <span class="ja">ノート</span>에 추가: <span class="ja">${esc(gotList)}</span></p>` : ""}
      <button class="btn primary" data-act="cont">계속</button>`, { onClose: () => showCurrent(true), label: g.title });
  }

  function noteToast(ch, keys) {
    toast(`📒 <span class="ja">ノート</span> +${keys.length} · <span class="ja">${esc(plain(ch.expressions[keys[0]].ja))}</span>`);
  }

  function finishChapter() {
    const run = S.run, ch = SH.getChapter(run.ch);
    const prev = S.chapters[ch.id];
    const total = ch.scenes.filter((s) => s.choices).length;
    const bestNow = run.grades.best || 0;
    S.chapters[ch.id] = {
      done: true, plays: (prev ? prev.plays : 0) + 1, delta: run.delta, flags: run.flags,
      grades: run.grades, missed: run.missed, got: run.got, total,
      bestCount: Math.max(bestNow, prev ? prev.bestCount : 0), lastBest: bestNow
    };
    S.run = null;
    save();
    if (ch.last && SH.seasonDef) go("ending");
    else go("result", { ch: ch.id });
  }

  /* ═══════════ 챕터 결과 ═══════════ */
  function renderResult({ ch: id }) {
    const ch = SH.getChapter(id), r = S.chapters[id];
    if (!ch || !r) return go("map", {}, false);
    const x = (k) => ch.expressions[k];
    const li = (k) => `<li><span class="ja">${ruby(x(k).ja)}</span>${x(k).trap ? '<span class="trap-b">주의</span>' : ""}<span class="k">${esc(x(k).ko)}</span></li>`;
    const perfect = r.lastBest === r.total;
    const eff = (k) => { const v = r.delta[k] || 0; return `<span class="eff ${v > 0 ? "up" : v < 0 ? "down" : ""}">${GAUGE_NAME[k]} ${v > 0 ? "+" : ""}${v * STEP}</span>`; };
    const next = SH.chapters.find((c) => c.no > ch.no);
    app.innerHTML = `<div class="screen">
      ${bar({ title: "챕터 결과", back: "map" })}
      <div class="scroll">
        <div class="result-head"><div class="cn">CHAPTER ${ch.no} CLEAR</div>
          <div class="stamp" aria-hidden="true">${perfect ? "優" : "済"}<small>${perfect ? "PERFECT" : "DONE"}</small></div>
          <h2 class="ja">${ruby(ch.title)}</h2></div>
        <div class="tally">
          <div><b class="g-best">${r.grades.best || 0}</b><span>◎ 자연스러움</span></div>
          <div><b class="g-awkward">${r.grades.awkward || 0}</b><span>△ 어색함</span></div>
          <div><b class="g-rude">${r.grades.rude || 0}</b><span>✕ 실례</span></div></div>
        <div class="effects" style="justify-content:center">${eff("trust")}${eff("like")}</div>
        ${r.missed.length ? `<div class="panel"><h3>놓친 핵심 표현 · ${r.missed.length}</h3><ul class="xlist">${r.missed.map(li).join("")}</ul></div>` : ""}
        <div class="panel"><h3>이번 챕터에서 모은 표현 · ${r.got.length}</h3><ul class="xlist">${r.got.map(li).join("")}</ul></div>
        <p class="fine">${perfect ? "모든 선택이 ◎. 이대로 다음 챕터로!" : "다시 하면 다른 대화가 펼쳐집니다. 결과는 마지막 플레이 기준으로 게이지에 반영돼요."}</p>
      </div>
      <div class="dock btn-col">
        ${next && next.status === "open" ? `<button class="btn primary" data-ch="${next.id}">다음 챕터 · <span class="ja">${ruby(next.title)}</span></button>` : ""}
        <div class="btn-row"><button class="btn" data-replay="${ch.id}">다시 하기</button><button class="btn" data-act="quiz">복습 퀴즈</button></div>
        <button class="btn ghost" data-act="map">일정표로</button>
      </div></div>`;
  }

  /* ═══════════ 시즌 엔딩 ═══════════ */
  function renderEnding() {
    const g = gauges();
    const def = SH.seasonDef;
    const e = def.endings.find((x) => x.when(g)) || def.endings[def.endings.length - 1];
    const missed = [];
    SH.chapters.forEach((c) => (S.chapters[c.id] ? S.chapters[c.id].missed : []).forEach((k) => missed.push([c, k])));
    const retry = SH.chapters.filter((c) => S.chapters[c.id] && S.chapters[c.id].lastBest < S.chapters[c.id].total)
      .sort((a, b) => S.chapters[a.id].lastBest / S.chapters[a.id].total - S.chapters[b.id].lastBest / S.chapters[b.id].total).slice(0, 2);
    app.innerHTML = `<div class="screen">${bar({ title: "シーズン1 ENDING", back: "map" })}
      <div class="scroll"><div class="result-head"><div class="cn">ENDING</div>
        <div class="stamp" aria-hidden="true">${e.id === "big" ? "祝" : e.id === "kentou" ? "検" : "再"}</div>
        <h2 class="ja">${ruby(e.ja)}</h2><p>${esc(e.ko)}</p></div>
        <div class="panel"><p class="note">${ruby(e.text)}</p></div>
        ${gaugeCards()}
        <div class="tally"><div><b>${Object.keys(S.notes).length}</b><span>획득 표현</span></div>
          <div><b>${missed.length}</b><span>놓친 표현</span></div><div><b>Lv.${g.lv}</b><span>日本語力</span></div></div>
        ${retry.length ? `<div class="panel"><h3>다시 해 볼 챕터</h3>${retry.map((c) => `<button class="btn" style="margin-top:8px" data-replay="${c.id}"><span class="ja">第${c.no}章 ${ruby(c.title)}</span></button>`).join("")}</div>` : ""}
      </div><div class="dock"><button class="btn primary" data-act="note">出張ノート 복습</button></div></div>`;
  }

  /* ═══════════ 出張ノート ═══════════ */
  function noteEntries() {
    return Object.entries(S.notes)
      .map(([id, m]) => {
        const [chId, k] = id.split(":");
        const ch = SH.getChapter(chId);
        const x = ch && ch.expressions[k];
        return x ? { id, ch, k, x, m } : null;
      })
      .filter(Boolean)
      .sort((a, b) => a.ch.no - b.ch.no || a.m.t - b.m.t);
  }
  let noteState = { tab: "list", card: 0, flipped: false, quiz: null };

  function renderNote(params) {
    if (params && params.tab) noteState.tab = params.tab;
    const list = noteEntries();
    const tabs = [["list", "표현"], ["cards", "카드"], ["quiz", "퀴즈"]]
      .map(([k, l]) => `<button role="tab" aria-selected="${noteState.tab === k}" data-tab="${k}">${l}</button>`).join("");
    let body = "", dock = "";
    if (!list.length) {
      body = `<div class="empty">아직 모은 표현이 없어요.<br>출장을 떠나면 장면에서 배운 표현이<br>여기에 자동으로 쌓입니다.</div>`;
      dock = `<button class="btn primary" data-act="map">출장 일정표로</button>`;
    } else if (noteState.tab === "list") {
      let lastCh = null;
      body = list.map((e) => {
        const head = lastCh !== e.ch.id ? `<p class="nch ja">第${e.ch.no}章 ${ruby(e.ch.title)} · ${esc(e.ch.ko)}</p>` : "";
        lastCh = e.ch.id;
        return head + `<div class="nitem"><p class="ja">${ruby(e.x.ja)}${e.x.trap ? '<span class="trap-b">주의</span>' : ""}</p>
          <p class="k">${esc(e.x.ko)}</p>${e.x.tip ? `<p class="t">${ruby(e.x.tip)}</p>` : ""}<div class="tools">${ttsBtn(e.x.ja)}</div></div>`;
      }).join("");
    } else if (noteState.tab === "cards") {
      const i = Math.min(noteState.card, list.length - 1);
      const e = list[i];
      body = `<div class="flip ${noteState.flipped ? "on" : ""}"><button class="flip-in" data-act="flip" aria-label="카드 뒤집기">
          <span class="face front"><span class="ja">${ruby(e.x.ja)}</span><span class="tap">탭해서 뜻 보기</span></span>
          <span class="face back"><span class="k">${esc(e.x.ko)}</span>${e.x.tip ? `<span class="t">${ruby(e.x.tip)}</span>` : ""}<span class="tap">탭해서 앞면</span></span>
        </button></div>
        <p class="cnt">${i + 1} / ${list.length}</p><div class="tools" style="justify-content:center">${ttsBtn(e.x.ja)}</div>`;
      dock = `<div class="btn-row"><button class="btn" data-card="-1" ${i === 0 ? "disabled" : ""}>‹ 이전</button><button class="btn primary" data-card="1">${i === list.length - 1 ? "처음으로" : "다음 ›"}</button></div>`;
    } else {
      body = quizBody(list);
      dock = quizDock();
    }
    app.innerHTML = `<div class="screen">
      ${bar({ title: '<span class="ja">出張ノート</span>', sub: `모은 표현 ${list.length}개`, back: "back" })}
      <div class="tabs" role="tablist">${tabs}</div>
      <div class="scroll">${body}</div>${dock ? `<div class="dock">${dock}</div>` : ""}</div>`;
  }

  /* 3지선다: 일본어 → 뜻 / 뜻 → 일본어를 번갈아 낸다. 오답 보기는 다른 챕터 표현까지 끌어온다. */
  function makeQuiz(list) {
    const pool = [];
    SH.chapters.forEach((c) => Object.entries(c.expressions).forEach(([k, x]) => pool.push({ ch: c, k, x })));
    const qs = shuffle(list.slice()).slice(0, Math.min(5, list.length)).map((e, n) => {
      const others = shuffle(pool.filter((p) => p.x.ko !== e.x.ko)).slice(0, 2);
      const opts = shuffle([e, ...others]);
      return { e, opts, dir: n % 2 ? "ko2ja" : "ja2ko", answer: null };
    });
    return { qs, i: 0, score: 0 };
  }
  function quizBody(list) {
    if (!noteState.quiz) noteState.quiz = makeQuiz(list);
    const Q = noteState.quiz;
    if (Q.i >= Q.qs.length) {
      return `<div class="result-head"><div class="cn">QUIZ RESULT</div>
        <div class="stamp" aria-hidden="true">${Q.score === Q.qs.length ? "優" : Q.score >= Q.qs.length / 2 ? "良" : "可"}</div>
        <h2>${Q.score} / ${Q.qs.length}</h2></div>
        <p class="fine" style="text-align:center">틀린 표현은 '표현' 탭에서 🔊로 한 번 더 들어 보세요.</p>`;
    }
    const q = Q.qs[Q.i];
    const show = q.dir === "ja2ko" ? `<div class="qlabel">이 말의 뜻은?</div><div class="ja">${ruby(q.e.x.ja)}</div>` : `<div class="qlabel">일본어로 하면?</div><div class="k">${esc(q.e.x.ko)}</div>`;
    const opts = q.opts.map((o, n) => {
      let cls = "";
      if (q.answer != null) { if (o.x.ko === q.e.x.ko) cls = "right"; else if (n === q.answer) cls = "wrong"; }
      const label = q.dir === "ja2ko" ? esc(o.x.ko) : `<span class="ja">${ruby(o.x.ja)}</span>`;
      return `<button class="qopt ${cls}" data-q="${n}" ${q.answer != null ? "disabled" : ""}>${label}</button>`;
    }).join("");
    return `<p class="cnt">${Q.i + 1} / ${Q.qs.length}</p><div class="qq">${show}</div>${opts}
      ${q.answer != null && q.e.x.tip ? `<div class="hint"><b>💡</b> ${ruby(q.e.x.tip)}</div>` : ""}`;
  }
  function quizDock() {
    const Q = noteState.quiz;
    if (!Q) return "";
    if (Q.i >= Q.qs.length) return `<button class="btn primary" data-act="requiz">한 번 더</button>`;
    return Q.qs[Q.i].answer != null ? `<button class="btn primary" data-act="qnext">${Q.i === Q.qs.length - 1 ? "결과 보기" : "다음 문제 ›"}</button>` : "";
  }
  function answerQuiz(n) {
    const Q = noteState.quiz, q = Q.qs[Q.i];
    if (q.answer != null) return;
    q.answer = n;
    const ok = q.opts[n].x.ko === q.e.x.ko;
    if (ok) Q.score++;
    const m = S.notes[q.e.id];
    if (m) ok ? m.ok++ : m.ng++;
    save();
    renderNote();
  }

  /* ═══════════ 바텀시트 ═══════════ */
  let sheetClose = null;
  const sheetOpen = () => !!$("#sheet-root").firstChild;
  function openSheet(inner, { onClose, label } = {}) {
    sheetClose = onClose || null;
    $("#sheet-root").innerHTML = `<div class="sheet" role="dialog" aria-modal="true" aria-label="${esc(label || "안내")}">
      <div class="sheet-back" data-act="cont"></div><div class="sheet-panel"><div class="grab"></div>${inner}</div></div>`;
    const b = $("#sheet-root .btn.primary") || $("#sheet-root button");
    if (b) b.focus({ preventScroll: true });
  }
  function closeSheet(run = false) {
    if (!sheetOpen()) return;
    $("#sheet-root").innerHTML = "";
    const f = sheetClose;
    sheetClose = null;
    if (run && f) f();
  }

  /* 💾 저장 — 진행은 장면마다 자동으로도 저장되지만, 눌러서 확인하고 나갈 수 있게 한다 */
  function saveSheet() {
    const ok = save();
    const run = S.run && SH.getChapter(S.run.ch);
    openSheet(`<h2 class="set-h">${ok ? "💾 저장했어요" : "저장하지 못했어요"}</h2>
      <p class="note">${ok
        ? `<span class="ja">第${run.no}章 ${ruby(run.title)}</span>, 지금 장면까지 이 기기에 저장됐어요. 다음에 앱을 켜면 표지에서 <b>이어하기</b>를 누르면 됩니다.`
        : "이 브라우저는 저장을 막고 있어요(시크릿 창 등). 일반 창이나 설치한 앱에서 열어 주세요."}</p>
      <div class="btn-row"><button class="btn" data-act="title">저장하고 나가기</button><button class="btn primary" data-act="close">계속하기</button></div>`, { label: "저장" });
  }
  function resetSheet() {
    openSheet(`<h2 class="set-h">처음부터 다시할까요?</h2>
      <p class="note">게이지, 챕터 기록, <span class="ja">出張ノート</span>가 모두 지워집니다. 난이도는 그대로 둡니다.</p>
      <div class="btn-row"><button class="btn" data-act="close">취소</button><button class="btn primary" data-act="doreset">지우고 시작</button></div>`, { label: "초기화 확인" });
  }

  /* ═══════════ 설치 안내 ═══════════ */
  const Install = {
    deferred: null,
    ua: navigator.userAgent,
    standalone: () => window.matchMedia("(display-mode: standalone)").matches || navigator.standalone === true,
    init() {
      window.addEventListener("beforeinstallprompt", (e) => { e.preventDefault(); this.deferred = e; this.hint(); });
      window.addEventListener("appinstalled", () => { this.deferred = null; this.hint(); });
    },
    hint() {
      const el = $("#installHint");
      if (el) el.hidden = this.standalone();
    },
    sheet() {
      const ua = this.ua;
      const isIOS = /iphone|ipad|ipod/i.test(ua) || (/Macintosh/.test(ua) && navigator.maxTouchPoints > 1);
      const isAndroid = /android/i.test(ua);
      const inApp = /KAKAOTALK|Teams|MSTeams|NAVER|Line\/|band|DaumApps|Instagram|FB_IAB|FBAN|FBAV|everytime/i.test(ua);
      let body;
      if (this.standalone()) body = "<p class='note'>이미 앱으로 실행 중이에요. 👍</p>";
      else if (inApp) body = `<p class="note"><b>카카오톡·팀즈 같은 앱 안에서 열려 있어요.</b> 여기서는 설치와 발음이 되지 않습니다.</p>
        <ol class="steps"><li>오른쪽 위 메뉴(⋯ 또는 ⋮)를 누릅니다</li><li><b>「다른 브라우저로 열기」</b>를 고릅니다${isIOS ? " — 아이폰은 Safari" : isAndroid ? " — 안드로이드는 Chrome" : ""}</li><li>열린 화면에서 이 안내를 다시 따라 하면 됩니다</li></ol>`;
      else if (isIOS) body = `<p class="note"><b>아이폰 · 아이패드 (Safari)</b></p>
        <ol class="steps"><li>화면 아래 <b>공유 버튼</b>(□ 위에 화살표)을 누릅니다</li><li>목록을 내려 <b>「홈 화면에 추가」</b>를 고릅니다</li><li>오른쪽 위 <b>「추가」</b>를 누르면 끝</li></ol>`;
      else if (isAndroid) body = `<p class="note"><b>안드로이드 (Chrome)</b></p><ol class="steps">${this.deferred ? "<li>아래 <b>「지금 설치」</b>를 누릅니다</li>" : "<li>오른쪽 위 메뉴(⋮)를 누릅니다</li><li><b>「앱 설치」</b> 또는 <b>「홈 화면에 추가」</b>를 고릅니다</li>"}</ol>`;
      else body = `<p class="note"><b>컴퓨터 (Chrome · Edge)</b></p><ol class="steps">${this.deferred ? "<li>아래 <b>「지금 설치」</b>를 누릅니다</li>" : ""}<li>주소창 오른쪽 끝의 <b>설치 아이콘</b>을 누릅니다</li><li>없으면 메뉴 → <b>「앱 설치」</b></li></ol>`;
      openSheet(`<h2 class="set-h">📲 홈 화면에 설치</h2>${body}
        <p class="fine">설치하면 아이콘을 눌러 주소창 없이 앱처럼 열리고, 인터넷이 끊겨도 계속 쓸 수 있어요.</p>
        <div class="btn-col">${this.deferred ? '<button class="btn primary" data-act="installnow">지금 설치</button>' : ""}<button class="btn" data-act="close">닫기</button></div>`, { label: "설치 안내" });
    },
    async now() {
      if (!this.deferred) return;
      this.deferred.prompt();
      try { await this.deferred.userChoice; } catch (e) {}
      this.deferred = null;
      closeSheet();
      this.hint();
    }
  };

  /* ═══════════ 이벤트(위임) ═══════════ */
  function shuffle(a) {
    for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; }
    return a;
  }

  document.addEventListener("click", (ev) => {
    const t = ev.target.closest("button, [data-act]");
    if (!t || t.disabled) return;
    const d = t.dataset;
    if (d.say != null) return TTS.speak(d.say);
    if (d.ko != null) {
      const ko = t.closest(".bubble").querySelector(".ko");
      ko.hidden = !ko.hidden;
      t.setAttribute("aria-pressed", String(!ko.hidden));
      return;
    }
    if (d.gloss != null) {
      const g = t.closest(".bubble, .model").querySelector(".gbody");
      g.hidden = !g.hidden;
      t.setAttribute("aria-expanded", String(!g.hidden));
      t.textContent = g.hidden ? "🔍 뜯어보기" : "🔍 닫기";
      if (!g.hidden) g.scrollIntoView({ block: "nearest", behavior: "smooth" });
      return;
    }
    if (d.pick != null) return pick(+d.pick);
    if (d.ch != null) {
      const c = SH.getChapter(d.ch);
      if (!c || c.status !== "open") return toast("준비 중인 챕터예요. 다음 업데이트에서 열립니다.");
      if (S.run && S.run.ch === d.ch) return go("play");
      return startChapter(d.ch);
    }
    if (d.replay != null) return startChapter(d.replay);
    if (d.tab != null) { noteState.tab = d.tab; noteState.flipped = false; if (d.tab === "quiz") noteState.quiz = null; return renderNote(); }
    if (d.card != null) {
      const n = noteEntries().length;
      noteState.card = noteState.card + +d.card;
      if (noteState.card >= n) noteState.card = 0;
      if (noteState.card < 0) noteState.card = 0;
      noteState.flipped = false;
      return renderNote();
    }
    if (d.q != null) return answerQuiz(+d.q);
    if (d.level != null) {
      S.settings.easy = d.level === "easy";
      save();
      applySettings();
      t.parentElement.querySelectorAll("button").forEach((b) => {
        b.setAttribute("aria-pressed", String(b === t));
        b.setAttribute("aria-checked", String(b === t));
      });
      $("#levelDesc").textContent = levelDesc();
      return;
    }
    switch (d.act) {
      case "title": return go("title");
      case "map": return go("map");
      case "back": return history.length > 1 && view.v === "note" ? history.back() : go("title");
      case "resume": return go("play");
      case "note": noteState.tab = "list"; return go("note");
      case "quiz": noteState.tab = "quiz"; noteState.quiz = null; return go("note", { tab: "quiz" });
      case "save": return saveSheet();
      case "install": return Install.sheet();
      case "installnow": return Install.now();
      case "reset": return resetSheet();
      case "doreset": {
        const keep = S.settings;
        S = fresh(); S.settings = keep; save();
        closeSheet(); toast("처음부터 다시 시작합니다."); return go("title");
      }
      case "close": return closeSheet();
      case "cont": return closeSheet(true);
      case "next": return advance();
      case "finish": return finishChapter();
      case "flip": noteState.flipped = !noteState.flipped; $(".flip").classList.toggle("on", noteState.flipped); return;
      case "qnext": noteState.quiz.i++; return renderNote();
      case "requiz": noteState.quiz = null; return renderNote();
    }
  });

  /* 키보드: 플레이 중 Enter/Space = 다음, 1~3 = 선택 (컴퓨터에서 테스트할 때 편하게) */
  document.addEventListener("keydown", (ev) => {
    if (view.v !== "play" || ev.target.closest("input, textarea")) return;
    if (sheetOpen()) { if (ev.key === "Escape") closeSheet(true); return; }
    const n = parseInt(ev.key, 10);
    if (n >= 1 && n <= 3) { const b = document.querySelectorAll(".choice")[n - 1]; if (b) b.click(); }
  });

  /* ═══════════ 오프라인 ═══════════ */
  function registerSW() {
    if (!("serviceWorker" in navigator) || location.protocol === "file:") return;
    navigator.serviceWorker.register("./sw.js").then((reg) => {
      // 같은 주소의 다른 앱(스틸링고 Lite·Pro)이 캐시를 지우는 경우가 있어, 열 때마다 비었는지 확인하고 다시 채운다
      const ask = () => reg.active && reg.active.postMessage({ type: "ensure-cache" });
      if (reg.active) ask(); else navigator.serviceWorker.ready.then(ask);
    }).catch(() => {});
  }

  /* ═══════════ 시작 ═══════════ */
  applySettings();
  app.innerHTML = '<div class="loading">출장 준비 중…</div>';
  SH.loadData("data/").then((res) => {
    const bad = res.filter((r) => !r.ok);
    if (bad.length) console.warn("불러오지 못한 데이터:", bad.map((r) => r.f).join(", "));
    if (S.run && (!SH.getChapter(S.run.ch) || !SH.getChapter(S.run.ch).byId[S.run.at])) S.run = null; // 데이터가 바뀌어 장면이 사라진 경우
    TTS.init();
    Install.init();
    try { history.replaceState({ v: "title" }, ""); } catch (e) {}
    go("title", {}, false);
    registerSW();
  });
})();
