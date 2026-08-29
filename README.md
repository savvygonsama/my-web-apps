# my-web-apps

혼자 쓰려고, 또 팀원들과 같이 쓰려고 만든 웹앱 모음입니다.
전부 **HTML 파일 하나로 끝나는 앱**입니다. 설치도 서버도 필요 없고, 파일을 내려받아
브라우저로 열면 바로 돌아갑니다. 인터넷이 끊겨도 동작합니다.

## 앱 목록

| 앱 | 무엇을 하는가 | 폴더 |
|---|---|---|
| 🚂 **자정 열차** | 선택으로 이야기를 만들어가는 인터랙티브 소설. 장면 65개, 결말 11개(숨은 결말 1개) | [`midnight-train/`](midnight-train/) |
| 🏭 **스틸링고 Lite** | 철강·자동차 업계 일본어 입문. 생활 소재로 가볍게 시작 | [`steel-lingo/lite/`](steel-lingo/lite/) |
| 🏭 **스틸링고 Pro** | 철강·자동차 업계 실무 일본어 훈련. 용어·예문·기사 독해·상담 회화·퀴즈 | [`steel-lingo/pro/`](steel-lingo/pro/) |
| 📖 **ことば日和** | 일본어 어휘 확장. `index.html`은 중급(N3), `beginner.html`은 초급판 | [`kotoba-biyori/`](kotoba-biyori/) |
| 🗣️ **ROUNDTABLE** | 토론형 영어 회화 쉐도잉. 하루 20분 | [`roundtable/`](roundtable/) |
| 🍵 **茶馆 CHÁGUǍN** | 중국어 일상 회화 쉐도잉. HSK 3~4급, 병음과 성조 색 표시 | [`chaguan/`](chaguan/) |
| 🧭 **업무 스타일 진단** | 8축 40문항 자가진단. 코드를 주고받아 서로의 궁합도 확인 | [`workstyle/`](workstyle/) |
| 🍚 **이번 주 식탁** | 조건을 고르면 주간 식단표·레시피·장보기 목록을 뽑아줌 | [`meal-planner/`](meal-planner/) |

## 쓰는 법

1. 위에서 폴더를 하나 고릅니다
2. `index.html`을 열고 우측 상단 **Download raw file** 버튼을 누릅니다
3. 내려받은 파일을 더블클릭하면 브라우저에서 열립니다

저장소 전체를 한 번에 받으려면 초록색 **Code → Download ZIP** 버튼을 쓰세요.

> 일본어·중국어 앱은 글꼴을 파일 안에 넣어둬서 하나에 7MB쯤 됩니다.
> 어느 컴퓨터에서 열어도 글자가 깨지지 않게 하려는 것이라, 원래 그렇습니다.

## 만든 방식

전부 [Claude Code](https://claude.com/claude-code)로 만들었습니다.
학습 기록이나 진행 상황은 브라우저 안(localStorage)에만 저장되고 어디로도 전송되지 않습니다.
서버가 없으니 계정도, 로그인도 없습니다.

## 스킬 (skills/)

앱 화면(`index.html`)과는 별개로, 각 앱에 **새 회차·새 단어를 만들어 넣을 때 쓰는 작업 설명서**입니다. Claude에게 "오늘 일본어", "새 회화 추가" 같은 말을 하면 이 설명서를 보고 형식에 맞는 원고를 만들어 줍니다. 사람이 직접 열어볼 일은 거의 없고, 백업 겸 참고용으로 올려둡니다.

| 스킬 | 대상 앱 | 폴더 |
|---|---|---|
| ことば日和 | `kotoba-biyori/` | [`skills/kotoba-biyori/`](skills/kotoba-biyori/) |
| 스틸링고 | `steel-lingo/lite/`, `steel-lingo/pro/` | [`skills/steel-lingo/`](skills/steel-lingo/) |
| 철강 일본어 매일 훈련 | 팀원용 훈련 자료 | [`skills/steel-japanese-drill/`](skills/steel-japanese-drill/) |
| 茶馆 CHÁGUǍN | `chaguan/` | [`skills/chaguan/`](skills/chaguan/) |
| ROUNDTABLE | `roundtable/` | [`skills/roundtable/`](skills/roundtable/) |

`workstyle/`, `meal-planner/`, `midnight-train/`은 한 번 만들고 끝나는 앱이라 별도 스킬이 없습니다.
