"""한문장 — 음성 파일 만들기 (VOICEVOX)

실행: python3 tools/make_audio.py <VOICEVOX 폴더>   (앱 폴더에서)
  <VOICEVOX 폴더>는 스틸링고 입문(steel-lingo/nyumon/tools/make_audio.py)과 같은 구성이다.
    voicevox_onnxruntime-linux-x64-1.17.3/  open_jtalk_dic_utf_8-1.11/  vvm/6.vvm
  파이썬 패키지: voicevox_core 0.16.4 휠

js/days.js 의 모든 단계 문장과 새 단어를 읽어 audio/ 에 mp3로 저장하고 audio/manifest.js 를 쓴다.
목소리: VOICEVOX:No.7 (アナウンス), 보통 속도. 앱의 '천천히 듣기'는 같은 파일을 0.8배로 튼다.
manifest.js 에 파일이 하나라도 있으면 앱 아래쪽 표기가 'VOICEVOX:No.7'로 바뀐다.
음성 파일이 없는 문장은 기기의 일본어 음성으로 읽는다. """
import hashlib, json, os, re, subprocess, sys, tempfile
from voicevox_core.blocking import Onnxruntime, OpenJtalk, Synthesizer, VoiceModelFile

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
VV = sys.argv[1] if len(sys.argv) > 1 else "/home/claude/vv"
STYLE = 30  # No.7 アナウンス

ort = Onnxruntime.load_once(filename=f"{VV}/voicevox_onnxruntime-linux-x64-1.17.3/lib/libvoicevox_onnxruntime.so.1.17.3")
syn = Synthesizer(ort, OpenJtalk(f"{VV}/open_jtalk_dic_utf_8-1.11"))
with VoiceModelFile.open(f"{VV}/vvm/6.vvm") as m:
    syn.load_voice_model(m)

js = subprocess.run(["node", "-e", """
const fs=require('fs'),vm=require('vm');const c={};c.self=c.window=c;vm.createContext(c);
for (const f of process.argv.slice(1)) vm.runInContext(fs.readFileSync(f,'utf8'),c);
console.log(JSON.stringify(c.NY.DAYS));
""", os.path.join(ROOT, "js/data.js"), os.path.join(ROOT, "js/days.js")], capture_output=True, text=True, check=True).stdout
DAYS = json.loads(js)

plain = lambda r: re.sub(r"([一-龯々〆ヶ]+)\[[^\]]+\]", r"\1", re.sub(r"\{\w+:|\}", "", r))
texts = []
for D in DAYS:
    for s in D["steps"]:
        texts.append(plain(s["r"]))
        texts.extend(w["w"] for w in s["words"])
texts = list(dict.fromkeys(texts))

out = os.path.join(ROOT, "audio"); os.makedirs(out, exist_ok=True)
manifest = {}
for t in texts:
    name = hashlib.sha1(t.encode()).hexdigest()[:10] + ".mp3"
    manifest[t] = name
    if os.path.exists(os.path.join(out, name)): continue
    q = syn.create_audio_query(t, STYLE)
    q.speed_scale = 1.0; q.pre_phoneme_length = 0.12; q.post_phoneme_length = 0.2
    wav = syn.synthesis(q, STYLE)
    with tempfile.NamedTemporaryFile(suffix=".wav") as f:
        f.write(wav); f.flush()
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", f.name, "-ac", "1", "-ar", "24000", "-b:a", "48k", os.path.join(out, name)], check=True)
    print("✓", t)

open(os.path.join(out, "manifest.js"), "w", encoding="utf-8").write(
    "/* 자동 생성 — tools/make_audio.py · VOICEVOX:No.7 */\nself.NY = self.NY || {};\nNY.AUDIO = " + json.dumps(manifest, ensure_ascii=False, indent=0) + ";\n")
print(f"{len(manifest)}개")
