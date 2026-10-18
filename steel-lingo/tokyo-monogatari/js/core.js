/* 東京物語 core — 데이터 등록, 조건(플래그), 후리가나 파서, 저장, 로더, 검증기.
   화면 코드(app.js)와 점검 페이지(tools/check.html)가 함께 쓴다.

   이야기 하나를 세 판으로 읽는다. 장면 하나가 세 판의 말을 함께 들고 있다.
   - 한국어편(ko): ko만 쓴다. 일본어가 한 글자도 나오지 않는다
   - 초급편(easy): ja(쉬운 일본어) + parts(뜯어보기) + hint, 해석(ko)이 처음부터 보인다
   - 상급편(hard): jx(자연스러운 일본어) + hx(뉘앙스 메모), 후리가나와 해석은 눌러야 보인다
   narr·act·ask·then·memo·엔딩 글은 세 판이 같이 쓰는 한국어다(narj가 있으면 일본어 두 판은 그것을 쓴다).

   점수도 정답도 없다. 선택은 '플래그'로 남고, 플래그가 뒤 장면·뒤 장·엔딩을 바꾼다.
   - choice.flag / route.flag / scene.flag : 문자열 하나 또는 배열. 지나가면 켜진다
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
    def.advanced = def.advanced || {};
    def.memo = def.memo || {};
    def.byId = {};
    def.scenes.forEach((s) => (def.byId[s.id] = s));
    SH.chapters.push(def);
    SH.chapters.sort((a, b) => a.no - b.no);
  };
  SH.season = (def) => (SH.seasonDef = def);
  SH.getChapter = (id) => SH.chapters.find((c) => c.id === id);
  /** 판별 표현 사전: 초급은 expressions, 상급은 advanced */
  SH.dict = (ch, ed) => (ed === "hard" ? ch.advanced : ch.expressions);

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
  const JP_RE = /[぀-ヿ㐀-䶿一-鿿豈-﫿々〆]/;

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

  /* ── 저장: 판마다 따로 ───────────────────── */
  const BASE = (self.SH_APP && self.SH_APP.storeKey) || "tokyomono.v1";
  let KEY = BASE + ".easy";
  SH.store = {
    use(ed) { KEY = BASE + "." + ed; },
    load() {
      try { return JSON.parse(localStorage.getItem(KEY)) || null; } catch (e) { return null; }
    },
    save(state) {
      try { localStorage.setItem(KEY, JSON.stringify(state)); return true; } catch (e) { return false; }
    },
    clear() {
      try { localStorage.removeItem(KEY); } catch (e) { /* 저장소 없음 */ }
    },
    /** 마지막으로 고른 판 */
    lastEd(v) {
      try {
        if (v) localStorage.setItem(BASE + ".ed", v);
        return localStorage.getItem(BASE + ".ed");
      } catch (e) { return null; }
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
  const cast = () => (SH.seasonDef && SH.seasonDef.cast) || {};

  /** 한 챕터를 점검해 {errors, warns, stats, sets, uses} 반환. sets/uses는 플래그 이름(시즌 점검용) */
  SH.validateChapter = (ch) => {
    const errors = [], warns = [];
    const E = (m) => errors.push(`[${ch.id}] ${m}`);
    const W = (m) => warns.push(`[${ch.id}] ${m}`);
    const stats = {
      scenes: 0, choicePoints: 0, options: 0, lines: 0,
      expressions: Object.keys(ch.expressions).length, advanced: Object.keys(ch.advanced).length, endings: 0, reachable: 0
    };
    const sets = new Set(), uses = [];
    if (ch.status !== "open") return { errors, warns, stats, sets, uses };

    const ids = new Set();
    ch.scenes.forEach((s) => {
      if (ids.has(s.id)) E(`장면 ID 중복: ${s.id}`);
      ids.add(s.id);
    });
    stats.scenes = ids.size;
    if (!ch.start || !ch.byId[ch.start]) E(`시작 장면 없음: ${ch.start}`);

    /** 일본어 칸: 후리가나 없는 한자가 있으면 오류 */
    const checkJa = (where, t) => {
      if (t == null) return;
      const open = (t.match(/\{/g) || []).length, close = (t.match(/\}/g) || []).length;
      if (open !== close) E(`${where}: 중괄호 짝이 맞지 않음`);
      const m = String(t).replace(RUBY_RE, "").match(KANJI_RE);
      if (m) E(`${where}: 후리가나 없는 한자 "${m[0]}" → ${SH.plain(t).slice(0, 30)}`);
    };
    /** 한국어 칸: 한국어편에도 보이므로 가나·한자가 있으면 오류 */
    const checkKo = (where, t) => {
      if (t == null) return;
      const m = String(t).match(JP_RE);
      if (m) E(`${where}: 한국어 칸에 일본어 "${m[0]}" → ${String(t).slice(0, 30)}`);
      if (/[{}]/.test(t)) E(`${where}: 한국어 칸에 중괄호`);
    };
    const checkLearn = (where, arr, dict, name) =>
      (arr || []).forEach((k) => { if (!dict[k]) E(`${where}: ${name} 키 "${k}"가 없음`); });
    const norm = (t) => SH.plain(t).replace(/[。、，．！？!?「」『』【】…・〜ー（）()\s　]/g, "");
    const checkParts = (where, ja, parts) => {
      if (!ja) return;
      if (!parts || !parts.length) return W(`${where}: 🔍 뜯어보기(parts) 없음`);
      parts.forEach((p, i) => {
        if (!p.p || !p.r || !p.w) E(`${where} 조각${i + 1}: p/r/w 누락`);
        checkJa(`${where} 조각${i + 1}`, p.p);
        checkJa(`${where} 조각${i + 1} why`, p.why);
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
    const checkWho = (where, w) => {
      if (w == null) return;
      if (w !== "me" && !cast()[w]) E(`${where}: who "${w}"가 season.js cast에 없음`);
    };
    /** 대사 한 줄(장면·alt·선택지)의 세 판 */
    const checkLine = (where, x, needAll) => {
      checkKo(where + " ko", x.ko);
      checkJa(where + " ja", x.ja);
      checkJa(where + " jx", x.jx);
      checkJa(where + " hint", x.hint);
      checkJa(where + " hx", x.hx);
      checkLearn(where, x.learn, ch.expressions, "learn");
      checkLearn(where, x.learnx, ch.advanced, "learnx");
      if (needAll || x.ko || x.ja || x.jx) {
        if (!x.ko) E(`${where}: ko(한국어편 대사) 누락`);
        if (!x.ja) E(`${where}: ja(초급편 대사) 누락`);
        if (!x.jx) E(`${where}: jx(상급편 대사) 누락`);
      }
      if (x.ja) checkParts(where, x.ja, x.parts);
    };
    const useCond = (where, c) => condTerms(c).forEach((f) => uses.push({ f, where: `[${ch.id}] ${where}` }));
    const addSets = (f) => SH.flagList(f).forEach((x) => sets.add(x));

    ["day", "ko", "place", "summary"].forEach((k) => checkKo(`장 ${k}`, ch[k]));
    checkJa("장 title", ch.title);
    if (!ch.sko) W("장 sko(한국어편 도장 글자) 없음");
    [["expressions", ch.expressions], ["advanced", ch.advanced]].forEach(([name, d]) =>
      Object.entries(d).forEach(([k, x]) => {
        if (!x.ja || !x.ko) E(`${name} ${k}: ja/ko 누락`);
        checkJa(`${name} ${k}`, x.ja);
        checkJa(`${name} ${k} tip`, x.tip);
      }));
    Object.entries(ch.memo).forEach(([f, t]) => { uses.push({ f, where: `[${ch.id}] memo` }); checkKo(`memo ${f}`, t); });

    ch.scenes.forEach((s) => {
      const at = `장면 ${s.id}`;
      checkKo(at + " narr", s.narr);
      checkJa(at + " narj", s.narj);
      checkKo(at + " ask", s.ask);
      checkKo(at + " act", s.act);
      checkWho(at, s.who);
      if (s.speaker) E(`${at}: speaker 대신 who(cast 키)를 쓴다`);
      if (s.ko || s.ja || s.jx) { stats.lines++; if (!s.who) E(`${at}: 대사에 who 없음`); }
      checkLine(at, s, false);
      addSets(s.flag);
      (s.alt || []).forEach((a, i) => {
        const aw = `${at} alt${i + 1}`;
        if (a.flag && !a.if && !a.any) E(`${aw}: alt 조건은 if/any로 쓴다 (flag는 '켜기' 전용)`);
        if (!a.if && !a.any) E(`${aw}: 조건(if/any)이 없음`);
        useCond(aw, a);
        checkKo(`${aw} narr`, a.narr); checkJa(`${aw} narj`, a.narj); checkKo(`${aw} act`, a.act);
        checkWho(aw, a.who);
        if (a.ko || a.ja || a.jx) checkLine(aw, a, true);
        else { checkJa(aw + " hint", a.hint); checkJa(aw + " hx", a.hx); }
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
        if (s.ko || s.ja) E(`${at}: 선택 장면에는 대사를 두지 않는다(ask만)`);
        if (s.choices.length < 2) E(`${at}: 선택지가 ${s.choices.length}개`);
        if (s.choices.every((c) => c.if || c.any)) E(`${at}: 모든 선택지에 조건이 붙어 있어 아무것도 안 보일 수 있음`);
        if (s.choices.filter((c) => !c.if && !c.any).length < 2) W(`${at}: 조건 없는 선택지가 2개 미만`);
        s.choices.forEach((c, i) => {
          const ca = `${at} 선택${i + 1}`;
          if (c.grade || c.note) E(`${ca}: 이 앱에는 등급(grade)·해설(note)이 없다`);
          checkLine(ca, c, true);
          checkKo(ca + " then", c.then);
          checkKo(ca + " tag", c.tag);
          useCond(ca, c);
          addSets(c.flag);
          checkNext(ca, c.next);
        });
      } else if (s.end) {
        stats.endings++;
        if (ch.last && !s.ending) W(`${at}: 마지막 장의 끝 장면에 ending이 없음`);
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

  /** 시즌 전체 점검: 장별 점검 + 쓰는 플래그가 어디선가 켜지는지 + 엔딩 연결 + 등장인물 */
  SH.validateAll = () => {
    let errors = [], warns = [];
    const sets = new Set(), uses = [], rows = [];
    const def = SH.seasonDef;
    if (!def) errors.push("season.js(엔딩·등장인물 정의) 없음");
    SH.chapters.forEach((ch) => {
      const r = SH.validateChapter(ch);
      errors = errors.concat(r.errors); warns = warns.concat(r.warns);
      r.sets.forEach((f) => sets.add(f)); uses.push(...r.uses);
      rows.push({ ch, stats: r.stats });
    });
    uses.forEach((u) => { if (!sets.has(u.f)) errors.push(`${u.where}: 플래그 "${u.f}"를 켜는 곳이 없음`); });
    if (def) {
      Object.entries(def.cast || {}).forEach(([k, c]) => {
        if (!c.ja || !c.ko) errors.push(`cast ${k}: ja/ko 누락`);
        if (c.ko && JP_RE.test(c.ko)) errors.push(`cast ${k}: ko에 일본어`);
        if (c.ja && String(c.ja).replace(RUBY_RE, "").match(KANJI_RE)) errors.push(`cast ${k}: 후리가나 없는 한자`);
      });
      const ids = new Set(def.endings.map((e) => e.id));
      if (ids.size !== def.endings.length) errors.push("엔딩 id 중복");
      def.endings.forEach((e) => {
        if (!e.ja || !e.ko || !e.text || !e.sko) errors.push(`엔딩 ${e.id}: ja/ko/text/sko 누락`);
        const jaBad = (t) => t && String(t).replace(RUBY_RE, "").match(KANJI_RE);
        if (jaBad(e.ja)) errors.push(`엔딩 ${e.id}: ja에 후리가나 없는 한자`);
        if (jaBad(e.textj)) errors.push(`엔딩 ${e.id}: textj에 후리가나 없는 한자`);
        ["ko", "text", "hint", "sko"].forEach((k) => { if (e[k] && JP_RE.test(e[k])) errors.push(`엔딩 ${e.id}: ${k}에 일본어`); });
      });
      const used = new Set();
      SH.chapters.forEach((ch) => ch.scenes.forEach((s) => {
        if (s.ending) { used.add(s.ending); if (!ids.has(s.ending)) errors.push(`[${ch.id}] 장면 ${s.id}: 엔딩 "${s.ending}"이 season.js에 없음`); }
      }));
      def.endings.forEach((e) => { if (!used.has(e.id)) warns.push(`엔딩 ${e.id}: 이어지는 끝 장면이 없음`); });
    }
    return { errors, warns, rows, flags: [...sets].sort() };
  };
})();
