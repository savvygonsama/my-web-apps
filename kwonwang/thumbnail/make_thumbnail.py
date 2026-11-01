import math, random
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageChops
random.seed(7)
W, H = 1920, 1080
SS = 2
w, h = W*SS, H*SS
KO = "/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc"
BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

def lerp(a,b,t): return a+(b-a)*t
def lc(c1,c2,t): return tuple(int(lerp(c1[i],c2[i],t)) for i in range(3))

# 1) 하늘: 위 남보라 → 가운데 붉은 노을 → 지평선 금빛
sky = Image.new("RGB",(w,h))
px = sky.load()
stops=[(0.0,(14,10,40)),(0.35,(70,24,70)),(0.6,(190,60,50)),(0.78,(250,150,60)),(1.0,(255,210,120))]
col=[]
for y in range(h):
    t=y/h
    for i in range(len(stops)-1):
        if stops[i][0]<=t<=stops[i+1][0]:
            u=(t-stops[i][0])/(stops[i+1][0]-stops[i][0]); col.append(lc(stops[i][1],stops[i+1][1],u)); break
d=ImageDraw.Draw(sky)
for y in range(h): d.line([(0,y),(w,y)],fill=col[y])
img=sky.convert("RGBA")

def layer(): return Image.new("RGBA",(w,h),(0,0,0,0))
def comp(l, blur=0):
    global img
    if blur: l=l.filter(ImageFilter.GaussianBlur(blur*SS))
    img=Image.alpha_composite(img,l)

# 별
l=layer(); d=ImageDraw.Draw(l)
for _ in range(260):
    x,y=random.randint(0,w),random.randint(0,int(h*0.38)); r=random.choice([1,1,2,2,3])*SS//2+1
    a=random.randint(90,230); d.ellipse([x-r,y-r,x+r,y+r],fill=(255,245,220,a))
comp(l)

# 2) 큰 해 (뒤에서 빛나는 원) — 오른쪽
cx,cy,R=int(w*0.74),int(h*0.46),int(h*0.33)
l=layer(); d=ImageDraw.Draw(l)
for k in range(30,0,-1):
    rr=R*(1+k*0.06); a=int(5+ (30-k)*1.2)
    d.ellipse([cx-rr,cy-rr,cx+rr,cy+rr],fill=(255,190,90,a))
comp(l, blur=20)
l=layer(); d=ImageDraw.Draw(l)
d.ellipse([cx-R,cy-R,cx+R,cy+R],fill=(255,214,130,255))
d.ellipse([cx-R*0.92,cy-R*0.92,cx+R*0.92,cy+R*0.92],fill=(255,232,170,255))
comp(l, blur=2)
# 해를 가로지르는 구름 띠
l=layer(); d=ImageDraw.Draw(l)
for i,(yy,th,x0,x1) in enumerate([(0.62,16,0.58,0.96),(0.67,10,0.62,0.9)]):
    y=int(h*yy); d.rounded_rectangle([int(w*x0),y,int(w*x1),y+th*SS],radius=th*SS,fill=(150,50,70,120))
comp(l, blur=6)

# 3) 산 (먹빛, 세 겹, 사이에 안개)
def ridge(base, amp, rough, color, seed, fog=None):
    random.seed(seed)
    pts=[(0,h)]
    n=90
    hs=[]; v=0
    for i in range(n+1):
        v=v*0.9+random.uniform(-1,1)*rough*0.25
        hs.append(v)
    for i in range(n+1):
        x=w*i/n
        peak = amp*(0.5+0.5*abs(math.sin(i*0.09+seed))**1.6*math.cos(i*0.031+seed*0.3))
        y=base - peak - hs[i]*amp*0.25
        pts.append((x,y))
    pts.append((w,h))
    l=layer(); d=ImageDraw.Draw(l); d.polygon(pts,fill=color)
    comp(l)
    if fog:
        l=layer(); d=ImageDraw.Draw(l)
        for k in range(12):
            y=base-amp*0.1+k*6*SS
            d.rectangle([0,y,w,y+8*SS],fill=fog+(int(60-k*4),))
        comp(l, blur=18)
ridge(h*0.72, h*0.22, 1.2, (110,40,70,255), 3, fog=(255,170,120))
ridge(h*0.80, h*0.20, 1.0, (60,22,48,255), 11, fog=(230,120,110))
# 탑 (가까운 산 위 왼쪽) 실루엣
l=layer(); d=ImageDraw.Draw(l)
px0,py0=int(w*0.30),int(h*0.76)
for i in range(6):
    ww=(130-i*16)*SS; hh=46*SS
    y=py0-i*hh
    d.rectangle([px0-ww*0.35,y-hh*0.75,px0+ww*0.35,y],fill=(35,14,32,255))
    d.polygon([(px0-ww*0.75,y-hh*0.72),(px0+ww*0.75,y-hh*0.72),(px0+ww*0.42,y-hh),(px0-ww*0.42,y-hh)],fill=(35,14,32,255))
d.rectangle([px0-4*SS,py0-6*46*SS-50*SS,px0+4*SS,py0-6*46*SS],fill=(35,14,32,255))
comp(l)
ridge(h*0.93, h*0.14, 0.8, (24,10,24,255), 21)

# 4) 무인이 선 바위 (가운데 오른쪽)
l=layer(); d=ImageDraw.Draw(l)
rx,ry=int(w*0.78),int(h*0.9)
d.polygon([(rx-330*SS,h),(rx-250*SS,ry-30*SS),(rx-120*SS,ry-70*SS),(rx+40*SS,ry-80*SS),(rx+200*SS,ry-50*SS),(rx+320*SS,ry+10*SS),(rx+380*SS,h)],fill=(16,8,18,255))
d.line([(rx-120*SS,ry-70*SS),(rx+40*SS,ry-80*SS),(rx+200*SS,ry-50*SS)],fill=(255,170,90,180),width=4*SS)
comp(l)

# 5) 무인 (네모난 몸, 앞으로 내지르는 주먹) — 실루엣 + 금빛 테두리
def limb(d, x, y, ang, length, width, fill):
    dx,dy=math.cos(ang),math.sin(ang); nx,ny=-dy,dx
    hw=width/2
    pts=[(x+nx*hw,y+ny*hw),(x-nx*hw,y-ny*hw),(x-nx*hw+dx*length,y-ny*hw+dy*length),(x+nx*hw+dx*length,y+ny*hw+dy*length)]
    d.polygon(pts,fill=fill)
    return (x+dx*length,y+dy*length)
S=SS*1.65
fx,fy=rx-20*SS, ry-80*SS   # 발 가운데
hip=(fx+5*S, fy-112*S)
body=layer(); d=ImageDraw.Draw(body)
DARK=(12,8,16,255)
# 다리 (넓게 벌린 마보)
k1=limb(d, hip[0]-20*S, hip[1], math.radians(150), 84*S, 36*S, DARK)
limb(d, k1[0], k1[1], math.radians(100), 74*S, 31*S, DARK)
k2=limb(d, hip[0]+20*S, hip[1], math.radians(30), 84*S, 36*S, DARK)
limb(d, k2[0], k2[1], math.radians(78), 74*S, 31*S, DARK)
# 몸통 (조금 앞으로 기울임)
tilt=math.radians(-4)
cx_,cy_=hip[0]+8*S, hip[1]-62*S
tw,th=86*S,124*S
def rot(px_,py_,a,ox,oy): 
    return (ox+(px_-ox)*math.cos(a)-(py_-oy)*math.sin(a), oy+(px_-ox)*math.sin(a)+(py_-oy)*math.cos(a))
corners=[(cx_-tw/2,cy_-th/2),(cx_+tw/2,cy_-th/2),(cx_+tw/2,cy_+th/2),(cx_-tw/2,cy_+th/2)]
d.polygon([rot(x,y,tilt,cx_,cy_) for x,y in corners],fill=DARK)
# 머리
hx,hy=rot(cx_+6*S,cy_-th/2-36*S,tilt,cx_,cy_)
d.rectangle([hx-30*S,hy-32*S,hx+30*S,hy+32*S],fill=DARK)
# 어깨
shL=rot(cx_-tw/2+6*S,cy_-th/2+18*S,tilt,cx_,cy_)
shR=rot(cx_+tw/2-6*S,cy_-th/2+18*S,tilt,cx_,cy_)
# 뒤 팔 (허리로 당긴 주먹)
e=limb(d, shR[0], shR[1], math.radians(70), 60*S, 28*S, DARK)
limb(d, e[0], e[1], math.radians(170), 46*S, 26*S, DARK)
# 앞 팔: 왼쪽 (화면 왼쪽)으로 쭉 내지른다
e=limb(d, shL[0]+6*S, shL[1]+4*S, math.radians(181), 70*S, 30*S, DARK)
fist=limb(d, e[0], e[1], math.radians(180), 66*S, 28*S, DARK)
d.rectangle([fist[0]-20*S,fist[1]-20*S,fist[0]+12*S,fist[1]+20*S],fill=DARK)
# 테두리 빛 (금빛 rim): 몸 알파를 넓혀 빼기
a=body.split()[3]
rim=a.filter(ImageFilter.MaxFilter(9)); rim=ImageChops.subtract(rim,a)
rimL=Image.new("RGBA",(w,h),(255,200,110,0)); rimL.putalpha(rim)
glow=a.filter(ImageFilter.GaussianBlur(26*SS))
gL=Image.new("RGBA",(w,h),(255,150,70,0)); gL.putalpha(glow.point(lambda v:int(v*0.8)))
comp(gL)
# 띠 (붉은 허리띠와 흩날리는 머리띠)
dd=ImageDraw.Draw(body)
wa=rot(cx_-tw/2,cy_+th/2-26*S,tilt,cx_,cy_); wb=rot(cx_+tw/2,cy_+th/2-26*S,tilt,cx_,cy_)
dd.line([wa,wb],fill=(200,30,40,255),width=int(14*S))
for k in range(2):
    pts=[(hx+28*S, hy-14*S+k*10*S)]
    for i in range(1,8):
        pts.append((hx+28*S+i*26*S, hy-14*S+k*10*S+math.sin(i*0.9+k)*14*S+i*4*S))
    dd.line(pts,fill=(210,35,45,255),width=int(9*S))
    tail=pts
for k in range(2):
    pts=[(wb[0]-4*S, wb[1]+k*8*S)]
    for i in range(1,7):
        pts.append((wb[0]-4*S+i*24*S, wb[1]+k*8*S+math.sin(i*0.8+k*1.3)*12*S+i*6*S))
    dd.line(pts,fill=(200,30,40,255),width=int(10*S))
comp(body)
comp(rimL)

# 6) 주먹 끝의 기운 폭발: 빛줄기 + 충격파 고리 + 불티
fxp=(fist[0]-24*S, fist[1])
l=layer(); d=ImageDraw.Draw(l)
for i in range(28):
    a=random.uniform(0,math.pi*2); L=random.uniform(120,330)*SS; wdt=random.uniform(4,12)*SS
    x2,y2=fxp[0]+math.cos(a)*L, fxp[1]+math.sin(a)*L*0.65
    d.line([fxp,(x2,y2)],fill=(255,230,150,random.randint(60,140)),width=int(wdt))
comp(l, blur=3)
l=layer(); d=ImageDraw.Draw(l)
for k,(rx_,a_) in enumerate([(90,220),(150,170),(220,120),(300,70)]):
    rr=rx_*SS
    d.ellipse([fxp[0]-rr*0.45,fxp[1]-rr,fxp[0]+rr*0.45,fxp[1]+rr],outline=(255,225,150,a_),width=int((10-k*2)*SS))
comp(l, blur=2)
l=layer(); d=ImageDraw.Draw(l)
for r_,a_ in [(140,60),(90,120),(54,200),(30,255)]:
    rr=r_*SS; d.ellipse([fxp[0]-rr,fxp[1]-rr,fxp[0]+rr,fxp[1]+rr],fill=(255,240,200,a_))
comp(l, blur=10)
l=layer(); d=ImageDraw.Draw(l)
for _ in range(120):
    a=random.uniform(0,math.pi*2); L=random.uniform(50,380)*SS
    x,y=fxp[0]+math.cos(a)*L, fxp[1]+math.sin(a)*L*0.7; r=random.uniform(2,6)*SS
    d.ellipse([x-r,y-r,x+r,y+r],fill=(255,random.randint(170,240),110,random.randint(120,255)))
comp(l)

# 7) 꽃잎 흩날림
l=layer(); d=ImageDraw.Draw(l)
for _ in range(70):
    x,y=random.uniform(0,w),random.uniform(0,h); s=random.uniform(6,14)*SS; a=random.uniform(0,math.pi)
    pts=[(x+math.cos(a)*s,y+math.sin(a)*s*0.5),(x+math.cos(a+math.pi/2)*s*0.45,y+math.sin(a+math.pi/2)*s*0.3),(x-math.cos(a)*s,y-math.sin(a)*s*0.5),(x-math.cos(a+math.pi/2)*s*0.45,y-math.sin(a+math.pi/2)*s*0.3)]
    d.polygon(pts,fill=(255,random.randint(150,200),random.randint(190,220),random.randint(150,230)))
comp(l)

# 8) 왼쪽 어둡게 (글씨 자리) + 가장자리 비네트
l=layer(); d=ImageDraw.Draw(l)
for x in range(0,int(w*0.55),4):
    a=int(170*(1-x/(w*0.55))**1.6)
    d.rectangle([x,0,x+4,h],fill=(8,4,14,a))
comp(l)
vig=Image.new("L",(w,h),0); dv=ImageDraw.Draw(vig)
dv.ellipse([-w*0.15,-h*0.25,w*1.15,h*1.25],fill=255); vig=vig.filter(ImageFilter.GaussianBlur(120*SS))
dark=Image.new("RGBA",(w,h),(0,0,0,255)); dark.putalpha(vig.point(lambda v:int((255-v)*0.75)))
comp(dark)

# 9) 제목
def text_block(txt, font, x, y, fill_top, fill_bot, stroke, glow_col):
    global img
    m=Image.new("L",(w,h),0); dm=ImageDraw.Draw(m)
    dm.text((x,y),txt,font=font,fill=255)
    bbox=m.getbbox()
    # 바깥 빛
    gl=m.filter(ImageFilter.MaxFilter(15)).filter(ImageFilter.GaussianBlur(22*SS))
    g=Image.new("RGBA",(w,h),glow_col+(0,)); g.putalpha(gl.point(lambda v:int(v*0.85))); img=Image.alpha_composite(img,g)
    # 두꺼운 테
    st=m.filter(ImageFilter.MaxFilter(stroke*2+1))
    s=Image.new("RGBA",(w,h),(20,8,10,255)); s.putalpha(st); img=Image.alpha_composite(img,s)
    # 위→아래 빛깔
    grad=Image.new("RGBA",(w,h)); gd=ImageDraw.Draw(grad)
    y0,y1=bbox[1],bbox[3]
    for yy in range(y0,y1+1):
        t=(yy-y0)/max(1,y1-y0); gd.line([(bbox[0],yy),(bbox[2],yy)],fill=lc(fill_top,fill_bot,t)+(255,))
    grad.putalpha(ImageChops.multiply(grad.split()[3], m)); img=Image.alpha_composite(img,grad)
    # 윗부분 빛 줄
    hl=Image.new("RGBA",(w,h),(255,255,240,0)); hm=m.copy(); hd=ImageDraw.Draw(hm)
    hd.rectangle([0,0,w,int(y0+(y1-y0)*0.45)],fill=0) if False else None
    return bbox
F1=ImageFont.truetype(BOLD, 128*SS)
F2=ImageFont.truetype(BOLD, 172*SS)
F3=ImageFont.truetype(KO, 64*SS)
F4=ImageFont.truetype(KO, 40*SS)
X0=90*SS
b1=text_block("MARTIAL ARTS", F1, X0, 130*SS, (255,250,225),(255,196,90), 9*SS, (255,140,40))
b2=text_block("SUPREME", F2, X0-6*SS, b1[3]+10*SS, (255,236,150),(230,120,30), 11*SS, (255,90,30))
# 한글 부제 (붉은 띠 위에)
l=layer(); d=ImageDraw.Draw(l)
by=b2[3]+50*SS
d.polygon([(X0-10*SS,by),(X0+700*SS,by),(X0+660*SS,by+96*SS),(X0-10*SS,by+96*SS)],fill=(170,20,30,235))
d.line([(X0-10*SS,by),(X0+700*SS,by)],fill=(255,210,120,255),width=4*SS)
d.line([(X0-10*SS,by+96*SS),(X0+660*SS,by+96*SS)],fill=(255,210,120,255),width=4*SS)
comp(l)
d=ImageDraw.Draw(img)
d.text((X0+30*SS,by+10*SS),"권왕 · 맨손의 강호",font=F3,fill=(255,245,225,255),stroke_width=3*SS,stroke_fill=(60,0,0,255))
# 아래 특징 세 줄 (작은 띠)
feats=["🥋"]  # (그림 글자는 글꼴에 없을 수 있어 글로만)
items=["권법 49가지","보스 · 레이드","배틀그라운드"]
fy0=by+140*SS
xx=X0
for it in items:
    tw_=d.textlength(it,font=F4)
    d.rounded_rectangle([xx,fy0,xx+tw_+48*SS,fy0+70*SS],radius=14*SS,fill=(20,10,24,210),outline=(255,200,110,255),width=3*SS)
    d.text((xx+24*SS,fy0+12*SS),it,font=F4,fill=(255,230,180,255))
    xx+=tw_+70*SS

out=img.convert("RGB").resize((W,H),Image.LANCZOS)
out.save("/home/user/my-web-apps/kwonwang/thumbnail/thumbnail_1920x1080.png")
print("ok")
