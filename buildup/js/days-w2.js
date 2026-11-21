/* BUILD-UP — 8~14회차 (2주차: 분사구·명사절·관계절로 압축하기)
   형식은 days-w1.js 머리말. */
window.BU = window.BU || {};
BU.DAYS = BU.DAYS || [];
BU.DAYS.push(
{
  day: 8, cat: "주거", level: "B2", title: "Priced Out", titleKo: "집값에 밀려나다 — 분사구문",
  gist: "과거분사 구문(, priced out by) · 관계절 · by -ing · while -ing",
  steps: [
    { r: "{core:Many young professionals are leaving the capital}.", ko: "많은 젊은 직장인들이 수도를 떠나고 있습니다.",
      gram: [ { t: "뼈대: 현재진행 = 지금 벌어지는 흐름", d: "are leaving은 '지금 이 순간'이 아니라 '요즘 이어지는 추세'를 말합니다. 사회 현상을 말할 때 자주 쓰는 시제입니다." } ],
      notes: [ { t: "young professionals", k: "collocation", m: "젊은 직장인(전문직)", tip: "20~30대 사무직을 묶어 말할 때 쓰는 기사체 표현입니다." } ] },
    { r: "Many young professionals are leaving the capital{part:, priced out by rents}.", ko: "많은 젊은 직장인들이 집세에 밀려 수도를 떠나고 있습니다.",
      gram: [ { t: ", + 과거분사구 = 왜 그렇게 됐는지(수동)", d: "priced out by rents = 집세 때문에 (시장에서) 밀려나서. because they are priced out by rents를 분사 하나로 줄인 형태입니다. 주어(직장인들)가 '당한' 일이라 과거분사입니다." } ],
      notes: [ { t: "be priced out (of ~)", k: "idiom", m: "가격이 너무 올라 (~에서) 밀려나다", tip: "priced out of the housing market(주택 시장에서 밀려난)으로 자주 씁니다." } ] },
    { r: "Many young professionals are leaving the capital, priced out by rents {rel:that have doubled in a decade}.", ko: "10년 사이 두 배가 된 집세에 밀려, 많은 젊은 직장인들이 수도를 떠나고 있습니다.",
      gram: [ { t: "명사 + that + 현재완료", d: "rents that have doubled in a decade = 10년 사이 두 배가 된 집세. 현재완료는 '지금까지 그렇게 되어 온' 변화입니다." } ],
      notes: [ { t: "double", k: "collocation", m: "두 배가 되다", tip: "동사로 씁니다. triple(세 배), halve(반으로 줄다)도 같은 방식입니다." } ] },
    { r: "Many young professionals are leaving the capital, priced out by rents that have doubled in a decade. {add:They keep their city salaries}.", ko: "…그들은 도시 수준의 급여를 그대로 받습니다.",
      gram: [ { t: "새 문장: 흐름의 다른 면", d: "떠난 사람들이 무엇을 '잃지 않는지'를 짧게 말합니다. 다음 단계에서 방법과 대비를 붙입니다." } ],
      notes: [ { t: "city salary", k: "colloquial", m: "도시(수도권) 수준의 급여", tip: "regional pay(지역 급여 수준)와 대비되는 말입니다." } ] },
    { r: "Many young professionals are leaving the capital, priced out by rents that have doubled in a decade. They keep their city salaries {part:by working remotely}.", ko: "…그들은 원격으로 일하면서 도시 수준의 급여를 그대로 받습니다.",
      gram: [ { t: "by + -ing = 방법", d: "by working remotely = 원격으로 일함으로써. 2회차 learn by watching과 같은 쓰임입니다." } ] },
    { r: "Many young professionals are leaving the capital, priced out by rents that have doubled in a decade. They keep their city salaries by working remotely {contrast:while paying far less for housing}.", ko: "…원격으로 일하면서 도시 수준의 급여를 받고, 집에는 훨씬 적게 씁니다.",
      gram: [ { t: "while + -ing = ~하면서(동시에)", d: "while paying far less = 훨씬 적게 내면서. while 뒤에 주어 없이 -ing를 바로 붙여 '같은 사람이 동시에 하는 일'을 말합니다." } ],
      notes: [ { t: "pay less for ~", k: "collocation", m: "~에 돈을 덜 내다", tip: "pay for + 대상. pay far less for housing." } ] },
    { r: "Many young professionals are leaving the capital, priced out by rents that have doubled in a decade. They keep their city salaries by working remotely while paying far less for housing{rel:, which is gradually reshaping smaller towns}.", ko: "10년 사이 두 배가 된 집세에 밀려 많은 젊은 직장인들이 수도를 떠나고 있습니다. 그들은 원격으로 일하며 도시 수준의 급여를 받고 집에는 훨씬 적게 쓰는데, 이것이 작은 도시들의 모습을 서서히 바꾸고 있습니다.",
      gram: [ { t: ", which + 진행형 = 앞 흐름이 낳는 변화", d: "앞 문장 전체(이주 흐름)를 받아 그 결과를 말합니다. is gradually reshaping으로 '지금 진행 중인 변화'임을 보여 줍니다." } ],
      notes: [ { t: "reshape", k: "business", m: "모습을 바꾸다, 재편하다", tip: "change보다 구조가 바뀐다는 느낌. reshape the industry, reshape the market." } ] }
  ],
  quiz: {
    blocks: ["Many young professionals are leaving the capital,", "priced out by rents", "that have doubled in a decade.", "They keep their city salaries", "by working remotely", "while paying far less for housing,", "which is gradually reshaping smaller towns."],
    orders: [[0,1,2,3,4,5,6]]
  }
},
{
  day: 9, cat: "고객", level: "B2", title: "What Customers Actually Mean", titleKo: "고객이 진짜 불만인 것 — not A but B, whether, what",
  gist: "not A but B · when + 절 · whether 명사절 · what절",
  steps: [
    { r: "{core:The real problem is} {core:the uncertainty}.", ko: "진짜 문제는 불확실성입니다.",
      gram: [ { t: "뼈대: The real problem is + 명사", d: "결론부터 말하는 틀입니다. 회의에서 쟁점을 한 문장으로 잡을 때 씁니다." } ],
      notes: [ { t: "The real problem is ~", k: "business", m: "진짜 문제는 ~입니다", tip: "The real issue is ~ 도 같은 자리입니다. 표면적인 불만과 진짜 원인을 가를 때 씁니다." } ] },
    { r: "The real problem is {contrast:not the price but} the uncertainty.", ko: "진짜 문제는 가격이 아니라 불확실성입니다.",
      gram: [ { t: "not A but B", d: "흔한 오해(A)를 먼저 치우고 진짜(B)를 내놓습니다. A와 B는 같은 품사(명사-명사)로 맞춥니다." } ],
      notes: [ { t: "not A but B", k: "grammar", m: "A가 아니라 B", tip: "말할 때는 not 뒤를 살짝 낮게, but 뒤를 힘주어 읽으면 대비가 살아납니다." } ] },
    { r: "The real problem is not the price but the uncertainty. {add:Our customers cannot plan production}.", ko: "…고객들은 생산 계획을 세울 수가 없습니다.",
      gram: [ { t: "새 문장: 불확실성이 낳는 결과", d: "추상적인 말(uncertainty)을 구체적인 피해(생산 계획 불가)로 바로 풀어 줍니다." } ],
      notes: [ { t: "plan production", k: "business", m: "생산 계획을 세우다", tip: "production planning(생산 계획)이라는 명사형도 자주 씁니다." } ] },
    { r: "The real problem is not the price but the uncertainty. Our customers cannot plan production {time:when they do not know}.", ko: "…알지 못할 때는 고객들이 생산 계획을 세울 수가 없습니다.",
      gram: [ { t: "when + 절 = ~할 때(조건처럼)", d: "when they do not know = 모를 때. if와 비슷하지만 '그런 상황이 자주 있다'는 느낌입니다." } ] },
    { r: "The real problem is not the price but the uncertainty. Our customers cannot plan production when they do not know {clause:whether an order will arrive}.", ko: "…주문품이 도착할지 모를 때는 고객들이 생산 계획을 세울 수가 없습니다.",
      gram: [ { t: "whether + 절 = ~인지 아닌지", d: "know의 목적어로 whether절을 씁니다. 명사절 안에서는 미래라도 will을 그대로 씁니다(조건절과 다름)." } ],
      trap: [ { ng: "when they do not know whether will an order arrive", why: "whether 뒤는 의문문 어순이 아니라 평서문 어순(주어 + 동사)입니다." } ] },
    { r: "The real problem is not the price but the uncertainty. Our customers cannot plan production when they do not know whether an order will arrive {time:on Monday or Thursday}.", ko: "…주문품이 월요일에 올지 목요일에 올지 모를 때는 생산 계획을 세울 수가 없습니다.",
      gram: [ { t: "A or B로 막연함을 구체로", d: "'언제 올지 모른다'보다 '월요일인지 목요일인지'가 훨씬 생생합니다. 숫자·요일 같은 구체가 설득력을 만듭니다." } ] },
    { r: "The real problem is not the price but the uncertainty. Our customers cannot plan production when they do not know whether an order will arrive on Monday or Thursday{add:, and that is what they actually complain about}.", ko: "진짜 문제는 가격이 아니라 불확실성입니다. 주문품이 월요일에 올지 목요일에 올지 모르면 고객들은 생산 계획을 세울 수가 없고, 그들이 실제로 불평하는 건 바로 그 점입니다.",
      gram: [ { t: "that is what + 절 = 그것이 바로 ~하는 것", d: "what they complain about = 그들이 불평하는 것. 앞 내용을 that으로 받고 what절로 '바로 그것'이라고 못 박습니다." } ],
      notes: [ { t: "complain about ~", k: "collocation", m: "~에 대해 불평하다", tip: "what절 안에서 전치사 about이 끝에 남습니다. what they complain about." } ] }
  ],
  quiz: {
    blocks: ["The real problem is", "not the price but the uncertainty.", "Our customers cannot plan production", "when they do not know", "whether an order will arrive", "on Monday or Thursday,", "and that is what they actually complain about."],
    orders: [[0,1,2,3,4,5,6]]
  }
},
{
  day: 10, cat: "데이터", level: "B2+", title: "Hidden in Plain Sight", titleKo: "약관 속 개인정보 — 가주어 it과 that절",
  gist: "It was … that(가주어) · but · 관계절 · It is hardly surprising that",
  steps: [
    { r: "{core:It was never hidden}.", ko: "그건 결코 숨겨진 적이 없습니다.",
      gram: [ { t: "뼈대: It + be + 형용사", d: "It은 아직 말하지 않은 내용을 대신 세워 둔 '가주어'입니다. 다음 단계에서 that절로 진짜 주어를 붙입니다." } ] },
    { r: "It was never hidden {clause:that our app collects location data}.", ko: "우리 앱이 위치 정보를 수집한다는 사실은 결코 숨겨진 적이 없습니다.",
      gram: [ { t: "It … that절 = 긴 주어를 뒤로", d: "That our app collects location data was never hidden처럼 긴 that절을 주어로 쓰면 머리가 무거워집니다. It을 앞에 세우고 내용을 뒤로 보내면 영어답게 읽힙니다." } ],
      notes: [ { t: "collect data", k: "collocation", m: "데이터를 수집하다", tip: "gather보다 체계적으로 모은다는 느낌. collect personal data." } ] },
    { r: "It was never hidden that our app collects location data{contrast:, but the detail was buried in a forty-page policy}.", ko: "…숨긴 적은 없지만, 그 내용은 40쪽짜리 약관 속에 묻혀 있었습니다.",
      gram: [ { t: ", but + 절 = 반전", d: "앞에서 인정한 사실(숨기지 않았다)을 뒤에서 뒤집습니다. 숨기지는 않았지만 사실상 안 보였다는 대비가 요점입니다." } ],
      notes: [ { t: "be buried in ~", k: "idiom", m: "~속에 묻혀 있다(찾기 어렵다)", tip: "The key point was buried in the appendix(핵심이 부록에 묻혀 있었다)." } ] },
    { r: "It was never hidden that our app collects location data, but the detail was buried in a forty-page policy {rel:that almost nobody reads}.", ko: "…그 내용은 거의 아무도 읽지 않는 40쪽짜리 약관 속에 묻혀 있었습니다.",
      gram: [ { t: "관계절로 '어떤 약관인지'", d: "that almost nobody reads = 거의 아무도 읽지 않는. 현재형으로 '언제나 그렇다'는 일반적 사실을 말합니다." } ],
      notes: [ { t: "almost nobody", k: "grammar", m: "거의 아무도 ~ 않다", tip: "nobody 자체가 부정이라 동사는 긍정(reads)으로 씁니다. almost nobody doesn't read ✗." } ] },
    { r: "It was never hidden that our app collects location data, but the detail was buried in a forty-page policy that almost nobody reads. {add:It is hardly surprising}.", ko: "…놀랄 일도 아닙니다.",
      gram: [ { t: "It is hardly + 형용사", d: "hardly = 거의 ~ 아니다. It is hardly surprising = 놀랄 일이 아니다. not surprising보다 '당연하다'는 판단이 더 단단합니다." } ] },
    { r: "It was never hidden that our app collects location data, but the detail was buried in a forty-page policy that almost nobody reads. It is hardly surprising {clause:that users felt misled}.", ko: "…사용자들이 속았다고 느낀 것도 놀랄 일이 아닙니다.",
      gram: [ { t: "다시 It … that절", d: "1~2단계와 같은 가주어 틀을 두 번째 문장에도 씁니다. 같은 틀을 반복하면 글이 정돈되어 보입니다." } ],
      notes: [ { t: "feel misled", k: "collocation", m: "오도당했다고 느끼다", tip: "mislead(오도하다)의 과거분사. lied to(거짓말을 들은)보다 덜 극단적인 표현입니다." } ] },
    { r: "It was never hidden that our app collects location data, but the detail was buried in a forty-page policy that almost nobody reads. It is hardly surprising that users felt misled {time:when the story finally appeared in the press}.", ko: "우리 앱이 위치 정보를 수집한다는 사실은 숨긴 적이 없지만, 그 내용은 거의 아무도 읽지 않는 40쪽짜리 약관에 묻혀 있었습니다. 그 이야기가 마침내 언론에 나왔을 때 사용자들이 속았다고 느낀 것도 놀랄 일이 아닙니다.",
      gram: [ { t: "when + 과거 = 그 일이 터진 때", d: "felt misled가 '언제' 일어났는지를 붙입니다. finally는 '오래 묻혀 있다가 마침내'의 느낌을 더합니다." } ],
      notes: [ { t: "appear in the press", k: "collocation", m: "언론에 보도되다", tip: "hit the headlines(헤드라인을 장식하다)는 더 구어적인 표현입니다." } ] }
  ],
  quiz: {
    blocks: ["It was never hidden", "that our app collects location data,", "but the detail was buried", "in a forty-page policy", "that almost nobody reads.", "It is hardly surprising", "that users felt misled", "when the story finally appeared in the press."],
    orders: [[0,1,2,3,4,5,6,7]]
  }
},
{
  day: 11, cat: "인구", level: "B2+", title: "Fewer Hands", titleKo: "고령화 — with + 명사 + -ing",
  gist: "treat A as B · to be p.p. · with + 명사 + -ing · if anything · 비교",
  steps: [
    { r: "{core:Companies can no longer treat older employees as a cost}.", ko: "기업들은 더 이상 고령 직원을 비용으로만 볼 수 없습니다.",
      gram: [ { t: "뼈대: treat A as B", d: "treat A as B = A를 B로 대하다(여기다). can no longer = 더 이상 ~할 수 없다." } ],
      notes: [ { t: "treat A as B", k: "collocation", m: "A를 B로 취급하다", tip: "see A as B, regard A as B도 같은 틀입니다. treat은 '실제로 그렇게 대한다'는 행동에 초점이 있습니다." } ] },
    { r: "Companies can no longer treat older employees as a cost {mod:to be managed}.", ko: "기업들은 더 이상 고령 직원을 관리해야 할 비용으로 볼 수 없습니다.",
      gram: [ { t: "명사 + to be p.p. = ~되어야 할", d: "a cost to be managed = 관리되어야 할 비용. 명사 뒤의 to부정사가 그 명사를 꾸밉니다. 비용이 '관리되는' 쪽이라 수동(to be managed)입니다." } ] },
    { r: "Companies can no longer treat older employees as a cost to be managed{part:, with the working-age population shrinking every year}.", ko: "생산가능인구가 해마다 줄어드는 상황에서, 기업들은 더 이상 고령 직원을 관리해야 할 비용으로 볼 수 없습니다.",
      gram: [ { t: "with + 명사 + -ing = ~가 …하는 상황에서", d: "배경 상황을 한 덩어리로 붙입니다. with the population shrinking = 인구가 줄어드는 가운데. because the population is shrinking을 압축한 형태입니다." } ],
      notes: [ { t: "working-age population", k: "business", m: "생산가능인구", tip: "보통 15~64세. labor force(경제활동인구)와는 다른 개념입니다." } ] },
    { r: "Companies can no longer treat older employees as a cost to be managed, with the working-age population shrinking every year. {add:Their experience} {add:is becoming harder to replace}.", ko: "…그들의 경험은 점점 대체하기 어려워지고 있습니다.",
      gram: [ { t: "is becoming + 비교급", d: "점점 ~해지고 있다. 진행형으로 '변화가 계속되는 중'임을 보여 줍니다. harder to replace = 대체하기 더 어려운." } ] },
    { r: "Companies can no longer treat older employees as a cost to be managed, with the working-age population shrinking every year. Their experience{hedge:, if anything,} is becoming harder to replace.", ko: "…오히려 그들의 경험은 점점 대체하기 어려워지고 있습니다.",
      gram: [ { t: ", if anything, = 오히려, 굳이 말하자면", d: "앞 내용과 반대 방향으로 '오히려 더'라고 말할 때 주어 뒤에 끼웁니다. 비용이 아니라 오히려 자산이라는 반전을 부드럽게 만듭니다." } ],
      notes: [ { t: "if anything", k: "idiom", m: "오히려, 굳이 따지면", tip: "It isn't cheaper. If anything, it's more expensive(싸지 않다. 오히려 더 비싸다)." } ] },
    { r: "Companies can no longer treat older employees as a cost to be managed, with the working-age population shrinking every year. Their experience, if anything, is becoming harder to replace {compare:than any piece of equipment}.", ko: "생산가능인구가 해마다 줄어드는 상황에서, 기업들은 더 이상 고령 직원을 관리해야 할 비용으로 볼 수 없습니다. 오히려 그들의 경험은 어떤 설비보다도 대체하기 어려워지고 있습니다.",
      gram: [ { t: "비교급 + than any + 단수 명사", d: "than any piece of equipment = 어떤 설비보다도. 사실상 최상급의 뜻을 비교급으로 말하는 방식입니다." } ],
      notes: [ { t: "a piece of equipment", k: "grammar", m: "설비 한 대", tip: "equipment는 셀 수 없어서 an equipment가 아니라 a piece of equipment입니다." } ] }
  ],
  quiz: {
    blocks: ["Companies can no longer treat", "older employees as a cost", "to be managed,", "with the working-age population", "shrinking every year.", "Their experience,", "if anything,", "is becoming harder to replace", "than any piece of equipment."],
    orders: [[0,1,2,3,4,5,6,7,8]]
  }
},
{
  day: 12, cat: "회의", level: "B2", title: "Meetings That Decide Nothing", titleKo: "아무것도 정하지 못하는 회의 — 축약 관계절",
  gist: "명사 + 과거분사(made in) · tend to be p.p. · unless · , so",
  steps: [
    { r: "{core:Decisions} {core:tend to be reopened}.", ko: "결정은 다시 뒤집히는 경향이 있습니다.",
      gram: [ { t: "뼈대: tend to + 수동", d: "tend to be reopened = 다시 열리는(재논의되는) 경향이 있다. 일반적인 패턴을 말할 때 단정 대신 tend to를 씁니다." } ],
      notes: [ { t: "reopen a decision", k: "business", m: "결정을 다시 논의하다", tip: "revisit a decision 도 같은 뜻입니다. 회의록에 자주 나옵니다." } ] },
    { r: "Decisions {part:made in meetings} tend to be reopened.", ko: "회의에서 내린 결정은 다시 뒤집히는 경향이 있습니다.",
      gram: [ { t: "명사 + 과거분사구 = ~된 명사", d: "decisions made in meetings = decisions that are made in meetings에서 that are를 뺀 축약 관계절입니다. 주어와 동사 사이에 끼워도 문장이 무거워지지 않습니다." } ],
      notes: [ { t: "make a decision", k: "collocation", m: "결정을 내리다", tip: "do a decision ✗. 수동으로는 a decision is made." } ] },
    { r: "Decisions made in meetings {mod:without a clear owner} tend to be reopened.", ko: "책임자가 분명하지 않은 회의에서 내린 결정은 다시 뒤집히는 경향이 있습니다.",
      gram: [ { t: "without + 명사로 조건 좁히기", d: "모든 회의가 아니라 '책임자 없는 회의'로 범위를 좁힙니다. 주장이 정확해지는 단계입니다." } ],
      notes: [ { t: "owner", k: "business", m: "(일·결정의) 책임자", tip: "업무에서 owner는 '소유자'가 아니라 '맡아 끝까지 책임지는 사람'입니다. Who owns this?" } ] },
    { r: "Decisions made in meetings without a clear owner tend to be reopened {time:a week later}.", ko: "책임자가 분명하지 않은 회의에서 내린 결정은 일주일 뒤 다시 뒤집히곤 합니다.",
      gram: [ { t: "a week later = 일주일 뒤에", d: "기간 + later는 '그로부터 ~ 뒤'. 구체적인 시간을 붙이면 경험에서 나온 말처럼 들립니다." } ] },
    { r: "Decisions made in meetings without a clear owner tend to be reopened a week later. {add:Everyone assumes someone else will follow up}.", ko: "…다들 다른 누군가가 후속 조치를 하리라 여깁니다.",
      gram: [ { t: "assume (that) + 절", d: "assume = (확인 없이) ~라고 여기다. that은 생략했습니다. 원인을 사람의 심리로 짚는 문장입니다." } ],
      notes: [ { t: "follow up", k: "phrasal", m: "후속 조치를 하다", tip: "명사로는 follow-up. I'll follow up with an email(메일로 후속 연락 드리겠습니다)." } ] },
    { r: "Decisions made in meetings without a clear owner tend to be reopened a week later. Everyone assumes someone else will follow up {cond:unless one person is named in the minutes}.", ko: "…회의록에 한 사람 이름이 적히지 않으면, 다들 다른 누군가가 후속 조치를 하리라 여깁니다.",
      gram: [ { t: "unless = ~하지 않는 한", d: "5회차와 같은 unless입니다. 해결책(이름을 적는 것)을 조건으로 슬쩍 넣었습니다." } ],
      notes: [ { t: "the minutes", k: "business", m: "회의록", tip: "항상 복수형 minutes. take the minutes(회의록을 쓰다)." } ] },
    { r: "Decisions made in meetings without a clear owner tend to be reopened a week later. Everyone assumes someone else will follow up unless one person is named in the minutes{result:, so nothing actually moves}.", ko: "책임자가 분명하지 않은 회의에서 내린 결정은 일주일 뒤 다시 뒤집히곤 합니다. 회의록에 한 사람 이름이 적히지 않으면 다들 다른 누군가가 하리라 여기고, 그래서 실제로는 아무것도 진행되지 않습니다.",
      gram: [ { t: ", so + 절 = 그래서", d: "가장 구어적인 결과 연결입니다. 1회차 As a result보다 가볍고 빠릅니다." } ],
      notes: [ { t: "nothing moves", k: "colloquial", m: "아무것도 진척되지 않다", tip: "Things are moving(일이 굴러가고 있다)의 반대. stall도 같은 뜻입니다." } ] }
  ],
  quiz: {
    blocks: ["Decisions", "made in meetings", "without a clear owner", "tend to be reopened", "a week later.", "Everyone assumes someone else will follow up", "unless one person is named in the minutes,", "so nothing actually moves."],
    orders: [[0,1,2,3,4,5,6,7]]
  }
},
{
  day: 13, cat: "철강·자동차", level: "B2+", title: "Lighter, Not Weaker", titleKo: "차체 경량화 — 결과 분사구문과 the 비교급",
  gist: "결과 분사구문(, cutting) · without -ing · The 비교급 …, the 비교급 …",
  steps: [
    { r: "{core:The carmaker switched to high-strength steel}.", ko: "그 자동차 회사는 고강도 강판으로 바꿨습니다.",
      gram: [ { t: "뼈대: switch to ~ = ~로 바꾸다", d: "switch from A to B = A에서 B로 바꾸다. 소재·공급사·시스템을 바꿀 때 가장 흔히 쓰는 동사입니다." } ],
      notes: [ { t: "high-strength steel", k: "business", m: "고강도 강(강판)", tip: "advanced high-strength steel(AHSS)은 더 높은 등급을 가리키는 업계 용어입니다." } ] },
    { r: "The carmaker switched to high-strength steel {mod:for the door frames}.", ko: "그 자동차 회사는 도어 프레임을 고강도 강판으로 바꿨습니다.",
      gram: [ { t: "for + 부위 = 어디에 쓰는지", d: "for the door frames = 도어 프레임용으로. 범위를 좁혀 구체적인 사례로 만듭니다." } ] },
    { r: "The carmaker switched to high-strength steel for the door frames{part:, cutting each body by eight kilograms}.", ko: "그 자동차 회사는 도어 프레임을 고강도 강판으로 바꿔, 차체 한 대당 8킬로그램을 줄였습니다.",
      gram: [ { t: ", + -ing = 그 결과 ~했다", d: "cutting each body by eight kilograms = 그래서 차체를 8kg 줄였다. and it cut ~을 분사로 압축한 '결과 분사구문'입니다. 8회차의 과거분사(이유)와 달리 -ing는 주어가 '한' 일입니다." } ],
      notes: [ { t: "cut A by + 수치", k: "collocation", m: "A를 ~만큼 줄이다", tip: "1회차 by(변화의 폭)와 같은 by입니다. cut weight by 8 kg." } ] },
    { r: "The carmaker switched to high-strength steel for the door frames, cutting each body by eight kilograms {mod:without losing crash performance}.", ko: "…충돌 성능은 그대로 두면서 차체 한 대당 8킬로그램을 줄였습니다.",
      gram: [ { t: "without + -ing = ~하지 않고", d: "without losing = 잃지 않고. 가볍게 만들면 약해지리라는 걱정을 미리 막는 덩어리입니다." } ],
      notes: [ { t: "crash performance", k: "business", m: "충돌 성능(충돌 안전성)", tip: "crashworthiness라는 전문 용어도 있습니다." } ] },
    { r: "The carmaker switched to high-strength steel for the door frames, cutting each body by eight kilograms without losing crash performance. {add:The thinner the sheet can be, the less fuel the car burns}.", ko: "…강판이 얇아질수록 차가 쓰는 연료는 줄어듭니다.",
      gram: [ { t: "The + 비교급 …, the + 비교급 … = ~할수록 …하다", d: "앞 절과 뒤 절이 함께 움직입니다. The thinner the sheet (can be), the less fuel (the car burns). 둘 다 the + 비교급으로 시작하는 것이 핵심입니다." } ],
      trap: [ { ng: "The sheet can be thinner, the less fuel...", why: "앞 절도 The + 비교급으로 시작해야 짝이 맞습니다." } ] },
    { r: "The carmaker switched to high-strength steel for the door frames, cutting each body by eight kilograms without losing crash performance. The thinner the sheet can be, the less fuel the car burns {time:over its lifetime}.", ko: "그 자동차 회사는 도어 프레임을 고강도 강판으로 바꿔, 충돌 성능은 그대로 둔 채 차체 한 대당 8킬로그램을 줄였습니다. 강판이 얇아질수록 차가 평생 쓰는 연료는 줄어듭니다.",
      gram: [ { t: "over + 기간 = ~에 걸쳐", d: "over its lifetime = 차의 수명 전체에 걸쳐. 한 번의 효과가 아니라 쌓이는 효과라는 점을 보여 줍니다." } ],
      notes: [ { t: "lifetime", k: "business", m: "(제품의) 수명 기간", tip: "lifetime cost(생애 비용), over the life of the vehicle도 같은 뜻입니다." } ] }
  ],
  quiz: {
    blocks: ["The carmaker switched to high-strength steel", "for the door frames,", "cutting each body by eight kilograms", "without losing crash performance.", "The thinner the sheet can be,", "the less fuel the car burns", "over its lifetime."],
    orders: [[0,1,2,3,4,5,6]]
  }
},
{
  day: 14, cat: "관광", level: "B2+", title: "Too Many Visitors", titleKo: "관광 과잉 — 2주차 총정리",
  gist: "총정리: 삽입 형용사구 · what절 주어 · not A but B · 관계절 · 결과 분사구문",
  steps: [
    { r: "{core:The old town} {core:is slowly emptying out}.", ko: "구시가지가 서서히 비어 가고 있습니다.",
      gram: [ { t: "뼈대: 현재진행 + 부사", d: "is slowly emptying out = 서서히 비어 가는 중이다. 8회차처럼 진행형으로 '흐름'을 말합니다." } ],
      notes: [ { t: "empty out", k: "phrasal", m: "(사람이 떠나) 텅 비다", tip: "The office empties out on Fridays(금요일엔 사무실이 텅 빈다)." } ] },
    { r: "The old town{part:, popular with visitors but expensive for residents,} is slowly emptying out.", ko: "방문객에게는 인기지만 주민에게는 비싼 구시가지가 서서히 비어 가고 있습니다.",
      gram: [ { t: "주어 뒤에 끼우는 형용사구", d: "popular with visitors but expensive for residents = 방문객에겐 인기, 주민에겐 비싼. which is ~를 뺀 압축형입니다. 양쪽을 쉼표로 감싸 한 번에 끼웁니다." } ],
      notes: [ { t: "popular with ~", k: "grammar", m: "~에게 인기 있는", tip: "전치사는 with입니다. popular to ✗." } ] },
    { r: "The old town, popular with visitors but expensive for residents, is slowly emptying out. {add:What locals object to is} {add:the short-term rentals}.", ko: "…주민들이 반대하는 것은 단기 임대입니다.",
      gram: [ { t: "What절 주어 = ~하는 것은", d: "What locals object to(주민들이 반대하는 것)가 통째로 주어입니다. 9회차 what절이 이번엔 문장 맨 앞에 섰습니다. 무게를 뒤쪽(진짜 답)에 싣는 틀입니다." } ],
      notes: [ { t: "object to ~", k: "collocation", m: "~에 반대하다", tip: "to는 전치사라 뒤에 명사·동명사가 옵니다. object to paying ✓, object to pay ✗." } ] },
    { r: "The old town, popular with visitors but expensive for residents, is slowly emptying out. What locals object to is {contrast:not tourism itself but} the short-term rentals.", ko: "…주민들이 반대하는 것은 관광 자체가 아니라 단기 임대입니다.",
      gram: [ { t: "복습: not A but B", d: "9회차 틀이 what절과 만났습니다. 흔한 오해(관광 반대)를 치우고 진짜 원인(단기 임대)을 내놓습니다." } ],
      notes: [ { t: "~ itself", k: "grammar", m: "~ 그 자체", tip: "tourism itself = 관광 그 자체. 범위를 좁혀 '그것 말고 다른 것'을 예고합니다." } ] },
    { r: "The old town, popular with visitors but expensive for residents, is slowly emptying out. What locals object to is not tourism itself but the short-term rentals {rel:that have replaced long-term tenants}.", ko: "…주민들이 반대하는 것은 관광 자체가 아니라, 장기 세입자를 밀어낸 단기 임대입니다.",
      gram: [ { t: "복습: 관계절 + 현재완료", d: "8회차 rents that have doubled와 같은 짜임입니다. 지금까지 벌어진 변화를 관계절로 붙입니다." } ],
      notes: [ { t: "long-term tenant", k: "business", m: "장기 세입자", tip: "short-term rental(단기 임대)과 짝으로 씁니다." } ] },
    { r: "The old town, popular with visitors but expensive for residents, is slowly emptying out. What locals object to is not tourism itself but the short-term rentals that have replaced long-term tenants{part:, pushing up rents across the district}.", ko: "방문객에게는 인기지만 주민에게는 비싼 구시가지가 서서히 비어 가고 있습니다. 주민들이 반대하는 것은 관광 자체가 아니라 장기 세입자를 밀어낸 단기 임대이고, 그 때문에 지역 전체의 집세가 오르고 있습니다.",
      gram: [ { t: "복습: 결과 분사구문", d: "13회차 , cutting과 같은 자리입니다. 단기 임대가 낳은 결과(집세 상승)를 -ing로 붙입니다." } ],
      notes: [ { t: "push up prices", k: "phrasal", m: "가격을 밀어 올리다", tip: "drive up 도 같은 뜻입니다. push down / drive down은 반대." } ] }
  ],
  quiz: {
    blocks: ["The old town,", "popular with visitors but expensive for residents,", "is slowly emptying out.", "What locals object to is", "not tourism itself but", "the short-term rentals", "that have replaced long-term tenants,", "pushing up rents across the district."],
    orders: [[0,1,2,3,4,5,6,7]]
  }
}
);
