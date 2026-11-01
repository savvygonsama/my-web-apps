import math, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageChops
random.seed(3)
W,H=1920,1080; SS=2; w,h=W*SS,H*SS

def lc(a,b,t): return tuple(int(a[i]+(b[i]-a[i])*t) for i in range(len(a)))
def layer(): return Image.new("RGBA",(w,h),(0,0,0,0))
img=None
def comp(l,blur=0):
    global img
    if blur: l=l.filter(ImageFilter.GaussianBlur(blur*SS))
    img=Image.alpha_composite(img,l)
def solid(mask,color,alpha=1.0):
    l=Image.new("RGBA",(w,h),color+(0,)); l.putalpha(mask.point(lambda v:int(v*alpha))); return l

# ---------------- 하늘 ----------------
ys=np.linspace(0,1,h)[:,None]
top=np.array([8,12,30]); mid=np.array([28,34,70]); low=np.array([150,70,60]); hor=np.array([235,150,90])
c=np.where(ys<0.45, top+(mid-top)*(ys/0.45), np.where(ys<0.75, mid+(low-mid)*((ys-0.45)/0.3), low+(hor-low)*np.clip((ys-0.75)/0.25,0,1)))
sky=np.repeat(c[:, None, :], w, axis=1).reshape(h,w,3).astype(np.uint8)
img=Image.fromarray(sky,"RGB").convert("RGBA")
# 별
l=layer(); d=ImageDraw.Draw(l)
for _ in range(500):
    x,y=random.uniform(0,w),random.uniform(0,h*0.5); r=random.choice([1,1,1,2,2,3])
    d.ellipse([x-r,y-r,x+r,y+r],fill=(235,240,255,random.randint(60,220)))
comp(l)
# 달 (인물 뒤, 위)
MX,MY,MR=w*0.60,h*0.40,h*0.36
l=layer(); d=ImageDraw.Draw(l)
for k in range(40,0,-1):
    rr=MR*(1+k*0.05); d.ellipse([MX-rr,MY-rr,MX+rr,MY+rr],fill=(255,200,140,int(3+(40-k)*0.9)))
comp(l,blur=30)
moon=layer(); d=ImageDraw.Draw(moon)
d.ellipse([MX-MR,MY-MR,MX+MR,MY+MR],fill=(255,236,200,255))
comp(moon,blur=1.5)
# 달의 무늬 (아주 옅게)
l=layer(); d=ImageDraw.Draw(l)
pass
comp(l,blur=8)
# 달 앞을 지나는 얇은 구름
l=layer(); d=ImageDraw.Draw(l)
for (yy,th,x0,x1,a) in []:
    d.rounded_rectangle([w*x0,h*yy,w*x1,h*yy+th*SS],radius=th*SS,fill=(60,40,70,a))
comp(l,blur=5)

# ---------------- 먹빛 산과 안개 ----------------
def ridge(base,amp,color,seed,freq=1.0,blur=0):
    rnd=random.Random(seed)
    xs=np.linspace(0,w,400)
    y=np.zeros_like(xs)
    for k in range(1,6):
        y+=amp/(k**1.3)*np.sin(xs/w*math.pi*(1.2*k*freq)+rnd.uniform(0,6.28))
    y=base-np.abs(y)
    pts=[(0,h)]+list(zip(xs,y))+[(w,h)]
    l=layer(); ImageDraw.Draw(l).polygon(pts,fill=color); comp(l,blur)
def mist(y0,height,color,alpha,blur):
    l=layer(); d=ImageDraw.Draw(l)
    d.rectangle([0,y0,w,y0+height],fill=color+(alpha,)); comp(l,blur)
ridge(h*0.70,h*0.20,(70,48,82,255),1,0.8,blur=2)
mist(h*0.66,h*0.08,(200,140,140),70,40)
ridge(h*0.80,h*0.17,(42,28,54,255),5,1.1,blur=1)
mist(h*0.78,h*0.06,(180,110,120),60,36)
ridge(h*0.90,h*0.10,(22,14,30,255),9,1.4)

# ---------------- 인물 ----------------
# 뼈대 (인물 좌표: 1000 = 키, y 아래로, 바닥 y=1000, 왼쪽을 본다)
S=(H*0.80*SS)/1000.0
OX=w*0.60-560*S; OY=h*0.935-1000*S
def P(x,y): return (OX+x*S, OY+y*S)
fig=layer(); fd=ImageDraw.Draw(fig)
BODY=(14,11,20,255)
def capsule(a,b,r1,r2,fill=BODY,dr=fd):
    ax,ay=P(*a); bx,by=P(*b); r1*=S; r2*=S
    dx,dy=bx-ax,by-ay; L=math.hypot(dx,dy) or 1; nx,ny=-dy/L,dx/L
    dr.polygon([(ax+nx*r1,ay+ny*r1),(bx+nx*r2,by+ny*r2),(bx-nx*r2,by-ny*r2),(ax-nx*r1,ay-ny*r1)],fill=fill)
    dr.ellipse([ax-r1,ay-r1,ax+r1,ay+r1],fill=fill); dr.ellipse([bx-r2,by-r2,bx+r2,by+r2],fill=fill)
def bez(pts,n=40):
    out=[]
    for i in range(n+1):
        t=i/n; q=list(pts)
        while len(q)>1: q=[(q[j][0]+(q[j+1][0]-q[j][0])*t, q[j][1]+(q[j+1][1]-q[j][1])*t) for j in range(len(q)-1)]
        out.append(q[0])
    return out
def poly(pts,fill=BODY,dr=fd): dr.polygon([P(*p) for p in pts],fill=fill)
def ribbon(path,w0,w1,fill=BODY,dr=fd,n=50):
    # 굵기가 줄어드는 휘날리는 띠
    pts=bez(path,n); L=[];R=[]
    for i,(x,y) in enumerate(pts):
        j=min(i+1,len(pts)-1); k=max(i-1,0)
        dx,dy=pts[j][0]-pts[k][0],pts[j][1]-pts[k][1]; m=math.hypot(dx,dy) or 1
        t=i/(len(pts)-1); ww=(w0+(w1-w0)*t)/2
        L.append((x-dy/m*ww,y+dx/m*ww)); R.append((x+dy/m*ww,y-dx/m*ww))
    poly(L+R[::-1],fill,dr)

def wave(start, length, amp, waves, drop, n=60, phase=0.0, w0=30, w1=6, fill=BODY, dr=None):
    x0,y0=start; pts=[]
    for i in range(n+1):
        t=i/n
        pts.append((x0+length*t, y0+drop*t*t+amp*t*math.sin(t*waves*math.pi*2+phase)))
    L=[];R=[]
    for i,(x,y) in enumerate(pts):
        j=min(i+1,n); k=max(i-1,0)
        dx,dy=pts[j][0]-pts[k][0],pts[j][1]-pts[k][1]; m=math.hypot(dx,dy) or 1
        t=i/n; ww=(w0+(w1-w0)*t)/2*(1+0.25*math.sin(t*waves*math.pi*2+phase+1.3))
        L.append((x-dy/m*ww,y+dx/m*ww)); R.append((x+dy/m*ww,y-dx/m*ww))
    poly(L+R[::-1],fill,dr or fd)
# 빨간 천은 따로 그린다 (테두리 빛이 덮지 않게)
cloth=layer(); cd=ImageDraw.Draw(cloth)
RED1=(170,24,32,255); RED2=(128,16,24,255)
# --- 뒤 팔 (허리로 당긴 주먹, 팔꿈치가 뒤로) : 몸통보다 먼저
capsule((572,332),(660,418),31,26); capsule((660,418),(610,468),25,21)
fd.ellipse([P(578,446)[0],P(578,446)[1],P(632,496)[0],P(632,496)[1]],fill=BODY)
# --- 뒤 다리 (오른쪽으로 곧게 뻗었다)
capsule((598,585),(722,772),58,40); capsule((722,772),(828,952),40,27)
capsule((812,935),(840,958),28,27)
poly([(810,950),(872,958),(925,988),(925,1000),(806,1000)])
# --- 앞 다리 (왼쪽으로 깊이 굽혔다)
capsule((528,585),(392,705),60,44); capsule((392,705),(352,948),42,28)
capsule((344,935),(358,962),29,27)
poly([(296,952),(366,948),(374,1000),(232,1000),(240,986)])
# --- 몸통: 넓은 등과 어깨, 가슴에서 허리로 좁아진다 (조금 앞으로 기울었다)
poly(bez([(520,296),(600,300),(612,330)],8)+bez([(612,330),(622,420),(600,500),(618,585)],18)
     +bez([(618,585),(560,598),(505,585)],8)+bez([(505,585),(488,520),(478,450),(452,392),(456,340)],18)
     +bez([(456,340),(470,312),(520,296)],8))
# 어깨 덩어리 (앞 어깨)
fd.ellipse([P(456,306)[0],P(456,306)[1],P(536,372)[0],P(536,372)[1]],fill=BODY)
# --- 웃옷 자락: 허리 아래로 퍼지며 뒤로 날린다
poly(bez([(500,560),(478,620),(466,660),(476,690)],12)+bez([(476,690),(540,705),(610,690),(690,712),(760,688)],22)+bez([(760,688),(690,640),(650,590),(626,560)],12))
# --- 앞 팔 (내지른 주먹): 어깨 → 팔꿈치 → 손목, 굵은 팔
capsule((498,336),(392,330),32,25); capsule((392,330),(292,326),25,21)
fd.rounded_rectangle([P(240,302)[0],P(240,302)[1],P(300,352)[0],P(300,352)[1]],radius=12*S,fill=BODY)
capsule((252,304),(290,302),7,7)
# 소매 (위팔에 걸친 펄럭이는 천)
poly(bez([(520,318),(470,306),(430,312),(410,334),(436,356),(500,362)],20))
# --- 목과 머리 (옆얼굴, 왼쪽을 본다)
capsule((528,304),(514,262),27,25)
poly(bez([(555,230),(556,180),(515,168),(482,182)],14)+bez([(482,182),(468,205),(466,222),(456,240),(470,246),(466,260),(478,272),(472,282),(500,290),(540,280),(556,256)],30))
fd.ellipse([P(520,150)[0],P(520,150)[1],P(562,190)[0],P(562,190)[1]],fill=BODY)    # 상투
# --- 빨간 천: 머리끈 · 허리띠 · 꼬리들 (바람에 오른쪽으로)
capsule((478,192),(556,186),8,8,fill=RED1,dr=cd)
wave((552,188),330,26,1.6,-20,phase=0.3,w0=18,w1=4,fill=RED1,dr=cd)
wave((552,194),240,22,1.3,30,phase=2.0,w0=14,w1=3,fill=RED2,dr=cd)
capsule((496,556),(620,574),19,19,fill=RED1,dr=cd)
wave((616,566),420,40,1.7,10,phase=0.0,w0=32,w1=8,fill=RED1,dr=cd)
wave((616,578),360,34,1.4,80,phase=2.4,w0=26,w1=6,fill=RED2,dr=cd)
# 꽁지머리 (상투에서 바람에)
wave((556,170),250,18,1.2,-6,phase=1.0,w0=26,w1=3)

# 몸 알파와 테두리 빛 (달빛: 뒤 오른쪽 위 / 기운: 앞 왼쪽)
A=fig.split()[3]
def shifted(m,dx,dy): return ImageChops.offset(m,int(dx),int(dy))
rimR=ImageChops.subtract(A,shifted(A,-4*SS,3*SS)).filter(ImageFilter.GaussianBlur(0.8*SS))
rimL=ImageChops.subtract(A,shifted(A,4*SS,1*SS)).filter(ImageFilter.GaussianBlur(0.9*SS))
halo=A.filter(ImageFilter.GaussianBlur(26*SS))
comp(solid(halo,(255,200,140),0.45))
grad=np.linspace(0,1,h)[:,None]
bd=np.zeros((h,w,4),np.uint8)
bd[...,0]=np.broadcast_to((24-12*grad),(h,w)).astype(np.uint8); bd[...,1]=np.broadcast_to((19-9*grad),(h,w)).astype(np.uint8); bd[...,2]=np.broadcast_to((32-14*grad),(h,w)).astype(np.uint8); bd[...,3]=255
body=Image.fromarray(bd,"RGBA"); body.putalpha(A)
img=Image.alpha_composite(img,body)
# 근육·옷 결 (몸 안쪽의 아주 옅은 선)
fold=layer(); fdd=ImageDraw.Draw(fold)
for path,wd in [([(565,600),(530,650),(486,688)],3),([(605,600),(650,650),(705,692)],3),([(470,612),(430,650),(405,700)],3),([(650,610),(700,700),(735,770)],3),
                ([(470,360),(500,400),(540,410)],2),([(498,430),(530,470),(560,480)],2),([(420,330),(404,332),(392,330)],2),([(330,320),(340,326)],2)]:
    pts=[P(*p) for p in bez(path,16)]; fdd.line(pts,fill=(44,34,58,220),width=int(wd*SS))
fold.putalpha(ImageChops.multiply(fold.split()[3],A))
comp(fold)
comp(solid(rimR,(255,228,180),0.95))
comp(solid(rimL,(170,220,255),0.75))
# 빨간 천과 그 위의 얇은 빛
CA=cloth.split()[3]
comp(cloth)
crim=ImageChops.subtract(CA,shifted(CA,-3*SS,3*SS)).filter(ImageFilter.GaussianBlur(0.7*SS))
comp(solid(crim,(255,170,150),0.8))
# 눈빛
ex,ey=P(478,222); l=layer(); d=ImageDraw.Draw(l); d.ellipse([ex-4*SS,ey-2*SS,ex+4*SS,ey+2*SS],fill=(210,240,255,255)); comp(l)
l=layer(); d=ImageDraw.Draw(l); d.ellipse([ex-14*SS,ey-8*SS,ex+14*SS,ey+8*SS],fill=(150,210,255,110)); comp(l,blur=4)

# ---------------- 주먹 끝의 기운 ----------------
FX,FY=P(232,327)
CY=(150,215,255); GD=(255,230,170)
# 공기가 찢어지는 원뿔 (주먹 앞쪽으로 퍼지는 충격파 고리, 옆에서 본 타원)
for k,(dist,ry,a,wd) in enumerate([(40,90,230,9),(120,170,170,7),(230,250,120,5),(370,330,70,4)]):
    l=layer(); d=ImageDraw.Draw(l)
    x=FX-dist*SS; rx=ry*0.28*SS; ryy=ry*SS
    d.ellipse([x-rx,FY-ryy,x+rx,FY+ryy],outline=CY+(a,),width=int(wd*SS))
    comp(l,blur=1.5)
# 빛줄기 (주먹에서 앞쪽 부채꼴로)
l=layer(); d=ImageDraw.Draw(l)
for _ in range(60):
    ang=math.pi+random.uniform(-0.55,0.55); L=random.uniform(150,700)*SS; st=random.uniform(10,60)*SS
    x0,y0=FX+math.cos(ang)*st,FY+math.sin(ang)*st; x1,y1=FX+math.cos(ang)*L,FY+math.sin(ang)*L
    d.line([(x0,y0),(x1,y1)],fill=(lc(CY,(255,255,255),random.random()))+(random.randint(40,150),),width=int(random.uniform(1.5,4)*SS))
comp(l,blur=1)
# 빛 덩어리
l=layer(); d=ImageDraw.Draw(l)
for r,a in [(220,40),(140,70),(80,140),(44,230),(22,255)]:
    d.ellipse([FX-r*SS,FY-r*SS*0.85,FX+r*SS,FY+r*SS*0.85],fill=(lc(CY,(255,255,255),1-r/220))+(a,))
comp(l,blur=12)
# 불티
l=layer(); d=ImageDraw.Draw(l)
for _ in range(160):
    ang=math.pi+random.uniform(-0.9,0.9); L=random.uniform(30,620)*SS
    x,y=FX+math.cos(ang)*L,FY+math.sin(ang)*L*0.8; r=random.uniform(1.5,4.5)*SS
    d.ellipse([x-r,y-r,x+r,y+r],fill=(lc(CY,GD,random.random()))+(random.randint(120,255),))
comp(l)
# 앞 땅에 튀는 돌가루와 바람 결
l=layer(); d=ImageDraw.Draw(l)
gy=OY+990*S
for _ in range(40):
    x=random.uniform(OX+150*S,OX+900*S); y=gy+random.uniform(-6,6)*SS
    d.line([(x,y),(x+random.uniform(60,220)*SS,y-random.uniform(0,10)*SS)],fill=(220,200,190,random.randint(30,90)),width=int(2*SS))
comp(l,blur=2)

# ---------------- 바위 (발밑) ----------------
l=layer(); d=ImageDraw.Draw(l)
gx0,gx1=OX+120*S,OX+1000*S
d.polygon([(gx0-200*SS,h),(gx0,gy+4*SS),(gx0+300*S,gy-6*S),(gx0+650*S,gy-2*S),(gx1,gy+10*S),(gx1+260*SS,h)],fill=(10,7,14,255))
comp(l)
l=layer(); d=ImageDraw.Draw(l)
d.line([(gx0,gy+4*SS),(gx0+300*S,gy-6*S),(gx0+650*S,gy-2*S),(gx1,gy+10*S)],fill=(255,210,160,140),width=int(3*SS))
comp(l,blur=1)

# ---------------- 꽃잎 (가까운 것은 흐리게 크게) ----------------
for depth in [0,1]:
    l=layer(); d=ImageDraw.Draw(l)
    for _ in range(40 if depth==0 else 10):
        x,y=random.uniform(0,w),random.uniform(0,h)
        if depth==1:
            # 크고 흐린 꽃잎은 가장자리에만 (달 위의 얼룩이 되지 않게)
            x=random.choice([random.uniform(0,w*0.12),random.uniform(w*0.9,w)]); y=random.uniform(h*0.55,h)
        elif (x-MX)**2+(y-MY)**2 < (MR*1.05)**2:
            continue
        s=(random.uniform(6,12) if depth==0 else random.uniform(26,46))*SS; a=random.uniform(0,6.28)
        pts=[(x+math.cos(a)*s,y+math.sin(a)*s*0.45),(x+math.cos(a+1.57)*s*0.42,y+math.sin(a+1.57)*s*0.3),(x-math.cos(a)*s,y-math.sin(a)*s*0.45),(x-math.cos(a+1.57)*s*0.42,y-math.sin(a+1.57)*s*0.3)]
        d.polygon(pts,fill=(255,random.randint(170,205),random.randint(195,225),random.randint(150,230) if depth==0 else 140))
    comp(l,blur=0 if depth==0 else 7)

# ---------------- 마감: 비네트 · 결 ----------------
vig=Image.new("L",(w,h),0); dv=ImageDraw.Draw(vig)
dv.ellipse([-w*0.1,-h*0.2,w*1.1,h*1.2],fill=255); vig=vig.filter(ImageFilter.GaussianBlur(160*SS))
dark=Image.new("RGBA",(w,h),(0,0,0,255)); dark.putalpha(vig.point(lambda v:int((255-v)*0.8))); comp(dark)
out=img.convert("RGB").resize((W,H),Image.LANCZOS)
noise=np.random.default_rng(1).normal(0,3.2,(H,W,1))
arr=np.clip(np.array(out).astype(np.float32)+noise,0,255).astype(np.uint8)
Image.fromarray(arr).save("/home/user/my-web-apps/kwonwang/thumbnail/thumbnail_1920x1080.png")
print("ok")
