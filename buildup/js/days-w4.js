/* BUILD-UP — 22~30회차 (4주차: 강조·도치·논증 — 주장에 힘 싣기)
   마지막 회차는 자동차·가전·에너지·건설 수요를 엮은 철강 영업 문장으로 끝낸다. 회사 이름은 쓰지 않는다.
   형식은 days-w1.js 머리말. */
window.BU = window.BU || {};
BU.DAYS = BU.DAYS || [];
BU.DAYS.push(
{
  day: 22, cat: "조직", level: "B2+", title: "It's Not the Hours", titleKo: "번아웃 — It is not A that …; it is B",
  gist: "강조 구문 It is … that · 동격 that절 · 관계절 생략 · however + 형용사",
  steps: [
    { r: "{core:It is not the long hours that burn people out}.", ko: "사람을 지치게 하는 건 긴 근무 시간이 아닙니다.",
      gram: [ { t: "뼈대: It is not A that + 동사 (강조 구문)", d: "The long hours burn people out을 It is … that 틀에 넣어 A를 무대 앞으로 끌어냅니다. not을 붙이면 '흔한 원인은 사실 원인이 아니다'라는 반전 예고가 됩니다." } ],
      notes: [ { t: "burn someone out", k: "phrasal", m: "~를 완전히 지치게 하다", tip: "명사로는 burnout. be burned out(번아웃 상태다)." } ] },
    { r: "It is not the long hours that burn people out{contrast:; it is the feeling}.", ko: "사람을 지치게 하는 건 긴 근무 시간이 아니라, 어떤 느낌입니다.",
      gram: [ { t: "; it is B = 짝을 맞춘 대조", d: "세미콜론 뒤에서 같은 틀(it is)을 반복해 진짜 원인을 내놓습니다. 뒤의 that burn people out은 반복을 피해 생략합니다." } ] },
    { r: "It is not the long hours that burn people out; it is the feeling {clause:that their work disappears into a system}.", ko: "…자기 일이 어떤 시스템 속으로 사라져 버린다는 느낌입니다.",
      gram: [ { t: "명사 + 동격 that절", d: "the feeling that ~ = ~라는 느낌. 6회차 evidence that과 같은 틀입니다. 막연한 '느낌'의 내용을 바로 풀어 줍니다." } ],
      notes: [ { t: "disappear into ~", k: "collocation", m: "~속으로 사라지다", tip: "My email disappeared into a black hole(메일이 블랙홀로 빠졌다)처럼 반응 없음을 말할 때 씁니다." } ] },
    { r: "It is not the long hours that burn people out; it is the feeling that their work disappears into a system {rel:nobody explains}.", ko: "사람을 지치게 하는 건 긴 근무 시간이 아니라, 자기 일이 아무도 설명해 주지 않는 시스템 속으로 사라진다는 느낌입니다.",
      gram: [ { t: "명사 + 주어 + 동사 (관계사 생략)", d: "a system (that) nobody explains = 아무도 설명하지 않는 시스템. 3회차와 같은 생략형입니다. 짧아서 리듬이 좋습니다." } ] },
    { r: "It is not the long hours that burn people out; it is the feeling that their work disappears into a system nobody explains. {add:Clear priorities} {add:are easier to live with than vague ones}.", ko: "…분명한 우선순위가 모호한 우선순위보다 견디기 쉽습니다.",
      gram: [ { t: "형용사 + to부정사 + 전치사 + 비교", d: "easier to live with = 받아들이고 지내기 더 쉬운. live with ~(~를 감수하다)의 with가 끝에 남습니다(4회차 train for와 같은 원리). vague ones의 ones는 priorities." } ],
      notes: [ { t: "live with ~", k: "phrasal", m: "~를 감수하다, 받아들이고 지내다", tip: "I can live with that(그 정도는 감수할 수 있어요). 협상에서 자주 듣는 말입니다." } ] },
    { r: "It is not the long hours that burn people out; it is the feeling that their work disappears into a system nobody explains. Clear priorities{contrast:, however demanding,} are easier to live with than vague ones.", ko: "사람을 지치게 하는 건 긴 근무 시간이 아니라, 자기 일이 아무도 설명해 주지 않는 시스템 속으로 사라진다는 느낌입니다. 분명한 우선순위는 아무리 빡빡해도 모호한 우선순위보다 견디기 쉽습니다.",
      gram: [ { t: ", however + 형용사, = 아무리 ~하더라도", d: "however demanding = however demanding they are(아무리 빡빡하더라도)를 줄인 형태입니다. 주어 뒤에 쉼표로 끼워 양보를 짧게 넣습니다." } ],
      notes: [ { t: "demanding", k: "colloquial", m: "요구가 많은, 빡빡한", tip: "a demanding client(까다로운 고객), a demanding schedule(빡빡한 일정)." } ] }
  ],
  quiz: {
    blocks: ["It is not the long hours", "that burn people out;", "it is the feeling", "that their work disappears into a system", "nobody explains.", "Clear priorities,", "however demanding,", "are easier to live with than vague ones."],
    orders: [[0,1,2,3,4,5,6,7]]
  }
},
{
  day: 23, cat: "안전", level: "B2+", title: "Only After the Accident", titleKo: "안전 문화 — Not until 도치",
  gist: "Not until … did + 주어 + 동사 · 관계절 · only when · That is why",
  steps: [
    { r: "{core:We separated walkways from loading zones}.", ko: "우리는 보행로를 하역 구역과 분리했습니다.",
      gram: [ { t: "뼈대: separate A from B", d: "A를 B와 분리하다. 다음 단계에서 이 평범한 문장을 '언제서야' 했는지로 뒤집습니다." } ],
      notes: [ { t: "loading zone", k: "business", m: "하역 구역", tip: "loading dock(하역장), forklift(지게차)와 함께 현장 안전 용어로 자주 씁니다." } ] },
    { r: "{focus:Not until a forklift nearly hit a visitor did we separate} walkways from loading zones.", ko: "지게차가 방문객을 칠 뻔한 뒤에야 우리는 보행로를 하역 구역과 분리했습니다.",
      gram: [ { t: "Not until A did + 주어 + 동사원형 = A하고 나서야 비로소 ~했다", d: "We did not separate them until ~ 에서 Not until ~ 을 맨 앞으로 보내면 뒤가 의문문 어순(did we separate)으로 뒤집힙니다. '그제야'라는 뉘우침이 강하게 실립니다." } ],
      notes: [ { t: "nearly hit", k: "collocation", m: "칠 뻔하다", tip: "nearly·almost + 과거형 = ~할 뻔했다. a near miss(아차 사고)는 안전 용어입니다." } ],
      trap: [ { ng: "Not until a forklift nearly hit a visitor we separated...", why: "Not until이 문장 앞에 오면 뒤는 did we separate처럼 도치해야 합니다." } ] },
    { r: "Not until a forklift nearly hit a visitor did we separate walkways from loading zones. {add:People accept rules}.", ko: "…사람들은 규칙을 받아들입니다.",
      gram: [ { t: "새 문장: 일반론", d: "우리 사례에서 사람의 습성 전반으로 넓힙니다. 현재형 = 언제나 그렇다." } ] },
    { r: "Not until a forklift nearly hit a visitor did we separate walkways from loading zones. People accept rules {rel:that slow them down}.", ko: "…사람들은 자신을 느리게 만드는 규칙을 받아들입니다.",
      gram: [ { t: "관계절로 '어떤 규칙인지'", d: "rules that slow them down = 그들을 느리게 하는 규칙. 안전 규칙이 왜 싫은지가 관계절 하나에 담깁니다." } ],
      notes: [ { t: "slow someone down", k: "phrasal", m: "~를 느리게 하다, 발목을 잡다", tip: "목적어가 대명사면 slow them down처럼 가운데 넣습니다." } ] },
    { r: "Not until a forklift nearly hit a visitor did we separate walkways from loading zones. People accept rules that slow them down {focus:only when they see the risk with their own eyes}.", ko: "…사람들은 위험을 제 눈으로 볼 때에만 자신을 느리게 하는 규칙을 받아들입니다.",
      gram: [ { t: "only when + 절 (문장 끝)", d: "15회차와 같은 only when입니다. 문장 끝에 두면 도치가 없습니다. 앞으로 보내면 Only when they see …, do people accept … 처럼 도치합니다." } ],
      notes: [ { t: "with one's own eyes", k: "idiom", m: "제 눈으로 직접", tip: "I saw it with my own eyes. 직접 경험의 무게를 강조합니다." } ] },
    { r: "Not until a forklift nearly hit a visitor did we separate walkways from loading zones. People accept rules that slow them down only when they see the risk with their own eyes. {add:That is why our safety training now starts}.", ko: "…그래서 지금 우리 안전 교육은 시작부터 다릅니다.",
      gram: [ { t: "복습: That is why + 절", d: "2회차의 결론 틀입니다. 앞의 일반론을 근거로 우리가 바꾼 것을 말합니다." } ] },
    { r: "Not until a forklift nearly hit a visitor did we separate walkways from loading zones. People accept rules that slow them down only when they see the risk with their own eyes. That is why our safety training now starts {place:on the shop floor}.", ko: "지게차가 방문객을 칠 뻔한 뒤에야 우리는 보행로를 하역 구역과 분리했습니다. 사람들은 위험을 제 눈으로 볼 때에만 자신을 느리게 하는 규칙을 받아들입니다. 그래서 지금 우리 안전 교육은 현장에서 시작합니다.",
      gram: [ { t: "on the shop floor = 현장에서", d: "강의실이 아니라 실제 작업장에서. 결론의 마지막 한 덩어리가 앞 두 문장의 교훈을 실행으로 바꿉니다." } ],
      notes: [ { t: "the shop floor", k: "business", m: "작업 현장, 생산 현장", tip: "공장의 생산 구역. on the shop floor ↔ in the office." } ] }
  ],
  quiz: {
    blocks: ["Not until a forklift nearly hit a visitor", "did we separate walkways from loading zones.", "People accept rules", "that slow them down", "only when they see the risk with their own eyes.", "That is why our safety training now starts", "on the shop floor."],
    orders: [[0,1,2,3,4,5,6]]
  }
},
{
  day: 24, cat: "자동화", level: "B2+", title: "More Robots, More Skills", titleKo: "자동화와 숙련 — The 비교급, the 비교급",
  gist: "The more …, the more … · the few · 관계절 · In other words · ; it …",
  steps: [
    { r: "{core:The more we automate, the more we depend on} {core:technicians}.", ko: "자동화를 할수록 우리는 기술자에게 더 의존합니다.",
      gram: [ { t: "뼈대: The more A, the more B", d: "13회차 the thinner …, the less …와 같은 틀입니다. 이번엔 동사(automate, depend)가 비교의 축입니다." } ],
      notes: [ { t: "depend on ~", k: "collocation", m: "~에 의존하다", tip: "rely on 과 거의 같은 뜻입니다. heavily depend on(크게 의존하다)." } ] },
    { r: "The more we automate, the more we depend on {mod:the few} technicians.", ko: "자동화를 할수록 우리는 몇 안 되는 기술자에게 더 의존합니다.",
      gram: [ { t: "the few + 복수 명사 = 몇 안 되는 그 ~들", d: "few(거의 없는)에 the를 붙이면 '얼마 안 되는 바로 그 사람들'이 됩니다. 희소성이 강조됩니다." } ],
      trap: [ { ng: "the a few technicians", why: "a few(몇몇)와 the few(몇 안 되는 그)는 다른 말입니다. the와 a를 같이 쓰지 않습니다." } ] },
    { r: "The more we automate, the more we depend on the few technicians {rel:who can fix the line}.", ko: "자동화를 할수록 우리는 라인을 고칠 수 있는 몇 안 되는 기술자에게 더 의존합니다.",
      gram: [ { t: "who 관계절로 '어떤 기술자인지'", d: "who can fix the line = 라인을 고칠 줄 아는. 사람에는 who를 씁니다." } ],
      notes: [ { t: "the line", k: "business", m: "생산 라인", tip: "production line을 줄여 the line이라고 합니다. stop the line(라인을 세우다)." } ] },
    { r: "The more we automate, the more we depend on the few technicians who can fix the line {time:when it stops}.", ko: "자동화를 할수록 우리는 라인이 멈췄을 때 고칠 수 있는 몇 안 되는 기술자에게 더 의존합니다.",
      gram: [ { t: "when + 현재형", d: "멈추면 그때. 일어날 때마다 반복되는 일이라 현재형입니다." } ] },
    { r: "The more we automate, the more we depend on the few technicians who can fix the line when it stops. {add:In other words, automation does not remove skilled work}.", ko: "…다시 말해, 자동화는 숙련 노동을 없애지 않습니다.",
      gram: [ { t: "In other words, = 다시 말해", d: "앞 내용을 더 짧고 일반적인 명제로 바꿔 말합니다. 듣는 사람에게 '요점은 이것'이라고 신호를 줍니다." } ],
      notes: [ { t: "skilled work", k: "business", m: "숙련 노동", tip: "skilled labor, skilled workers도 같은 계열입니다. unskilled(비숙련)와 대비." } ] },
    { r: "The more we automate, the more we depend on the few technicians who can fix the line when it stops. In other words, automation does not remove skilled work{contrast:; it concentrates it}.", ko: "…다시 말해, 자동화는 숙련 노동을 없애는 게 아니라 한곳으로 모읍니다.",
      gram: [ { t: "A does not X; it Y", d: "부정 + 세미콜론 + 긍정으로 대비를 날카롭게 만듭니다. 4회차, 22회차와 같은 리듬입니다." } ],
      notes: [ { t: "concentrate", k: "collocation", m: "한곳에 모으다, 집중시키다", tip: "concentrate power / risk / expertise in ~ (~에 집중시키다)." } ] },
    { r: "The more we automate, the more we depend on the few technicians who can fix the line when it stops. In other words, automation does not remove skilled work; it concentrates it {place:in fewer, more valuable hands}.", ko: "자동화를 할수록 우리는 라인이 멈췄을 때 고칠 수 있는 몇 안 되는 기술자에게 더 의존합니다. 다시 말해, 자동화는 숙련 노동을 없애는 게 아니라 더 적고 더 귀한 사람들의 손에 모읍니다.",
      gram: [ { t: "형용사 두 개를 쉼표로", d: "fewer, more valuable hands = 더 적고, 더 귀한 손. 두 비교급을 나란히 놓아 '수는 줄고 값은 오른다'를 한 번에 말합니다." } ],
      notes: [ { t: "in someone's hands", k: "idiom", m: "~의 손에(맡겨져)", tip: "hands가 '사람'을 대신합니다. in safe hands(믿을 만한 사람에게 맡겨진)." } ] }
  ],
  quiz: {
    blocks: ["The more we automate,", "the more we depend on", "the few technicians", "who can fix the line", "when it stops.", "In other words, automation does not remove skilled work;", "it concentrates it", "in fewer, more valuable hands."],
    orders: [[0,1,2,3,4,5,6,7]]
  }
},
{
  day: 25, cat: "설득", level: "B2+", title: "Data Doesn't Persuade Alone", titleKo: "숫자만으로는 설득이 안 된다 — No matter how",
  gist: "no matter how + 형용사 · unless · what절 · ; it is",
  steps: [
    { r: "{core:A proposal will not win approval}.", ko: "제안은 승인을 받지 못할 것입니다.",
      gram: [ { t: "뼈대: will not + 동사", d: "단정적인 예측에서 출발해 '아무리 ~해도', '~하지 않는 한'을 차례로 붙여 조건을 정교하게 만듭니다." } ],
      notes: [ { t: "win approval", k: "collocation", m: "승인을 얻다", tip: "gain approval, get sign-off(결재를 받다)도 같은 자리에 씁니다." } ] },
    { r: "A proposal will not win approval{contrast:, no matter how strong the data is,}.", ko: "데이터가 아무리 탄탄해도 제안은 승인을 받지 못할 것입니다.",
      gram: [ { t: "no matter how + 형용사 + 주어 + 동사", d: "no matter how strong the data is = 데이터가 아무리 강력해도. 22회차 however demanding보다 구어적이고, 주어·동사를 다 갖춘 형태입니다." } ],
      trap: [ { ng: "no matter how the data is strong", why: "how 바로 뒤에 형용사를 붙입니다. how strong the data is." } ] },
    { r: "A proposal will not win approval, no matter how strong the data is, {cond:unless the decision makers can see}.", ko: "의사결정자들이 알아보지 못하면, 데이터가 아무리 탄탄해도 제안은 승인을 받지 못할 것입니다.",
      gram: [ { t: "양보 + 조건을 한 문장에", d: "no matter how(아무리 ~해도)로 흔한 기대를 꺾고, unless(~하지 않는 한)로 진짜 조건을 내놓습니다. see 다음에 무엇을 볼지는 다음 단계에서." } ],
      notes: [ { t: "decision makers", k: "business", m: "의사결정권자", tip: "stakeholders(이해관계자)보다 '결정 권한이 있는 사람'으로 좁습니다." } ] },
    { r: "A proposal will not win approval, no matter how strong the data is, unless the decision makers can see {clause:what changes for them}.", ko: "의사결정자들이 자신에게 무엇이 달라지는지 알 수 없다면, 데이터가 아무리 탄탄해도 제안은 승인을 받지 못할 것입니다.",
      gram: [ { t: "see + what절 = 무엇이 ~인지 알다", d: "what changes for them = 그들에게 무엇이 달라지는지. what이 주어 역할을 하는 명사절입니다." } ] },
    { r: "A proposal will not win approval, no matter how strong the data is, unless the decision makers can see what changes for them. {add:What people remember after a meeting is rarely a chart}.", ko: "…회의가 끝난 뒤 사람들이 기억하는 건 차트인 경우가 드뭅니다.",
      gram: [ { t: "복습: What절 주어 + rarely", d: "14회차처럼 what절을 주어로 세웁니다. rarely(좀처럼 ~ 않는)로 단정 대신 경향을 말합니다." } ] },
    { r: "A proposal will not win approval, no matter how strong the data is, unless the decision makers can see what changes for them. What people remember after a meeting is rarely a chart{contrast:; it is a single, concrete example}.", ko: "의사결정자들이 자신에게 무엇이 달라지는지 알 수 없다면, 데이터가 아무리 탄탄해도 제안은 승인을 받지 못할 것입니다. 회의가 끝난 뒤 사람들이 기억하는 건 차트가 아니라 구체적인 사례 하나입니다.",
      gram: [ { t: "복습: rarely X; it is Y", d: "22·24회차와 같은 대조 리듬입니다. a single, concrete example = 단 하나의 구체적인 사례. 형용사 둘을 쉼표로 나란히 놓았습니다." } ],
      notes: [ { t: "a concrete example", k: "collocation", m: "구체적인 사례", tip: "give a concrete example. abstract(추상적인)와 대비됩니다." } ] }
  ],
  quiz: {
    blocks: ["A proposal will not win approval,", "no matter how strong the data is,", "unless the decision makers can see", "what changes for them.", "What people remember after a meeting", "is rarely a chart;", "it is a single, concrete example."],
    orders: [[0,1,2,3,4,5,6]]
  }
},
{
  day: 26, cat: "철강·탄소", level: "B2+", title: "Paying for Lower Carbon", titleKo: "저탄소 강재 — 진행형 수동태와 so that",
  gist: "are being + p.p. · by + 행위자 · so that · even if",
  steps: [
    { r: "{core:Our customers are being asked} {core:to report the carbon}.", ko: "우리 고객사들은 탄소를 보고하라는 요구를 받고 있습니다.",
      gram: [ { t: "뼈대: are being + p.p. = (지금) ~되고 있다", d: "진행형 수동태입니다. 요구가 '지금 진행 중'이라는 것을 보여 줍니다. ask A to do의 수동 = A is asked to do." } ],
      notes: [ { t: "report the carbon", k: "business", m: "탄소(배출량)를 보고하다", tip: "carbon footprint(탄소 발자국), Scope 3 emissions(공급망 배출)와 함께 쓰는 실무 표현입니다." } ] },
    { r: "Our customers are being asked {mod:by their own clients} to report the carbon.", ko: "우리 고객사들은 자기 고객들로부터 탄소를 보고하라는 요구를 받고 있습니다.",
      gram: [ { t: "by + 행위자", d: "누가 요구하는지 밝힙니다. their own clients = 그들 자신의 고객. 요구가 공급망을 타고 내려온다는 그림이 보입니다." } ] },
    { r: "Our customers are being asked by their own clients to report the carbon {mod:in every part they buy}.", ko: "우리 고객사들은 자기 고객들로부터 구매하는 모든 부품의 탄소를 보고하라는 요구를 받고 있습니다.",
      gram: [ { t: "명사 + (that) + 주어 + 동사", d: "every part (that) they buy = 그들이 사는 모든 부품. 생략형 관계절로 범위를 정확히 정합니다." } ] },
    { r: "Our customers are being asked by their own clients to report the carbon in every part they buy. {add:We are publishing emissions data for each grade of steel}.", ko: "…우리는 강종별 배출량 데이터를 공개하고 있습니다.",
      gram: [ { t: "현재진행 = 지금 하고 있는 대응", d: "요구(are being asked)에 대한 우리의 대응(are publishing)을 같은 진행형으로 맞춰 대칭을 만듭니다." } ],
      notes: [ { t: "grade of steel", k: "business", m: "강종(강재 등급)", tip: "steel grade라고도 합니다. 성분·강도에 따라 나눈 제품 등급입니다." } ] },
    { r: "Our customers are being asked by their own clients to report the carbon in every part they buy. We are publishing emissions data for each grade of steel {purpose:so that they can compare suppliers}.", ko: "…고객사들이 공급사를 비교할 수 있도록 우리는 강종별 배출량 데이터를 공개하고 있습니다.",
      gram: [ { t: "so that + 주어 + can = ~할 수 있도록", d: "목적을 절로 말합니다. to부정사보다 '누가' 할 수 있게 되는지(they)가 분명합니다." } ],
      trap: [ { ng: "so they can to compare suppliers", why: "can 뒤에는 동사원형입니다. to를 붙이지 않습니다." } ] },
    { r: "Our customers are being asked by their own clients to report the carbon in every part they buy. We are publishing emissions data for each grade of steel so that they can compare suppliers{contrast:, even if that makes our older products look worse}.", ko: "우리 고객사들은 자기 고객들로부터 구매하는 모든 부품의 탄소를 보고하라는 요구를 받고 있습니다. 그래서 우리는, 예전 제품이 불리해 보이더라도, 고객사들이 공급사를 비교할 수 있도록 강종별 배출량 데이터를 공개하고 있습니다.",
      gram: [ { t: ", even if + 절 = 설령 ~하더라도", d: "although는 '사실인데도', even if는 '그렇게 되더라도'입니다. 불리함을 감수하는 결정이라는 점이 신뢰를 줍니다." } ],
      notes: [ { t: "make A look worse", k: "grammar", m: "A를 더 나빠 보이게 만들다", tip: "make + 목적어 + 동사원형(look). 2회차 watch + O + 동사원형과 같은 짜임입니다." } ] }
  ],
  quiz: {
    blocks: ["Our customers are being asked", "by their own clients", "to report the carbon", "in every part they buy.", "We are publishing emissions data", "for each grade of steel", "so that they can compare suppliers,", "even if that makes our older products look worse."],
    orders: [[0,1,2,3,4,5,6,7]]
  }
},
{
  day: 27, cat: "피드백 문화", level: "B2+", title: "Why Nobody Speaks Up", titleKo: "아무도 말하지 않는 이유 — It is not that …; it is that …",
  gist: "It is not that … ; it is that … · 동명사 주어 · until · for -ing",
  steps: [
    { r: "{core:It is not that our engineers have no opinions}.", ko: "우리 엔지니어들에게 의견이 없는 게 아닙니다.",
      gram: [ { t: "뼈대: It is not that + 절 = ~인 것은 아니다", d: "흔한 오해를 먼저 부정합니다. 22회차 It is not A that(강조 구문)과 달리, 여기서는 that 뒤에 문장 전체가 옵니다." } ] },
    { r: "It is not that our engineers have no opinions{contrast:; it is that they have learned}.", ko: "우리 엔지니어들에게 의견이 없는 게 아니라, 그들은 배운 것입니다.",
      gram: [ { t: "; it is that + 절 = 그게 아니라 ~인 것이다", d: "부정한 자리에 진짜 이유를 같은 틀로 넣습니다. 무엇을 배웠는지는 다음 단계에서." } ] },
    { r: "It is not that our engineers have no opinions; it is that they have learned {clause:that raising a problem in a review creates more work for them}.", ko: "우리 엔지니어들에게 의견이 없는 게 아니라, 리뷰에서 문제를 제기하면 자기 일만 늘어난다는 걸 배운 것입니다.",
      gram: [ { t: "learn that + 절 (안에 동명사 주어)", d: "that절 안의 주어가 raising a problem in a review(리뷰에서 문제를 제기하는 것)라는 동명사구입니다. 4회차 Writing a clean first draft와 같은 짜임입니다." } ],
      notes: [ { t: "raise a problem", k: "collocation", m: "문제를 제기하다", tip: "raise an issue / a concern 도 같은 계열입니다. 1회차 rise와 달리 raise는 목적어가 있습니다." } ] },
    { r: "It is not that our engineers have no opinions; it is that they have learned that raising a problem in a review creates more work for them. {add:Silence will remain the rational choice}.", ko: "…침묵이 여전히 합리적인 선택으로 남을 것입니다.",
      gram: [ { t: "remain + 명사 = 여전히 ~로 남다", d: "7회차 remain essential(형용사)처럼 명사도 붙습니다. the rational choice = 합리적인 선택. 침묵을 탓하지 않고 구조의 결과로 봅니다." } ] },
    { r: "It is not that our engineers have no opinions; it is that they have learned that raising a problem in a review creates more work for them. Silence will remain the rational choice {time:until we reward people}.", ko: "…우리가 사람들에게 보상하기 전까지는 침묵이 합리적인 선택으로 남을 것입니다.",
      gram: [ { t: "until + 현재형 = ~할 때까지", d: "미래 일이라도 until 절은 현재형입니다(17회차 before, once와 같은 규칙)." } ] },
    { r: "It is not that our engineers have no opinions; it is that they have learned that raising a problem in a review creates more work for them. Silence will remain the rational choice until we reward people {purpose:for flagging risks early}.", ko: "우리 엔지니어들에게 의견이 없는 게 아니라, 리뷰에서 문제를 제기하면 자기 일만 늘어난다는 걸 배운 것입니다. 위험을 일찍 알린 사람에게 보상하기 전까지는 침묵이 합리적인 선택으로 남을 것입니다.",
      gram: [ { t: "reward A for -ing = ~한 것에 대해 A에게 보상하다", d: "for 뒤에 무엇을 칭찬하는지 동명사로 붙입니다. thank A for -ing, blame A for -ing도 같은 틀입니다." } ],
      notes: [ { t: "flag a risk", k: "business", m: "위험을 미리 알리다", tip: "flag는 '깃발을 꽂아 표시하다'에서 왔습니다. flag an issue early." } ] }
  ],
  quiz: {
    blocks: ["It is not that our engineers have no opinions;", "it is that they have learned", "that raising a problem in a review", "creates more work for them.", "Silence will remain the rational choice", "until we reward people", "for flagging risks early."],
    orders: [[0,1,2,3,4,5,6]]
  }
},
{
  day: 28, cat: "에너지 정책", level: "B2+", title: "No Perfect Option", titleKo: "에너지 믹스 — granted와 not whether A but whether B",
  gist: "형용사 + to부정사 두 개 · , granted, but · regardless of · not whether A but whether B",
  steps: [
    { r: "{core:Nuclear power is expensive to build}.", ko: "원자력은 짓는 데 비용이 많이 듭니다.",
      gram: [ { t: "뼈대: 형용사 + to부정사", d: "expensive to build = 짓기에 비싼. 주어(원자력)가 to build의 목적어 역할을 하는 틀입니다. hard to replace(11회차)와 같습니다." } ] },
    { r: "Nuclear power is expensive to build {mod:and slow to approve}.", ko: "원자력은 짓는 데 비용이 많이 들고 인허가도 느립니다.",
      gram: [ { t: "같은 틀을 and로 나란히", d: "expensive to build and slow to approve. 형용사 + to부정사를 두 개 겹쳐 약점을 한 호흡에 말합니다." } ],
      notes: [ { t: "approve", k: "business", m: "승인하다(인허가)", tip: "명사 approval. regulatory approval(규제 당국의 승인)." } ] },
    { r: "Nuclear power is expensive to build and slow to approve{contrast:, granted, but it delivers steady output}.", ko: "원자력이 짓는 데 비싸고 인허가가 느린 건 인정합니다. 하지만 꾸준한 출력을 냅니다.",
      gram: [ { t: ", granted, but = 그건 인정하지만", d: "granted를 쉼표로 끼워 상대의 반론을 먼저 인정하고 but으로 뒤집습니다. 토론에서 상대를 존중하면서 반박하는 가장 세련된 틀입니다." } ],
      notes: [ { t: "steady output", k: "business", m: "안정적인 출력(공급량)", tip: "baseload power(기저 전력)라는 전문 용어와 연결됩니다." } ] },
    { r: "Nuclear power is expensive to build and slow to approve, granted, but it delivers steady output {mod:regardless of the weather}.", ko: "…하지만 날씨와 상관없이 꾸준한 출력을 냅니다.",
      gram: [ { t: "regardless of + 명사 = ~와 상관없이", d: "태양광·풍력과의 대비를 직접 말하지 않고도 드러냅니다. 듣는 사람이 비교를 스스로 떠올립니다." } ],
      trap: [ { ng: "irregardless of the weather", why: "irregardless는 표준 영어에서 틀린 말로 봅니다. regardless of." } ] },
    { r: "Nuclear power is expensive to build and slow to approve, granted, but it delivers steady output regardless of the weather. {add:The real question is} {add:whether anything else can keep heavy industry running}.", ko: "…진짜 질문은 다른 무언가가 중공업을 계속 돌릴 수 있느냐입니다.",
      gram: [ { t: "The real question is + whether절", d: "9회차 The real problem is와 같은 틀에 whether절을 보어로 붙입니다. keep A running = A를 계속 돌아가게 하다." } ],
      notes: [ { t: "keep something running", k: "collocation", m: "~를 계속 가동시키다", tip: "keep the plant running, keep the lights on(최소한의 운영을 유지하다)." } ] },
    { r: "Nuclear power is expensive to build and slow to approve, granted, but it delivers steady output regardless of the weather. The real question is {contrast:not whether it is cheap, but} whether anything else can keep heavy industry running.", ko: "…진짜 질문은 그게 싸냐가 아니라, 다른 무언가가 중공업을 계속 돌릴 수 있느냐입니다.",
      gram: [ { t: "not whether A, but whether B", d: "9회차 not A but B의 whether절 버전입니다. 상대가 묻는 질문(싸냐)을 치우고 진짜 질문으로 바꿔 놓습니다." } ] },
    { r: "Nuclear power is expensive to build and slow to approve, granted, but it delivers steady output regardless of the weather. The real question is not whether it is cheap, but whether anything else can keep heavy industry running {time:at night}.", ko: "원자력이 짓는 데 비싸고 인허가가 느린 건 인정하지만, 날씨와 상관없이 꾸준한 출력을 냅니다. 진짜 질문은 그게 싸냐가 아니라, 밤에도 다른 무언가가 중공업을 계속 돌릴 수 있느냐입니다.",
      gram: [ { t: "마지막 한 덩어리로 논점을 찌르기", d: "at night 하나가 '해가 없을 때'를 떠올리게 해 태양광의 한계를 직접 말하지 않고 짚습니다." } ] }
  ],
  quiz: {
    blocks: ["Nuclear power is expensive to build", "and slow to approve,", "granted,", "but it delivers steady output", "regardless of the weather.", "The real question is", "not whether it is cheap, but", "whether anything else can keep heavy industry running", "at night."],
    orders: [[0,1,2,3,4,5,6,7,8]]
  }
},
{
  day: 29, cat: "통상", level: "B2+", title: "When Tariffs Rise", titleKo: "관세의 역설 — 명사화와 however",
  gist: "명사화 주어(The introduction of) · in the short term · 주어 뒤 however · , which",
  steps: [
    { r: "{core:The introduction of new tariffs} {core:has protected domestic mills}.", ko: "새 관세 도입은 국내 제철소를 보호했습니다.",
      gram: [ { t: "뼈대: 명사화 주어", d: "Introducing new tariffs 대신 The introduction of new tariffs(새 관세의 도입)처럼 동사를 명사로 바꿔 주어로 씁니다. 보고서·기사체의 핵심 기술입니다." } ],
      notes: [ { t: "domestic mills", k: "business", m: "국내 제철소", tip: "mill은 제철소·압연 공장을 가리킵니다. steel mill, rolling mill." } ] },
    { r: "The introduction of new tariffs {mod:on imported steel} has protected domestic mills.", ko: "수입 철강에 대한 새 관세 도입은 국내 제철소를 보호했습니다.",
      gram: [ { t: "tariffs on + 대상", d: "관세는 on으로 대상을 붙입니다. a tariff on imported steel = 수입 철강에 매기는 관세." } ],
      trap: [ { ng: "tariffs for imported steel", why: "관세·세금의 대상은 on입니다. a tax on fuel, a tariff on steel." } ] },
    { r: "The introduction of new tariffs on imported steel has protected domestic mills {time:in the short term}.", ko: "수입 철강에 대한 새 관세 도입은 단기적으로는 국내 제철소를 보호했습니다.",
      gram: [ { t: "in the short term = 단기적으로는", d: "이 한 덩어리가 '장기적으로는 다르다'는 반전을 예고합니다. in the long term과 짝입니다." } ] },
    { r: "The introduction of new tariffs on imported steel has protected domestic mills in the short term. {add:The manufacturers} {add:are now paying more than their foreign competitors}.", ko: "…제조업체들은 이제 해외 경쟁사보다 돈을 더 내고 있습니다.",
      gram: [ { t: "새 문장: 다른 쪽에서 본 결과", d: "보호받는 쪽(제철소)에서 비용을 떠안는 쪽(수요 산업)으로 시선을 옮깁니다." } ] },
    { r: "The introduction of new tariffs on imported steel has protected domestic mills in the short term. The manufacturers {rel:who buy that steel} are now paying more than their foreign competitors.", ko: "…그 철강을 사는 제조업체들은 이제 해외 경쟁사보다 돈을 더 내고 있습니다.",
      gram: [ { t: "주어 + who 관계절 + 동사", d: "5회차 Drivers whose homes …처럼 주어와 동사 사이에 끼워 '어떤 제조업체인지' 좁힙니다." } ],
      notes: [ { t: "foreign competitors", k: "business", m: "해외 경쟁사", tip: "competitors abroad 도 같은 뜻입니다." } ] },
    { r: "The introduction of new tariffs on imported steel has protected domestic mills in the short term. The manufacturers who buy that steel{link:, however,} are now paying more than their foreign competitors.", ko: "…하지만 그 철강을 사는 제조업체들은 이제 해외 경쟁사보다 돈을 더 내고 있습니다.",
      gram: [ { t: "주어 뒤에 끼우는 however", d: "7회차 therefore와 같은 자리입니다. 문장 맨 앞 However보다 '이쪽 사정은 다르다'는 대비가 주어에 바로 걸립니다." } ] },
    { r: "The introduction of new tariffs on imported steel has protected domestic mills in the short term. The manufacturers who buy that steel, however, are now paying more than their foreign competitors{rel:, which weakens the very industries the tariffs were meant to support}.", ko: "수입 철강에 대한 새 관세 도입은 단기적으로는 국내 제철소를 보호했습니다. 하지만 그 철강을 사는 제조업체들은 이제 해외 경쟁사보다 돈을 더 내고 있고, 이것이 관세가 지키려던 바로 그 산업을 약하게 만듭니다.",
      gram: [ { t: ", which + the very + 명사", d: "the very industries = 바로 그 산업들. very가 명사 앞에서 '바로 그'라는 강조가 됩니다. the tariffs were meant to support = 관세가 지원하려던(생략형 관계절)." } ],
      notes: [ { t: "be meant to ~", k: "idiom", m: "~하기로 되어 있다, ~하려는 것이다", tip: "The policy was meant to help small firms(그 정책은 소기업을 도우려던 것이었다)." } ] }
  ],
  quiz: {
    blocks: ["The introduction of new tariffs", "on imported steel", "has protected domestic mills", "in the short term.", "The manufacturers who buy that steel,", "however,", "are now paying more than their foreign competitors,", "which weakens the very industries", "the tariffs were meant to support."],
    orders: [[0,1,2,3,4,5,6,7,8]]
  }
},
{
  day: 30, cat: "철강 영업", level: "B2+", title: "One Material, Many Markets", titleKo: "소재 하나, 시장 여럿 — 30회차 총정리",
  gist: "총정리: 강조 구문 · although · , which is why · so that",
  steps: [
    { r: "{core:It is automotive, appliance and energy customers that are driving our growth}.", ko: "우리 성장을 이끄는 건 자동차·가전·에너지 고객입니다.",
      gram: [ { t: "뼈대: 강조 구문 It is A that", d: "22회차 틀을 긍정으로 씁니다. 여러 수요 산업 중 '바로 이들'이 성장을 이끈다고 무대 앞에 세웁니다." } ],
      notes: [ { t: "drive growth", k: "business", m: "성장을 이끌다", tip: "growth drivers(성장 동력)라는 명사형도 자주 씁니다." } ] },
    { r: "It is automotive, appliance and energy customers that are driving our growth {time:this year}.", ko: "올해 우리 성장을 이끄는 건 자동차·가전·에너지 고객입니다.",
      gram: [ { t: "this year = 올해", d: "this 앞에도 전치사를 쓰지 않습니다(1회차 last year와 같은 규칙)." } ] },
    { r: "It is automotive, appliance and energy customers that are driving our growth this year{contrast:, although construction demand remains weak}.", ko: "건설 수요는 여전히 약하지만, 올해 우리 성장을 이끄는 건 자동차·가전·에너지 고객입니다.",
      gram: [ { t: "복습: , although + 절", d: "2회차 양보절입니다. 약한 시장(건설)을 숨기지 않고 인정하면 강한 시장 이야기가 더 믿을 만해집니다." } ],
      notes: [ { t: "remain weak", k: "collocation", m: "여전히 약하다", tip: "7회차 remain essential과 같은 remain입니다. demand remains sluggish(부진하다)도 자주 씁니다." } ] },
    { r: "It is automotive, appliance and energy customers that are driving our growth this year, although construction demand remains weak. {add:Each of them needs a different grade of steel}.", ko: "…각 산업은 서로 다른 강종을 필요로 합니다.",
      gram: [ { t: "Each of them + 단수 동사", d: "each는 하나하나를 가리키므로 needs(단수)입니다. Each of them need ✗." } ],
      notes: [ { t: "a different grade of steel", k: "business", m: "서로 다른 강종", tip: "26회차 grade of steel. 자동차는 고강도·가공성, 가전은 표면 품질, 에너지는 두께·인성을 따집니다." } ] },
    { r: "It is automotive, appliance and energy customers that are driving our growth this year, although construction demand remains weak. Each of them needs a different grade of steel{rel:, which is why we assign a dedicated engineer}.", ko: "…각 산업은 서로 다른 강종을 필요로 하고, 그래서 우리는 전담 엔지니어를 배정합니다.",
      gram: [ { t: ", which is why + 절 = 그래서 ~하는 것이다", d: "1회차 , which와 2회차 That is why를 한 덩어리로 합친 틀입니다. 앞 사실을 받아 바로 우리의 대응으로 잇습니다." } ],
      notes: [ { t: "a dedicated engineer", k: "business", m: "전담 엔지니어", tip: "dedicated = 한 고객·업무만 맡는. a dedicated account manager(전담 영업 담당)." } ] },
    { r: "It is automotive, appliance and energy customers that are driving our growth this year, although construction demand remains weak. Each of them needs a different grade of steel, which is why we assign a dedicated engineer {place:to every major account}.", ko: "…그래서 우리는 주요 고객사마다 전담 엔지니어를 배정합니다.",
      gram: [ { t: "assign A to B = A를 B에 배정하다", d: "to 뒤에 받는 쪽. every major account = 모든 주요 거래처. account는 영업에서 '고객사'를 뜻합니다." } ],
      notes: [ { t: "major account", k: "business", m: "주요 거래처", tip: "key account management(핵심 고객 관리)는 영업 조직에서 쓰는 용어입니다." } ] },
    { r: "It is automotive, appliance and energy customers that are driving our growth this year, although construction demand remains weak. Each of them needs a different grade of steel, which is why we assign a dedicated engineer to every major account {purpose:so that problems are solved before they reach the line}.", ko: "건설 수요는 여전히 약하지만, 올해 우리 성장을 이끄는 건 자동차·가전·에너지 고객입니다. 각 산업은 서로 다른 강종을 필요로 하고, 그래서 우리는 문제가 고객의 생산 라인에 닿기 전에 해결되도록 주요 고객사마다 전담 엔지니어를 배정합니다.",
      gram: [ { t: "복습: so that + 수동", d: "26회차 so that에 수동(are solved)을 넣었습니다. 누가 푸느냐보다 '문제가 해결되는 것'에 초점을 둡니다. before 절은 현재형(reach)." } ],
      notes: [ { t: "before it reaches the line", k: "business", m: "(고객) 생산 라인에 닿기 전에", tip: "품질 문제를 사전에 잡는다는 영업의 핵심 약속입니다. 30회차를 처음 문장(Our production costs rose.)과 나란히 읽어 보세요." } ] }
  ],
  quiz: {
    blocks: ["It is automotive, appliance and energy customers", "that are driving our growth this year,", "although construction demand remains weak.", "Each of them needs a different grade of steel,", "which is why we assign a dedicated engineer", "to every major account", "so that problems are solved before they reach the line."],
    orders: [[0,1,2,3,4,5,6]]
  }
}
);
