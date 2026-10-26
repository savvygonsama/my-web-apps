"""스틸링고 입문 — 음성 파일 만들기 (VOICEVOX)

실행: python3 tools/make_audio.py <VOICEVOX 폴더>   (앱 폴더에서)
  <VOICEVOX 폴더> 안에 아래 세 가지가 있어야 한다. 모두 github.com/VOICEVOX 공개 배포본.
    voicevox_onnxruntime-linux-x64-1.17.3/   (onnxruntime-builder 릴리스)
    open_jtalk_dic_utf_8-1.11/               (r9y9/open_jtalk 릴리스)
    vvm/6.vvm                                (voicevox_vvm 0.16.4 릴리스, No.7 목소리)
  파이썬 패키지: voicevox_core 0.16.4 휠 (voicevox_core 릴리스)

js/data.js 에 나오는 글자·단어·Lite 문장을 모두 읽어 audio/ 에 mp3로 저장하고 audio/manifest.js 를 쓴다.
목소리: VOICEVOX:No.7 (アナウンス). 앱 화면에 'VOICEVOX:No.7' 표기를 반드시 남긴다.

검수 기준 (어학 전문가 권고)
- 글자 하나는 글자 소리 그대로: は=ha, へ=he. を는 お와 같은 소리로 낸다.
- 단어는 한자로 넣어 억양을 맞추고, 엔진이 읽은 가나가 원래 단어와 같은지 대조한다. 다르면 멈춘다.
- 같은 목소리·같은 속도(0.9배).
"""
import json, os, subprocess, sys, tempfile
from voicevox_core.blocking import Onnxruntime, OpenJtalk, Synthesizer, VoiceModelFile

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
VV = sys.argv[1] if len(sys.argv) > 1 else "/home/claude/vv"
STYLE = 30  # No.7 アナウンス

R = {'あ':'a','い':'i','う':'u','え':'e','お':'o','か':'ka','き':'ki','く':'ku','け':'ke','こ':'ko','さ':'sa','し':'shi','す':'su','せ':'se','そ':'so',
     'た':'ta','ち':'chi','つ':'tsu','て':'te','と':'to','な':'na','に':'ni','ぬ':'nu','ね':'ne','の':'no','は':'ha','ひ':'hi','ふ':'fu','へ':'he','ほ':'ho',
     'ま':'ma','み':'mi','む':'mu','め':'me','も':'mo','や':'ya','ゆ':'yu','よ':'yo','ら':'ra','り':'ri','る':'ru','れ':'re','ろ':'ro','わ':'wa','を':'wo','ん':'n',' ':'_'}
# 엔진에 넣을 글: 한자로 넣어야 억양이 맞는다. 없으면 가나 그대로.
KANJI = {"あい":"愛","いえ":"家","うえ":"上","あお":"青","え":"絵","かお":"顔","あか":"赤","えき":"駅","いけ":"池","こえ":"声","きく":"聞く",
         "すし":"寿司","あさ":"朝","かさ":"傘","いす":"椅子","せき":"席","て":"手","した":"下","くつ":"靴","そと":"外","ちかてつ":"地下鉄",
         "ねこ":"猫","いぬ":"犬","なつ":"夏","さかな":"魚","なに":"何","はな":"花","ひと":"人","ふね":"船","ほし":"星","まち":"町","みみ":"耳",
         "むし":"虫","あめ":"雨","もも":"桃","やま":"山","ゆき":"雪","よこ":"横","へや":"部屋","ゆめ":"夢","さくら":"桜","そら":"空","はる":"春",
         "いろ":"色","くるま":"車","とり":"鳥","わたし":"私","かわ":"川","ほん":"本","ほんを よむ":"本を読む",
         "あかい ねこ":"赤い猫","ひとの かさ":"人の傘","あめの まち":"雨の町","やまの うえ":"山の上","さくらの いろ":"桜の色","わたしの ほん":"私の本"}
# 엔진이 다르게 읽는 것은 가나 표기(AquesTalk식, ' 가 억양 자리)로 고정한다
FIXED = {"にほん": "ニホ'ン"}          # 日本 은 ニッポン 으로 읽힌다
SPOKEN = {"を": "お"}                  # を 는 お 와 같은 소리
kata = lambda s: ''.join(chr(ord(c) + 0x60) if 'ぁ' <= c <= 'ゖ' else c for c in s)

ort = Onnxruntime.load_once(filename=f"{VV}/voicevox_onnxruntime-linux-x64-1.17.3/lib/libvoicevox_onnxruntime.so.1.17.3")
syn = Synthesizer(ort, OpenJtalk(f"{VV}/open_jtalk_dic_utf_8-1.11"))
with VoiceModelFile.open(f"{VV}/vvm/6.vvm") as m:
    syn.load_voice_model(m)

js = subprocess.run(["node", "-e", """
const fs=require('fs'),vm=require('vm');const c={};c.self=c;vm.createContext(c);
vm.runInContext(fs.readFileSync(process.argv[1],'utf8'),c);
const N=c.NY;console.log(JSON.stringify({kana:Object.keys(N.KANA),lessons:N.LESSONS,lite:N.LITE_LINE.audio}));
""", os.path.join(ROOT, "js/data.js")], capture_output=True, text=True, check=True).stdout
D = json.loads(js)
texts = set()
for L in D["lessons"]:
    texts.update(v[0] for v in L["cards"].values()); texts.update(r[0] for r in L["read"]); texts.add(L["reward"][0])
    if L.get("phrase"): texts.add(L["phrase"][0])

out = os.path.join(ROOT, "audio"); os.makedirs(out, exist_ok=True)
moras = lambda q: ''.join(m.text for ap in q.accent_phrases for m in ap.moras)
def save(q, name):
    q.speed_scale = 0.9; q.pre_phoneme_length = 0.12; q.post_phoneme_length = 0.15
    wav = syn.synthesis(q, STYLE)
    with tempfile.NamedTemporaryFile(suffix=".wav") as t:
        t.write(wav); t.flush()
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", t.name, "-ac", "1", "-ar", "24000", "-b:a", "48k", os.path.join(out, name)], check=True)

man, bad = {}, []
for k in D["kana"]:
    name = f"k_{R[k]}.mp3"; save(syn.create_audio_query_from_kana(kata(SPOKEN.get(k, k)) + "'", STYLE), name); man["@" + k] = name
for t in sorted(texts):
    q = syn.create_audio_query_from_kana(FIXED[t], STYLE) if t in FIXED else syn.create_audio_query(KANJI.get(t, t), STYLE)
    want = kata(t.replace(" ", "").replace("を", "お"))
    if moras(q) != want: bad.append(f"{t}: 엔진은 {moras(q)}")
    name = "w_" + ''.join(R[c] for c in t) + ".mp3"; save(q, name); man[t] = name
q = syn.create_audio_query(D["lite"], STYLE); save(q, "lite.mp3"); man[D["lite"]] = "lite.mp3"
print("Lite 문장 →", moras(q))
if bad:
    print("❌ 읽기가 다른 단어:\n" + "\n".join(bad)); sys.exit(1)

keep = set(man.values())
for f in os.listdir(out):
    if f.endswith(".mp3") and f not in keep: os.remove(os.path.join(out, f))
open(os.path.join(out, "manifest.js"), "w", encoding="utf-8").write(
    "/* 자동 생성 — tools/make_audio.py · VOICEVOX:No.7 */\nself.NY = self.NY || {};\nNY.AUDIO = " + json.dumps(man, ensure_ascii=False, indent=0) + ";\n")
print(len(D["kana"]), "글자 +", len(texts), "단어 + Lite 1 =", len(man), "개, 읽기 대조 이상 없음")
