# 東京物語 이야기 설계 노트

다음 장을 쓰거나 고칠 때 보는 설계 노트다. 앱은 이 파일을 읽지 않는다.

## 판 세 가지
| 판 | 화면에 쓰는 칸 | 특징 |
|---|---|---|
| 한국어편 `ko` | `ko` | 일본어가 한 글자도 안 나온다. 일본어를 몰라도 이야기만 즐긴다 |
| 초급편 `easy` | `ja` + `parts` + `hint` + `learn` | 짧고 쉬운 です·ます / 쉬운 반말. 후리가나·해석이 처음부터 보인다 |
| 상급편 `hard` | `jx` + `hx` + `learnx` | 원어민이 실제로 하는 말(축약·반말·경어·속어). 후리가나·해석은 눌러야 보인다 |

`narr`·`act`·`ask`·`then`·`memo`·엔딩 글은 세 판이 같이 쓰므로 **순수 한국어**로만 쓴다(검증기가 막는다).

## 배경
- 2박 3일. 공항·입국심사·귀국 비행기 장면은 없다. 호텔에 짐을 푼 첫날 밤 11시에서 시작해 셋째 날 아침 골목을 나서는 데서 끝난다.
- 무대는 가구라자카(神楽坂). 돌길 골목, 작은 신사, 그 안쪽의 이름 없는 골목에 **めしや よすが**가 있다.
- 가게는 자정부터 새벽까지만 연다. 낮에 가 보면 그 자리는 잡초 난 공터다. 20년 전 그 자리의 식당 '요스가'가 불탔다.

## 숨은 이야기 (엔딩마다 해석이 갈린다)
- 20년 전 그 골목의 식당 '요스가'는 사요코가 하던 가게였다. 다친 젊은 건달 구로다 데쓰지(마스터)에게 밥을 먹이고 "발을 씻으라"고 했다.
- 데쓰지는 손을 씻겠다고 약속했다. 그런데 패싸움 죄를 대신 뒤집어쓰고 고가 형사에게 잡혀 들어간다. 그사이 옆집 불이 번져 가게가 탔고, 사요코는 사라졌다.
- 출소한 데쓰지는 같은 골목에서 사요코가 열던 시간(자정~새벽)에만 가게를 연다. 매일 새벽 1시, 구석 자리에 따뜻한 술 한 잔을 놓는다.
- 주인공에게만 사요코가 보인다. 귀신인지, 살아 있는 사람의 그리움인지, 꿈인지는 끝까지 정하지 않는다. 헌책방 주인은 "가마쿠라의 요양원에 있다는 소문"을 안다.

## 등장인물 (season.js cast 키)
| 키 | ja | ko | 말투 |
|---|---|---|---|
| me | — | 나 · 김링고 | 한국 철강회사 직원, 휴가 중 |
| master | マスター | 마스터 | 50대 후반. 왼쪽 눈썹에서 뺨까지 흉터, 왼손 새끼손가락이 짧다. 말수 적고 거칠다(상급: 〜んな, 〜ねえ, 食{く}ってけ). 아버지는 니가타 산조의 대장장이. 야스키 강철 칼 |
| sayoko | 小夜子{さよこ}さん | 사요코 씨 | 남색 바탕에 흰 동백이 그려진 옛 기모노. 단정하고 옛스러운 여성어 |
| chiaki | 千秋{ちあき}さん | 치아키 씨 | 34세 종합건설사 현장소장. 도라노몬 초고층 빌딩 현장. 기둥용 후판(厚板) 납기가 늦어 속이 탄다. 시원시원한 말투 |
| ren | 蓮{れん}くん | 렌 | 19세 배달 라이더. 아키타 출신. 어둠의 아르바이트(闇バイト)에 걸렸다. 〜っす |
| koga | 古賀{こが}さん | 고가 씨 | 60대 전직 형사. 20년 전 데쓰지를 잡아넣은 사람. 새벽 3시에 오차즈케를 먹으러 온다 |
| ume | 梅{うめ}さん | 우메 할머니 | 담뱃가게 할머니. 80대, 수다스러운 도쿄 서민 말투 |
| furuhon | 古本屋{ふるほんや}さん | 헌책방 주인 | 진보초 헌책방 노인 |
| front | フロント | 호텔 프런트 | 정중한 접객 경어 |
| men | 男{おとこ} | 남자 | 렌을 쫓는 남자들 |
| kuro | クロ | 쿠로 | 흰 앞발 하나인 검은 고양이(대사는 "にゃあ" 정도) |

## 장 구성과 플래그
- **1장 雨の神楽坂** (첫날 밤 11시): front_warn · umbrella / cat_friend · cat_food · lost / hesitate
- **2장 めしや よすが** (첫날 자정~새벽): order_tonjiru · order_tamago · order_kimchi / knife · scar · chiaki_talk / chiaki_steel · chiaki_line / sayoko_hello · sayoko_ask · sayoko_quiet / ren_worry · ren_tell / promise_return · matchbox · ask_day
- **3장 昼の路地** (둘째 날 낮): umesan_story · matchbox_seen / photo · sayoko_alive · photo_book / chiaki_tower · chiaki_deal · chiaki_mystery / omikuji / koga_story · koga_meet · koga_ren
- **4장 二度目の夜** (둘째 날 밤): same_order · master_past · knife_story / sayoko_msg · sayoko_wait · sayoko_umbrella / lie_men · dumb · koga_call · brave / ren_police · ren_apprentice · ren_home / chiaki_night · steel_talk · chiaki_promise · chiaki_toast / kanzashi · told_master · sayoko_bye
- **5장 夜明け** (셋째 날 새벽~아침): 마스터에게 남기는 말(deliver_msg · tell_alive · knife_home · ren_entrust · return_plain · ask_dream) → 낙서장(note_korean · note_rain · note_cat · note_sayoko) → 골목을 나서며(look_back · walk_on · call_chiaki · meet_koga) → 엔딩

## 엔딩 갈림 순서 (5장 마지막 route, 위에서부터 먼저 맞는 것)
1. zenin 모두의 요스가: deliver_msg + ren_apprentice + chiaki_night + koga_call
2. machibito 기다리던 사람: tell_alive
3. nidaime 2대째: ren_entrust
4. kaji 대장장이의 아들: knife_home
5. kanzashi 비녀: deliver_msg + note_sayoko
6. kanban 간판을 내리는 아침: deliver_msg
7. tekkotsu 철골의 인연: call_chiaki + chiaki_promise
8. tower 도쿄타워 아래서: call_chiaki
9. koga 형사의 오차즈케: meet_koga
10. yume 꿈이었을까: ask_dream
11. kasa 검은 우산: sayoko_umbrella + look_back
12. kuro 검은 고양이의 안내: note_cat + (cat_friend 또는 cat_food)
13. ame 비 오는 밤에 또: note_rain + promise_return
14. hangul 한글 낙서: note_korean
15. yarinaoshi 다시 시작: ren_police
16. akita 아키타에서 온 편지: ren_home
17. maboroshi 환상의 가게: look_back
18. tsuzuku 도쿄의 밤은 계속된다: 나머지 전부
