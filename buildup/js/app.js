/* BUILD-UP — 화면

   훈련 구조는 스틸링고 한문장을 따른다.
     시작 → (지난 회차 완성 문장 한 번) → [문장마다 3번 따라 읽기 + 바로 아래 해설] × 단계 수 → 조립 퀴즈 → 완성 문장 3번 → 끝
   - 뼈대 문장 하나에서 출발해 단계마다 덩어리를 하나씩 붙인다. 마지막엔 두세 문장이 된다.
   - ← 앞 문장 · 다음 문장 → 으로 언제든 오간다. 3번을 채우지 않아도 된다. 문장마다 따라 읽은 횟수는 남는다.
   - 📌 여기까지 저장하면 홈의 「이어서 하기」로 그 문장부터. 화면을 덮거나 앱을 내려도 자리는 남는다.
   - 끝내면 다음 회차가 바로 열린다. 앞 회차를 건너뛰고 뒤로 가는 것만 막는다. 끝낸 회차는 언제든 다시.
   음성·속도·끊어 읽기·자동 진행·설치 안내는 ROUNDTABLE과 같다(기기의 영어 음성). */
(function () {
"use strict";

/* ---------- 저장 ---------- */
const K = "bu1-";
const store = {
  get(k, d){ try{ const v = localStorage.getItem(K+k); return v===null? d : JSON.parse(v); }catch(e){ return d; } },
  set(k, v){ try{ localStorage.setItem(K+k, JSON.stringify(v)); return true; }catch(e){ toast("저장 공간이 부족합니다"); return false; } }
};
const S = {
  done: store.get("done", {}),       // {day: "YYYY-MM-DD"} 처음 끝낸 날
  cur:  store.get("cur", null),      // 하던 훈련 {day,i,reps,plan,review,picked,order,miss}
  cfg:  store.get("cfg", { rate: 0.95, reps: 3, intro: false })
};
function save(){ store.set("done", S.done); store.set("cur", S.cur); store.set("cfg", S.cfg); }

/* ---------- utils ---------- */
const $ = s => document.querySelector(s);
const esc = s => String(s==null?"":s).replace(/[&<>"]/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;"}[c]));
const today = () => { const d = new Date(); return d.getFullYear()+"-"+String(d.getMonth()+1).padStart(2,"0")+"-"+String(d.getDate()).padStart(2,"0"); };
function toast(m){ const t=$("#toast"); t.textContent=m; t.classList.add("on"); clearTimeout(t._x); t._x=setTimeout(()=>t.classList.remove("on"),2200); }
const dayOf = n => BU.DAYS.find(d => d.day === n);
const doneDays = () => Object.keys(S.done).map(Number).sort((a,b)=>a-b);
const nextDay = () => { for(let i=1;i<=BU.TOTAL;i++) if(!S.done[i]) return i; return BU.TOTAL+1; };
const doneToday = () => Object.values(S.done).includes(today());
const READS = 3;

/* ---------- 음성 (TTS) — ROUNDTABLE과 같은 방식 ---------- */
let VOICES = [];
function loadVoices(){
  const all = window.speechSynthesis ? speechSynthesis.getVoices() : [];
  VOICES = all.filter(v=>/^en(-|_|$)/i.test(v.lang));
  if(!VOICES.length) VOICES = all;
}
if(window.speechSynthesis){ loadVoices(); speechSynthesis.onvoiceschanged = ()=>{ loadVoices(); }; }
function pickVoice(){
  let v = VOICES.find(x=>x.name===S.cfg.voice);
  if(!v){
    const f = VOICES.filter(x=>/female|zira|aria|jenny|samantha|karen|libby|sonia/i.test(x.name));
    v = f[0] || VOICES[0];
  }
  return v;
}
let autoTok = null;
function stopSpeak(){ autoTok=null; if(window.speechSynthesis) speechSynthesis.cancel();
  document.querySelectorAll(".chunk.on").forEach(x=>x.classList.remove("on")); }
function speak(text, rate, cb){
  if(!window.speechSynthesis){ toast("이 브라우저는 음성 재생을 지원하지 않습니다"); cb&&cb(); return; }
  speechSynthesis.cancel();
  const u = new SpeechSynthesisUtterance(text);
  const v = pickVoice(); if(v){ u.voice=v; u.lang=v.lang; } else u.lang="en-US";
  u.rate = rate || S.cfg.rate; u.pitch = 1.0;
  u.onend = ()=> cb && cb();
  u.onerror = ()=> cb && cb();
  speechSynthesis.speak(u);
}

/* 끊어 읽기 — ROUNDTABLE의 것을 그대로 쓴다.
   덩어리 수를 먼저 정하고, 끊어도 되는 자리(문장 끝·쉼표·접속사·관계사)에서만 끊는다. */
function chunkify(s){
  const toks = String(s).trim().split(/\s+/).filter(Boolean);
  const W = toks.length;
  const MIN = 3, MAX = 15, IDEAL = 10;
  if(W <= MIN * 2) return [toks.join(" ")];
  const clean = w => w.replace(/[^\w']/g, "").toLowerCase();
  const SUB   = /^(but|because|so|although|though|while|unless|whereas|since|before|after|until|once|if|whether|provided|when)$/;
  const REL   = /^(which|who|whom|whose|that|where)$/;
  const COORD = /^(and|or|yet)$/;
  const SUBJ  = /^(i|you|he|she|it|we|they|this|that|these|those|there|the|a|an|my|your|his|her|its|our|their|nobody|everyone|everybody|somebody|someone|people|most)$/;
  function strength(i){
    const prev = toks[i-1], w = clean(toks[i]), nx = i + 1 < W ? clean(toks[i+1]) : "";
    if(/[.!?]["')\]]?$/.test(prev)) return 100;
    if(/[;:—–]$/.test(prev))        return 85;
    if(/,$/.test(prev)) return (SUB.test(w) || REL.test(w) || COORD.test(w)) ? 75 : 65;
    if(SUB.test(w))  return 55;
    if(REL.test(w))  return 50;
    if(COORD.test(w) && SUBJ.test(nx)) return 40;
    return 0;
  }
  const cost = new Array(W + 1).fill(Infinity);
  const from = new Array(W + 1).fill(-1);
  cost[0] = 0;
  for(let b = MIN; b <= W; b++){
    if(b < W){
      if(strength(b) === 0) continue;
      if(W - b < MIN) continue;
    }
    const cut = b < W ? 45 - strength(b) * 0.6 : 0;
    for(let a = 0; a <= b - MIN; a++){
      if(cost[a] === Infinity) continue;
      const L = b - a;
      let c = cost[a] + Math.abs(L - IDEAL) * 2 + cut;
      if(L > MAX) c += (L - MAX) * 10;
      if(c < cost[b]){ cost[b] = c; from[b] = a; }
    }
  }
  if(cost[W] === Infinity) return [toks.join(" ")];
  const cuts = [];
  for(let b = W; b > 0; b = from[b]) cuts.unshift(b);
  const out = []; let prev = 0;
  for(const c of cuts){ out.push(toks.slice(prev, c).join(" ")); prev = c; }
  return out;
}

/* ---------- 문장 표기: {역할:새로 붙은 덩어리} ---------- */
const plain = r => r.replace(/\{\w+:/g, "").replace(/\}/g, "");
function parse(raw){
  const out = [], re = /\{(\w+):([^}]*)\}/g;
  let last = 0, m;
  while((m = re.exec(raw))){
    if(m.index > last) out.push({ t: raw.slice(last, m.index) });
    out.push({ t: m[2], role: m[1], fresh: true });
    last = re.lastIndex;
  }
  if(last < raw.length) out.push({ t: raw.slice(last) });
  return out;
}
/* 완성 문장: 그날 붙인 덩어리를 모두 찾아 색을 입힌다(긴 덩어리부터) */
function fullSegs(D){
  const spans = [];
  D.steps.forEach(s => parse(s.r).forEach(p => { if(p.role) spans.push(p); }));
  spans.sort((a,b) => b.t.length - a.t.length);
  let segs = [{ t: plain(D.steps[D.steps.length-1].r) }];
  spans.forEach(sp => {
    for(let i=0;i<segs.length;i++){
      const g = segs[i]; if(g.role) continue;
      const at = g.t.indexOf(sp.t); if(at < 0) continue;
      const parts = [];
      if(at > 0) parts.push({ t: g.t.slice(0, at) });
      parts.push({ t: sp.t, role: sp.role });
      if(at + sp.t.length < g.t.length) parts.push({ t: g.t.slice(at + sp.t.length) });
      segs.splice(i, 1, ...parts); break;
    }
  });
  return segs;
}
function sentHTML(segs, o){
  o = o || {};
  return segs.map(p => {
    if(!p.role || (o.onlyFresh && !p.fresh)) return esc(p.t);
    return '<span class="blk c-'+BU.ROLES[p.role].c+(o.onlyFresh?' grow':'')+'">'+esc(p.t)+'</span>';
  }).join("");
}
function chipsHTML(segs, withText){
  /* withText: 이번 단계에 새로 붙은 덩어리를 역할별로 묶어 글자까지 보여 준다(나눠 둔 덩어리는 … 로 잇는다)
     아니면: 완성 문장에 쓰인 역할 이름만 */
  const groups = [];
  segs.filter(p => p.role && (!withText || p.fresh)).forEach(p => {
    const g = groups.find(x => x.role === p.role);
    if(g) g.t.push(p.t.trim()); else groups.push({ role: p.role, t: [p.t.trim()] });
  });
  return '<div class="legend">'+groups.map(g => {
    const txt = g.t.join(" … ").replace(/^[,;]\s*/, "");
    return '<span class="chip c-'+BU.ROLES[g.role].c+'">'+BU.ROLES[g.role].name+
      (withText ? '<i>'+esc(txt.length>40 ? txt.slice(0,38)+"…" : txt)+'</i>' : '')+'</span>';
  }).join("")+'</div>';
}
const finalText = D => plain(D.steps[D.steps.length-1].r);
const words = s => s.trim().split(/\s+/).length;

/* ---------- 훈련 계획 ---------- */
function buildPlan(D){
  const plan = [{ t:"start" }];
  const prev = dayOf(D.day - 1);
  if(prev && S.done[prev.day]) plan.push({ t:"warm" });
  D.steps.forEach((_, i) => plan.push({ t:"read", s:i }));
  plan.push({ t:"quiz" }, { t:"final" }, { t:"done" });
  return plan;
}
function startDay(n, review){
  const D = dayOf(n); if(!D) return;
  stopSpeak();
  if(S.cur && S.cur.day === n){ go("session"); return; }    // 멈춘 자리가 있으면 그 자리부터
  S.cur = { day:n, i:0, reps:{}, plan:buildPlan(D), review:!!review, picked:[], order:null, miss:0 };
  save(); go("session");
}
function step(d){
  stopSpeak();
  S.cur.i = Math.max(0, Math.min(S.cur.plan.length-1, S.cur.i + d));
  save(); go("session");
}
/* 여기까지 하고 저장 — 저장됐는지 읽어 보고 나서 알린다(ROUNDTABLE과 같다) */
function saveAndExit(){
  stopSpeak(); save();
  const kept = store.get("cur", null);
  toast(kept ? "여기까지 저장했습니다. 다음에 열면 이어집니다."
             : "저장하지 못했습니다. 브라우저 저장 공간을 확인해 주세요.");
  go("home");
}
document.addEventListener("visibilitychange", ()=>{ if(document.hidden && view==="session") save(); });
window.addEventListener("pagehide", ()=>{ if(view==="session") save(); });

/* ---------- 라우팅 ---------- */
let view = "home";
function go(v, keepScroll){
  view = v;
  if(!keepScroll) window.scrollTo(0, 0);
  $("#footbar").classList.remove("on");
  if(v === "session" && S.cur) return renderSession();
  view = "home";
  renderHome();
}

/* ---------- 홈 ---------- */
function renderHome(){
  const n = doneDays().length, nx = nextDay(), D = dayOf(nx);
  const C = S.cur && S.cur.plan[S.cur.i].t !== "done" ? S.cur : null;
  let h = "";
  if(!S.cfg.intro) h += introHTML();
  h += '<div class="hd" style="margin-top:20px"><small>Build-up shadowing · 하루 한 회차 권장</small>'+n+' / '+BU.TOTAL+' 회차 완료</div>';
  if(C){
    const X = dayOf(C.day), it = C.plan[C.i];
    const where = it.t==="read" ? (it.s+1)+"번째 문장" : it.t==="quiz" ? "조립 퀴즈" : it.t==="final" ? "완성 문장" : "시작";
    h += '<div class="card resume"><b>📌 이어서 하기</b>'+
         '<div class="sub" style="margin:4px 0 10px">DAY '+C.day+' · '+esc(X.title)+' — '+where+'에서 멈췄습니다.</div>'+
         '<button class="btn acc" id="goResume">이어서 하기 →</button></div>';
  }
  if(nx > BU.TOTAL){
    h += '<div class="today"><span class="tag">COMPLETE</span><h2>30 build-ups, done.</h2>'+
         '<div class="kotitle">30회차를 모두 끝냈습니다. 아래 목록에서 언제든 다시 해 보세요.</div></div>';
  }else if(D && !(C && C.day === nx)){
    const first = plain(D.steps[0].r), fin = finalText(D);
    const label = n===0 ? "첫 회차 시작" : doneToday() ? "다음 회차 바로 하기" : "오늘 훈련 시작";
    h += '<div class="today">'+
         '<span class="tag">DAY '+D.day+'</span> <span class="tag r">'+esc(D.cat)+'</span>'+
         '<h2>'+esc(D.title)+'</h2><div class="kotitle">'+esc(D.titleKo)+'</div>'+
         '<p class="seed">'+esc(first)+'</p><p class="grow">→ '+D.steps.length+'단계를 거쳐 '+words(fin)+'단어, '+sentCount(fin)+'문장으로</p>'+
         '<div class="row"><button class="btn'+(C?' ghost':' acc')+'" id="goSess">'+label+' →</button>'+
         '<span class="sub">오늘의 문형: '+esc(D.gist)+'</span></div>'+
         (doneToday() ? '<div class="sub" style="margin-top:10px">오늘 한 회차는 끝냈습니다. 하루 한 회차를 권하지만, 더 하고 싶으면 바로 이어서 해도 됩니다.</div>' : '')+
         '</div>';
  }
  h += '<button class="btn ghost wide" id="installBig" hidden>📲 앱으로 설치하기<small>홈 화면에 아이콘 · 인터넷 없이도 열림</small></button>';
  h += '<div class="hd"><small>Curriculum</small>회차 목록</div><div class="sub">완성 문장이 위에서 아래로 보입니다. 끝낸 회차는 눌러서 언제든 다시 할 수 있습니다.</div><div class="dlist">';
  BU.DAYS.forEach(X => {
    const d = X.day, done = !!S.done[d], open = done || d === nx;
    const st = C && C.day===d ? '<span class="st now">이어서</span>' : done ? '<span class="st ok">완료 ✓</span>' :
               open ? '<span class="st next">'+(n===0?"시작":"다음")+'</span>' : '<span class="st lock">🔒</span>';
    h += '<div class="ditem'+(open?'':' locked')+'"'+(open?' data-day="'+d+'" role="button" tabindex="0"':'')+'>'+
         '<div class="num">'+d+'</div><div class="t"><b>'+esc(X.title)+'</b> <span class="tk">· '+esc(X.titleKo)+'</span>'+
         '<span class="fin">'+esc(firstSentence(finalText(X)))+'</span></div>'+st+
         (done?'<button class="play" data-say="'+d+'" aria-label="듣기">▶</button>':'')+'</div>';
  });
  if(BU.DAYS.length < BU.TOTAL) h += '<div class="ditem locked"><div class="num">…</div><div class="t"><b>'+(BU.DAYS.length+1)+'~'+BU.TOTAL+'회차</b><span class="fin">준비 중</span></div></div>';
  h += '</div>';
  $("#view").innerHTML = h;
  const on = (id, fn) => { const el = document.getElementById(id); if(el) el.onclick = fn; };
  on("goResume", ()=> go("session"));
  on("goSess", ()=> startDay(nx));
  on("introOk", ()=>{ S.cfg.intro = true; save(); go("home"); });
  document.querySelectorAll(".ditem[data-day]").forEach(el => {
    const open = ()=>{ const d = +el.dataset.day; startDay(d, !!S.done[d]); };
    el.onclick = e => { if(!e.target.closest(".play")) open(); };
    el.onkeydown = e => { if(e.key==="Enter") open(); };
  });
  document.querySelectorAll("[data-say]").forEach(b => b.onclick = e => { e.stopPropagation(); speak(finalText(dayOf(+b.dataset.say)), S.cfg.rate); });
  Install.attach();
}
const firstSentence = s => { const m = s.match(/^.*?[.!?;](?=\s|$)/); return m && m[0].length < s.length ? m[0].replace(/;$/, "")+" …" : s; };
const sentCount = s => (s.match(/[.!?](\s|$)/g) || []).length || 1;
function introHTML(){
  const D = BU.DAYS[0];
  const demo = D ? D.steps.slice(0,3).map(s=>'<div class="from" style="color:var(--ink)">'+sentHTML(parse(s.r),{onlyFresh:true})+'</div>').join("") : "";
  return '<div class="card" style="margin-top:20px">'+
    '<div class="hd" style="margin:0 0 8px"><small>How it works</small>뼈대 한 문장에서 두세 문장까지</div>'+
    demo+'<div class="sub" style="margin:6px 0 12px">⋯ 덩어리를 하나씩 붙여 30~40단어까지</div>'+
    '<ol class="sub" style="padding-left:20px;margin:0 0 12px;line-height:1.9">'+
    '<li><b>뼈대 문장에서 출발</b> — 주어와 동사만 있는 문장부터</li>'+
    '<li><b>덩어리를 하나씩</b> — 이유·조건·양보·관계절·두 번째 문장을 차례로 붙입니다</li>'+
    '<li><b>문장마다 3번</b> — 천천히(0.7x) → 보통 속도 → 소리와 동시에. 덩어리별로 눌러 들을 수 있습니다</li>'+
    '<li><b>바로 아래에서 해설</b> — 이번에 붙인 덩어리가 하는 일과 표현 노트</li>'+
    '<li><b>조립하고 통으로</b> — 완성 문장을 블록으로 맞추고 처음부터 끝까지 3번</li></ol>'+
    '<div class="sub" style="margin-bottom:12px">수준은 ROUNDTABLE과 같은 B2입니다. 소리는 기기의 영어 음성으로 나옵니다.</div>'+
    '<button class="btn ghost sm" id="introOk">알겠습니다</button></div>';
}

/* ---------- 세션 ---------- */
const GUIDE = [["1번째","천천히 듣고 따라 읽기 — 「천천히 0.7x」를 권합니다"],["2번째","보통 속도로 따라 읽기"],["3번째","소리와 동시에 겹쳐 읽기"]];
function dotsHTML(n){ return Array.from({length:READS},(_,k)=>'<span class="dot '+(k<n?"on":"")+'"></span>').join(""); }
function speedBar(){
  return '<span class="speedbar" id="spd">속도 '+[0.7,0.85,0.95,1.1].map(r=>
    '<button data-r="'+r+'" class="'+(Math.abs(S.cfg.rate-r)<0.01?"on":"")+'">'+r+'x</button>').join("")+'</span>';
}
function bindSpeed(){
  document.querySelectorAll("#spd button").forEach(b=> b.onclick = ()=>{
    S.cfg.rate = +b.dataset.r; save();
    document.querySelectorAll("#spd button").forEach(x=>x.classList.toggle("on", x===b));
  });
}
function shadowControls(text, reps){
  const chunks = words(text) >= 12 ? chunkify(text) : [];
  return (chunks.length > 1 ? '<div class="chunks"><div class="sub">덩어리로 끊어 읽기 — 줄을 누르면 그 부분만 들립니다</div>'+
            chunks.map((c,ci)=>'<div class="chunk" data-c="'+ci+'">'+esc(c)+'</div>').join("")+'</div>' : '')+
    '<div class="rule"></div>'+
    '<div class="guide">'+(reps>=READS ? '<b>3번 끝</b>더 읽어도 좋고, 다음 문장으로 가도 됩니다' : '<b>'+GUIDE[reps][0]+'</b>'+GUIDE[reps][1])+'</div>'+
    '<div class="row"><button class="btn" id="pLine">듣기 ▶</button>'+
    '<button class="btn ghost sm" id="pSlow">천천히 0.7x</button>'+
    '<button class="btn ghost sm" id="pAuto">자동 진행 ▶▶</button>'+
    '<span style="flex:1"></span><span class="counter" id="dots">'+dotsHTML(reps)+'</span></div>'+
    '<div class="row" style="margin-top:10px">'+speedBar()+'</div>';
}
function bumpRep(){
  const C = S.cur; C.reps[C.i] = Math.min(9, (C.reps[C.i]||0)+1);
  const n = C.reps[C.i], dots = $("#dots");
  if(dots) dots.innerHTML = dotsHTML(n);
  const g = document.querySelector(".guide");
  if(g) g.innerHTML = n>=READS ? '<b>3번 끝</b>더 읽어도 좋고, 다음 문장으로 가도 됩니다' : '<b>'+GUIDE[n][0]+'</b>'+GUIDE[n][1];
  save();
}
function bindShadow(text, chunks){
  const play = rate => { stopSpeak(); bumpRep(); speak(text, rate); };
  $("#pLine").onclick = ()=> play();
  $("#pSlow").onclick = ()=> play(0.7);
  $("#pAuto").onclick = ()=>{ if(autoTok){ stopSpeak(); $("#pAuto").textContent = "자동 진행 ▶▶"; } else autoRun(); };
  const cs = chunkify(text);
  document.querySelectorAll(".chunk").forEach(el => el.onclick = ()=>{
    stopSpeak(); el.classList.add("on");
    speak(cs[+el.dataset.c], Math.min(S.cfg.rate, 0.9), ()=> el.classList.remove("on"));
  });
  bindSpeed();
}
/* 자동 진행 — 재생 → 따라 읽을 여유 → 재생 … 3번 채우면 다음 문장 (ROUNDTABLE과 같은 리듬) */
function autoRun(){
  const token = {}; autoTok = token;
  const b = $("#pAuto"); if(b){ b.textContent = "■ 자동 정지"; b.classList.remove("ghost"); }
  const gap = t => Math.max(1200, t.split(/\s+/).length * 360);
  (function run(){
    if(autoTok!==token) return;
    const C = S.cur, it = C.plan[C.i];
    if(it.t!=="read" && it.t!=="final"){ autoTok=null; return; }
    const text = it.t==="read" ? plain(dayOf(C.day).steps[it.s].r) : finalText(dayOf(C.day));
    if((C.reps[C.i]||0) >= READS){
      if(it.t==="final"){ autoTok=null; renderSession(true); toast("3번 끝 — 아래 「다음」으로 마무리하세요"); return; }
      C.i++; save(); renderSession(true);
      const nt = C.plan[C.i].t;
      if(nt==="read" || nt==="final"){ autoTok = token; const b2=$("#pAuto"); if(b2){ b2.textContent="■ 자동 정지"; b2.classList.remove("ghost"); } setTimeout(run, 600); }
      else { autoTok=null; toast("문장 쌓기 끝 — 조립 퀴즈로 넘어왔습니다"); }
      return;
    }
    const slow = (C.reps[C.i]||0) === 0;
    bumpRep();
    speak(text, slow ? 0.7 : S.cfg.rate, ()=>{
      if(autoTok!==token) return;
      setTimeout(run, gap(text) * (slow ? 1.3 : 1));
    });
  })();
}

function renderSession(keepScroll){
  const C = S.cur, D = dayOf(C.day), it = C.plan[C.i];
  if(!D){ S.cur = null; save(); go("home"); return; }
  if(it.t === "done") return renderDone();
  if(!keepScroll) window.scrollTo(0,0);
  const reps = C.reps[C.i] || 0;
  const bar = '<div class="steps">'+C.plan.slice(0,-1).map((_,k)=>'<div class="'+(k<C.i?"past":k===C.i?"on":"")+'"></div>').join("")+'</div>';
  const head = (name, em) => '<div class="sesshead"><span class="tag">DAY '+D.day+'</span><span class="stepname">'+name+(em?'<em>'+em+'</em>':'')+'</span></div>';
  let h = bar, after = null;

  if(it.t === "start"){
    h += head("시작", C.review ? "다시 하기" : "");
    h += '<div class="today"><span class="tag r">'+esc(D.cat)+'</span> <span class="tag">'+esc(D.level||"B2")+'</span>'+
         '<h2>'+esc(D.title)+'</h2><div class="kotitle">'+esc(D.titleKo)+'</div>'+
         '<div class="sub"><b>오늘의 문형</b> · '+esc(D.gist)+'</div>'+
         '<div class="rule"></div><div class="sub">뼈대 문장</div><p class="seed" style="margin-top:4px">'+esc(plain(D.steps[0].r))+'</p>'+
         '<div class="sub">→ '+D.steps.length+'단계를 거쳐 '+words(finalText(D))+'단어로 늘어납니다. 아래 「다음 문장 →」으로 시작하세요.</div></div>';
  }

  if(it.t === "warm"){
    const P = dayOf(C.day-1), text = finalText(P);
    h += head("지난 회차 완성 문장", "한 번 듣고 따라 읽기");
    h += '<div class="shadowbox"><div class="lbl">DAY '+P.day+' · '+esc(P.title)+'</div>'+
         '<div class="bigen">'+sentHTML(fullSegs(P))+'</div><div class="bigko">'+esc(P.steps[P.steps.length-1].ko)+'</div>'+
         shadowControls(text, reps)+'</div>';
    after = ()=> bindShadow(text);
  }

  if(it.t === "read"){
    const st = D.steps[it.s], segs = parse(st.r), text = plain(st.r);
    h += head("문장 "+(it.s+1)+" / "+D.steps.length, it.s===0 ? "뼈대 문장" : words(text)+"단어");
    h += '<div class="shadowbox"><div class="lbl">'+(it.s===0?"STEP 1 · 뼈대":"STEP "+(it.s+1)+" · 새로 붙은 덩어리")+'</div>'+
         chipsHTML(segs, true)+
         '<div class="bigen">'+sentHTML(segs,{onlyFresh:true})+'</div><div class="bigko">'+esc(st.ko)+'</div>'+
         shadowControls(text, reps)+'</div>';
    h += explHTML(st);
    h += '<div class="sub" style="margin-top:14px">스페이스바 = 듣기 · Enter = 다음 문장</div>';
    after = ()=> bindShadow(text);
  }

  if(it.t === "quiz"){
    const Q = D.quiz;
    if(!C.order){ C.order = shuffle(Q.blocks.map((_,k)=>k)); save(); }
    const picked = C.picked || [], complete = picked.length === Q.blocks.length;
    h += head("조립 퀴즈", "완성 문장을 블록으로");
    h += '<div class="shadowbox"><div class="lbl">ASSEMBLE</div><div class="bigko" style="margin-top:6px">'+esc(D.steps[D.steps.length-1].ko)+'</div>'+
         '<div class="slots'+(complete?" ok":"")+'">'+(picked.map(k=>'<span>'+esc(Q.blocks[k])+'</span>').join("") || '<span class="ph">블록을 순서대로 눌러 주세요</span>')+'</div>'+
         '<div class="pool">'+C.order.map(k=>'<button class="opt" data-k="'+k+'" '+(picked.includes(k)?"disabled":"")+'>'+esc(Q.blocks[k])+'</button>').join("")+'</div>'+
         '<div class="row">'+(picked.length && !complete ? '<button class="btn ghost sm" id="undo">↩ 하나 되돌리기</button>' : '')+
         (complete ? '<span class="sub" style="color:var(--ok);font-weight:700">완성! 아래 「다음 문장 →」으로 통째로 읽기</span>' :
           C.miss ? '<span class="sub">문장 순서를 떠올려 보세요. 뼈대(주어+동사)가 어디였는지부터.</span>' : '')+'</div></div>';
    after = ()=>{
      document.querySelectorAll(".pool .opt").forEach(b=> b.onclick = ()=>{
        const k = +b.dataset.k, next = picked.concat(k);
        if(Q.orders.some(o=>next.every((x,j)=>o[j]===x))){ C.picked = next; save(); renderSession(true); }
        else { b.classList.add("ng"); setTimeout(()=>b.classList.remove("ng"),450); if(!C.miss){ C.miss=1; save(); renderSession(true); } }
      });
      const u = $("#undo"); if(u) u.onclick = ()=>{ C.picked = picked.slice(0,-1); save(); renderSession(true); };
    };
  }

  if(it.t === "final"){
    const segs = fullSegs(D), text = finalText(D);
    h += head("완성 문장", "처음부터 끝까지 3번");
    h += '<div class="shadowbox"><div class="lbl">FULL BUILD-UP · '+words(text)+' words</div>'+chipsHTML(segs,false)+
         '<div class="bigen">'+sentHTML(segs)+'</div><div class="bigko">'+esc(D.steps[D.steps.length-1].ko)+'</div>'+
         shadowControls(text, reps)+'</div>';
    after = ()=> bindShadow(text);
  }

  $("#view").innerHTML = h;
  renderFoot();
  if(after) after();
}
function explHTML(st){
  let h = '<div class="expl"><h4>🔍 이번에 붙인 것</h4>';
  (st.gram||[]).forEach(g=>{ h += '<div class="gram"><b>'+esc(g.t)+'</b><p>'+esc(g.d)+'</p></div>'; });
  if(st.notes && st.notes.length){
    h += '<div class="notes">'+st.notes.map(n=>'<div class="note"><b>'+esc(n.t)+'</b><span class="k">'+esc(BU.KINDS[n.k]||n.k)+'</span> — '+esc(n.m)+
         (n.tip?'<span class="tip">'+esc(n.tip)+'</span>':'')+'</div>').join("")+'</div>';
  }
  (st.trap||[]).forEach(t=>{ h += '<div class="trap"><p class="ng">✗ '+esc(t.ng)+'</p><p>'+esc(t.why)+'</p></div>'; });
  return h + '</div>';
}
function renderFoot(){
  const C = S.cur, last = C.i >= C.plan.length-2;
  let h = '<button class="btn ghost sm" id="fPrev"'+(C.i===0?" disabled":"")+'>← 앞 문장</button>';
  h += '<span class="sub" style="font-size:12px">'+(C.i+1)+'/'+(C.plan.length-1)+'</span><span class="sp"></span>';
  h += '<button class="btn ghost sm" id="fSave">📌 여기까지 저장</button>';
  h += '<button class="btn '+(last?"acc":"")+' sm" id="fNext">'+(C.i===0?"시작 →":last?"훈련 완료 ✓":"다음 문장 →")+'</button>';
  $("#footin").innerHTML = h;
  $("#footbar").classList.add("on");
  $("#fPrev").onclick = ()=> step(-1);
  $("#fSave").onclick = saveAndExit;
  $("#fNext").onclick = ()=> step(1);
}
function renderDone(){
  const C = S.cur, D = dayOf(C.day);
  if(!C.review && !S.done[C.day]) S.done[C.day] = today();
  const segs = fullSegs(D), text = finalText(D);
  const reads = Object.values(C.reps).reduce((a,b)=>a+b,0);
  const nx = nextDay(), N = dayOf(nx);
  S.cur = null; save();
  let h = '<div class="hd" style="margin-top:30px"><small>Session complete</small>DAY '+D.day+' 완성</div>'+
    '<div class="card"><div class="sub">뼈대</div><p class="from">'+esc(plain(D.steps[0].r))+'</p>'+
    '<p class="arrow">↓ 덩어리 '+(D.steps.length-1)+'개를 붙여서</p>'+
    '<div class="bigen">'+sentHTML(segs)+'</div>'+chipsHTML(segs,false)+
    '<div class="bigko">'+esc(D.steps[D.steps.length-1].ko)+'</div>'+
    '<div class="row" style="margin-top:12px"><button class="btn ghost sm" id="dPlay">다시 듣기 ▶</button></div>'+
    '<div class="streak"><div><b>'+words(text)+'</b><span>단어</span></div><div><b>'+reads+'</b><span>따라 읽은 횟수</span></div>'+
    '<div><b>'+doneDays().length+'</b><span>완료 회차</span></div></div></div>';
  if(D.day === BU.TOTAL) h += '<div class="today"><span class="tag">COMPLETE</span><h2>30 build-ups, done.</h2><div class="kotitle">뼈대 한 문장에서 두세 문장짜리 논지까지, 30번을 쌓았습니다. 목록에서 언제든 다시 읽어 보세요.</div></div>';
  h += '<div class="card sub">내일 시작하기 전에 오늘 완성 문장을 <b>보지 않고</b> 한 번 말해 보세요. 덩어리 순서가 떠오르면 성공입니다.</div>';
  h += '<div class="row" style="margin-top:6px">'+(N ? '<button class="btn acc" id="dNext">다음 회차 바로 하기 → <small>DAY '+N.day+' · '+esc(N.title)+'</small></button>' : '')+
       '<button class="btn ghost" id="dHome">홈으로</button></div>';
  $("#view").innerHTML = h;
  $("#footbar").classList.remove("on");
  $("#dPlay").onclick = ()=> speak(text, S.cfg.rate);
  $("#dHome").onclick = ()=> go("home");
  const dn = $("#dNext"); if(dn) dn.onclick = ()=> startDay(N.day);
}
function shuffle(a){ a=a.slice(); for(let i=a.length-1;i>0;i--){ const j=Math.floor(Math.random()*(i+1)); [a[i],a[j]]=[a[j],a[i]]; } return a; }

/* 키보드 — ROUNDTABLE과 같다: 스페이스바 = 듣기, Enter = 다음 */
document.addEventListener("keydown", e=>{
  if(view!=="session" || !S.cur) return;
  if(e.target && /INPUT|TEXTAREA|BUTTON/.test(e.target.tagName) && e.code!=="Space" && e.code!=="Enter") return;
  const it = S.cur.plan[S.cur.i];
  if(e.code==="Space" && (it.t==="read" || it.t==="final" || it.t==="warm")){
    e.preventDefault(); const b = $("#pLine"); if(b) b.click();
  }
  if(e.code==="Enter"){ e.preventDefault(); step(1); }
});
$("#brand").onclick = ()=>{ if(view==="session") saveAndExit(); else go("home"); };

/* ---------- 화면 밝기: 휴대폰 설정을 따른다 ---------- */
function applyTheme(){
  const dark = window.matchMedia && matchMedia("(prefers-color-scheme: dark)").matches;
  document.documentElement.setAttribute("data-theme", dark ? "dark" : "light");
}
applyTheme();
if(window.matchMedia) matchMedia("(prefers-color-scheme: dark)").addEventListener?.("change", applyTheme);

/* ═══════════ 앱으로 설치하기 (ROUNDTABLE과 같다) ═══════════
   링크를 카카오톡·팀즈로 보내면 대개 그 앱 안의 브라우저로 열린다.
   거기서는 설치도 소리도 되지 않으므로, 그 경우를 가장 먼저 잡아 크롬·사파리로 넘긴다. */
const Install = (function(){
  if("serviceWorker" in navigator){
    window.addEventListener("load", ()=> navigator.serviceWorker.register("./sw.js").then(()=>{
      if(navigator.serviceWorker.controller) navigator.serviceWorker.controller.postMessage({type:"ensure-cache"});
    }).catch(()=>{}));
  }
  const UA = navigator.userAgent;
  const isIOS = /iPhone|iPad|iPod/i.test(UA) || (/Macintosh/.test(UA) && navigator.maxTouchPoints > 1);
  const isAndroid = /Android/i.test(UA);
  const isMobile = isIOS || isAndroid;
  const inApp = /KAKAOTALK|Teams|MSTeams|NAVER|Line\/|band|DaumApps|Instagram|FB_IAB|FBAN|FBAV|everytime/i.test(UA);
  const TARGET = isIOS ? "사파리" : "크롬";
  const TO = isIOS ? "사파리로" : "크롬으로";
  function copyLink(){
    const url = location.href;
    const done = ()=> toast("주소를 복사했습니다. " + TARGET + "에 붙여 넣어 주세요.");
    if(navigator.clipboard && navigator.clipboard.writeText) navigator.clipboard.writeText(url).then(done, done);
    else{
      const ta = document.createElement("textarea"); ta.value = url; ta.style.position = "fixed"; ta.style.opacity = "0";
      document.body.appendChild(ta); ta.select(); try{ document.execCommand("copy"); }catch(e){} document.body.removeChild(ta); done();
    }
  }
  function openOutside(){
    const url = location.href;
    if(/KAKAOTALK/i.test(UA)){ location.href = "kakaotalk://web/openExternal?url=" + encodeURIComponent(url); return; }
    if(isIOS){
      location.href = url.replace(/^https:/, "x-safari-https:").replace(/^http:/, "x-safari-http:");
      setTimeout(()=>{ if(!document.hidden) copyLink(); }, 1200); return;
    }
    if(isAndroid){
      location.href = "intent://" + url.replace(/^https?:\/\//, "") + "#Intent;scheme=" + location.protocol.replace(":", "") +
        ";package=com.android.chrome;S.browser_fallback_url=" + encodeURIComponent(url) + ";end";
      return;
    }
    window.open(url, "_blank");
  }
  if(inApp && isMobile){
    const box = $("#openChrome"); box.hidden = false;
    $("#ocApp").textContent = /KAKAOTALK/i.test(UA) ? "지금은 카카오톡 안에서 열려 있습니다." : "지금은 다른 앱 안에서 열려 있습니다.";
    $("#ocMsg").textContent = "여기서는 영어 발음이 나오지 않고 설치도 되지 않습니다. " + TO + " 열면 소리가 납니다.";
    $("#ocGo").textContent = TO + " 열기";
    $("#ocGo").onclick = openOutside; $("#ocCopy").onclick = copyLink;
    $("#ocClose").onclick = ()=>{ box.hidden = true; };
  }
  const note = $("#installNote"), title = $("#installTitle"), steps = $("#installSteps"), nowBtn = $("#installNow");
  const standalone = window.matchMedia("(display-mode: standalone)").matches || navigator.standalone === true;
  let deferred = null;
  window.addEventListener("beforeinstallprompt", e=>{ e.preventDefault(); deferred = e; if(!note.hidden) open(); });
  window.addEventListener("appinstalled", ()=>{ $("#installBtn").hidden = true; const b=$("#installBig"); if(b) b.hidden = true; note.hidden = true; });
  function build(){
    if(inApp){
      title.textContent = "📲 먼저 브라우저로 열어 주세요";
      return "<p><b>지금 카카오톡·팀즈 같은 앱 안에서 열려 있습니다.</b> 여기서는 설치가 되지 않습니다.</p><ol>" +
        "<li>화면 <b>오른쪽 위 메뉴</b>(⋯ 또는 ⋮)를 누릅니다</li><li><b>「다른 브라우저로 열기」</b>를 고릅니다" +
        (isIOS ? " — 아이폰은 <b>Safari</b>" : isAndroid ? " — 안드로이드는 <b>Chrome</b>" : "") + "</li>" +
        "<li>열린 화면에서 이 안내가 다시 나오면 그대로 따라 하시면 됩니다</li></ol>";
    }
    if(isIOS){
      title.textContent = "📲 홈 화면에 추가하기";
      return "<p><b>아이폰 · 아이패드 (Safari)</b></p><ol><li>화면 <b>아래쪽 공유 버튼</b>(□ 위에 화살표)을 누릅니다</li>" +
        "<li>목록을 내려 <b>「홈 화면에 추가」</b>를 고릅니다</li><li>오른쪽 위 <b>「추가」</b>를 누르면 끝입니다</li></ol>";
    }
    if(isAndroid){
      title.textContent = "📲 앱으로 설치하기";
      return "<p><b>안드로이드 (Chrome)</b></p><ol>" + (deferred ? "<li>아래 <b>「지금 설치」</b> 버튼을 누릅니다</li>" :
        "<li>화면 <b>오른쪽 위 메뉴(⋮)</b>를 누릅니다</li><li><b>「앱 설치」</b> 또는 <b>「홈 화면에 추가」</b>를 고릅니다</li>") + "</ol>";
    }
    title.textContent = "📲 앱으로 설치하기";
    return "<p><b>컴퓨터 (Chrome · Edge)</b></p><ol>" + (deferred ? "<li>아래 <b>「지금 설치」</b> 버튼을 누릅니다</li>" : "") +
      "<li>주소창 오른쪽 끝의 <b>설치 아이콘</b>을 누릅니다</li><li>없으면 메뉴 → <b>「앱 설치」</b></li></ol>";
  }
  function open(){
    steps.innerHTML = build() + "<p>설치하면 아이콘을 눌러 주소창 없이 앱처럼 열리고, 인터넷이 끊겨도 계속 쓸 수 있습니다. 지금까지의 기록은 그대로 남습니다.</p>";
    nowBtn.hidden = !deferred; note.hidden = false;
  }
  nowBtn.onclick = async ()=>{
    if(!deferred) return;
    deferred.prompt(); const { outcome } = await deferred.userChoice; deferred = null; nowBtn.hidden = true;
    if(outcome === "accepted"){ $("#installBtn").hidden = true; const b=$("#installBig"); if(b) b.hidden = true; note.hidden = true; }
  };
  const SEEN = "buildup-install-seen";
  $("#installNoteClose").onclick = ()=>{ note.hidden = true; try{ localStorage.setItem(SEEN, "1"); }catch(e){} };
  let asked = false;
  return {
    /* 설치한 앱으로 열었을 때만 버튼을 숨긴다. 처음 연 휴대폰에는 한 번 저절로 띄운다. */
    attach(){
      if(standalone) return;
      $("#installBtn").hidden = false; $("#installBtn").onclick = open;
      const big = $("#installBig"); if(big){ big.hidden = false; big.onclick = open; }
      if(asked) return; asked = true;
      let seen = false; try{ seen = localStorage.getItem(SEEN) === "1"; }catch(e){}
      if(!seen && isMobile && $("#openChrome").hidden) setTimeout(()=>{ if(note.hidden) open(); }, 1200);
    }
  };
})();

go("home");
window.__bu = { S, go, plain, fullSegs, chunkify };
})();
