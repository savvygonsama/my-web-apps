/* 스틸링고 東京物語 — 화면과 진행.
   화면: 표지(title) → 일정표(map) → 플레이(play) → 챕터 결과(result) / 夜ノート(note) / 엔딩(ending) / 엔딩 앨범(album)

   大阪物語와 같은 분기형 엔진. 점수·정답이 없고, 선택은 플래그로 남아 뒤 장면·뒤 장·엔딩을 바꾼다.
   여기에 판(edition)이 셋 있다. 판마다 기록이 따로 저장된다.
   - ko   한국어편: 대사·선택지가 모두 한국어. 일본어·발음·노트가 없다
   - easy 초급편: 쉬운 일본어 + 후리가나 + 해석 + 🔍 뜯어보기
   - hard 상급편: 원어민 말투(jx). 후리가나와 해석은 눌러야 보인다. 뉘앙스 메모(hx) */
(function () {
  "use strict";
  const { ruby, esc, plain } = SH;
  const $ = (sel, root = document) => root.querySelector(sel);
  const app = $("#app");
  const html = document.documentElement;
  const CFG = self.SH_APP || {};

  /* ═══════════ 상태 ═══════════ */
  const fresh = () => ({
    v: 1,
    settings: { furi: false, big: false, rate: 1 },
    chapters: {}, // id → { done, plays, flags, picks:[문장], got }
    run: null, // { ch, at, hist:[{id, a, pick?}], flags, picks, got }
    notes: {}, // "c3:osusume" → { t, ok, ng }
    seen: {}, // 장면 id → [가 본 선택지 번호] (새 여행에도 남는다)
    endings: {}, // 엔딩 id → 처음 본 시각 (새 여행에도 남는다)
    pics: {}, // 본 삽화 id → 처음 본 시각 (새 여행에도 남는다)
    lastEnding: null,
    trips: 0
  });
  /* 판: 주소의 ?ed= → 지난번에 고른 판 → 초급편 */
  const EDS = {
    ko: { name: "한국어편", desc: "일본어 없이, 이야기만 즐겨요. 대사와 선택지가 모두 한국어예요." },
    easy: { name: "초급편", desc: "쉬운 일본어로 읽어요. 후리가나와 해석이 처음부터 보이고, 🔍 뜯어보기로 문장을 쪼개 볼 수 있어요." },
    hard: { name: "상급편", desc: "원어민이 실제로 쓰는 말투로 읽어요. 후리가나와 해석은 눌러야 보이고, 뉘앙스 메모가 붙어요." }
  };
  const urlEd = (() => { try { return new URLSearchParams(location.search).get("ed"); } catch (e) { return null; } })();
  let ED = EDS[urlEd] ? urlEd : EDS[SH.store.lastEd()] ? SH.store.lastEd() : "easy";
  let S;
  function useEdition(ed) {
    const big = S && S.settings.big; // 글자 크기는 판을 바꿔도 따라간다
    ED = ed;
    SH.store.lastEd(ed);
    SH.store.use(ed);
    S = Object.assign(fresh(), SH.store.load() || {});
    S.settings = Object.assign(fresh().settings, S.settings);
    if (big != null) S.settings.big = big;
  }
  useEdition(ED);
  const save = () => { S.savedAt = Date.now(); return SH.store.save(S); };
  const isKo = () => ED === "ko", isEasy = () => ED === "easy", isHard = () => ED === "hard";

  /* 여행은 순서대로 — 앞 장을 모두 마쳐야 다음 장이 열린다(앞 장의 선택이 뒤로 이어지므로) */
  const unlocked = (c) => SH.chapters.filter((x) => x.no < c.no).every((x) => S.chapters[x.id] && S.chapters[x.id].done);
  /** 지금까지의 기억(플래그). 진행 중인 장은 마친 기록 대신 지금 기록을 쓴다 */
  function flags() {
    const f = new Set();
    Object.entries(S.chapters).forEach(([id, c]) => { if (c.done && (!S.run || S.run.ch !== id)) (c.flags || []).forEach((x) => f.add(x)); });
    if (S.run) S.run.flags.forEach((x) => f.add(x));
    return f;
  }
  const addFlags = (list) => SH.flagList(list).forEach((x) => { if (!S.run.flags.includes(x)) S.run.flags.push(x); });

  /* 판에 따라 화면 규칙이 바뀐다. 상급편만 '후리가나 늘 보이기' 설정이 있다 */
  function applySettings() {
    html.classList.toggle("easy", isEasy());
    html.classList.toggle("ed-ko", isKo());
    html.classList.toggle("no-furi", isHard() && !S.settings.furi);
    html.classList.toggle("big", !!S.settings.big);
  }

  /* 상황 묘사는 두세 문장씩 끊어 문단으로 — 한 덩어리로 길게 이어지면 읽기 어렵다 */
  function paras(htmlText) {
    const sent = htmlText.split(/(?<=[.!?。！？])\s+/);
    const out = [];
    for (let i = 0; i < sent.length; i += 2) out.push(sent.slice(i, i + 2).join(" "));
    return out.map((p) => `<span class="np">${p}</span>`).join("");
  }

  /* 삽화: 장면의 pic → img/<pic>.<확장자>. data/index.js 의 SH_PICS 에 적힌 그림만 보여 준다.
     film: "95.12.24" 처럼 날짜를 주면 1995년 필름 사진 액자로 그린다 */
  const PICS = self.SH_PICS || {};
  window.SH_imgFail = (el) => { el.closest("figure").hidden = true; };
  window.SH_imgLoad = () => { const sc = $("#logScroll"); if (sc && sc.scrollHeight - sc.scrollTop - sc.clientHeight < 600) scrollDown(false); };
  function figHTML(s) {
    if (!s.pic || !PICS[s.pic]) return "";
    if (S.pics && !S.pics[s.pic]) S.pics[s.pic] = Date.now();
    return `<figure class="pic${s.film ? " film" : ""}"><img src="img/${esc(s.pic)}.${esc(PICS[s.pic])}" alt="${esc(s.cap || "")}" loading="lazy" decoding="async" onload="SH_imgLoad()" onerror="SH_imgFail(this)">${
      s.film ? `<span class="fdate">'${esc(s.film).replace(/\./g, " ")}</span>` : ""}${s.cap ? `<figcaption>${esc(s.cap)}</figcaption>` : ""}</figure>`;
  }

  /* 판별 글 고르기. 데이터의 한 줄(장면·선택지)이 세 판의 말을 함께 들고 있다 */
  const T = {
    /** 화면에 보일 대사(HTML) */
    line: (x) => (isKo() ? esc(x.ko) : ruby(isHard() ? x.jx || x.ja : x.ja)),
    /** 대사 원문(발음·기록용) */
    raw: (x) => (isKo() ? x.ko : isHard() ? x.jx || x.ja : x.ja),
    /** 기록해 둔 원문을 다시 그리기 */
    show: (t) => (isKo() ? esc(t) : ruby(t)),
    narr: (s) => paras(ruby(!isKo() && s.narj ? s.narj : s.narr)),
    who: (w) => {
      if (w === "me") return "나 · 김링고";
      const c = SH.seasonDef && SH.seasonDef.cast && SH.seasonDef.cast[w];
      return c ? (isKo() ? esc(c.ko) : ruby(c.ja)) : "";
    },
    hint: (x) => (isKo() ? "" : isHard() ? x.hx : x.hint),
    learn: (x) => (isKo() ? [] : (isHard() ? x.learnx : x.learn) || []),
    title: (ch) => (isKo() ? esc(ch.ko) : ruby(ch.title)),
    chHead: (ch) => (isKo() ? `${ch.no}장 · ${esc(ch.ko)}` : `<span class="ja">第${ch.no}章 ${ruby(ch.title)}</span>`),
    stamp: (o) => esc(isKo() ? o.sko || o.stamp : o.stamp || "夜"),
    eTitle: (e) => (isKo() ? esc(e.ko) : ruby(e.ja)),
    eText: (e) => ruby(!isKo() && e.textj ? e.textj : e.text)
  };
  const dict = (ch) => SH.dict(ch, ED);

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
  const koBtn = () => `<button class="chip" data-ko aria-pressed="${isEasy()}">뜻</button>`;
  const furiBtn = () => `<button class="chip" data-furi aria-pressed="false" aria-label="후리가나 보기">あ 읽기</button>`;

  /* ═══════════ 공용 조각 ═══════════ */
  const ICON = {
    back: '<svg viewBox="0 0 24 24"><path d="M15 18l-6-6 6-6"/></svg>',
    book: '<svg viewBox="0 0 24 24"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20V3H6.5A2.5 2.5 0 0 0 4 5.5z"/><path d="M4 19.5A2.5 2.5 0 0 0 6.5 22H20v-5"/></svg>',
    album: '<svg viewBox="0 0 24 24"><rect x="3" y="4" width="18" height="16" rx="2"/><circle cx="9" cy="10" r="2"/><path d="M21 16l-5-5-9 9"/></svg>'
  };
  const MASCOT = `<svg class="mascot" viewBox="0 0 100 80" role="img" aria-label="${CFG.mascotLabel}">
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

  function bar({ title, sub, back, right = "" }) {
    return `<header class="bar">
      ${back ? `<button class="icon-btn" data-act="${back}" aria-label="뒤로">${ICON.back}</button>` : '<span style="width:8px"></span>'}
      <h1>${title}${sub ? `<small>${sub}</small>` : ""}</h1>${right}</header>`;
  }
  const saveBtn = () => `<button class="save-btn" data-act="save" aria-label="지금까지 저장">💾 저장</button>`;
  const albumBtn = () => `<button class="icon-btn" data-act="album" aria-label="엔딩 앨범">${ICON.album}</button>`;
  const nEndings = () => (SH.seasonDef ? SH.seasonDef.endings.length : 0);
  const nFound = () => (SH.seasonDef ? SH.seasonDef.endings.filter((e) => S.endings[e.id]).length : 0);

  /* 가 본 갈래: 선택 지점마다 고른 적 있는 선택지를 센다. 정답률이 아니라 '얼마나 다른 길을 걸어 봤나' */
  function branchCount(ch) {
    let total = 0, seen = 0;
    ch.scenes.forEach((s) => {
      if (!s.choices) return;
      total += s.choices.length;
      seen += (S.seen[s.id] || []).length;
    });
    return { total, seen };
  }

  function tripCard() {
    const done = SH.chapters.filter((c) => S.chapters[c.id] && S.chapters[c.id].done).length;
    let total = 0, seen = 0;
    SH.chapters.forEach((c) => { const b = branchCount(c); total += b.total; seen += b.seen; });
    return `<div class="tripcard">
      <div><b>${done}<small>/${SH.chapters.length}</small></b><span>지나온 장</span></div>
      <div><b>${seen}<small>/${total}</small></b><span>걸어 본 갈래</span></div>
      <button data-act="album"><b>${nFound()}<small>/${nEndings()}</small></b><span>엔딩 앨범 ›</span></button></div>`;
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
    $("#toast").classList.remove("toast-on");
    if ("speechSynthesis" in window) try { speechSynthesis.cancel(); } catch (e) {}
    ({ title: renderTitle, map: renderMap, play: renderPlay, result: renderResult, note: renderNote, ending: renderEnding, album: renderAlbum }[v] || renderTitle)(params);
  }
  window.addEventListener("popstate", (e) => {
    const st = e.state || { v: "title" };
    if (sheetOpen()) { closeSheet(true); try { history.pushState(view, ""); } catch (x) {} return; }
    go(st.v, st, false);
  });

  /* ═══════════ 표지 ═══════════ */
  const fmtTime = (t) => {
    const d = new Date(t);
    return `${d.getMonth() + 1}월 ${d.getDate()}일 ${d.getHours()}:${String(d.getMinutes()).padStart(2, "0")}`;
  };
  function renderTitle() {
    const run = S.run && SH.getChapter(S.run.ch);
    const any = run || Object.keys(S.chapters).length;
    const nNotes = Object.keys(S.notes).length;
    const eds = Object.entries(EDS).map(([k, v]) =>
      `<button role="radio" data-ed="${k}" aria-checked="${ED === k}" aria-pressed="${ED === k}">${v.name}</button>`).join("");
    app.innerHTML = `<div class="screen">
      <div class="scroll title-scroll">
        <p class="byline">STEEL LINGO SERIES</p>
        <div class="ticket">
          <div class="ticket-top">${MASCOT}
            <div><h1 class="logo-title"><span class="series">스틸링고</span>${isKo()
              ? `<span class="ko-logo">${esc(CFG.titleKo)}</span>`
              : `<span class="ja">${CFG.titleHTML}</span>`}</h1>
            <p class="tagline">${CFG.tagline}</p></div>
          </div>
          <div class="perf"></div>
          <div class="ticket-grid">
            <div class="route"><div class="tf"><b>FROM</b><span class="big">${CFG.from}</span></div><span class="plane" aria-hidden="true">✈</span><div class="tf" style="text-align:right"><b>TO</b><span class="big">${CFG.to}</span></div></div>
            <div class="tf"><b>PASSENGER</b><span class="${isKo() ? "" : "ja"}">${isKo() ? CFG.passengerKo : CFG.passenger}</span></div>
            <div class="tf"><b>ENDINGS</b><span>${nFound()} / ${nEndings()}</span></div>
          </div>
          <div class="barcode" aria-hidden="true"></div>
        </div>
        <p class="rule">정답은 없어요. 내가 한 말에 상대가 반응하고, 그 반응이 다음 이야기를 바꿉니다.</p>
        <div class="seg ed-seg" role="radiogroup" aria-label="판 고르기">${eds}</div>
        <p class="level-desc">${EDS[ED].desc}${isHard() ? ` <button class="linkish" data-act="furiall" aria-pressed="${!!S.settings.furi}">${S.settings.furi ? "후리가나 늘 보이기: 켬" : "후리가나 늘 보이기: 끔"}</button>` : ""}</p>
        <p class="fine ed-note">판마다 진행 기록과 엔딩 앨범이 따로 저장돼요. <button class="linkish" data-act="bigtext" aria-pressed="${!!S.settings.big}">글자 크기: ${S.settings.big ? "크게" : "보통"}</button></p>
        <div class="title-actions btn-col">
          ${run
            ? `<button class="btn primary resume" data-act="resume"><span>이어하기 · ${T.chHead(run)}</span>
                 ${S.savedAt ? `<small>마지막 저장 ${fmtTime(S.savedAt)}</small>` : ""}</button>
               <button class="btn" data-act="map">${CFG.trip} 일정표</button>`
            : `<button class="btn primary" data-act="map">${any ? CFG.trip + " 일정표" : CFG.trip + " 떠나기"}</button>`}
          ${isKo()
            ? `<button class="btn" data-act="album">엔딩 앨범<small>${nFound()}/${nEndings()}</small></button>`
            : `<div class="btn-row"><button class="btn" data-act="note"><span class="ja">${CFG.noteName}</span><small>${nNotes}</small></button>
            <button class="btn" data-act="album">엔딩 앨범<small>${nFound()}/${nEndings()}</small></button></div>`}
          ${any ? '<button class="btn ghost" data-act="reset">새 여행 떠나기</button>' : ""}
        </div>
        <p class="install-hint" id="installHint" hidden>앱처럼 쓰려면 <button data-act="install">📲 홈 화면에 설치</button></p>
        <p class="credit">기획과 구성 by 곤사마<br>Special Thanks to 앤셜리</p>
      </div></div>`;
    Install.hint();
  }

  /* ═══════════ 일정표 ═══════════ */
  function renderMap() {
    const items = SH.chapters.map((c) => {
      const st = S.chapters[c.id];
      const running = S.run && S.run.ch === c.id;
      const locked = c.status === "open" && !unlocked(c);
      const cls = c.status !== "open" || locked ? "soon" : st && st.done ? "done" : "open";
      const b = branchCount(c);
      const pill = c.status !== "open" ? '<span class="pill">준비 중</span>'
        : locked ? '<span class="pill">🔒 잠김</span>'
        : running ? '<span class="pill mid">진행 중</span>'
        : st && st.done ? `<span class="pill done">갈래 ${b.seen}/${b.total}</span>`
        : '<span class="pill go">플레이</span>';
      return `<li class="stop ${cls}">
        <span class="dot" aria-hidden="true">${st && st.done ? "✓" : c.no}</span>
        <button class="card" data-ch="${c.id}">
          <div class="cd"><span>${esc(c.day)} · ${esc(c.place)}</span>${pill}</div>
          <p class="ct ${isKo() ? "" : "ja"}">${T.title(c)}${isKo() ? "" : `<small>${esc(c.ko)}</small>`}</p>
          <p class="cs">${esc(c.summary)}</p>
        </button></li>`;
    }).join("");
    const mem = memories();
    app.innerHTML = `<div class="screen">
      ${bar({ title: isKo() ? CFG.mapKo : `<span class="ja">${CFG.mapTitle}</span>`, sub: EDS[ED].name + " · " + CFG.trip + " 일정표", back: "title", right: albumBtn() + (isKo() ? "" : `<button class="icon-btn" data-act="note" aria-label="${CFG.noteName}">${ICON.book}</button>`) })}
      <div class="scroll">${tripCard()}
        ${mem.length ? `<details class="panel diary"><summary>이번 여행의 기억 · ${mem.length}</summary><ul class="memo">${mem.map((m) => `<li>${ruby(m)}</li>`).join("")}</ul></details>` : ""}
        <p class="sec-h">${CFG.itin}</p><ol class="itin">${items}</ol>
        <p class="fine">지나온 장을 누르면 그 장부터 다시 걸을 수 있어요. 다른 말을 하면 뒤 이야기도 달라집니다.</p></div></div>`;
  }

  /** 지금 켜진 플래그를 장별 memo로 풀어 쓴 '여행 일기' */
  function memories() {
    const f = flags(), out = [];
    SH.chapters.forEach((c) => Object.entries(c.memo).forEach(([k, t]) => { if (f.has(k)) out.push(t); }));
    return out;
  }

  /* ═══════════ 플레이 ═══════════ */
  /** 장면 + 지금 조건에 맞는 alt. a를 주면 그 alt로 고정(기록 다시 그리기용) */
  const scene = (ch, id, a) => {
    const s = ch.byId[id];
    if (!s) return null;
    const idx = a != null ? a : (s.alt || []).findIndex((x) => SH.test(x, flags()));
    return { s: idx >= 0 && s.alt && s.alt[idx] ? Object.assign({}, s, s.alt[idx]) : s, a: idx };
  };

  function startChapter(id) {
    const ch = SH.getChapter(id);
    if (!ch || ch.status !== "open") return;
    // 이 장을 다시 걸으면 이 장의 지난 기록과, 그 선택을 바탕으로 한 뒤 장의 기록을 함께 지운다
    SH.chapters.forEach((c) => { if (c.no >= ch.no) delete S.chapters[c.id]; });
    S.run = { ch: id, at: ch.start, hist: [], flags: [], picks: [], got: [] };
    save();
    go("play");
  }

  /** 말풍선: 한국어편은 한국어 한 줄, 초급편은 일본어+해석+뜯어보기, 상급편은 일본어(해석·읽기는 눌러서) */
  function bubble(x) {
    if (isKo()) return `<div class="bubble"><p class="kt">${T.line(x)}</p></div>`;
    return `<div class="bubble"><p class="ja">${T.line(x)}</p>
        <p class="ko" ${isEasy() ? "" : "hidden"}>${esc(x.ko)}</p>
        <div class="tools">${ttsBtn(T.raw(x))}${koBtn()}${isHard() ? furiBtn() : glossBtn(x.parts)}</div>${isEasy() ? glossHTML(x.parts) : ""}</div>`;
  }
  function lineHTML(s, isNew) {
    const fig = figHTML(s);
    if (s.narr && !s.ko) return `${fig ? `<div class="figwrap ${isNew ? "new" : ""}">${fig}</div>` : ""}<p class="narr ${isNew ? "new" : ""}">${T.narr(s)}</p>`;
    if (!s.ko) return fig ? `<div class="figwrap ${isNew ? "new" : ""}">${fig}</div>` : "";
    if (fig) return `<div class="figwrap ${isNew ? "new" : ""}">${fig}</div>` + lineHTML(Object.assign({}, s, { pic: null }), isNew);
    const me = s.who === "me";
    const h = T.hint(s);
    return `<div class="msg ${me ? "me" : "them"} ${isNew ? "new" : ""}">
      <span class="who">${T.who(s.who)}</span>
      ${s.act ? `<span class="act">${esc(s.act)}</span>` : ""}
      ${bubble(s)}
      ${h ? `<div class="hint"><b>${isHard() ? "📝" : "💡"}</b> ${ruby(h)}</div>` : ""}
    </div>`;
  }
  function pickHTML(c, isNew) {
    const h = isHard() ? c.hx : "";
    return `<div class="msg me ${isNew ? "new" : ""}">
      <span class="who">나 · 김링고</span>
      ${bubble(c)}
      ${h ? `<div class="hint"><b>📝</b> ${ruby(h)}</div>` : ""}</div>
      ${c.then ? `<p class="narr then ${isNew ? "new" : ""}">${esc(c.then)}</p>` : ""}`;
  }

  /* 🔍 뜯어보기 — 조각 · 읽기 · 뜻과 역할 표. 초보자용이라 기본은 접어 둔다 */
  const glossBtn = (parts) => (parts && parts.length ? `<button class="chip" data-gloss aria-expanded="false">🔍 뜯어보기</button>` : "");
  function glossHTML(parts) {
    if (!parts || !parts.length) return "";
    return `<div class="gbody" hidden><table class="parts">
      <tr><th>조각 · 읽기</th><th>뜻과 역할</th></tr>
      ${parts.map((p) => `<tr><td class="p"><span class="ja">${ruby(p.p)}</span><span class="r ja">${esc(p.r)}</span></td>
        <td class="w"><b>${esc(p.w)}</b>${p.why ? `<span class="why">${ruby(p.why)}</span>` : ""}</td></tr>`).join("")}
    </table></div>`;
  }

  function collect(ch, keys, list) {
    const added = [];
    (keys || []).forEach((k) => {
      if (!dict(ch)[k]) return;
      const id = ch.id + ":" + k;
      if (!S.notes[id]) { S.notes[id] = { t: Date.now(), ok: 0, ng: 0 }; added.push(k); }
      if (list && !list.includes(k)) list.push(k);
    });
    return added;
  }

  function renderPlay() {
    const run = S.run;
    const ch = run && SH.getChapter(run.ch);
    if (!ch) return go("map", {}, false);
    const logParts = run.hist.map((h) => {
      const r = scene(ch, h.id, h.a);
      if (!r) return "";
      return lineHTML(r.s, false) + (h.pick != null && r.s.choices && r.s.choices[h.pick] ? pickHTML(r.s.choices[h.pick], false) : "");
    });
    app.innerHTML = `<div class="screen" id="play">
      ${bar({ title: T.chHead(ch), sub: esc(isKo() ? ch.day : ch.ko + " · " + ch.day), back: "map", right: saveBtn() })}
      <div class="scroll" id="logScroll"><div class="log" id="log">${logParts.join("")}</div></div>
      <div class="dock" id="dock"></div></div>`;
    showCurrent(false);
  }

  function scrollDown(smooth) {
    const sc = $("#logScroll");
    if (!sc) return;
    requestAnimationFrame(() => sc.scrollTo({ top: sc.scrollHeight, behavior: smooth ? "smooth" : "auto" }));
  }

  /** 지금 장면을 기록에 붙이고 아래 손잡이(다음/선택지/끝)를 그린다 */
  function showCurrent(animate = true) {
    const run = S.run, ch = SH.getChapter(run.ch);
    const r = scene(ch, run.at);
    const log = $("#log"), dock = $("#dock");
    if (!r) { dock.innerHTML = '<p class="empty">장면을 찾을 수 없습니다.</p>'; return; }
    const s = r.s;
    run.a = r.a;
    log.insertAdjacentHTML("beforeend", lineHTML(s, animate));
    if (s.flag) addFlags(s.flag);
    const got = collect(ch, T.learn(s), run.got);
    if (got.length && animate) noteToast(ch, got);
    save();

    if (s.choices) {
      const f = flags();
      const vis = s.choices.map((c, i) => [c, i]).filter(([c]) => SH.test(c, f));
      const seen = S.seen[s.id] || [];
      dock.innerHTML = `<div class="choices-wrap">
        <div class="ask"><span>${esc(s.ask || "뭐라고 할까?")}</span><span class="pill ed-pill">${EDS[ED].name}</span></div>
        <div class="choices">${vis.map(([c, i], n) =>
          `<button class="choice${c.tag ? " memory" : ""}" data-pick="${i}"><span class="n">${n + 1}</span><span class="cb">
            ${c.tag ? `<span class="ctag">✨ ${esc(c.tag)}</span>` : ""}
            <span class="${isKo() ? "kt" : "ja"}">${T.line(c)}</span>${isEasy() ? `<span class="ck">${esc(c.ko)}</span>` : ""}</span>
            ${seen.includes(i) ? '<span class="been" title="전에 골라 본 말">✓</span>' : ""}</button>`).join("")}</div></div>`;
    } else if (s.end) {
      dock.innerHTML = `<button class="btn primary" data-act="finish">${ch.last ? "여행의 끝으로" : "이 장 마치기"}</button>`;
    } else {
      dock.innerHTML = `<button class="btn primary" data-act="next">다음 <span aria-hidden="true">›</span></button>`;
    }
    scrollDown(animate);
  }

  function advance() {
    const run = S.run, ch = SH.getChapter(run.ch);
    const r = scene(ch, run.at, run.a);
    if (!r || r.s.choices || r.s.end) return;
    const s = r.s;
    run.hist.push({ id: s.id, a: r.a });
    // route: 지금까지의 기억(이 장 + 앞 장)으로 다음 장면이 갈린다
    const f = flags();
    const rt = (s.route || []).find((x) => SH.test(x, f));
    if (rt && rt.flag) addFlags(rt.flag);
    run.at = rt ? rt.next : s.next;
    save();
    showCurrent(true);
  }

  function pick(i) {
    const run = S.run, ch = SH.getChapter(run.ch);
    const r = scene(ch, run.at, run.a);
    if (!r || !r.s.choices || !r.s.choices[i]) return;
    const s = r.s, c = s.choices[i];
    run.hist.push({ id: s.id, a: r.a, pick: i });
    if (c.flag) addFlags(c.flag);
    run.picks.push(T.raw(c));
    const seen = (S.seen[s.id] = S.seen[s.id] || []);
    if (!seen.includes(i)) seen.push(i);
    const got = collect(ch, T.learn(c), run.got);
    run.at = c.next;
    save();

    $("#dock").innerHTML = "";
    $("#log").insertAdjacentHTML("beforeend", pickHTML(c, true));
    if (got.length) noteToast(ch, got);
    setTimeout(() => showCurrent(true), 380);
  }

  function noteToast(ch, keys) {
    toast(`📒 <span class="ja">ノート</span> +${keys.length} · <span class="ja">${esc(plain(dict(ch)[keys[0]].ja))}</span>`);
  }

  function finishChapter() {
    const run = S.run, ch = SH.getChapter(run.ch);
    const r = scene(ch, run.at, run.a);
    const prev = S.chapters[ch.id];
    S.chapters[ch.id] = { done: true, plays: (prev ? prev.plays : 0) + 1, flags: run.flags, picks: run.picks, got: run.got };
    S.run = null;
    if (ch.last && SH.seasonDef) {
      const def = SH.seasonDef;
      const f = flags();
      const e = (r && r.s.ending && def.endings.find((x) => x.id === r.s.ending))
        || def.endings.find((x) => x.when && x.when(f)) || def.endings[def.endings.length - 1];
      const isNew = !S.endings[e.id];
      if (isNew) S.endings[e.id] = Date.now();
      S.lastEnding = e.id;
      S.trips = (S.trips || 0) + 1;
      save();
      return go("ending", { id: e.id, isNew });
    }
    save();
    go("result", { ch: ch.id });
  }

  /* ═══════════ 챕터 결과 ═══════════ */
  function renderResult({ ch: id }) {
    const ch = SH.getChapter(id), r = S.chapters[id];
    if (!ch || !r) return go("map", {}, false);
    const x = (k) => dict(ch)[k];
    const li = (k) => `<li><span class="ja">${ruby(x(k).ja)}</span><span class="k">${esc(x(k).ko)}</span></li>`;
    const mem = Object.entries(ch.memo).filter(([k]) => (r.flags || []).includes(k)).map(([, t]) => t);
    const b = branchCount(ch);
    const next = SH.chapters.find((c) => c.no > ch.no);
    app.innerHTML = `<div class="screen">
      ${bar({ title: "이번 장의 이야기", back: "map" })}
      <div class="scroll">
        <div class="result-head"><div class="cn">CHAPTER ${ch.no}</div>
          <div class="stamp" aria-hidden="true">${T.stamp(ch)}<small>DONE</small></div>
          <h2 class="${isKo() ? "" : "ja"}">${T.title(ch)}</h2></div>
        ${mem.length ? `<div class="panel"><h3>이번 장에서 생긴 일</h3><ul class="memo">${mem.map((m) => `<li>${ruby(m)}</li>`).join("")}</ul></div>` : ""}
        ${r.picks && r.picks.length ? `<div class="panel"><h3>내가 한 말 · ${r.picks.length}</h3><ul class="xlist said">${r.picks.map((p) => `<li><span class="${isKo() ? "" : "ja"}">${T.show(p)}</span></li>`).join("")}</ul></div>` : ""}
        <div class="panel branches"><h3>이 장에서 걸어 본 갈래</h3>
          <div class="meter"><i style="width:${b.total ? Math.round((b.seen / b.total) * 100) : 0}%"></i></div>
          <p class="fine" style="margin-top:8px">${b.seen} / ${b.total}. 다른 말을 고르면 다른 사람이 다른 반응을 하고, 뒤 이야기도 바뀝니다.</p></div>
        ${r.got.length && !isKo() ? `<div class="panel"><h3>이번 장에서 모은 표현 · ${r.got.length}</h3><ul class="xlist">${r.got.filter(x).map(li).join("")}</ul></div>` : ""}
      </div>
      <div class="dock btn-col">
        ${next && next.status === "open" ? `<button class="btn primary" data-ch="${next.id}">다음 장 · <span class="${isKo() ? "" : "ja"}">${T.title(next)}</span></button>` : ""}
        ${isKo() ? `<button class="btn" data-replay="${ch.id}">이 장 다시 걷기</button>`
          : `<div class="btn-row"><button class="btn" data-replay="${ch.id}">이 장 다시 걷기</button><button class="btn" data-act="quiz">복습 퀴즈</button></div>`}
        <button class="btn ghost" data-act="map">일정표로</button>
      </div></div>`;
  }

  /* ═══════════ 엔딩 ═══════════ */
  function renderEnding({ id, isNew } = {}) {
    const def = SH.seasonDef;
    const e = def.endings.find((x) => x.id === (id || S.lastEnding));
    if (!e) return go("album", {}, false);
    const mem = memories();
    app.innerHTML = `<div class="screen">${bar({ title: "ENDING", sub: `${nFound()} / ${nEndings()} 엔딩`, back: "title" })}
      <div class="scroll"><div class="result-head"><div class="cn">${isNew ? "NEW ENDING" : "ENDING"}</div>
        <div class="stamp" aria-hidden="true">${T.stamp(e)}</div>
        <h2 class="${isKo() ? "" : "ja"}">${T.eTitle(e)}</h2>${isKo() ? "" : `<p class="eko">${esc(e.ko)}</p>`}</div>
        <div class="panel"><p class="note story">${T.eText(e)}</p></div>
        ${mem.length ? `<div class="panel"><h3>이번 여행의 기억</h3><ul class="memo">${mem.map((m) => `<li>${ruby(m)}</li>`).join("")}</ul></div>` : ""}
        ${albumGrid()}
        <p class="fine" style="text-align:center">다른 사람에게 다른 말을 건네면, 같은 사흘 밤이 전혀 다른 이야기가 됩니다.</p>
        <p class="credit">스틸링고 ${isKo() ? esc(CFG.titleKo) : `<span class="ja">${CFG.titleText}</span>`} · ${EDS[ED].name} · 기획과 구성 by 곤사마<br>Special Thanks to 앤셜리</p>
      </div><div class="dock btn-col"><button class="btn primary" data-act="newtrip">새 여행 떠나기</button>
        ${isKo() ? `<button class="btn" data-act="map">장 골라 다시 걷기</button>`
          : `<div class="btn-row"><button class="btn" data-act="map">장 골라 다시 걷기</button><button class="btn" data-act="note"><span class="ja">${CFG.noteName}</span></button></div>`}</div></div>`;
  }

  function albumGrid() {
    const def = SH.seasonDef;
    return `<div class="panel"><h3>엔딩 앨범 · ${nFound()} / ${nEndings()}</h3><div class="album">${def.endings.map((e) => S.endings[e.id]
      ? `<button class="aitem got" data-ending="${e.id}"><span class="astamp">${T.stamp(e)}</span><span class="${isKo() ? "" : "ja"}">${T.eTitle(e)}</span>${isKo() ? "" : `<small>${esc(e.ko)}</small>`}</button>`
      : `<div class="aitem"><span class="astamp">?</span><span>???</span><small>${esc(e.hint || "")}</small></div>`).join("")}</div></div>`;
  }
  function renderAlbum() {
    app.innerHTML = `<div class="screen">${bar({ title: "엔딩 앨범", sub: `${nFound()} / ${nEndings()} 발견`, back: "back" })}
      <div class="scroll">${albumGrid()}
        <p class="fine">엔딩은 점수가 아니라 누구와 어떤 이야기를 나눴는지로 갈립니다. 본 엔딩을 누르면 다시 읽을 수 있어요. 새 여행을 떠나도 앨범은 남아요.</p></div>
      <div class="dock"><button class="btn primary" data-act="map">${CFG.trip} 일정표</button></div></div>`;
  }
  function endingSheet(id) {
    const e = SH.seasonDef.endings.find((x) => x.id === id);
    if (!e) return;
    openSheet(`<div class="result-head" style="padding-top:4px"><div class="stamp" aria-hidden="true">${T.stamp(e)}</div>
      <h2 class="${isKo() ? "" : "ja"}">${T.eTitle(e)}</h2>${isKo() ? "" : `<p class="eko">${esc(e.ko)}</p>`}</div>
      <p class="note story">${T.eText(e)}</p><button class="btn primary" data-act="close">닫기</button>`, { label: e.ko });
  }

  /* ═══════════ 旅ノート ═══════════ */
  function noteEntries() {
    return Object.entries(S.notes)
      .map(([id, m]) => {
        const [chId, k] = id.split(":");
        const ch = SH.getChapter(chId);
        const x = ch && dict(ch)[k];
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
      body = `<div class="empty">아직 모은 표현이 없어요.<br>${CFG.trip}을 떠나면 듣고 말한 표현이<br>여기에 자동으로 쌓입니다.</div>`;
      dock = `<button class="btn primary" data-act="map">${CFG.trip} 일정표로</button>`;
    } else if (noteState.tab === "list") {
      let lastCh = null;
      body = list.map((e) => {
        const head = lastCh !== e.ch.id ? `<p class="nch ja">第${e.ch.no}章 ${ruby(e.ch.title)} · ${esc(e.ch.ko)}</p>` : "";
        lastCh = e.ch.id;
        return head + `<div class="nitem"><p class="ja">${ruby(e.x.ja)}</p>
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
      ${bar({ title: `<span class="ja">${CFG.noteName}</span>`, sub: `${EDS[ED].name} · 모은 표현 ${list.length}개`, back: "back" })}
      <div class="tabs" role="tablist">${tabs}</div>
      <div class="scroll">${body}</div>${dock ? `<div class="dock">${dock}</div>` : ""}</div>`;
  }

  /* 3지선다: 일본어 → 뜻 / 뜻 → 일본어를 번갈아 낸다. 오답 보기는 다른 챕터 표현까지 끌어온다. */
  function makeQuiz(list) {
    const pool = [];
    SH.chapters.forEach((c) => Object.entries(dict(c)).forEach(([k, x]) => pool.push({ ch: c, k, x })));
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
        <p class="fine" style="text-align:center">헷갈린 표현은 '표현' 탭에서 🔊로 한 번 더 들어 보세요.</p>`;
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
        ? `${EDS[ED].name} ${T.chHead(run)}, 지금 장면까지 이 기기에 저장됐어요. 다음에 앱을 켜면 표지에서 <b>이어하기</b>를 누르면 됩니다.`
        : "이 브라우저는 저장을 막고 있어요(시크릿 창 등). 일반 창이나 설치한 앱에서 열어 주세요."}</p>
      <div class="btn-row"><button class="btn" data-act="title">저장하고 나가기</button><button class="btn primary" data-act="close">계속하기</button></div>`, { label: "저장" });
  }
  function resetSheet() {
    openSheet(`<h2 class="set-h">새 여행을 떠날까요?</h2>
      <p class="note">${EDS[ED].name}의 장 기록과 기억이 지워지고 1장부터 다시 시작해요. <b>엔딩 앨범</b>${isKo() ? "" : `과 <span class="ja">${CFG.noteName}</span>`}, 걸어 본 갈래 표시는 그대로 남아요.</p>
      <div class="btn-col"><button class="btn primary" data-act="donewtrip">새 여행 떠나기</button>
        <button class="btn" data-act="close">취소</button>
        <button class="btn ghost danger" data-act="wipe">앨범과 노트까지 모두 지우기</button></div>`, { label: "새 여행 확인" });
  }
  function wipeSheet() {
    openSheet(`<h2 class="set-h">정말 모두 지울까요?</h2>
      <p class="note">${EDS[ED].name}의 엔딩 앨범${isKo() ? "" : `, <span class="ja">${CFG.noteName}</span>`}, 걸어 본 갈래 표시까지 전부 지워집니다. 다른 판의 기록은 남아요. 되돌릴 수 없어요.</p>
      <div class="btn-row"><button class="btn" data-act="close">취소</button><button class="btn primary" data-act="dowipe">모두 지우기</button></div>`, { label: "전체 삭제 확인" });
  }
  function rewindSheet(id) {
    const ch = SH.getChapter(id);
    const later = SH.chapters.filter((c) => c.no > ch.no && S.chapters[c.id]);
    openSheet(`<h2 class="set-h">${T.chHead(ch)}부터 다시 걸을까요?</h2>
      <p class="note">${later.length ? `이 장에서 다른 말을 하면 뒤 이야기가 달라지므로, <b>${ch.no + 1}장 이후의 기록</b>은 지워져요. ` : ""}엔딩 앨범${isKo() ? "" : `과 <span class="ja">${CFG.noteName}</span>`}는 그대로예요.</p>
      <div class="btn-row"><button class="btn" data-act="close">취소</button><button class="btn primary" data-replay="${id}" data-confirm="1">다시 걷기</button></div>`, { label: "다시 걷기 확인" });
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
  function newTrip() {
    const keep = { settings: S.settings, notes: S.notes, seen: S.seen, endings: S.endings, pics: S.pics, lastEnding: S.lastEnding, trips: S.trips };
    S = Object.assign(fresh(), keep);
    save();
  }

  document.addEventListener("click", (ev) => {
    const t = ev.target.closest("button, [data-act]");
    if (!t || t.disabled) return;
    const d = t.dataset;
    if (d.say != null) return TTS.speak(d.say);
    if (d.furi != null) {
      const b = t.closest(".bubble");
      const on = b.classList.toggle("furi-on");
      t.setAttribute("aria-pressed", String(on));
      return;
    }
    if (d.ed != null) {
      if (d.ed === ED) return;
      useEdition(d.ed);
      applySettings();
      noteState = { tab: "list", card: 0, flipped: false, quiz: null };
      try { history.replaceState({ v: "title" }, "", location.pathname); } catch (e) {}
      renderTitle();
      const el = document.querySelector(`[data-ed="${d.ed}"]`);
      if (el) el.focus({ preventScroll: true });
      return;
    }
    if (d.ko != null) {
      const ko = t.closest(".bubble").querySelector(".ko");
      ko.hidden = !ko.hidden;
      t.setAttribute("aria-pressed", String(!ko.hidden));
      return;
    }
    if (d.gloss != null) {
      const g = t.closest(".bubble").querySelector(".gbody");
      g.hidden = !g.hidden;
      t.setAttribute("aria-expanded", String(!g.hidden));
      t.textContent = g.hidden ? "🔍 뜯어보기" : "🔍 닫기";
      if (!g.hidden) g.scrollIntoView({ block: "nearest", behavior: "smooth" });
      return;
    }
    if (d.pick != null) return pick(+d.pick);
    if (d.ending != null) return endingSheet(d.ending);
    if (d.ch != null) {
      const c = SH.getChapter(d.ch);
      if (!c || c.status !== "open") return toast("준비 중인 장이에요. 다음 업데이트에서 열립니다.");
      if (!unlocked(c)) return toast(CFG.trip + "은 순서대로! 앞 장을 먼저 마쳐 주세요.");
      if (S.run && S.run.ch === d.ch) return go("play");
      if (S.chapters[d.ch] && S.chapters[d.ch].done) return rewindSheet(d.ch);
      return startChapter(d.ch);
    }
    if (d.replay != null) {
      const later = SH.chapters.some((c) => c.no > SH.getChapter(d.replay).no && S.chapters[c.id]);
      if (later && !d.confirm) return rewindSheet(d.replay);
      return startChapter(d.replay);
    }
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
    switch (d.act) {
      case "title": return go("title");
      case "bigtext": S.settings.big = !S.settings.big; save(); applySettings(); return renderTitle();
      case "furiall": S.settings.furi = !S.settings.furi; save(); applySettings(); return renderTitle();
      case "map": return go("map");
      case "album": return go("album");
      case "back": return history.length > 1 && (view.v === "note" || view.v === "album") ? history.back() : go("title");
      case "resume": return go("play");
      case "note": if (isKo()) return; noteState.tab = "list"; return go("note");
      case "quiz": noteState.tab = "quiz"; noteState.quiz = null; return go("note", { tab: "quiz" });
      case "save": return saveSheet();
      case "install": return Install.sheet();
      case "installnow": return Install.now();
      case "reset": return resetSheet();
      case "newtrip": return resetSheet();
      case "donewtrip": newTrip(); closeSheet(); toast("새 여행을 떠납니다. ✈"); return go("map");
      case "wipe": return wipeSheet();
      case "dowipe": {
        const keep = S.settings;
        S = fresh(); S.settings = keep; save();
        closeSheet(); toast("모두 지웠어요."); return go("title");
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

  /* 키보드: 플레이 중 Enter = 다음, 1~4 = 선택 (컴퓨터에서 테스트할 때 편하게) */
  document.addEventListener("keydown", (ev) => {
    if (view.v !== "play" || ev.target.closest("input, textarea")) return;
    if (sheetOpen()) { if (ev.key === "Escape") closeSheet(true); return; }
    const n = parseInt(ev.key, 10);
    if (n >= 1 && n <= 4) { const b = document.querySelectorAll(".choice")[n - 1]; if (b) b.click(); }
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
  app.innerHTML = `<div class="loading">도쿄로 가는 중…</div>`;
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
