import json,re,glob,sys
keys=json.load(open('keys.json',encoding='utf-8'))
def norm(s):
    s=s.replace('%%','\2')
    s=re.sub(r'%[-+#0]*\d*\.?\d*[dfiuxXg]','\1',s)
    s=re.sub(r'%-?\d*s','\3',s)
    s=re.sub(r'\d[\d,.]*','\1',s)
    return s.replace('\2','%')
def toks(s): return [c for c in norm(s) if c in '\1\3']
en={}
for f in sorted(glob.glob('en_*.tsv')):
    for line in open(f,encoding='utf-8'):
        line=line.rstrip('\n')
        if not line.strip(): continue
        i,_,t=line.partition('\t'); i=int(i); k=keys[i]
        t=t.strip()
        if t.startswith('\\32'): t=' '+t[3:]
        if k[:1]==' ': t=' '+t
        if k[-1:]==' ': t=t+' '
        en[i]=t
bad=[]
for i,t in en.items():
    if toks(keys[i])!=toks(t): bad.append(i)
    if re.search('[가-힣]',t): bad.append(i)
for i in sorted(set(bad)): print('BAD',i,keys[i],'=>',en[i])
print('have',len(en),'of',len(keys),'bad',len(set(bad)))
if len(sys.argv)>1:
    def lit(s):
        return re.sub(r'(?<!\\)"','\\"',s)
    out=['-- 권왕 영어 사전 (코드 안의 한국어 글자 → 영어). tools: tools/lang/gen.py 로 만든다','return {']
    for i,t in sorted(en.items()):
        if i in bad: continue
        out.append('\t["%s"] = "%s",'%(lit(keys[i]),lit(t)))
    out.append('}')
    open(sys.argv[1],'w',encoding='utf-8').write('\n'.join(out)+'\n')
