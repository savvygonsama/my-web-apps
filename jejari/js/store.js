/* 제자리 · 저장소

   설정은 localStorage 키 하나, 세션과 걱정은 IndexedDB.
   어디로도 보내지 않는다. 브라우저가 저장소를 막는 경우(사생활 보호 창 등)에도
   앱이 멈추지 않도록 모든 읽기·쓰기를 감싼다. 그때는 이번 실행 동안만 메모리에 둔다. */

import { RULES } from './content.js';

const KEY = 'jejari.settings';

const DEFAULTS = {
  onboarded: false,
  skippedOnboarding: false,   // [지금 바로 SOS]로 첫 안내를 건너뛰었는가
  firstSosNotice: false,      // 건너뛴 사람의 첫 SOS에 한 줄 고지를 보여 줄 차례인가
  askScreenAfter: false,      // 세션 뒤에 선별 문항을 물어볼 차례인가
  screenAnswer: undefined,    // 'yes' | 'no' | null(잘 모르겠음) | undefined(아직 안 물음)
  defaultRoute: 'breath',
  pace: 'normal',
  vibrate: false,
  reduceMotion: false,
  theme: 'auto',
  reviewTime: RULES.defaultReviewTime,
  icsFreq: 'weekdays',
  eapName: '',
  eapPhone: '',
  installSeen: false,
  suggestedFor: null,         // F-04 제안을 이미 보여 준 세션 id
  installedAt: null,
};

let mem = null;

export function getSettings() {
  if (mem) return mem;
  let saved = {};
  try { saved = JSON.parse(localStorage.getItem(KEY) || '{}') || {}; } catch (e) { saved = {}; }
  mem = { ...DEFAULTS, ...saved };
  if (!mem.installedAt) { mem.installedAt = new Date().toISOString(); saveSettings(); }
  return mem;
}

export function saveSettings(patch) {
  const s = getSettings();
  if (patch) Object.assign(s, patch);
  try { localStorage.setItem(KEY, JSON.stringify(s)); } catch (e) { /* 메모리에만 남는다 */ }
  return s;
}

export function resetSettings() {
  mem = { ...DEFAULTS, installedAt: new Date().toISOString() };
  saveSettings();
}

/* ---------- IndexedDB ---------- */

let dbp = null;
const fallback = { sessions: new Map(), worries: new Map(), seq: 1 };


function open() {
  if (dbp) return dbp;
  dbp = new Promise((resolve) => {
    let req;
    try { req = indexedDB.open('jejari', 1); } catch (e) { resolve(null); return; }
    req.onupgradeneeded = () => {
      const db = req.result;
      if (!db.objectStoreNames.contains('sessions')) {
        const s = db.createObjectStore('sessions', { keyPath: 'id', autoIncrement: true });
        s.createIndex('startedAt', 'startedAt');
      }
      if (!db.objectStoreNames.contains('worries')) {
        db.createObjectStore('worries', { keyPath: 'id', autoIncrement: true });
      }
    };
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => resolve(null);
    req.onblocked = () => resolve(null);
  });
  return dbp;
}

function req2p(fnStore, store, mode) {
  return open().then((db) => new Promise((resolve, reject) => {
    const t = db.transaction(store, mode);
    const r = fnStore(t.objectStore(store));
    let out;
    if (r) r.onsuccess = () => { out = r.result; };
    t.oncomplete = () => resolve(out);
    t.onerror = () => reject(t.error);
    t.onabort = () => reject(t.error);
  }));
}

export async function put(store, rec) {
  const db = await open();
  if (!db) {
    if (rec.id == null) rec.id = fallback.seq++;
    fallback[store].set(rec.id, { ...rec });
    return rec.id;
  }
  const copy = { ...rec };
  if (copy.id == null) delete copy.id;
  const id = await req2p((os) => os.put(copy), store, 'readwrite');
  if (rec.id == null) rec.id = id;
  return rec.id;
}

export async function all(store) {
  const db = await open();
  if (!db) return [...fallback[store].values()].map((r) => ({ ...r }));
  return (await req2p((os) => os.getAll(), store, 'readonly')) || [];
}

export async function remove(store, id) {
  const db = await open();
  if (!db) { fallback[store].delete(id); return; }
  await req2p((os) => os.delete(id), store, 'readwrite');
}

export async function clear(store) {
  const db = await open();
  if (!db) { fallback[store].clear(); return; }
  await req2p((os) => os.clear(), store, 'readwrite');
}

export async function requestPersist() {
  try { if (navigator.storage && navigator.storage.persist) await navigator.storage.persist(); } catch (e) { /* 없어도 된다 */ }
}
