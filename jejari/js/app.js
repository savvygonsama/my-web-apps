/* 제자리 · 화면과 흐름

   순서는 언제나 "몸 먼저, 이름 붙이기 다음, 생각은 나중".
   세션(1분 SOS·루틴)은 한 단계씩 화면을 그리고 사용자의 선택을 기다리는 흐름으로 돈다.
   [그만하기], [지금 많이 힘들다면], 앱이 뒤로 숨는 일이 생기면 흐름을 바로 끊고 그 사유를 남긴다.
   이어하기는 두지 않는다. */

import {
  VERSION, CONTACTS, PRIVACY, RULES, PACES, EMOTIONS, UNSURE, NEXT_ACTIONS, REAPPRAISAL,
  ROUTINES, ICS_TITLE, EVIDENCE, TERMS, PRIVACY_TEXT,
} from './content.js';
import { getSettings, saveSettings, resetSettings, put, all, remove, clear, requestPersist } from './store.js';

const $view = document.getElementById('view');
const $top = document.getElementById('top');
const $live = document.getElementById('live');
const settings = getSettings;

const BREATH_LEAD = '편하게 들이쉬고 조금 길게 내쉬어요. 깊게 쉬지 않아도 돼요.';
const BREATH_SAFETY = '어지럽거나 손발이 저리면 바로 멈추고 평소처럼 숨 쉬세요.';
const FIRST_NOTICE = '숨쉬기가 불편한 질환이 있거나, 호흡 중 어지럽거나 숨이 더 불편하면 [호흡 대신 다른 방법]을 눌러요.';
const KIND_LABEL = { sos: '1분 SOS', r1: '회의·발표 전', r2: '아침 업무 시작 전', r3: '퇴근 후 정리' };
const ROUTE_LABEL = { breath: '호흡', no_breath: '호흡 없이', switched: '호흡에서 바꿈' };

/* ---------- 작은 도구 ---------- */

function h(tag, attrs, ...kids) {
  const el = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs || {})) {
    if (v == null || v === false) continue;
    if (k === 'class') el.className = v;
    else if (k === 'text') el.textContent = v;
    else if (k.startsWith('on') && typeof v === 'function') el.addEventListener(k.slice(2), v);
    else if (k === 'value') el.value = v;
    else if (k === 'checked') el.checked = !!v;
    else if (k === 'disabled') el.disabled = !!v;
    else el.setAttribute(k, v === true ? '' : v);
  }
  for (const c of kids.flat(Infinity)) {
    if (c == null || c === false) continue;
    el.append(c.nodeType ? c : String(c));
  }
  return el;
}
function btn(label, onclick, cls = '', attrs = {}) {
  return h('button', { type: 'button', class: `btn ${cls}`.trim(), onclick, ...attrs }, label);
}
function link(label, href, cls = '', attrs = {}) {
  return h('a', { class: `btn ${cls}`.trim(), href, ...attrs }, label);
}
function actions(...kids) { return h('div', { class: 'actions' }, kids); }
function announce(text) { $live.textContent = ''; setTimeout(() => { $live.textContent = text; }, 30); }

function pad(n) { return String(n).padStart(2, '0'); }
function localDate(d = new Date()) { return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`; }
function fmtDateTime(iso) { const d = new Date(iso); return `${d.getMonth() + 1}월 ${d.getDate()}일 ${pad(d.getHours())}:${pad(d.getMinutes())}`; }
function fmtDate(ymd) { if (!ymd) return ''; const [, m, d] = ymd.split('-'); return `${Number(m)}월 ${Number(d)}일`; }
function addDays(ymd, n) { const [y, m, d] = ymd.split('-').map(Number); const t = new Date(y, m - 1, d + n); return localDate(t); }
function isLate(time) { const hh = Number(time.split(':')[0]); return hh >= RULES.lateReviewHour || hh < 5; }
function reviewPassed() { const [hh, mm] = settings().reviewTime.split(':').map(Number); const n = new Date(); return n.getHours() * 60 + n.getMinutes() >= hh * 60 + mm; }
function josa(word, a, b) { const c = word.charCodeAt(word.length - 1); return (c >= 0xac00 && c <= 0xd7a3 && (c - 0xac00) % 28) ? a : b; }

function toast(text) {
  const t = h('div', { class: 'toast', role: 'status' }, text);
  document.body.append(t);
  setTimeout(() => t.remove(), 2200);
}

function modal({ title, body = [], buttons }) {
  return new Promise((resolve) => {
    const prev = document.activeElement;
    const close = (v) => { back.remove(); document.removeEventListener('keydown', onKey); if (prev && prev.focus) prev.focus(); resolve(v); };
    const onKey = (e) => { if (e.key === 'Escape') close(null); };
    const box = h('div', { class: 'modal stack', role: 'dialog', 'aria-modal': 'true', 'aria-label': title || '' },
      title && h('h2', {}, title),
      body.map((b) => (typeof b === 'string' ? h('p', {}, b) : b)),
      h('div', { class: 'btn-col' }, buttons.map((b) => btn(b.label, () => close(b.value), b.primary ? 'primary block' : 'block'))));
    const back = h('div', { class: 'modal-back', onclick: (e) => { if (e.target === back) close(null); } }, box);
    document.body.append(back);
    document.addEventListener('keydown', onKey);
    const first = box.querySelector('button'); if (first) first.focus();
  });
}

function isReduced() {
  return settings().reduceMotion || (window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches);
}
function applyLook() {
  const s = settings(), root = document.documentElement;
  if (s.theme === 'light' || s.theme === 'dark') root.dataset.theme = s.theme; else delete root.dataset.theme;
  if (s.reduceMotion) root.dataset.motion = 'reduce'; else delete root.dataset.motion;
}

/* ---------- 화면 그리기 ---------- */

function renderTop(spec = {}) {
  const left = h('div', { class: 'top-left' });
  if (spec.left === 'stop') left.append(h('button', { type: 'button', class: 'stop-btn', onclick: () => { endSession('user'); go('home'); } }, '그만하기'));
  else if (spec.left === 'back') left.append(h('button', { type: 'button', class: 'back-btn', onclick: () => go(spec.backTo || 'home') }, spec.backLabel || '뒤로'));
  else left.append(h('span', { class: 'brand' }, '제자리'));
  const right = spec.crisis === false ? null
    : h('button', { type: 'button', class: 'crisis-pill', onclick: () => { endSession('crisis'); go('c'); } }, '지금 많이 힘들다면');
  $top.replaceChildren(left, right || '');
}

function render(topSpec, ...nodes) {
  renderTop(topSpec);
  $view.replaceChildren(...nodes.flat(Infinity).filter((n) => n != null && n !== false));
  $view.classList.add('fading');
  requestAnimationFrame(() => requestAnimationFrame(() => $view.classList.remove('fading')));
  window.scrollTo(0, 0);
  $view.focus({ preventScroll: true });
}

/* ---------- 세션 ---------- */

const ABORT = Symbol('abort');
let S = null;            // 진행 중인 세션
let homeOnVisible = false;
let wakeLock = null;

async function lockScreen() {
  try { if ('wakeLock' in navigator) wakeLock = await navigator.wakeLock.request('screen'); } catch (e) { wakeLock = null; }
}
function unlockScreen() { try { if (wakeLock) wakeLock.release(); } catch (e) { /* 없어도 된다 */ } wakeLock = null; }

function newSession(path, kind, route) {
  S = {
    path, started: false, finished: false, reject: null, cleanup: null,
    rec: { startedAt: new Date().toISOString(), kind, route, pre: null, post: null, emotions: [], nextAction: null, backToWork: null, endReason: 'background', dizzy: false },
  };
  return S;
}
function startRecording() {
  if (!S || S.started) return;
  S.started = true;
  S.rec.startedAt = new Date().toISOString();
  save();
  lockScreen();
  requestPersist();
}
function save() { if (S && S.started) put('sessions', S.rec).catch(() => {}); }
function sessionTop() { return { left: 'stop' }; }

/* 흐름을 끊는다. 이미 끝난 세션이면 기록은 그대로 둔다. */
function endSession(reason) {
  if (!S) return;
  const s = S;
  S = null;
  if (s.cleanup) s.cleanup();
  if (s.started && !s.finished && reason) { s.rec.endReason = reason; put('sessions', s.rec).catch(() => {}); }
  unlockScreen();
  if (s.reject) s.reject(ABORT);
}
function finishRecord() {
  if (!S) return;
  S.finished = true;
  S.rec.endReason = 'done';
  save();
}
function closeSession() {
  const s = S;
  endSession(null);
  if (s && settings().askScreenAfter) go('screen'); else go('home');
}

function wait(build) {
  return new Promise((resolve, reject) => {
    const sess = S;
    if (!sess) { reject(ABORT); return; }
    sess.reject = reject;
    build((v) => { if (S === sess) { sess.reject = null; resolve(v); } });
  });
}
function runFlow(fn) {
  fn().catch((e) => { if (e !== ABORT) { console.error(e); endSession('user'); go('home'); } });
}

document.addEventListener('visibilitychange', () => {
  if (document.visibilityState === 'hidden') {
    if (S && S.started && !S.finished) { endSession('background'); homeOnVisible = true; }
  } else if (homeOnVisible) {
    homeOnVisible = false;
    go('home');
  }
});

/* ---------- 세션 단계 ---------- */

function hexToRgb(hex) {
  const m = hex.trim().replace('#', '');
  return [0, 2, 4].map((i) => parseInt(m.slice(i, i + 2), 16));
}
function mix(a, b, t) { return `rgb(${a.map((v, i) => Math.round(v + (b[i] - v) * t)).join(',')})`; }

function breath({ count, title, lead = BREATH_LEAD, sub = '편해지려 애쓰지 않아도 돼요.' }) {
  return wait((done) => {
    const pace = PACES[settings().pace] || PACES.normal;
    const cyc = pace.inhale + pace.exhale;
    const reduced = isReduced();
    const cs = getComputedStyle(document.documentElement);
    const col = {
      in: hexToRgb(cs.getPropertyValue('--breath-in')), out: hexToRgb(cs.getPropertyValue('--breath-out')),
      ringIn: hexToRgb(cs.getPropertyValue('--breath-ring-in')), ringOut: hexToRgb(cs.getPropertyValue('--breath-ring-out')),
    };
    const circle = h('div', { class: 'pacer-circle', 'aria-hidden': 'true' });
    const word = h('span', { class: 'word' }, '들이쉬어요');
    const num = h('span', { class: 'count', hidden: !reduced }, String(pace.inhale));
    const prog = h('p', { class: 'progress center', 'aria-hidden': 'true' }, `1/${count}`);
    const emph = settings().screenAnswer === undefined;

    let raf = 0;
    const stop = (v) => { cancelAnimationFrame(raf); if (S) S.cleanup = null; done(v); };

    render(sessionTop(),
      title && h('h1', { class: 'center' }, title),
      h('p', { class: 'center' }, lead),
      h('div', { class: 'pacer-wrap' },
        h('div', { class: 'pacer-box' }, circle, h('div', { class: 'pacer-label' }, word, num)),
        prog),
      h('p', { class: 'center muted' }, sub),
      h('p', { class: 'safety' }, BREATH_SAFETY),
      h('div', { class: 'btn-row' },
        btn('어지러워서 멈춤', () => stop('dizzy')),
        btn('호흡 대신 다른 방법', () => stop('switch'), emph ? 'emph' : '')));

    const t0 = performance.now();
    let lastPhase = -1;
    const vib = settings().vibrate && 'vibrate' in navigator;
    function frame(now) {
      const t = (now - t0) / 1000;
      const i = Math.floor(t / cyc);
      if (i >= count) { stop('done'); return; }
      const inCyc = t - i * cyc;
      const inhale = inCyc < pace.inhale;
      const len = inhale ? pace.inhale : pace.exhale;
      const pt = Math.min(1, (inhale ? inCyc : inCyc - pace.inhale) / len);
      const phase = i * 2 + (inhale ? 0 : 1);
      if (phase !== lastPhase) {
        lastPhase = phase;
        word.textContent = inhale ? '들이쉬어요' : '내쉬어요';
        prog.textContent = `${i + 1}/${count}`;
        announce(inhale ? `${i + 1}번째 호흡, ${count}번 중. 들이쉬기, ${pace.inhale}초` : `내쉬기, ${pace.exhale}초`);
        if (vib) { try { navigator.vibrate(30); } catch (e) { /* 지원하지 않는 기기 */ } }
        if (reduced) {
          circle.style.transform = 'scale(0.85)';
          circle.style.backgroundColor = mix(inhale ? col.in : col.out, inhale ? col.in : col.out, 0);
          circle.style.borderColor = mix(inhale ? col.ringIn : col.ringOut, inhale ? col.ringIn : col.ringOut, 0);
        }
      }
      if (reduced) {
        num.textContent = String(Math.max(1, Math.ceil(len - pt * len - 1e-6)));
      } else {
        const p = (1 - Math.cos(Math.PI * pt)) / 2;
        const s = inhale ? 0.6 + 0.4 * p : 1 - 0.4 * p;
        const m = inhale ? p : 1 - p;
        circle.style.transform = `scale(${s.toFixed(4)})`;
        circle.style.backgroundColor = mix(col.out, col.in, m);
        circle.style.borderColor = mix(col.ringOut, col.ringIn, m);
      }
      raf = requestAnimationFrame(frame);
    }
    raf = requestAnimationFrame(frame);
    S.cleanup = () => cancelAnimationFrame(raf);
  });
}

function rating(kind, { notice } = {}) {
  const pre = kind === 'pre';
  return wait((done) => {
    let val = null;
    const boxes = [];
    const next = btn('다음', () => done(val), 'primary block', { disabled: true });
    for (let n = 0; n <= 10; n++) {
      const b = h('button', {
        type: 'button', 'aria-pressed': 'false', 'aria-label': `${n}점, 10점 중`,
        onclick: () => { val = n; boxes.forEach((x) => x.setAttribute('aria-pressed', String(x === b))); next.disabled = false; },
      }, String(n));
      boxes.push(b);
    }
    render(sessionTop(),
      h('div', { class: 'stack' },
        notice && h('p', { class: 'banner' }, notice),
        h('h1', {}, pre ? '지금 얼마나 불편한가요?' : '지금은 몇 점쯤이에요?'),
        h('p', { class: 'muted' }, pre ? '0은 편안함, 10은 견디기 어려울 만큼이에요.' : '그대로여도 괜찮아요.'),
        h('div', { class: 'rating', role: 'group', 'aria-label': '0점부터 10점' }, boxes)),
      actions(next, btn('건너뛰기', () => done(null), 'quiet')));
  });
}

function emotionStep() {
  return wait((done) => {
    let picked = [];
    const result = h('p', { class: 'result', 'aria-live': 'polite', hidden: true });
    const chips = EMOTIONS.map((e) => h('button', {
      type: 'button', class: 'chip', 'aria-pressed': 'false',
      onclick: () => {
        if (e === UNSURE) picked = picked.includes(UNSURE) ? [] : [UNSURE];
        else {
          picked = picked.filter((x) => x !== UNSURE);
          if (picked.includes(e)) picked = picked.filter((x) => x !== e);
          else picked = [...picked, e].slice(-2);
        }
        chips.forEach((c) => c.setAttribute('aria-pressed', String(picked.includes(c.textContent))));
        result.hidden = picked.length === 0;
        if (picked[0] === UNSURE) result.textContent = '지금 느낌을 딱 집어 말하기 어려워요. 그래도 괜찮아요.';
        else if (picked.length === 1) result.textContent = `지금 나는 ${picked[0]}을 느끼고 있어요.`;
        else if (picked.length === 2) result.textContent = `지금 나는 ${picked[0]}과 ${picked[1]}을 느끼고 있어요.`;
      },
    }, e));
    render(sessionTop(),
      h('div', { class: 'stack' },
        h('h1', {}, '지금 느낌에 가장 가까운 말을 골라요.'),
        h('p', { class: 'muted' }, '한두 개만 골라도 돼요.'),
        h('div', { class: 'chips' }, chips),
        result),
      actions(btn('다음', () => done(picked), 'primary block'), btn('건너뛰기', () => done([]), 'quiet')));
  });
}

function nextActionStep() {
  return wait((done) => {
    let val = null;
    const result = h('p', { class: 'result', 'aria-live': 'polite', hidden: true });
    const show = () => { result.hidden = !val; if (val) result.textContent = `${val}, 그것 하나면 돼요.`; };
    const input = h('input', { type: 'text', placeholder: '직접 적기 (예: 보고서 2쪽 다시 보기)', 'aria-label': '다음 동작 직접 적기', maxlength: '80' });
    const chips = NEXT_ACTIONS.map((a) => h('button', {
      type: 'button', class: 'chip', 'aria-pressed': 'false',
      onclick: () => { val = val === a ? null : a; input.value = ''; chips.forEach((c) => c.setAttribute('aria-pressed', String(c.textContent === val))); show(); },
    }, a));
    input.addEventListener('input', () => { val = input.value.trim() || null; chips.forEach((c) => c.setAttribute('aria-pressed', 'false')); show(); });
    render(sessionTop(),
      h('div', { class: 'stack' },
        h('h1', {}, '하던 일에서 가장 작은 다음 동작 하나는요?'),
        h('div', { class: 'chips' }, chips),
        input, result),
      actions(btn('다음', () => done(val), 'primary block'), btn('건너뛰기', () => done(null), 'quiet')));
  });
}

async function outer({ intro, title } = {}) {
  const steps = [
    [3, '보이는 것 3개를 속으로 이름 붙여요.', '예: 모니터, 컵, 창문'],
    [2, '들리는 소리 2개를 찾아봐요.', '예: 키보드 소리, 냉방기 소리'],
    [1, '의자에 닿은 몸이나 바닥에 닿은 발바닥, 느낌 하나를 찾아봐요.', '찾기 어려우면 그냥 넘어가도 돼요.'],
  ];
  for (let k = 0; k < steps.length; k++) {
    const [n, big, sub] = steps[k];
    await wait((done) => render(sessionTop(),
      h('div', { class: 'stack' },
        k === 0 && h('p', { class: 'banner' }, intro || '눈은 뜬 채로 해요. 화면을 보면서 하나씩 따라 해요.'),
        title && h('p', { class: 'muted' }, title),
        h('p', { class: 'pacer-label' }, h('span', { class: 'count', 'aria-hidden': 'true' }, String(n))),
        h('h1', {}, big),
        h('p', { class: 'muted' }, sub)),
      actions(btn('다음', () => done(), 'primary block'))));
  }
}

function dizzyScreen() {
  return wait((done) => render(sessionTop(),
    h('div', { class: 'stack' },
      h('h1', {}, '평소처럼 숨 쉬세요'),
      h('p', {}, '지금은 아무것도 따라 하지 않아도 돼요.'),
      h('p', { class: 'safety' }, '처음 겪는 가슴 통증, 심한 숨참, 쓰러질 것 같은 느낌이면 119로 전화하세요.'),
      link('119 전화', `tel:${CONTACTS.emergency.tel}`, 'block', { 'aria-label': '119에 전화하기' }),
      h('p', { class: 'muted' }, '괜찮아지면 숨 대신 눈에 보이는 것으로 이어 갈 수 있어요.')),
    actions(btn('호흡 없이 이어 하기', () => done('continue'), 'primary block'), btn('여기서 끝내기', () => done('end')))));
}

/* 호흡 단계를 돌리고, 바꾸기·어지러움을 처리한다.
   돌려주는 값: 'done' 그대로 끝남 / 'switched' 남은 부분을 바깥 감각으로 / 'ended' 세션을 닫았음 */
async function breathGuarded(opts) {
  const res = await breath(opts);
  if (res === 'done') return 'done';
  if (S.rec.route !== 'no_breath') S.rec.route = 'switched';
  if (res === 'switch') { save(); return 'switched'; }
  S.rec.dizzy = true;
  save();
  const c = await dizzyScreen();
  if (c === 'end') {
    if (!S.finished) endSession('dizzy'); else endSession(null);
    go('home');
    return 'ended';
  }
  return 'switched-dizzy';
}
function switchIntro(r) {
  return r === 'switched-dizzy' ? '눈은 뜬 채로 해요. 화면을 보면서 하나씩 따라 해요.' : '숨 대신 눈과 귀로 이어 갈게요.';
}

function finalScreen(main) {
  return wait((done) => render(sessionTop(),
    h('div', { class: 'stack' }, h('h1', {}, main), h('p', { class: 'muted' }, '필요하면 언제든 다시 열어요.')),
    actions(btn('닫기', () => done(), 'primary block'))));
}

function worryReserve() {
  return wait((done) => {
    const input = h('input', { type: 'text', placeholder: '예: 질문에 답 못 하면', 'aria-label': '걱정 한 줄', maxlength: '120' });
    render(sessionTop(),
      h('div', { class: 'stack' },
        h('h1', {}, '걱정 예약하기'),
        h('p', {}, '지금 떠오른 걱정을 한 줄로 적어요. 단어 하나만 써도 돼요.'),
        input),
      actions(
        btn('예약하기', async () => {
          const text = input.value.trim();
          if (!text) { input.focus(); return; }
          const tomorrow = reviewPassed();
          await put('worries', { text, createdAt: new Date().toISOString(), dueDate: tomorrow ? addDays(localDate(), 1) : localDate(), status: 'waiting', happened: null, reviewedAt: null, action: null, actionDate: null });
          done(tomorrow ? 'tomorrow' : 'today');
        }, 'primary block'),
        btn('건너뛰기', () => done(null), 'quiet')));
    input.focus();
  }).then((when) => {
    if (!when) return null;
    return wait((done) => render(sessionTop(),
      h('div', { class: 'stack' },
        h('h1', {}, '적어 두었어요'),
        h('p', {}, `적어 두었으니 지금은 하던 일로 돌아가도 돼요. ${when === 'today' ? '오늘' : '내일'} ${settings().reviewTime}에 다시 볼게요.`)),
      actions(btn('하던 일로 돌아가기', () => done(when), 'primary block'))));
  });
}

async function talkSuggestion() {
  const rows = await all('sessions');
  const now = Date.now();
  const week = rows.filter((r) => now - Date.parse(r.startedAt) < 7 * 864e5);
  if (week.filter((r) => r.post != null && r.post >= RULES.f09HighPost).length >= RULES.f09HighCount) {
    return '최근 일주일 동안 끝난 뒤에도 8점 이상인 때가 세 번 이상 있었어요. 혼자 버티기보다 이야기 나눌 곳이 있으면 좋겠어요.';
  }
  const perDay = {};
  rows.filter((r) => r.kind === 'sos').forEach((r) => { const d = localDate(new Date(r.startedAt)); perDay[d] = (perDay[d] || 0) + 1; });
  for (let k = 0; k < RULES.f09Days; k++) {
    if ((perDay[localDate(new Date(now - k * 864e5))] || 0) < RULES.f09DailySos) return null;
  }
  return '사흘 연속으로 하루 다섯 번 이상 SOS를 열었어요. 혼자 버티기보다 이야기 나눌 곳이 있으면 좋겠어요.';
}

function endScreen(talk) {
  const r = S.rec;
  const breathing = r.route === 'breath';
  return wait((done) => {
    const sub = h('p', { class: 'muted', hidden: true }, '조금 더 이어 가거나, 마음에 걸리는 걸 적어 둘 수 있어요.');
    const choices = [['yes', '예'], ['some', '조금'], ['no', '아니요']];
    const chips = choices.map(([v, label]) => h('button', {
      type: 'button', class: 'chip', 'aria-pressed': String(r.backToWork === v),
      onclick: () => { r.backToWork = r.backToWork === v ? null : v; chips.forEach((c, i) => c.setAttribute('aria-pressed', String(choices[i][0] === r.backToWork))); sub.hidden = r.backToWork !== 'no'; save(); },
    }, label));
    const score = r.pre != null && r.post != null;
    render(sessionTop(),
      h('div', { class: 'stack' },
        score && h('h1', {}, `시작 ${r.pre} → 지금 ${r.post}`),
        score && r.post >= r.pre && h('p', { class: 'muted' }, '그런 날도 있어요.'),
        h('h2', {}, '하던 일로 돌아갈 수 있겠어요?'),
        h('div', { class: 'chips', role: 'group', 'aria-label': '하던 일로 돌아갈 수 있겠어요?' }, chips),
        sub,
        h('p', {}, '1분은 시작점이에요. 더 필요하면 조금 더 이어 가세요.'),
        talk && h('div', { class: 'info-card stack' }, h('p', {}, talk),
          h('div', { class: 'btn-row' }, btn('상담 창구 보기', () => { closeSessionTo('c2'); }, 'small-btn'), btn('닫기', (e) => e.target.closest('.info-card').remove(), 'small-btn')))),
      actions(
        btn('하던 일로 돌아가기', () => done('back'), 'primary block'),
        btn(breathing ? '30초 더 호흡' : '한 번 더 둘러보기', () => done('more'), 'block'),
        btn('걱정 예약하기', () => done('worry'), 'block'),
        btn('긴 루틴 해 보기', () => done('routine'), 'block')));
  });
}
function closeSessionTo(path) { endSession(null); go(path); }

/* ---------- 1분 SOS ---------- */

async function sos(route) {
  newSession('sos', 'sos', route);
  startRecording();
  const st = settings();
  let notice = null;
  if (st.firstSosNotice) { notice = FIRST_NOTICE; saveSettings({ firstSosNotice: false }); }
  S.rec.pre = await rating('pre', { notice });
  save();

  let askedNext = false;
  if (route === 'breath') {
    const r = await breathGuarded({ count: RULES.sosBreaths });
    if (r === 'ended') return;
    if (r !== 'done') await outer({ intro: switchIntro(r) });
  } else {
    await outer();
  }
  S.rec.emotions = await emotionStep();
  save();
  if (S.rec.route !== 'breath') { S.rec.nextAction = await nextActionStep(); askedNext = true; save(); }

  for (;;) {
    S.rec.post = await rating('post');
    finishRecord();
    const choice = await endScreen(await talkSuggestion());
    if (choice === 'more') {
      if (S.rec.route === 'breath') {
        const r = await breathGuarded({ count: RULES.extraBreaths, lead: '세 번만 더 해요.' });
        if (r === 'ended') return;
        if (r !== 'done') await outer({ intro: switchIntro(r) });
      } else {
        await outer();
      }
      continue;
    }
    if (choice === 'routine') { closeSessionTo('routines'); return; }
    if (choice === 'worry') {
      await worryReserve();
    } else if (!askedNext) {
      S.rec.nextAction = await nextActionStep();
      save();
    }
    break;
  }
  const a = S.rec.nextAction;
  await finalScreen(a ? `${a}부터 해요.` : '하던 일로 돌아가요.');
  closeSession();
}

/* 마지막 SOS가 호흡에서 벗어났거나 점수가 올랐으면 한 번 제안한다 (F-04) */
async function maybeSuggestNoBreath() {
  const rows = (await all('sessions')).filter((r) => r.kind === 'sos').sort((a, b) => b.startedAt.localeCompare(a.startedAt));
  const last = rows[0];
  if (!last || last.id === settings().suggestedFor) return 'breath';
  let text = null;
  if (last.dizzy) text = '지난번에는 호흡 중에 어지러워서 멈췄어요. 이번엔 호흡 없이 해 볼까요?';
  else if (last.route === 'switched') text = '지난번에는 호흡 도중 다른 방법으로 바꿨어요. 이번엔 호흡 없이 해 볼까요?';
  else if (last.pre != null && last.post != null && last.post - last.pre >= RULES.suggestRise) text = '지난번에는 끝난 뒤 점수가 더 높았어요. 이번엔 호흡 없이 해 볼까요?';
  if (!text) return 'breath';
  saveSettings({ suggestedFor: last.id });
  const v = await modal({ body: [text], buttons: [{ label: '호흡 없이 하기', value: 'no_breath', primary: true }, { label: '그대로 하기', value: 'breath' }] });
  return v || 'breath';
}

/* ---------- 루틴 ---------- */

function overview(key) {
  const R = ROUTINES[key];
  return wait((done) => render(sessionTop(),
    h('div', { class: 'stack' }, h('h1', {}, `${R.title} · 약 ${R.minutes}분`), h('p', {}, R.lead)),
    actions(btn('시작', () => done(), 'primary block'))));
}

/* 루틴 안의 호흡 구간. 기본이 호흡 없음이거나 이미 바꿨으면 바깥 감각으로 대신한다 (N2) */
async function routineBreath(sec, title) {
  if (S.rec.route !== 'breath') { await outer({ title: '주변으로 주의를 옮겨요' }); return true; }
  const pace = PACES[settings().pace] || PACES.normal;
  const count = Math.max(1, Math.floor(sec / (pace.inhale + pace.exhale)));
  const r = await breathGuarded({ count, title });
  if (r === 'ended') return false;
  if (r !== 'done') await outer({ intro: switchIntro(r), title: '주변으로 주의를 옮겨요' });
  return true;
}

function inputStep({ title, sub, placeholder, multiline }) {
  return wait((done) => {
    const input = multiline
      ? h('textarea', { placeholder, 'aria-label': title, maxlength: '2000' })
      : h('input', { type: 'text', placeholder, 'aria-label': title, maxlength: '160' });
    render(sessionTop(),
      h('div', { class: 'stack' }, h('h1', {}, title), sub && h('p', { class: 'muted' }, sub), input),
      actions(btn(multiline ? '다 적었어요' : '다음', () => done(input.value.trim() || null), 'primary block'), btn('건너뛰기', () => done(null), 'quiet')));
  });
}

function choiceStep({ title, body = [], options, skip = true }) {
  return wait((done) => render(sessionTop(),
    h('div', { class: 'stack' }, h('h1', {}, title), body.map((b) => (typeof b === 'string' ? h('p', {}, b) : b))),
    actions(options.map(([v, label, primary]) => btn(label, () => done(v), primary ? 'primary block' : 'block')),
      skip && btn('건너뛰기', () => done(null), 'quiet'))));
}

async function r1() {
  newSession('r1', 'r1', settings().defaultRoute);
  await overview('r1');
  startRecording();
  S.rec.pre = await rating('pre'); save();
  if (!(await routineBreath(ROUTINES.r1.breathSec, '숨부터 골라요'))) return;
  S.rec.emotions = await emotionStep(); save();
  await wait((done) => {
    let picked = null;
    const chips = REAPPRAISAL.chips.map((c) => h('button', { type: 'button', class: 'chip', 'aria-pressed': 'false',
      onclick: () => { picked = picked === c ? null : c; chips.forEach((x) => x.setAttribute('aria-pressed', String(x.textContent === picked))); } }, c));
    render(sessionTop(),
      h('div', { class: 'stack' },
        h('h1', {}, REAPPRAISAL.text),
        h('p', { class: 'safety' }, REAPPRAISAL.safety),
        h('p', { class: 'muted' }, REAPPRAISAL.sub),
        h('div', { class: 'chips' }, chips)),
      actions(btn('다음', () => done(picked), 'primary block'), btn('건너뛰기', () => done(null), 'quiet')));
  });
  const first = await inputStep({ title: '회의에서 처음 할 말을 한 줄로 적어 봐요.', placeholder: '예: 결론부터 말씀드리겠습니다.' });
  S.rec.nextAction = first; save();
  S.rec.post = await rating('post');
  finishRecord();
  await finalScreen(first ? `첫 문장: "${first}" 여기서 시작해요.` : '준비한 첫 장부터 시작해요.');
  closeSession();
}

async function r2() {
  newSession('r2', 'r2', settings().defaultRoute);
  await overview('r2');
  startRecording();
  S.rec.pre = await rating('pre'); save();
  if (!(await routineBreath(ROUTINES.r2.breathSec, '숨부터 골라요'))) return;
  S.rec.emotions = await emotionStep(); save();
  const line = await inputStep({ title: '오늘 마음에 걸리는 일이 있으면 한 줄로 적어요.', placeholder: '예: 오후 보고' });
  if (line) {
    const how = await choiceStep({ title: '이 일은 어떻게 할까요?', body: [line],
      options: [['act', '지금 할 수 있는 첫 동작 정하기', true], ['defer', '정리 시간으로 미뤄 두기']] });
    if (how === 'act') { S.rec.nextAction = await nextActionStep(); save(); }
    if (how === 'defer') {
      const tomorrow = reviewPassed();
      await put('worries', { text: line, createdAt: new Date().toISOString(), dueDate: tomorrow ? addDays(localDate(), 1) : localDate(), status: 'waiting', happened: null, reviewedAt: null, action: null, actionDate: null });
      toast(`적어 두었어요. ${tomorrow ? '내일' : '오늘'} ${settings().reviewTime}에 다시 볼게요.`);
    }
  }
  await wait((done) => {
    const time = h('input', { type: 'time', value: settings().reviewTime, 'aria-label': '정리 시간', hidden: true });
    const title = h('h1', {}, `오늘 정리 시간은 ${settings().reviewTime}이에요.`);
    let editing = false;
    const change = btn('시간 바꾸기', async () => {
      if (!editing) { editing = true; time.hidden = false; time.focus(); change.textContent = '이 시간으로 저장'; return; }
      if (await setReviewTime(time.value)) { title.textContent = `오늘 정리 시간은 ${settings().reviewTime}이에요.`; time.hidden = true; editing = false; change.textContent = '시간 바꾸기'; }
    }, 'block');
    render(sessionTop(), h('div', { class: 'stack' }, title, time),
      actions(btn('확인', () => done(), 'primary block'), change));
  });
  S.rec.post = await rating('post');
  finishRecord();
  const a = S.rec.nextAction;
  await finalScreen(a ? `${a}부터 해요.` : '하던 일로 돌아가요.');
  closeSession();
}

async function r3() {
  newSession('r3', 'r3', settings().defaultRoute);
  await overview('r3');
  startRecording();
  S.rec.pre = await rating('pre'); save();
  if (!(await routineBreath(ROUTINES.r3.breathSec, '숨부터 골라요'))) return;

  const today = localDate();
  let waiting = (await all('worries')).filter((w) => w.status === 'waiting' && w.dueDate <= today)
    .sort((a, b) => a.createdAt.localeCompare(b.createdAt));
  let write = true;
  if (waiting.length) {
    await choiceStep({ title: `오늘 적어 둔 것 ${waiting.length}개`, skip: false,
      body: ['낮에 미뤄 둔 걱정이에요. 하나씩 읽어 봐요.', h('ul', { class: 'plain' }, waiting.map((w) => h('li', {}, w.text)))],
      options: [['next', '다음', true]] });
  } else {
    const v = await choiceStep({ title: '오늘은 적어 둔 것이 없어요.', skip: false,
      body: ['떠오르는 게 있으면 다음 단계에서 적어도 되고, 마무리 호흡만 하고 마쳐도 돼요.'],
      options: [['write', '적어 보기', true], ['finish', '마무리로 가기']] });
    write = v === 'write';
  }
  if (write) {
    const text = await inputStep({ title: '더 적고 싶은 게 있으면 적어요.', sub: '문장이 정리되지 않아도 돼요. 일찍 끝내도 괜찮아요. 한 줄에 하나씩 적으면 따로 나눠서 볼 수 있어요.', multiline: true });
    if (text) {
      for (const line of text.split('\n').map((x) => x.trim()).filter(Boolean)) {
        const w = { text: line, createdAt: new Date().toISOString(), dueDate: today, status: 'waiting', happened: null, reviewedAt: null, action: null, actionDate: null };
        await put('worries', w);
        waiting.push(w);
      }
    }
  }
  for (const w of waiting) {
    const v = await choiceStep({ title: '항목마다 하나를 골라요.', body: [h('p', { class: 'result' }, w.text)],
      options: [['can', '내가 손댈 수 있음', true], ['cannot', '지금은 손댈 수 없음']] });
    if (v === 'can') {
      const got = await wait((done) => {
        const input = h('input', { type: 'text', placeholder: '다음 동작 하나', 'aria-label': '다음 동작', maxlength: '120' });
        const date = h('input', { type: 'date', value: addDays(today, 1), 'aria-label': '날짜' });
        render(sessionTop(),
          h('div', { class: 'stack' }, h('h1', {}, '다음 동작 하나와 날짜를 정해요.'), h('p', { class: 'result' }, w.text), input, date),
          actions(btn('다음', () => done({ a: input.value.trim(), d: date.value }), 'primary block'), btn('건너뛰기', () => done(null), 'quiet')));
      });
      if (got) Object.assign(w, { status: 'action', action: got.a || null, actionDate: got.d || null, reviewedAt: new Date().toISOString() });
    } else if (v === 'cannot') {
      Object.assign(w, { status: 'letgo', reviewedAt: new Date().toISOString() });
      await choiceStep({ title: '오늘은 여기 내려놓아요.', body: [w.text], options: [['next', '다음', true]], skip: false });
    }
    if (v) await put('worries', w);
  }

  const cutoff = Date.now() - RULES.happenedAfterDays * 864e5;
  const old = (await all('worries')).filter((w) => w.status === 'letgo' && w.happened == null && Date.parse(w.createdAt) <= cutoff)
    .sort((a, b) => a.createdAt.localeCompare(b.createdAt)).slice(0, RULES.happenedMax);
  for (const w of old) {
    const v = await choiceStep({ title: '지난번에 적어 둔 걱정이에요. 실제로 일어났나요?', body: [h('p', { class: 'result' }, w.text)],
      options: [['yes', '일어났어요'], ['no', '일어나지 않았어요'], ['unknown', '아직 몰라요']] });
    if (v === 'yes' || v === 'no') { w.happened = v; await put('worries', w); }
  }

  if (!(await routineBreath(ROUTINES.r3.closingSec, '마무리로 숨을 골라요'))) return;
  S.rec.post = await rating('post');
  finishRecord();
  await wait((done) => render(sessionTop(),
    h('div', { class: 'stack' }, h('h1', {}, '오늘 정리는 여기까지예요.'), h('p', { class: 'muted' }, '남은 건 다음 정리 시간에 다시 볼게요.')),
    actions(btn('닫기', () => done(), 'primary block'))));
  closeSession();
}

async function setReviewTime(t) {
  if (!/^\d{2}:\d{2}$/.test(t || '')) return false;
  if (isLate(t)) {
    const v = await modal({ body: ['잠들기 직전은 피하는 게 좋아요. 조금 이른 시간은 어때요?'],
      buttons: [{ label: '시간 다시 고르기', value: 'again', primary: true }, { label: '이대로 두기', value: 'keep' }] });
    if (v !== 'keep') return false;
  }
  saveSettings({ reviewTime: t });
  toast('저장했어요.');
  return true;
}

/* ---------- 일반 화면 ---------- */

let installEvent = null;
let updateReady = false;
const UA = navigator.userAgent;
const isIOS = /iPhone|iPad|iPod/i.test(UA) || (/Macintosh/.test(UA) && navigator.maxTouchPoints > 1);
const isAndroid = /Android/i.test(UA);
const inApp = /KAKAOTALK|Teams|MSTeams|NAVER|Line\/|band|DaumApps|Instagram|FB_IAB|FBAN|FBAV|everytime/i.test(UA);
const standalone = () => (window.matchMedia && matchMedia('(display-mode: standalone)').matches) || navigator.standalone === true;

window.addEventListener('beforeinstallprompt', (e) => { e.preventDefault(); installEvent = e; });
window.addEventListener('appinstalled', () => { installEvent = null; });

function inAppBanner() {
  if (!inApp || !(isIOS || isAndroid)) return null;
  const target = isIOS ? '사파리' : '크롬';
  const open = () => {
    const url = location.href;
    if (/KAKAOTALK/i.test(UA)) { location.href = 'kakaotalk://web/openExternal?url=' + encodeURIComponent(url); return; }
    if (isIOS) { location.href = url.replace(/^https:/, 'x-safari-https:'); return; }
    location.href = 'intent://' + url.replace(/^https?:\/\//, '') + '#Intent;scheme=https;package=com.android.chrome;S.browser_fallback_url=' + encodeURIComponent(url) + ';end';
  };
  const copy = () => { const u = location.href.split('#')[0]; (navigator.clipboard ? navigator.clipboard.writeText(u) : Promise.reject()).then(() => toast(`주소를 복사했어요. ${target}에 붙여 넣어 주세요.`), () => toast(u)); };
  return h('div', { class: 'info-card stack' },
    h('p', {}, `지금은 다른 앱 안에서 열려 있어요. 여기서는 설치가 되지 않고 기록이 지워질 수 있어요. ${target}로 열어 주세요.`),
    h('div', { class: 'btn-row' }, btn(`${target}로 열기`, open, 'small-btn'), btn('주소 복사', copy, 'small-btn')));
}

async function home() {
  const s = settings();
  if (!s.onboarded) { onboard(); return; }
  const breathDefault = s.defaultRoute === 'breath';
  const card = h('button', { type: 'button', class: 'card', onclick: () => go('w') },
    h('span', {}, `오늘 정리 시간 ${s.reviewTime}`), h('span', { class: 'meta' }, '…'));
  render({},
    inAppBanner(),
    h('button', { type: 'button', class: 'sos', onclick: () => go(`sos?route=${s.defaultRoute}`) },
      h('span', { class: 'big' }, '1분 SOS'), h('span', { class: 'sub' }, breathDefault ? '따라 하기만 하면 돼요' : '호흡 없이 · 눈 뜬 채로')),
    h('div', { class: 'spacer' }),
    btn(breathDefault ? '호흡 없이 1분' : '호흡과 함께 1분', () => go(`sos?route=${breathDefault ? 'no_breath' : 'breath'}`), 'block alt-sos'),
    h('h2', { class: 'section-title' }, '시간이 조금 있다면'),
    routineCards(),
    h('div', { class: 'spacer' }),
    card,
    h('nav', { class: 'nav', 'aria-label': '메뉴' },
      btn('기록', () => go('log')), btn('설정', () => go('set')), btn('근거 보기', () => go('evidence'))));
  const n = (await all('worries')).filter((w) => w.status === 'waiting').length;
  card.lastChild.textContent = n ? `적어 둔 것 ${n}개` : '적어 둔 것 없음';
}

function routineCards() {
  return h('div', { class: 'cards' }, ['r1', 'r2', 'r3'].map((k) =>
    h('button', { type: 'button', class: 'card', onclick: () => go(k) },
      h('span', {}, ROUTINES[k].title), h('span', { class: 'meta' }, `약 ${ROUTINES[k].minutes}분`))));
}

function routines() {
  render({ left: 'back' }, h('div', { class: 'stack' }, h('h1', {}, '시간이 조금 있다면'), routineCards()));
}

function screeningButtons(after) {
  const answer = (v) => {
    const patch = { screenAnswer: v, askScreenAfter: false };
    if (v === 'yes') patch.defaultRoute = 'no_breath';
    if (v === 'no' || v === null) patch.defaultRoute = 'breath';
    saveSettings(patch);
    const msg = v === 'yes' ? '호흡 없이 하는 방법을 기본으로 둘게요. 설정에서 언제든 바꿀 수 있어요.'
      : v === 'no' ? '호흡과 함께 하는 방법을 기본으로 둘게요. 설정에서 언제든 바꿀 수 있어요.'
        : '호흡과 함께 하는 방법을 기본으로 둘게요. 하다가 불편하면 [호흡 대신 다른 방법]을 누르면 돼요.';
    after(msg);
  };
  return h('div', { class: 'btn-col' }, btn('예', () => answer('yes'), 'block'), btn('아니요', () => answer('no'), 'block'), btn('잘 모르겠음', () => answer(null), 'block'));
}

function onboard() {
  const result = h('div', { class: 'stack' });
  const start = btn('시작하기', () => {
    saveSettings({ onboarded: true });
    requestPersist();
    if (!standalone() && !settings().installSeen) go('install'); else go('home');
  }, 'primary block');
  const qBox = h('div', { class: 'stack' },
    h('h2', {}, '숨에 집중하면 오히려 더 불편하거나 어지러웠던 적이 있나요?'),
    screeningButtons((msg) => { qBox.replaceWith(result); result.append(h('p', { class: 'result' }, msg), start); start.focus(); }));
  render({},
    h('div', { class: 'btn-row top-action' }, h('span', { class: 'grow' }),
      btn('지금 바로 SOS', () => {
        saveSettings({ onboarded: true, skippedOnboarding: true, firstSosNotice: true, askScreenAfter: true });
        go('sos?route=breath');
      }, 'small-btn')),
    h('div', { class: 'stack-lg' },
      h('h1', {}, '시작하기 전에'),
      h('p', {}, '이 앱은 의료기기가 아니에요. 질병이 있는지 판단하거나 치료하지 않아요. 힘든 상태가 계속되면 의사나 전문 상담가와 이야기해 주세요.'),
      h('div', { class: 'stack' },
        h('p', {}, '기록은 이 휴대폰에만 저장되고 어디로도 보내지 않아요. 회사는 누가 설치했는지, 언제 썼는지, 무엇을 적었는지 받지 않아요. 회사가 관리하는 업무폰이거나 내보낸 파일을 회사 드라이브에 둔 경우는 다를 수 있어요.'),
        btn('개인정보 안내 보기', () => go('privacy?from=onboard'), 'quiet')),
      h('p', {}, '천식·COPD 같은 호흡기 질환이나 심혈관 질환이 있거나, 임신 중 숨쉬기가 불편하다면 호흡 없는 방법을 쓰고 의사와 상의해 주세요.'),
      qBox));
}

function screening() {
  const result = h('div', { class: 'stack' });
  const body = h('div', { class: 'stack' },
    h('h2', {}, '숨에 집중하면 오히려 더 불편하거나 어지러웠던 적이 있나요?'),
    screeningButtons((msg) => { body.replaceWith(result); result.append(h('p', { class: 'result' }, msg), btn('홈으로', () => go('home'), 'primary block')); }),
    btn('나중에', () => go('home'), 'quiet'));
  render({},
    h('div', { class: 'stack-lg' },
      h('h1', {}, '하나만 물어볼게요'),
      h('p', {}, '다음부터 더 맞는 방법으로 시작하려고 해요.'),
      body,
      h('p', { class: 'muted' }, '호흡기·심혈관 질환이 있거나 임신 중 숨쉬기가 불편하다면 호흡 없는 방법을 권해요.'),
      btn('처음 안내 보기', () => { saveSettings({ onboarded: false }); go('home'); }, 'quiet')));
}

function install() {
  const done = () => { saveSettings({ installSeen: true }); go('home'); };
  let body;
  if (standalone()) body = [h('p', {}, '이미 홈 화면에서 열려 있어요.')];
  else if (isIOS) {
    body = [h('ol', { class: 'plain' },
      h('li', {}, '화면 아래 공유 버튼을 눌러요.'), h('li', {}, "'홈 화면에 추가'를 눌러요."), h('li', {}, "오른쪽 위 '추가'를 눌러요.")),
    h('p', {}, 'Safari에서 바로 쓰면 7일 동안 열지 않을 때 기록이 지워질 수 있어요. 홈 화면에 추가하면 그렇지 않아요.'),
    h('p', { class: 'muted' }, 'Safari에서 쓰던 기록은 홈 화면 앱으로 옮겨지지 않아요. 앱을 지우면 기록도 함께 지워져요.')];
  } else {
    body = [
      installEvent
        ? btn('홈 화면에 설치', async () => { installEvent.prompt(); const r = await installEvent.userChoice; installEvent = null; if (r.outcome === 'accepted') done(); }, 'primary block')
        : h('ol', { class: 'plain' }, h('li', {}, '브라우저 오른쪽 위 메뉴(⋮)를 눌러요.'), h('li', {}, "'앱 설치' 또는 '홈 화면에 추가'를 눌러요.")),
      h('p', {}, "설치한 뒤 아이콘을 길게 누르면 '1분 SOS'로 바로 들어갈 수 있어요."),
      h('p', { class: 'muted' }, '앱을 지우면 기록도 함께 지워져요.')];
  }
  render({ left: 'back', backTo: 'home' },
    inAppBanner(),
    h('div', { class: 'stack' }, h('h1', {}, '홈 화면에 두면 더 빨리 열려요'), body,
      h('p', { class: 'muted' }, '설치는 선택이에요. 설치하지 않아도 모든 기능을 쓸 수 있어요.')),
    actions(btn('나중에 하기', done, 'block')));
}

function crisis() {
  const s = settings();
  render({ left: 'back', backTo: 'home', backLabel: '돌아가기', crisis: false },
    h('div', { class: 'stack' },
      h('h1', {}, '지금 많이 힘들다면'),
      h('p', {}, '혼자 견디지 않아도 돼요. 아래 번호는 24시간 연결돼요.'),
      h('div', { class: 'crisis-card' },
        h('div', { class: 'num' }, '109'), h('div', { class: 'name' }, '자살예방상담전화'), h('div', {}, '24시간 · 무료'),
        h('div', { class: 'btn-row' },
          link('전화하기', `tel:${CONTACTS.c109.tel}`, '', { 'aria-label': '109 자살예방상담전화에 전화하기' }),
          link('문자 보내기', `sms:${CONTACTS.c109.sms}`, '', { 'aria-label': '109에 문자 보내기' }))),
      h('div', { class: 'crisis-card' },
        h('div', { class: 'num' }, CONTACTS.mental.label), h('div', { class: 'name' }, '정신건강상담전화'), h('div', {}, '24시간'),
        h('div', { class: 'btn-row' }, link('전화하기', `tel:${CONTACTS.mental.tel}`, '', { 'aria-label': '1577-0199 정신건강상담전화에 전화하기' }))),
      h('div', { class: 'crisis-card' },
        h('div', { class: 'num' }, '119'), h('div', {}, '처음 겪는 가슴 통증, 심한 숨참, 쓰러질 것 같은 느낌이면 119로 전화하세요.'),
        h('div', { class: 'btn-row' }, link('전화하기', `tel:${CONTACTS.emergency.tel}`, '', { 'aria-label': '119에 전화하기' }))),
      h('p', {}, "글로 이야기하고 싶다면 카카오톡에서 '마들랜'을 검색해요. 24시간 상담해요."),
      s.eapName && s.eapPhone && h('div', { class: 'info-card' },
        h('div', {}, `사내 상담: ${s.eapName} ${s.eapPhone}`),
        h('div', { class: 'btn-row' }, link('전화하기', `tel:${s.eapPhone.replace(/[^\d+]/g, '')}`))),
      h('p', {}, '가까이 믿을 만한 사람이 있다면 곁에 있어 달라고 말해도 돼요.'),
      h('p', {}, '이 앱은 상담 기관에 연결하거나 알림을 보내지 않아요. 전화와 문자는 직접 걸어요.'),
      h('p', { class: 'muted' }, '인터넷 없이도 열리는 화면이에요. 전화와 문자는 휴대폰 기본 앱으로 연결돼요.'),
      h('p', { class: 'muted small' }, `번호 확인: ${CONTACTS.checkedAt}`)),
    actions(btn('돌아가기', () => go('home'), 'block')));
}

function talkPlaces() {
  const s = settings();
  const offline = () => (navigator.onLine ? null : h('p', { class: 'muted' }, '인터넷 연결이 필요해요.'));
  render({ left: 'back', backTo: 'home', backLabel: '돌아가기' },
    h('div', { class: 'stack' },
      h('h1', {}, '이야기 나눌 곳'),
      h('p', {}, '혼자 버티지 않아도 돼요. 편한 곳을 골라 직접 연락해요.'),
      s.eapName && s.eapPhone && h('div', { class: 'info-card' }, h('div', {}, `사내 상담: ${s.eapName} ${s.eapPhone}`),
        h('div', { class: 'btn-row' }, link('전화하기', `tel:${s.eapPhone.replace(/[^\d+]/g, '')}`))),
      h('div', { class: 'info-card' }, h('h2', {}, `정신건강상담전화 ${CONTACTS.mental.label}`), h('p', {}, '24시간'),
        h('div', { class: 'btn-row' }, link('전화하기', `tel:${CONTACTS.mental.tel}`))),
      h('div', { class: 'info-card' }, h('h2', {}, '근로자건강센터'), h('p', {}, '직무스트레스 상담 · 무료'), h('p', { class: 'muted' }, '이용 대상은 센터마다 달라요.'),
        h('div', { class: 'btn-row' }, link('센터 찾기', CONTACTS.workerCenterUrl, '', { target: '_blank', rel: 'noopener noreferrer' })), offline()),
      h('div', { class: 'info-card' }, h('h2', {}, '심리상담 바우처'), h('p', {}, '복지로나 가까운 주민센터에서 신청해요. 의뢰서가 필요하고 본인부담이 있어요.'),
        h('div', { class: 'btn-row' }, link('복지로 열기', CONTACTS.voucherUrl, '', { target: '_blank', rel: 'noopener noreferrer' })), offline()),
      h('p', {}, '이 앱은 상담 기관에 연결하거나 알림을 보내지 않아요. 연락은 직접 해요.'),
      h('p', {}, '지금 많이 위험하다고 느끼면'),
      btn('지금 많이 힘들다면', () => go('c'), 'block'),
      h('p', { class: 'muted small' }, `안내 확인: ${CONTACTS.checkedAt}`)));
}

async function worries() {
  const s = settings();
  const list = h('div', { class: 'list' });
  render({ left: 'back' },
    h('div', { class: 'stack' },
      h('h1', {}, '적어 둔 걱정'),
      h('p', {}, `정리 시간 ${s.reviewTime}에 다시 봐요.`),
      btn('퇴근 후 정리 시작', () => go('r3'), 'block'),
      list));
  const rows = (await all('worries')).sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  if (!rows.length) { list.append(h('p', { class: 'muted' }, '아직 적어 둔 것이 없어요. 걱정이 떠오르면 SOS 끝에서 한 줄로 적어 둘 수 있어요.')); return; }
  for (const w of rows) {
    const status = w.status === 'waiting' ? '기다리는 중'
      : w.status === 'action' ? `다음 동작 정함${w.actionDate ? ` · ${fmtDate(w.actionDate)}` : ''}${w.action ? ` · ${w.action}` : ''}` : '오늘은 내려놓음';
    list.append(h('div', { class: 'row' },
      h('div', { class: 'grow' }, h('div', {}, w.text), h('div', { class: 'muted small' }, `${fmtDateTime(w.createdAt)} · ${status}`)),
      btn('지우기', async () => {
        const v = await modal({ body: ['이 항목을 지울까요? 지우면 되돌릴 수 없어요.'], buttons: [{ label: '지우기', value: 'del', primary: true }, { label: '취소', value: null }] });
        if (v) { await remove('worries', w.id); toast('지웠어요.'); worries(); }
      }, 'small-btn', { 'aria-label': `${w.text} 지우기` })));
  }
}

async function log() {
  const rows = (await all('sessions')).sort((a, b) => b.startedAt.localeCompare(a.startedAt));
  const cut = Date.now() - 30 * 864e5;
  const recent = rows.filter((r) => Date.parse(r.startedAt) >= cut);
  const yes = recent.filter((r) => r.backToWork === 'yes').length;
  const pres = recent.map((r) => r.pre).filter((v) => v != null);
  const posts = recent.map((r) => r.post).filter((v) => v != null);
  const avg = (a) => (a.reduce((x, y) => x + y, 0) / a.length).toFixed(1);
  const list = h('div', { class: 'list' });
  for (const r of rows) {
    const stopLabel = r.endReason === 'dizzy' ? ' · 어지러워서 멈춤' : (r.endReason !== 'done' ? ' · 중간에 멈춤' : '');
    const score = r.pre != null || r.post != null ? ` · ${r.pre ?? '-'} → ${r.post ?? '-'}` : '';
    list.append(h('div', { class: 'row' },
      h('div', { class: 'grow' },
        h('div', {}, `${fmtDateTime(r.startedAt)} · ${KIND_LABEL[r.kind] || r.kind}`),
        h('div', { class: 'muted small' }, `${ROUTE_LABEL[r.route] || ''}${score}${r.dizzy && r.endReason !== 'dizzy' ? ' · 어지러워서 멈춤' : ''}${stopLabel}`)),
      btn('지우기', async () => {
        const v = await modal({ body: ['이 기록을 지울까요? 되돌릴 수 없어요.'], buttons: [{ label: '지우기', value: 'del', primary: true }, { label: '취소', value: null }] });
        if (v) { await remove('sessions', r.id); toast('지웠어요.'); log(); }
      }, 'small-btn', { 'aria-label': '이 기록 지우기' })));
  }
  render({ left: 'back' },
    h('div', { class: 'stack' },
      h('h1', {}, '기록'),
      recent.length
        ? [h('p', {}, `최근 30일 동안 ${recent.length}번 썼어요. 그중 ${yes}번은 하던 일로 돌아갈 수 있겠다고 답했어요.`),
          pres.length && posts.length && h('p', {}, `시작 점수 평균 ${avg(pres)}, 끝 점수 평균 ${avg(posts)}`),
          h('p', { class: 'muted' }, '점수 변화에는 시간이 지난 영향도 함께 섞여 있어요.')]
        : h('p', { class: 'muted' }, '아직 기록이 없어요. 필요할 때 1분 SOS를 열면 여기에 남아요.'),
      btn('설문용 요약 보기', survey, 'block'),
      list));
}

async function survey() {
  const s = settings();
  const rows = await all('sessions');
  const ws = await all('worries');
  const cut = Date.now() - 30 * 864e5;
  const recent = rows.filter((r) => Date.parse(r.startedAt) >= cut);
  const days = new Set(recent.map((r) => localDate(new Date(r.startedAt)))).size;
  const sos = recent.filter((r) => r.kind === 'sos');
  const cnt = (f) => recent.filter(f).length;
  const lines = [
    ['설치일', s.installedAt ? localDate(new Date(s.installedAt)) : '-'],
    ['최근 30일 중 쓴 날 수', `${days}일`],
    ['SOS 횟수', `호흡 ${sos.filter((r) => r.route === 'breath').length} / 호흡 없이 ${sos.filter((r) => r.route !== 'breath').length}`],
    ['어지러워서 멈춘 횟수', String(cnt((r) => r.dizzy))],
    ['하던 일로 돌아갈 수 있겠어요?', `예 ${cnt((r) => r.backToWork === 'yes')} / 조금 ${cnt((r) => r.backToWork === 'some')} / 아니요 ${cnt((r) => r.backToWork === 'no')}`],
    ['예약한 걱정 수', String(ws.length)],
    ['정리 시간에 다시 본 수', String(ws.filter((w) => w.status !== 'waiting').length)],
  ];
  const text = lines.map(([k, v]) => `${k}: ${v}`).join('\n');
  const v = await modal({ title: '설문용 요약',
    body: ['설문에 옮겨 적을 숫자만 모았어요. 직접 적은 글은 들어가지 않아요. 옮겨 적을지는 직접 정해요.',
      h('dl', { class: 'kv' }, lines.map(([k, val]) => [h('dt', {}, k), h('dd', {}, val)]))],
    buttons: [{ label: '복사하기', value: 'copy' }, { label: '닫기', value: null, primary: true }] });
  if (v === 'copy' && navigator.clipboard) navigator.clipboard.writeText(text).then(() => toast('복사했어요.'), () => {});
}

function seg(options, current, onPick) {
  const wrap = h('div', { class: 'seg', role: 'group' });
  const buttons = options.map(([v, label]) => h('button', { type: 'button', 'aria-pressed': String(v === current),
    onclick: () => { buttons.forEach((b, i) => b.setAttribute('aria-pressed', String(options[i][0] === v))); onPick(v); } }, label));
  wrap.append(...buttons);
  return wrap;
}

function download(name, type, text) {
  const blob = new Blob([text], { type });
  const url = URL.createObjectURL(blob);
  const a = h('a', { href: url, download: name });
  document.body.append(a); a.click(); a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 4000);
}

function icsText() {
  const s = settings();
  const [hh, mm] = s.reviewTime.split(':').map(Number);
  const weekdays = s.icsFreq !== 'daily';
  const d = new Date();
  d.setHours(hh, mm, 0, 0);
  if (d.getTime() <= Date.now()) d.setDate(d.getDate() + 1);
  while (weekdays && (d.getDay() === 0 || d.getDay() === 6)) d.setDate(d.getDate() + 1);
  const ymd = localDate(d).replace(/-/g, '');
  const now = new Date();
  const stamp = `${now.getUTCFullYear()}${pad(now.getUTCMonth() + 1)}${pad(now.getUTCDate())}T${pad(now.getUTCHours())}${pad(now.getUTCMinutes())}${pad(now.getUTCSeconds())}Z`;
  const uid = `${Array.from(crypto.getRandomValues(new Uint8Array(12))).map((b) => b.toString(16).padStart(2, '0')).join('')}@jejari`;
  return [
    'BEGIN:VCALENDAR', 'VERSION:2.0', 'PRODID:-//jejari//KO', 'CALSCALE:GREGORIAN', 'METHOD:PUBLISH',
    'BEGIN:VTIMEZONE', 'TZID:Asia/Seoul', 'BEGIN:STANDARD', 'DTSTART:19700101T000000', 'TZOFFSETFROM:+0900', 'TZOFFSETTO:+0900', 'TZNAME:KST', 'END:STANDARD', 'END:VTIMEZONE',
    'BEGIN:VEVENT', `UID:${uid}`, `DTSTAMP:${stamp}`, `DTSTART;TZID=Asia/Seoul:${ymd}T${pad(hh)}${pad(mm)}00`, 'DURATION:PT10M',
    weekdays ? 'RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR' : 'RRULE:FREQ=DAILY',
    `SUMMARY:${ICS_TITLE}`,
    'BEGIN:VALARM', 'ACTION:DISPLAY', `DESCRIPTION:${ICS_TITLE}`, 'TRIGGER:-PT0M', 'END:VALARM',
    'END:VEVENT', 'END:VCALENDAR', '',
  ].join('\r\n');
}

function csvCell(v) { const s = v == null ? '' : String(v); return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s; }

async function exportData(kind, withText) {
  const sessions = await all('sessions');
  const stamp = localDate().replace(/-/g, '');
  if (kind === 'csv') {
    const head = ['startedAt', 'kind', 'route', 'pre', 'post', 'emotions', 'nextAction', 'backToWork', 'endReason', 'dizzy'];
    const body = sessions.map((r) => head.map((k) => csvCell(k === 'emotions' ? (r.emotions || []).join('|') : k === 'nextAction' && !withText ? '' : r[k])).join(','));
    download(`jejari-sessions-${stamp}.csv`, 'text/csv', '﻿' + [head.join(','), ...body].join('\n'));
  } else {
    const ws = await all('worries');
    const data = {
      app: 'jejari', version: VERSION, exportedAt: new Date().toISOString(), withText,
      sessions: sessions.map((r) => ({ ...r, nextAction: withText ? r.nextAction : null })),
      worries: ws.map((w) => ({ ...w, text: withText ? w.text : '', action: withText ? w.action : null })),
    };
    download(`jejari-backup-${stamp}.json`, 'application/json', JSON.stringify(data, null, 2));
  }
  toast('파일을 저장했어요.');
}

function importData() {
  const input = h('input', { type: 'file', accept: 'application/json,.json', hidden: true });
  input.addEventListener('change', async () => {
    const f = input.files && input.files[0];
    input.remove();
    if (!f) return;
    try {
      const data = JSON.parse(await f.text());
      if (data.app !== 'jejari') throw new Error('not jejari');
      const v = await modal({ body: [`가져온 기록(세션 ${data.sessions.length}개, 걱정 ${data.worries.length}개)을 지금 기록에 더할까요?`],
        buttons: [{ label: '더하기', value: 'ok', primary: true }, { label: '취소', value: null }] });
      if (!v) return;
      for (const r of data.sessions) { const c = { ...r }; delete c.id; await put('sessions', c); }
      for (const w of data.worries) { const c = { ...w }; delete c.id; await put('worries', c); }
      toast('가져왔어요.');
    } catch (e) {
      toast('이 앱에서 내보낸 파일이 아니에요.');
    }
  });
  document.body.append(input);
  input.click();
}

async function deleteAll() {
  const keep = h('input', { type: 'checkbox', checked: true });
  const a = await modal({ body: ['모든 기록을 지울까요? 세션 기록과 적어 둔 걱정이 모두 지워지고, 되돌릴 수 없어요.', h('label', { class: 'check' }, keep, '설정은 남겨 두기')],
    buttons: [{ label: '다음', value: 'next', primary: true }, { label: '취소', value: null }] });
  if (!a) return;
  const b = await modal({ body: ['한 번 더 확인할게요. 지운 기록은 다시 볼 수 없어요.'],
    buttons: [{ label: '모두 지우기', value: 'del', primary: true }, { label: '취소', value: null }] });
  if (!b) return;
  await clear('sessions');
  await clear('worries');
  if (!keep.checked) { resetSettings(); applyLook(); }
  toast('모든 기록을 지웠어요.');
  go('home');
}

function settingsScreen() {
  const s = settings();
  const group = (title, ...kids) => h('section', { class: 'set-group stack' }, h('h2', {}, title), kids);
  let withText = false;
  const time = h('input', { type: 'time', value: s.reviewTime, 'aria-label': '정리 시간' });
  time.addEventListener('change', async () => { if (!(await setReviewTime(time.value))) time.value = settings().reviewTime; });
  const eapName = h('input', { type: 'text', value: s.eapName, placeholder: '이름 (예: 사내 상담실)', 'aria-label': '사내 상담 창구 이름', maxlength: '40' });
  const eapPhone = h('input', { type: 'tel', value: s.eapPhone, placeholder: '전화번호', 'aria-label': '사내 상담 창구 전화번호', maxlength: '20' });
  const saveEap = () => { saveSettings({ eapName: eapName.value.trim(), eapPhone: eapPhone.value.trim() }); toast('저장했어요.'); };
  eapName.addEventListener('change', saveEap);
  eapPhone.addEventListener('change', saveEap);
  const vibSupported = 'vibrate' in navigator;

  render({ left: 'back' },
    h('h1', {}, '설정'),
    group('1분 SOS 기본 방법', seg([['breath', '호흡과 함께'], ['no_breath', '호흡 없이']], s.defaultRoute, (v) => saveSettings({ defaultRoute: v }))),
    group('호흡 속도', seg([['normal', '보통: 4초 들이쉬고 6초 내쉬기'], ['quick', '조금 빠르게: 3초 들이쉬고 5초 내쉬기']], s.pace, (v) => saveSettings({ pace: v })),
      h('p', { class: 'muted' }, '편하게 느껴지는 쪽을 골라요.')),
    vibSupported && group('진동 안내', seg([[true, '켜기'], [false, '끄기']], s.vibrate, (v) => saveSettings({ vibrate: v })),
      h('p', { class: 'muted' }, '원이 바뀔 때 짧게 진동해요. 기본은 꺼짐이에요.')),
    group('움직임 줄이기', seg([[true, '켜기'], [false, '끄기']], s.reduceMotion, (v) => { saveSettings({ reduceMotion: v }); applyLook(); }),
      h('p', { class: 'muted' }, '원이 커지고 작아지는 대신 숫자와 색으로 안내해요.')),
    group('화면 테마', seg([['auto', '휴대폰 설정 따르기'], ['light', '밝게'], ['dark', '어둡게']], s.theme, (v) => { saveSettings({ theme: v }); applyLook(); })),
    group('정리 시간', time),
    group('캘린더에 반복 일정 추가',
      seg([['daily', '매일'], ['weekdays', '평일만']], s.icsFreq, (v) => saveSettings({ icsFreq: v })),
      btn('일정 파일 받기', () => download('jejari.ics', 'text/calendar', icsText()), 'block'),
      h('p', { class: 'muted' }, `일정 제목은 '${ICS_TITLE}'으로만 들어가고, 적어 둔 내용은 들어가지 않아요. 회사 공유 캘린더가 아니라 개인 캘린더에 넣어 주세요.`),
      h('p', { class: 'muted' }, `일정이 열리지 않으면 캘린더 앱에서 ${s.reviewTime} 반복 일정을 직접 만들어 주세요.`)),
    group('사내 상담 창구', eapName, eapPhone,
      h('p', { class: 'muted' }, "입력하면 '지금 많이 힘들다면' 화면에 함께 보여요. 이 정보도 이 휴대폰에만 저장돼요.")),
    group('기록 내보내기',
      h('label', { class: 'check' }, h('input', { type: 'checkbox', onchange: (e) => { withText = e.target.checked; } }), '직접 적은 글 포함하기'),
      h('div', { class: 'btn-col' },
        btn('전체 (JSON, 다시 가져오기용)', () => exportData('json', withText), 'block'),
        btn('세션 기록 (CSV)', () => exportData('csv', withText), 'block'),
        btn('내보낸 파일 가져오기', importData, 'block')),
      h('p', { class: 'muted' }, '파일은 이 휴대폰에 저장돼요. 앱은 어디로도 보내지 않아요.')),
    group('전체 기록 삭제', btn('전체 기록 삭제', deleteAll, 'block')),
    group('안내',
      h('div', { class: 'btn-col' },
        btn('설치 안내 다시 보기', () => go('install'), 'block'),
        btn('처음 안내 다시 보기', () => { saveSettings({ onboarded: false }); go('home'); }, 'block'),
        btn('이용 안내', () => go('terms'), 'block'),
        btn('개인정보 안내', () => go('privacy'), 'block'),
        btn('근거 보기', () => go('evidence'), 'block'))),
    group(`버전 ${VERSION}`, updateReady && h('p', {}, '새 버전이 있어요. 다음에 앱을 열 때 적용돼요.')));
}

function evidence() {
  const E = EVIDENCE;
  render({ left: 'back' },
    h('div', { class: 'stack-lg' },
      h('h1', {}, '근거 보기'),
      E.intro.map((t) => h('p', {}, t)),
      h('section', { class: 'stack' }, h('h2', {}, E.orderTitle), E.order.map((t) => h('p', {}, t))),
      h('section', { class: 'stack' }, h('h2', {}, '근거 강도 읽는 법'),
        h('dl', { class: 'kv' }, E.levels.map(([k, v]) => [h('dt', {}, k), h('dd', {}, v)]))),
      h('section', {},
        h('h2', {}, '방법별 근거'),
        h('p', { class: 'pinned' }, E.pinned),
        E.methods.map(([name, level, text]) => h('div', { class: 'method stack' },
          h('h3', {}, name, h('span', { class: 'badge' }, level)), h('p', {}, text)))),
      h('section', { class: 'stack' }, h('h2', {}, '이 앱이 하지 않는 것'), h('ul', { class: 'plain' }, E.doesNot.map((t) => h('li', {}, t)))),
      h('section', { class: 'stack' }, h('h2', {}, '참고문헌'), h('p', { class: 'muted small' }, E.refsNote),
        h('ol', { class: 'refs' }, E.refs.map((t) => h('li', {}, t))))));
}

function terms() {
  render({ left: 'back', backTo: 'set' }, h('div', { class: 'stack' }, h('h1', {}, '이용 안내'), TERMS.map((t) => h('p', {}, t))));
}

function privacy(from) {
  const P = PRIVACY;
  render({ left: 'back', backTo: from === 'onboard' ? 'home' : 'set' },
    h('div', { class: 'stack' },
      h('h1', {}, '개인정보 안내'),
      PRIVACY_TEXT.map((t) => h('p', {}, t)),
      h('dl', { class: 'kv' },
        [['운영 주체', P.operator], ['앱을 올려 둔 곳', P.hosting], ['접속 기록 항목', P.logItems], ['보관 기간', P.retention], ['열람 여부', P.access], ['문의', P.contact]]
          .map(([k, v]) => [h('dt', {}, k), h('dd', {}, v)]))));
}

/* ---------- 길잡이 ---------- */

function parseHash() {
  const raw = location.hash.replace(/^#\/?/, '');
  const [path, qs] = raw.split('?');
  return { path: path || 'home', q: new URLSearchParams(qs || '') };
}
function go(path) {
  const target = `#/${path}`;
  if (location.hash === target) route(); else location.hash = target;
}

async function route() {
  const { path, q } = parseHash();
  if (S && path !== S.path) endSession(S.finished ? null : 'user');
  if (S && path === S.path) return;
  const st = settings();
  const sessionPaths = ['sos', 'r1', 'r2', 'r3'];
  if (!st.onboarded && sessionPaths.includes(path)) {
    /* 바로가기로 처음 들어온 사람은 안내를 건너뛴 것으로 본다 */
    saveSettings({ onboarded: true, skippedOnboarding: true, firstSosNotice: true, askScreenAfter: true });
  }
  switch (path) {
    case 'sos': {
      let r = q.get('route') === 'no_breath' ? 'no_breath' : 'breath';
      if (r === 'breath') r = await maybeSuggestNoBreath();
      if (parseHash().path !== 'sos') return;
      runFlow(() => sos(r));
      break;
    }
    case 'r1': runFlow(r1); break;
    case 'r2': runFlow(r2); break;
    case 'r3': runFlow(r3); break;
    case 'c': crisis(); break;
    case 'c2': talkPlaces(); break;
    case 'w': worries(); break;
    case 'log': log(); break;
    case 'set': settingsScreen(); break;
    case 'evidence': evidence(); break;
    case 'install': install(); break;
    case 'terms': terms(); break;
    case 'privacy': privacy(q.get('from')); break;
    case 'routines': routines(); break;
    case 'screen': screening(); break;
    default: home();
  }
}

/* ---------- 시작 ---------- */

applyLook();
if (window.matchMedia) {
  const mq = matchMedia('(prefers-color-scheme: dark)');
  if (mq.addEventListener) mq.addEventListener('change', applyLook);
}
window.addEventListener('hashchange', route);

/* 새 버전이 들어오면 세션 중이 아닐 때만 새로고침한다. 호흡 중인 화면은 건드리지 않는다.
   처음 방문해 서비스워커가 막 자리를 잡을 때는 새로고침하지 않는다(첫 안내를 읽는 중일 수 있다). */
if ('serviceWorker' in navigator && location.protocol !== 'file:') {
  let reloading = false;
  const hadController = !!navigator.serviceWorker.controller;
  navigator.serviceWorker.addEventListener('controllerchange', () => {
    if (hadController && !reloading && !S) { reloading = true; location.reload(); }
  });
  navigator.serviceWorker.register('./sw.js').then((reg) => {
    if (reg.waiting && hadController) reg.waiting.postMessage({ type: 'skip-waiting' });
    reg.addEventListener('updatefound', () => {
      const nw = reg.installing;
      if (!nw) return;
      nw.addEventListener('statechange', () => { if (nw.state === 'installed' && navigator.serviceWorker.controller) updateReady = true; });
    });
  }).catch(() => {});
}

route();
