/* 出張編 core — 데이터 등록, 후리가나 파서, 저장, 로더, 검증기.
   화면 코드(app.js)와 점검 페이지(tools/check.html)가 함께 쓴다. */
(function () {
  "use strict";
  const SH = (window.SH = window.SH || {});
  SH.chapters = [];
  SH.seasonDef = null;

  /* ── 데이터 등록 ─────────────────────────── */
  SH.chapter = (def) => {
    def.scenes = def.scenes || [];
    def.expressions = def.expressions || {};
    def.byId = {};
    def.scenes.forEach((s) => (def.byId[s.id] = s));
    SH.chapters.push(def);
    SH.chapters.sort((a, b) => a.no - b.no);
  };
  SH.season = (def) => (SH.seasonDef = def);
  SH.getChapter = (id) => SH.chapters.find((c) => c.id === id);

  /* ── 후리가나: 漢字{かんじ} 표기 ─────────── */
  const KANJI = "\\u3400-\\u4DBF\\u4E00-\\u9FFF\\uF900-\\uFAFF々〆ヵヶ";
  const RUBY_RE = new RegExp("([" + KANJI + "]+)\\{([^{}]+)\\}", "g");
  const KANJI_RE = new RegExp("[" + KANJI + "]");
  const KATA_RE = /^[゠-ヿ・ー]+$/;

  SH.esc = (s) =>
    String(s == null ? "" : s).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
  /** 표기 → <ruby> HTML */
  SH.ruby = (s) => SH.esc(s).replace(RUBY_RE, "<ruby>$1<rt>$2</rt></ruby>");
  /** 표기 → 화면용 평문(읽기 제거) */
  SH.plain = (s) => String(s || "").replace(RUBY_RE, "$1");
  /** 표기 → 음성용 문장. 가타카나 읽기(인명·회사명)는 읽기로 바꿔 오독을 막는다 */
  SH.speech = (s) =>
    String(s || "")
      .replace(RUBY_RE, (m, base, read) => (KATA_RE.test(read) ? read : base))
      .replace(/[（(][^）)]*[）)]/g, "")
      .replace(/〜/g, "");

  /* ── 저장 ───────────────────────────────── */
  const KEY = "shucchou.v1";
  SH.store = {
    load() {
      try { return JSON.parse(localStorage.getItem(KEY)) || null; } catch (e) { return null; }
    },
    save(state) {
      try { localStorage.setItem(KEY, JSON.stringify(state)); return true; } catch (e) { return false; }
    },
    clear() {
      try { localStorage.removeItem(KEY); } catch (e) { /* 저장소 없음 */ }
    }
  };

  /* ── 데이터 로더 ─────────────────────────── */
  SH.loadData = (base) => {
    const files = self.SH_DATA_FILES || [];
    const one = (f) =>
      new Promise((res) => {
        const el = document.createElement("script");
        el.src = base + f;
        el.onload = () => res({ f, ok: true });
        el.onerror = () => res({ f, ok: false });
        document.head.appendChild(el);
      });
    return Promise.all(files.map(one));
  };

  /* ── 검증기 ─────────────────────────────── */
  SH.GRADES = ["best", "awkward", "rude"];
  SH.EFFECT_KEYS = ["trust", "like"];

  /** 한 챕터를 점검해 {errors, warns, stats} 반환 */
  SH.validateChapter = (ch) => {
    const errors = [], warns = [];
    const E = (m) => errors.push(`[${ch.id}] ${m}`);
    const W = (m) => warns.push(`[${ch.id}] ${m}`);
    const stats = { scenes: 0, choicePoints: 0, expressions: Object.keys(ch.expressions).length, endings: 0, reachable: 0 };
    if (ch.status !== "open") return { errors, warns, stats };

    const ids = new Set();
    ch.scenes.forEach((s) => {
      if (ids.has(s.id)) E(`장면 ID 중복: ${s.id}`);
      ids.add(s.id);
    });
    stats.scenes = ids.size;
    if (!ch.start || !ch.byId[ch.start]) E(`시작 장면 없음: ${ch.start}`);

    const checkText = (where, t) => {
      if (t == null) return;
      const open = (t.match(/\{/g) || []).length, close = (t.match(/\}/g) || []).length;
      if (open !== close) E(`${where}: 중괄호 짝이 맞지 않음`);
      // 루비를 뺀 나머지에 한자가 남아 있으면 후리가나 누락
      const m = String(t).replace(RUBY_RE, "").match(KANJI_RE);
      if (m) E(`${where}: 후리가나 없는 한자 "${m[0]}" → ${SH.plain(t).slice(0, 30)}`);
    };
    const checkLearn = (where, arr) =>
      (arr || []).forEach((k) => { if (!ch.expressions[k]) E(`${where}: learn 키 "${k}"가 expressions에 없음`); });
    const norm = (t) => SH.plain(t).replace(/[。、，．！？!?「」『』【】…・（）()\s　]/g, "");
    const checkParts = (where, ja, parts) => {
      if (!ja) return;
      if (!parts || !parts.length) return W(`${where}: 🔍 뜯어보기(parts) 없음`);
      parts.forEach((p, i) => {
        if (!p.p || !p.r || !p.w) E(`${where} 조각${i + 1}: p/r/w 누락`);
        checkText(`${where} 조각${i + 1}`, p.p);
        checkText(`${where} 조각${i + 1} why`, p.why);
        if (p.r && KANJI_RE.test(p.r)) E(`${where} 조각${i + 1}: 읽기(r)에 한자가 있음`);
        if (p.r && /[A-Za-z]/.test(p.r)) E(`${where} 조각${i + 1}: 읽기(r)에 알파벳이 있음 "${p.r}"`);
      });
      const joined = parts.map((p) => norm(p.p)).join("");
      if (joined !== norm(ja)) E(`${where}: 조각을 이어도 문장과 다름\n   조각: ${joined}\n   문장: ${norm(ja)}`);
    };
    const checkNext = (where, n) => {
      if (!n) E(`${where}: next 없음 (막다른 장면)`);
      else if (!ch.byId[n]) E(`${where}: next "${n}" 장면이 존재하지 않음`);
    };

    Object.entries(ch.expressions).forEach(([k, x]) => {
      if (!x.ja || !x.ko) E(`표현 ${k}: ja/ko 누락`);
      checkText(`표현 ${k}`, x.ja);
      checkText(`표현 ${k} tip`, x.tip);
    });

    ch.scenes.forEach((s) => {
      const at = `장면 ${s.id}`;
      checkText(at + " ja", s.ja);
      checkText(at + " narr", s.narr);
      checkText(at + " hint", s.hint);
      checkText(at + " ask", s.ask);
      if (s.speaker !== "自分") checkText(at + " speaker", s.speaker);
      checkLearn(at, s.learn);
      (s.alt || []).forEach((a, i) => {
        checkText(`${at} alt${i}`, a.ja); checkText(`${at} alt${i} narr`, a.narr); checkText(`${at} alt${i} hint`, a.hint);
        if (a.ja) checkParts(`${at} alt${i}`, a.ja, a.parts);
      });
      if (s.ja && !s.ko) E(`${at}: 한국어 뜻(ko) 누락`);
      checkParts(at, s.ja, s.parts);
      (s.route || []).forEach((r, i) => checkNext(`${at} route${i + 1}`, r.next));
      if (s.choices) {
        stats.choicePoints++;
        // 길이로 정답이 보이면 안 된다: 정답이 혼자 가장 긴 지점을 센다
        const lens = s.choices.map((c) => norm(c.ja || "").length);
        const bi = s.choices.findIndex((c) => c.grade === "best");
        if (bi >= 0 && lens.every((l, i) => i === bi || l < lens[bi])) stats.bestLongest = (stats.bestLongest || 0) + 1;
        if (Math.max(...lens) > Math.min(...lens) * 3) W(`${at}: 선택지 길이 차이가 큼 (${lens.join("/")})`);
        s.choices.forEach((c, i) => { if (c.act) W(`${at} 선택${i + 1}: 선택지에 동작 설명(act)이 있으면 답이 보인다`); });
        if (s.choices.length !== 3) W(`${at}: 선택지가 ${s.choices.length}개 (권장 3개)`);
        const g = s.choices.map((c) => c.grade).sort().join(",");
        if (g !== "awkward,best,rude") W(`${at}: 등급 구성 ${g} (권장 best/awkward/rude 각 1)`);
        s.choices.forEach((c, i) => {
          const ca = `${at} 선택${i + 1}`;
          if (!SH.GRADES.includes(c.grade)) E(`${ca}: grade "${c.grade}" 알 수 없음`);
          if (!c.ja || !c.ko) E(`${ca}: ja/ko 누락`);
          if (!c.note) E(`${ca}: 해설(note) 누락`);
          else if (c.note.length > 140) W(`${ca}: 해설이 김 (${c.note.length}자)`);
          checkText(ca, c.ja);
          checkText(ca + " note", c.note);
          checkText(ca + " act", c.act);
          checkLearn(ca, c.learn);
          checkParts(ca, c.ja, c.parts);
          Object.keys(c.effects || {}).forEach((k) => { if (!SH.EFFECT_KEYS.includes(k)) E(`${ca}: effects 키 "${k}" 알 수 없음`); });
          checkNext(ca, c.next);
        });
      } else if (s.end) {
        stats.endings++;
      } else {
        checkNext(at, s.next);
      }
    });

    // 도달 가능성 + 모든 장면에서 끝까지 갈 수 있는지
    const out = (s) =>
      (s.choices ? s.choices.map((c) => c.next) : s.end ? [] : [s.next, ...(s.route || []).map((r) => r.next)]).filter((n) => ch.byId[n]);
    const seen = new Set();
    const q = ch.byId[ch.start] ? [ch.start] : [];
    while (q.length) {
      const id = q.shift();
      if (seen.has(id)) continue;
      seen.add(id);
      out(ch.byId[id]).forEach((n) => q.push(n));
    }
    stats.reachable = seen.size;
    ch.scenes.forEach((s) => { if (!seen.has(s.id)) W(`장면 ${s.id}: 시작에서 도달할 수 없음`); });
    const canEnd = new Set(ch.scenes.filter((s) => s.end).map((s) => s.id));
    let grew = true;
    while (grew) {
      grew = false;
      ch.scenes.forEach((s) => {
        if (!canEnd.has(s.id) && out(s).some((n) => canEnd.has(n))) { canEnd.add(s.id); grew = true; }
      });
    }
    ch.scenes.forEach((s) => { if (seen.has(s.id) && !canEnd.has(s.id)) E(`장면 ${s.id}: 챕터 끝에 도달할 수 없음 (순환/막힘)`); });
    if (!stats.endings) E("끝 장면(end:true)이 없음");
    if (stats.choicePoints && (stats.bestLongest || 0) > stats.choicePoints / 2)
      W(`정답이 가장 긴 문장인 지점이 ${stats.bestLongest}/${stats.choicePoints}곳 — 길이만 보고 맞힐 수 있음`);
    return { errors, warns, stats };
  };
})();
