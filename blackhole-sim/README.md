# 🕳 BLACK HOLE (블랙홀 시뮬레이터, 베타)

로블록스용 시뮬레이터 게임입니다. 내가 작은 블랙홀이 되어 돌아다니면, 내 크기보다 작은 건 전부 소용돌이치며 빨려 들어옵니다.
삼킨 만큼 질량이 쌓이고, 질량으로 몸집을 키워 돌멩이에서 시작해 자동차, 빌딩, 산, 마지막엔 행성과 태양까지 삼킵니다.

## 바로 해 보기

### 방법 1. 게임 파일 열기 (가장 쉬움)

1. 이 폴더의 [`blackhole-sim.rbxlx`](blackhole-sim.rbxlx)를 엽니다
2. 오른쪽 위 **Download raw file** 버튼으로 내려받습니다
3. 내려받은 파일을 더블클릭하면 로블록스 스튜디오에서 열립니다
4. 위쪽 **Play** 버튼(▶)을 누르면 바로 시작됩니다

### 방법 2. 스크립트 직접 붙여 넣기

스튜디오에서 **Baseplate** 템플릿으로 새 게임을 만든 다음, 아래 여섯 개를 만들고 내용을 그대로 붙여 넣습니다.
"안에"라고 적힌 것은 그 스크립트를 오른쪽 클릭해서 그 아래에 만듭니다.

| 넣을 곳 (탐색기 창) | 만들 것 | 이름 | 붙여 넣을 파일 |
|---|---|---|---|
| ReplicatedStorage | ModuleScript | `Config` | [`src/shared/Config.lua`](src/shared/Config.lua) |
| ReplicatedStorage | ModuleScript | `Props` | [`src/shared/Props.lua`](src/shared/Props.lua) |
| ServerScriptService | Script | `HoleServer` | [`src/server/HoleServer/init.server.lua`](src/server/HoleServer/init.server.lua) |
| `HoleServer` 안에 | ModuleScript | `World` | [`src/server/HoleServer/World.lua`](src/server/HoleServer/World.lua) |
| StarterPlayer → StarterPlayerScripts | LocalScript | `HoleClient` | [`src/client/HoleClient/init.client.lua`](src/client/HoleClient/init.client.lua) |
| `HoleClient` 안에 | ModuleScript | `Fx` | [`src/client/HoleClient/Fx.lua`](src/client/HoleClient/Fx.lua) |

맵, 물체, 조명, 화면 UI는 스크립트가 알아서 만듭니다. Baseplate는 스크립트가 지우고 구역 바닥을 깝니다.

### 🧪 테스트 계정

스튜디오에서 ▶ Play로 들어가거나, 게임을 올린 뒤 **게임 주인**으로 들어가면 테스트 계정이 됩니다.
왼쪽 **🧪 테스트** 창에서 질량 받기(+1K ~ +1T), 크기 레벨 바로 정하기, 모든 업그레이드 최대, 처음으로 되돌리기를 쓸 수 있습니다.
테스트 계정의 기록은 저장하지 않습니다. 정식 공개 전에는 [`Config.lua`](src/shared/Config.lua)의 `Config.TEST_MODE`를 `false`로 바꾸세요.

### 저장 기능 켜기

저장은 로블록스 서버(DataStore)를 씁니다. 스튜디오에서 저장까지 확인하려면 **File → Publish to Roblox**로 한 번 올린 뒤
**Home → Game Settings → Security**에서 **Enable Studio Access to API Services**를 켜세요.

## 하는 법

| | PC | 휴대폰 |
|---|---|---|
| 이동 | WASD | 왼쪽 조이스틱 |
| 빅뱅 창 | B | 🌌 버튼 |
| 구역 이동 창 | M | 🗺 버튼 |

- 돌아다니기만 하면 됩니다. 내 크기(반지름)보다 작은 물체가 흡입 범위 안에 들어오면 자동으로 빨려 들어옵니다
- 너무 큰 물체는 **빨간 테두리**가 쳐지고, 화면 아래에 필요한 크기가 뜹니다
- 1.5초 안에 계속 삼키면 **연속 흡수** 숫자가 올라갑니다
- 커질수록 빨라지고, 카메라가 멀어져서 큰 세상이 한눈에 보입니다

## 업그레이드 (오른쪽 카드)

| 업그레이드 | 효과 | 최대 |
|---|---|---|
| ⚫ 크기 | 반지름 = 1.5 × 1.1^레벨. 더 큰 것을 삼킨다 | 57 (반지름 약 340) |
| 🌀 흡입력 | 반지름 바깥까지 끌어당긴다 | 15 |
| 💠 질량 배율 | 삼킬 때 얻는 질량 레벨당 +20% | 40 |

**최대** 버튼은 질량이 되는 만큼 한 번에 올립니다.

## 구역 6개

보라색 벽은 크기가 되면 초록색으로 바뀌며 통과됩니다. 괄호 안은 삼키는 데 필요한 크기입니다.

| 구역 | 들어가는 크기 | 물체 |
|---|---|---|
| 1 공원 | 처음부터 | 돌멩이(0.8), 꽃(0.9), 축구공(1.2), 쓰레기통(1.8), 벤치(2.6), 덤불(2.8), 작은 나무(3) |
| 2 마을 | 6 | 우체통(3.5), 자전거(4), 가로등(4.6), 자동차(6), 큰 나무(7), 오두막(9) |
| 3 도시 | 14 | 트럭(11), 버스(13), 집(15), 가게(18), 분수대(20) |
| 4 대도시 | 30 | 빌딩(26), 타워(32), 경기장(38), 대관람차(42) |
| 5 바다와 산 | 65 | 배(55), 등대(60), 섬(75), 산(90) |
| 6 우주 | 140 | 인공위성(115), 소행성(140), 달(180), 행성(240), 태양(320) |

삼킨 물체는 구역마다 10~35초 뒤 같은 자리에 다시 생깁니다. 자동차·집·행성 색은 자리마다 다릅니다.

## 🌌 빅뱅

크기 레벨 48(반지름 약 145)이 되면 빅뱅할 수 있습니다. 질량과 업그레이드가 모두 사라지는 대신
**질량 배율이 영구히 +100%** 오르고 블랙홀 색이 바뀝니다.

보랏빛 블랙홀 → 푸른 퀘이사 → 붉은 거성 → 황금 특이점 → 초록 성운 → 무지개 우주

## 연출

- 블랙홀: 검은 구멍, 어두운 원반, 숨 쉬듯 빛나는 테두리, 도는 소용돌이 팔 세 개, 빠르게 도는 강착 원반, 안으로 빨려 드는 빛 알갱이
- 삼키기: 물체가 조각조각 소용돌이치며 작아져 구멍 속으로 사라지고, "+질량" 숫자가 떠오름. 내 크기에 가까운 큰 것을 삼키면 터지는 빛과 묵직한 소리
- 커질 때 퍼지는 빛 고리, 새 구역에 들어가면 큰 배너, 빅뱅 때 하늘까지 닿는 빛기둥과 무지개 고리

## 파일 구성

```
blackhole-sim/
├── blackhole-sim.rbxlx            스튜디오에서 바로 여는 게임 파일
├── default.project.json           Rojo 프로젝트 설정
└── src/
    ├── shared/
    │   ├── Config.lua             수치: 업그레이드, 구역, 물체 31종, 빅뱅
    │   └── Props.lua              물체 31종의 모양
    ├── server/HoleServer/
    │   ├── init.server.lua        삼키기 판정, 질량, 업그레이드, 빅뱅, 저장
    │   └── World.lua              조명, 구역 바닥과 벽, 문, 물체 배치
    └── client/HoleClient/
        ├── init.client.lua        화면 UI, 카메라, 문 통과, 너무 큰 물체 표시
        └── Fx.lua                 블랙홀 모양, 빨려 드는 연출, 숫자, 효과음
```

밸런스는 [`Config.lua`](src/shared/Config.lua) 한 파일에 있습니다.
`src`를 고친 뒤 게임 파일을 다시 만들려면 [Rojo](https://rojo.space)로 `rojo build default.project.json -o blackhole-sim.rbxlx`를 실행합니다.

## 다음에 넣을 것

- 다른 플레이어 블랙홀 삼키기 (크기가 훨씬 크면)
- 펫 위성: 블랙홀 둘레를 도는 작은 위성이 대신 삼켜 줌
- 일일 퀘스트, 전체 서버 순위
