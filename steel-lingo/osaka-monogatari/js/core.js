/* 大阪物語 core — 데이터 등록, 조건(플래그), 후리가나 파서, 저장, 로더, 검증기.
   화면 코드(app.js)와 점검 페이지(tools/check.html)가 함께 쓴다.

   이 앱에는 점수도, 정답도 없다. 선택은 '플래그'로 남고, 플래그가 뒤 장면·뒤 장·엔딩을 바꾼다.
   - choice.flag / route.flag / scene.flag : 문자열 하나 또는 배열. 지나가면 켜진다
   - scene.move = true 이면 선택지가 '장소 고르기'다(label·sub, 일본어 없음). 한 시간대에 한 곳만 갈 수 있다
   - if: ["a", "!b"] = a가 켜져 있고 b는 꺼져 있을 때 / any: ["a", "b"] = 둘 중 하나라도
     → route(갈림길), alt(같은 장면의 다른 판), choice(그 기억이 있어야 보이는 선택지)에 쓴다 */
(function () {
  "use strict";
  const SH = (window.SH = window.SH || {});
  SH.chapters = [];
  SH.seasonDef = null;

  /* ── 데이터 등록 ─────────────────────────── */
  SH.chapter = (def) => {
    def.scenes = def.scenes || [];
    def.expressions = def.expressions || {};
    def.memo = def.memo || {};
    def.byId = {};
    def.scenes.forEach((s) => (def.byId[s.id] = s));
    SH.chapters.push(def);
    SH.chapters.sort((a, b) => a.no - b.no);
  };
  SH.season = (def) => (SH.seasonDef = def);
  SH.getChapter = (id) => SH.chapters.find((c) => c.id === id);

  /* ── 조건 ───────────────────────────────── */
  SH.flagList = (f) => (f == null ? [] : Array.isArray(f) ? f : [f]);
  const holds = (term, set) => (term[0] === "!" ? !set.has(term.slice(1)) : set.has(term));
  /** {if, any}가 지금 플래그로 성립하는가. 둘 다 없으면 언제나 참 */
  SH.test = (cond, set) => {
    if (!cond) return true;
    if (cond.if && !SH.flagList(cond.if).every((t) => holds(t, set))) return false;
    if (cond.any && !SH.flagList(cond.any).some((t) => holds(t, set))) return false;
    return true;
  };

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
  const KEY = (self.SH_APP && self.SH_APP.storeKey) || "osakamono.v2";
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
  const condTerms = (c) => [...SH.flagList(c && c.if), ...SH.flagList(c && c.any)].map((t) => t.replace(/^!/, ""));

  /** 한 챕터를 점검해 {errors, warns, stats, sets, uses} 반환. sets/uses는 플래그 이름(시즌 점검용) */
  SH.validateChapter = (ch) => {
    const errors = [], warns = [];
    const E = (m) => errors.push(`[${ch.id}] ${m}`);
    const W = (m) => warns.push(`[${ch.id}] ${m}`);
    const stats = { scenes: 0, choicePoints: 0, options: 0, expressions: Object.keys(ch.expressions).length, endings: 0, reachable: 0 };
    const sets = new Set(), uses = [];
    if (ch.status !== "open") return { errors, warns, stats, sets, uses };

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
    const norm = (t) => SH.plain(t).replace(/[。、，．！？!?「」『』【】…・〜（）()\s　]/g, "");
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
    const useCond = (where, c) => condTerms(c).forEach((f) => uses.push({ f, where: `[${ch.id}] ${where}` }));
    const addSets = (f) => SH.flagList(f).forEach((x) => sets.add(x));

    Object.entries(ch.expressions).forEach(([k, x]) => {
      if (!x.ja || !x.ko) E(`표현 ${k}: ja/ko 누락`);
      checkText(`표현 ${k}`, x.ja);
      checkText(`표현 ${k} tip`, x.tip);
    });
    Object.keys(ch.memo).forEach((f) => uses.push({ f, where: `[${ch.id}] memo` }));

    ch.scenes.forEach((s) => {
      const at = `장면 ${s.id}`;
      checkText(at + " ja", s.ja);
      checkText(at + " narr", s.narr);
      checkText(at + " hint", s.hint);
      checkText(at + " ask", s.ask);
      checkText(at + " act", s.act);
      if (s.speaker !== "自分") checkText(at + " speaker", s.speaker);
      checkLearn(at, s.learn);
      addSets(s.flag);
      if (s.ja && !s.ko) E(`${at}: 한국어 뜻(ko) 누락`);
      checkParts(at, s.ja, s.parts);
      (s.alt || []).forEach((a, i) => {
        const aw = `${at} alt${i + 1}`;
        if (a.flag && !a.if && !a.any) E(`${aw}: alt 조건은 if/any로 쓴다 (flag는 '켜기' 전용)`);
        if (!a.if && !a.any) E(`${aw}: 조건(if/any)이 없음`);
        useCond(aw, a);
        checkText(`${aw} ja`, a.ja); checkText(`${aw} narr`, a.narr); checkText(`${aw} hint`, a.hint);
        checkText(`${aw} act`, a.act); if (a.speaker && a.speaker !== "自分") checkText(`${aw} speaker`, a.speaker);
        if (a.ja) { if (!a.ko) E(`${aw}: ja를 바꾸면 ko도 바꿔야 함`); checkParts(aw, a.ja, a.parts); }
        if (a.choices) E(`${aw}: alt로 선택지를 바꾸지 않는다 — 선택지마다 if를 쓴다`);
      });
      (s.route || []).forEach((r, i) => {
        checkNext(`${at} route${i + 1}`, r.next);
        if (!r.if && !r.any) W(`${at} route${i + 1}: 조건이 없어 언제나 이 길로 간다`);
        useCond(`${at} route${i + 1}`, r);
        addSets(r.flag);
      });
      if (s.choices) {
        stats.choicePoints++;
        stats.options += s.choices.length;
        if (s.choices.length < 2) E(`${at}: 선택지가 ${s.choices.length}개`);
        if (s.choices.every((c) => c.if || c.any)) E(`${at}: 모든 선택지에 조건이 붙어 있어 아무것도 안 보일 수 있음`);
        if (s.choices.filter((c) => !c.if && !c.any).length < 2) W(`${at}: 조건 없는 선택지가 2개 미만`);
        s.choices.forEach((c, i) => {
          const ca = `${at} 선택${i + 1}`;
          if (c.grade || c.note) E(`${ca}: 이 앱에는 등급(grade)·해설(note)이 없다`);
          if (s.move) {
            // 장소 고르기: 일본어 대사 대신 장소 이름(label)과 한 줄 설명(sub)
            if (!c.label) E(`${ca}: 장소 고르기에는 label이 필요`);
            checkText(ca + " label", c.label); checkText(ca + " sub", c.sub); checkText(ca + " then", c.then);
            useCond(ca, c); addSets(c.flag); checkNext(ca, c.next);
            return;
          }
          if (!c.ja || !c.ko) E(`${ca}: ja/ko 누락`);
          checkText(ca, c.ja);
          checkText(ca + " then", c.then);
          checkLearn(ca, c.learn);
          checkParts(ca, c.ja, c.parts);
          useCond(ca, c);
          addSets(c.flag);
          checkNext(ca, c.next);
        });
      } else if (s.end) {
        stats.endings++;
        if (ch.last && !s.ending) W(`${at}: 마지막 장의 끝 장면에 ending이 없음 (시즌 when으로 정함)`);
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
    return { errors, warns, stats, sets, uses };
  };

  /** 시즌 전체 점검: 장별 점검 + 쓰는 플래그가 어디선가 켜지는지 + 엔딩 연결 */
  SH.validateAll = () => {
    let errors = [], warns = [];
    const sets = new Set(), uses = [], rows = [];
    SH.chapters.forEach((ch) => {
      const r = SH.validateChapter(ch);
      errors = errors.concat(r.errors); warns = warns.concat(r.warns);
      r.sets.forEach((f) => sets.add(f)); uses.push(...r.uses);
      rows.push({ ch, stats: r.stats });
    });
    uses.forEach((u) => { if (!sets.has(u.f)) errors.push(`${u.where}: 플래그 "${u.f}"를 켜는 곳이 없음`); });
    const def = SH.seasonDef;
    if (!def) errors.push("season.js(엔딩 정의) 없음");
    else {
      const ids = new Set(def.endings.map((e) => e.id));
      if (ids.size !== def.endings.length) errors.push("엔딩 id 중복");
      def.endings.forEach((e) => {
        if (!e.ja || !e.ko || !e.text) errors.push(`엔딩 ${e.id}: ja/ko/text 누락`);
        if (e.ja && /[一-鿿]/.test(String(e.ja).replace(RUBY_RE, ""))) errors.push(`엔딩 ${e.id}: 후리가나 없는 한자`);
        if (e.text && /[一-鿿]/.test(String(e.text).replace(RUBY_RE, ""))) errors.push(`엔딩 ${e.id} text: 후리가나 없는 한자`);
      });
      const used = new Set();
      SH.chapters.forEach((ch) => ch.scenes.forEach((s) => {
        if (s.ending) { used.add(s.ending); if (!ids.has(s.ending)) errors.push(`[${ch.id}] 장면 ${s.id}: 엔딩 "${s.ending}"이 season.js에 없음`); }
      }));
      def.endings.forEach((e) => { if (!used.has(e.id) && !e.when) warns.push(`엔딩 ${e.id}: 이어지는 끝 장면이 없음`); });
    }
    return { errors, warns, rows, flags: [...sets].sort() };
  };
})();
