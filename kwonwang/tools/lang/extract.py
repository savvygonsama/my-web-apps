import re,glob,json,sys
HAN=re.compile('[가-힣]')
def lits(src):
    i=0;n=len(src);out=[]
    while i<n:
        c=src[i]
        if src.startswith('--',i):
            m=re.match(r'--\[(=*)\[',src[i:])
            if m:
                end=src.find(']'+m.group(1)+']',i); i=end+2+len(m.group(1)) if end>=0 else n
            else:
                j=src.find('\n',i); i=n if j<0 else j
            continue
        if c in '"\'':
            j=i+1;buf=[]
            while j<n and src[j]!=c:
                if src[j]=='\\': buf.append(src[j:j+2]); j+=2; continue
                if src[j]=='\n': break
                buf.append(src[j]); j+=1
            out.append(''.join(buf)); i=j+1; continue
        m=re.match(r'\[(=*)\[',src[i:i+10])
        if m:
            end=src.find(']'+m.group(1)+']',i); out.append(src[i+2+len(m.group(1)):end]); i=end+2+len(m.group(1)); continue
        i+=1
    return out
order=["src/shared/Config.lua"]+sorted(glob.glob("src/server/**/*.lua",recursive=True))+sorted(glob.glob("src/client/**/*.lua",recursive=True))+["src/shared/Poses.lua"]
seen={};keys=[]
for f in order:
    for t in lits(open(f,encoding="utf-8").read()):
        if HAN.search(t) and t not in seen:
            seen[t]=f; keys.append(t)
json.dump(keys,open(sys.argv[1],"w",encoding="utf-8"),ensure_ascii=False)
print(len(keys), sum(len(k) for k in keys))
