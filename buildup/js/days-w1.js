/* BUILD-UP — 1~7회차 (1주차: 이유·결과·양보·관계절로 늘리기)
   r: 그 단계의 문장. {역할:…} 이 이번에 새로 붙은 덩어리. ko: 뜻. gram: 이번에 붙인 구조 해설.
   notes: 표현 노트(ROUNDTABLE과 같은 t·k·m·tip). trap: 틀리기 쉬운 것. quiz.blocks: 이으면 완성 문장. */
window.BU = window.BU || {};
BU.DAYS = BU.DAYS || [];
BU.DAYS.push(
{
  day: 1, cat: "경제", level: "B2", title: "When Costs Climb", titleKo: "비용이 오를 때 — 이유와 결과 붙이기",
  gist: "by + 수치 · because · , which(앞 절 받기) · As a result",
  steps: [
    { r: "{core:Our production costs rose}.", ko: "우리 생산 비용이 올랐습니다.",
      gram: [ { t: "뼈대: 주어 + 자동사", d: "rise(오르다)는 목적어 없이 쓰는 자동사입니다. 과거형 rose. 무엇이 어떻게 됐는지만 말하는 가장 짧은 문장에서 출발합니다." } ],
      notes: [ { t: "production costs", k: "business", m: "생산 비용", tip: "보통 복수형으로 씁니다. the cost of production 도 같은 뜻입니다." } ],
      trap: [ { ng: "Our production costs raised.", why: "raise는 '~을 올리다'라는 타동사라 목적어가 필요합니다. 스스로 오르면 rise입니다." } ] },
    { r: "Our production costs rose {quant:by twelve percent}.", ko: "우리 생산 비용이 12퍼센트 올랐습니다.",
      gram: [ { t: "by + 수치 = 변화의 폭", d: "rose by 12% 는 '12%만큼 올랐다'입니다. rose to 12% 라고 하면 '12%가 되었다(도달점)'로 뜻이 바뀝니다." } ],
      notes: [ { t: "increase / fall / drop by ~", k: "grammar", m: "~만큼 늘다 / 줄다", tip: "변화의 폭에는 by, 도달한 값에는 to. 회의 숫자 보고에서 가장 자주 헷갈리는 곳입니다." } ] },
    { r: "Our production costs rose by twelve percent {time:last year}.", ko: "우리 생산 비용이 작년에 12퍼센트 올랐습니다.",
      gram: [ { t: "때는 문장 끝", d: "last year, last quarter 같은 때 표현은 보통 문장 끝에 둡니다. 숫자와 때가 나란히 오면 '얼마나 → 언제' 순서가 자연스럽습니다." } ],
      trap: [ { ng: "...by twelve percent in last year.", why: "last·next·this 앞에는 in을 쓰지 않습니다." } ] },
    { r: "Our production costs rose by twelve percent last year {reason:because energy prices surged}.", ko: "에너지 가격이 급등해서 우리 생산 비용이 작년에 12퍼센트 올랐습니다.",
      gram: [ { t: "because + 절 = 이유", d: "이유를 같은 문장 안에 붙입니다. because 뒤에는 주어 + 동사가 있는 완전한 절이 옵니다. 명사만 오면 because of 입니다." } ],
      notes: [ { t: "surge", k: "business", m: "급등하다", tip: "rise보다 훨씬 빠르고 큰 오름입니다. 수요·가격·주문에 자주 씁니다. a surge in demand." } ] },
    { r: "Our production costs rose by twelve percent last year because energy prices surged{rel:, which squeezed our margins}.", ko: "에너지 가격이 급등해서 우리 생산 비용이 작년에 12퍼센트 올랐고, 그것이 우리 마진을 짓눌렀습니다.",
      gram: [ { t: ", which = 앞 내용 전체를 받는다", d: "쉼표 + which가 앞 절 전체(비용이 오른 일)를 받아 '그리고 그것이 ~했다'로 잇습니다. 한국어로는 '~했고, 그 탓에'에 가깝습니다." } ],
      notes: [ { t: "squeeze margins", k: "collocation", m: "마진을 짓누르다", tip: "margins are under pressure 와 같은 뜻의 더 생생한 표현입니다." } ],
      trap: [ { ng: "..., that squeezed our margins.", why: "쉼표 뒤에 이어 붙이는 관계절(계속적 용법)에는 that을 쓰지 않습니다." } ] },
    { r: "Our production costs rose by twelve percent last year because energy prices surged, which squeezed our margins. {add:As a result, we had to renegotiate several long-term contracts}.", ko: "…그것이 우리 마진을 짓눌렀습니다. 그 결과 우리는 장기 계약 몇 건을 재협상해야 했습니다.",
      gram: [ { t: "두 번째 문장 + As a result", d: "결과는 새 문장으로 떼어 As a result로 엽니다. 한 문장에 다 몰아넣는 것보다 듣는 사람이 숨을 쉴 자리가 생깁니다." } ],
      notes: [
        { t: "As a result,", k: "business", m: "그 결과", tip: "So보다 격식 있고, 보고·회의에서 인과를 또렷하게 합니다." },
        { t: "renegotiate a contract", k: "business", m: "계약을 재협상하다", tip: "long-term contract(장기 계약)와 자주 함께 씁니다." }
      ] },
    { r: "Our production costs rose by twelve percent last year because energy prices surged, which squeezed our margins. As a result, we had to renegotiate several long-term contracts {mod:with our largest customers}.", ko: "에너지 가격이 급등해서 우리 생산 비용이 작년에 12퍼센트 올랐고, 그것이 우리 마진을 짓눌렀습니다. 그 결과 우리는 최대 고객사들과 맺은 장기 계약 몇 건을 재협상해야 했습니다.",
      gram: [ { t: "with + 상대 = 누구와의", d: "계약·협상·합의는 상대 앞에 with를 씁니다. renegotiate contracts with our customers." } ],
      notes: [ { t: "our largest customers", k: "business", m: "최대 고객사들", tip: "거래 규모가 가장 큰 곳. key accounts 라고도 합니다." } ] }
  ],
  quiz: {
    blocks: ["Our production costs rose", "by twelve percent", "last year", "because energy prices surged,", "which squeezed our margins.", "As a result,", "we had to renegotiate", "several long-term contracts", "with our largest customers."],
    orders: [[0,1,2,3,4,5,6,7,8]]
  }
},
{
  day: 2, cat: "일하는 방식", level: "B2", title: "Remote, but Not Easy", titleKo: "재택근무의 득실 — 양보와 이유",
  gist: "make + O + 형용사 + to부정사 · although · 지각동사 + O + 동사원형 · That is why",
  steps: [
    { r: "{core:Remote work makes informal feedback harder to give}.", ko: "재택근무는 가벼운 피드백을 주기 더 어렵게 만듭니다.",
      gram: [ { t: "뼈대: make + 목적어 + 형용사 + to부정사", d: "make A harder to do = A를 ~하기 더 어렵게 만들다. 원인(Remote work)을 주어로 세우면 짧은 문장으로 영향을 말할 수 있습니다." } ],
      notes: [ { t: "informal feedback", k: "collocation", m: "격식 없는 피드백, 지나가며 주는 조언", tip: "회의에서 주는 공식 평가(formal review)와 대비되는 말입니다." } ] },
    { r: "Remote work makes informal feedback harder to give{contrast:, although it saves our team two hours a day}.", ko: "재택근무는 우리 팀에게 하루 두 시간을 아껴 주지만, 가벼운 피드백은 주기 더 어렵게 만듭니다.",
      gram: [ { t: ", although + 절 = 양보", d: "although는 '~이긴 하지만'. 장점을 인정하면서 단점을 말하는 균형 잡힌 문장이 됩니다. 뒤에 붙이면 '물론 ~이긴 하지만' 하고 덧붙이는 느낌입니다." } ],
      notes: [ { t: "save someone time", k: "collocation", m: "~에게 시간을 아껴 주다", tip: "save + 사람 + 시간. It saves us two hours a day." } ],
      trap: [ { ng: "although it saves..., but it makes...", why: "although와 but을 한 문장에 함께 쓰지 않습니다. 둘 중 하나만." } ] },
    { r: "Remote work makes informal feedback harder to give, although it saves our team two hours a day. {add:Junior staff are hit hardest}.", ko: "…하루 두 시간을 아껴 주지만요. 가장 큰 타격을 받는 건 저연차 직원들입니다.",
      gram: [ { t: "새 문장: 누가 가장 영향을 받나", d: "be hit hardest = 가장 큰 타격을 받다. 수동태로 '당하는 쪽'을 주어로 세웁니다." } ],
      notes: [ { t: "be hit hardest", k: "collocation", m: "가장 큰 타격을 받다", tip: "be hit hard by ~ (~로 큰 타격을 받다)의 최상급입니다. 경제 기사 단골 표현입니다." } ] },
    { r: "Remote work makes informal feedback harder to give, although it saves our team two hours a day. Junior staff are hit hardest{reason:, because they learn by watching senior colleagues}.", ko: "…가장 큰 타격을 받는 건 저연차 직원들입니다. 선배들을 보면서 배우기 때문입니다.",
      gram: [ { t: "by + -ing = ~함으로써", d: "learn by watching = 보면서(봄으로써) 배우다. 방법을 말할 때 by 뒤에는 동명사를 씁니다." } ],
      notes: [ { t: "senior colleagues", k: "business", m: "선배 동료, 경력이 많은 동료", tip: "senior는 나이가 아니라 경력·직급을 말합니다." } ] },
    { r: "Remote work makes informal feedback harder to give, although it saves our team two hours a day. Junior staff are hit hardest, because they learn by watching senior colleagues {compl:handle difficult calls}.", ko: "…선배들이 어려운 통화를 처리하는 모습을 보면서 배우기 때문입니다.",
      gram: [ { t: "watch + 목적어 + 동사원형", d: "지각동사(watch·see·hear) 뒤에는 '목적어 + 동사원형'으로 그 사람이 하는 일을 붙입니다. watch colleagues handle calls = 동료가 통화를 처리하는 것을 보다." } ],
      notes: [ { t: "handle a difficult call", k: "business", m: "까다로운 통화를 처리하다", tip: "handle은 '다루다·처리하다'. handle a complaint, handle pressure." } ],
      trap: [ { ng: "watching senior colleagues to handle difficult calls", why: "지각동사 뒤에는 to를 붙이지 않습니다. 동사원형 또는 -ing(진행 중인 모습)." } ] },
    { r: "Remote work makes informal feedback harder to give, although it saves our team two hours a day. Junior staff are hit hardest, because they learn by watching senior colleagues handle difficult calls. {add:That is why we now bring everyone into the office}.", ko: "…그래서 지금은 모두를 사무실로 불러 모읍니다.",
      gram: [ { t: "That is why + 절 = 그래서 ~하는 것이다", d: "앞 두 문장을 이유로 묶어 결론을 냅니다. As a result보다 말하는 사람의 판단이 들어간 결론입니다." } ],
      notes: [ { t: "bring someone into the office", k: "business", m: "~를 사무실로 불러 모으다", tip: "return to the office(사무실 복귀)와 함께 자주 쓰는 말입니다." } ] },
    { r: "Remote work makes informal feedback harder to give, although it saves our team two hours a day. Junior staff are hit hardest, because they learn by watching senior colleagues handle difficult calls. That is why we now bring everyone into the office {time:on Tuesdays}.", ko: "재택근무는 우리 팀에게 하루 두 시간을 아껴 주지만, 가벼운 피드백은 주기 더 어렵게 만듭니다. 가장 큰 타격을 받는 건 저연차 직원들인데, 선배들이 어려운 통화를 처리하는 모습을 보면서 배우기 때문입니다. 그래서 지금은 화요일마다 모두를 사무실로 불러 모읍니다.",
      gram: [ { t: "on + 요일s = ~요일마다", d: "on Tuesdays 처럼 요일을 복수로 쓰면 '매주 화요일'입니다. on Tuesday는 '(이번) 화요일'." } ] }
  ],
  quiz: {
    blocks: ["Remote work makes informal feedback", "harder to give,", "although it saves our team", "two hours a day.", "Junior staff are hit hardest,", "because they learn by watching", "senior colleagues handle difficult calls.", "That is why we now bring everyone", "into the office on Tuesdays."],
    orders: [[0,1,2,3,4,5,6,7,8]]
  }
},
{
  day: 3, cat: "공급망", level: "B2", title: "Stuck at the Port", titleKo: "항만 적체 — so ~ that과 결과",
  gist: "so + 형용사 + that · 수동태(be left idle) · , which means",
  steps: [
    { r: "{core:The port was} {core:congested}.", ko: "항구가 혼잡했습니다.",
      gram: [ { t: "뼈대: be + 형용사", d: "상태를 말하는 가장 짧은 문장입니다. congested(혼잡한)는 도로·항만·통신망이 막힌 상태에 씁니다." } ],
      notes: [ { t: "congested", k: "business", m: "혼잡한, 정체된", tip: "port congestion(항만 적체)은 물류 뉴스의 단골 표현입니다." } ] },
    { r: "The port was {focus:so} congested {result:that our shipment sat on the dock}.", ko: "항구가 너무 혼잡해서 우리 화물이 부두에 그대로 놓여 있었습니다.",
      gram: [ { t: "so + 형용사 + that + 절 = 너무 ~해서 …했다", d: "so가 정도를 끌어올리고 that절이 그 결과를 말합니다. 원인과 결과를 한 문장에 붙이는 가장 기본 틀입니다." } ],
      notes: [ { t: "sit on the dock", k: "colloquial", m: "부두에 (움직이지 않고) 놓여 있다", tip: "sit은 물건이 '방치된 채 있다'는 뜻으로 자주 씁니다. The order sat in the warehouse for weeks." } ],
      trap: [ { ng: "The port was very congested that...", why: "that 결과절과 짝을 이루는 것은 so입니다. very는 쓸 수 없습니다." } ] },
    { r: "The port was so congested that our shipment sat on the dock {quant:for nine days}.", ko: "항구가 너무 혼잡해서 우리 화물이 9일 동안 부두에 놓여 있었습니다.",
      gram: [ { t: "for + 기간", d: "얼마 동안이었는지를 끝에 붙입니다. for nine days. during은 '~ 동안(그 기간 중에)'으로 쓰임이 다릅니다." } ] },
    { r: "The port was so congested {time:last month} that our shipment sat on the dock for nine days.", ko: "지난달 항구가 너무 혼잡해서 우리 화물이 9일 동안 부두에 놓여 있었습니다.",
      gram: [ { t: "so ~ that 사이에 때를 끼우기", d: "last month는 '혼잡했던 때'라서 congested 바로 뒤, that 앞에 둡니다. 끝에 두면 '9일'과 엉켜 뜻이 흐려집니다." } ] },
    { r: "The port was so congested last month that our shipment sat on the dock for nine days. {add:Two of our production lines were left idle}.", ko: "…우리 생산 라인 두 개가 멈춰 서 있었습니다.",
      gram: [ { t: "be left + 형용사 = ~한 채로 남겨지다", d: "leave A idle(A를 놀게 두다)의 수동태입니다. 원인(부품이 안 옴)보다 결과(라인이 섬)에 초점을 맞춥니다." } ],
      notes: [ { t: "idle", k: "business", m: "가동되지 않는, 노는", tip: "idle capacity(유휴 설비), stand idle(놀고 있다)." } ] },
    { r: "The port was so congested last month that our shipment sat on the dock for nine days. Two of our production lines were left idle {time:for most of that week}.", ko: "…그 주 대부분 동안 우리 생산 라인 두 개가 멈춰 서 있었습니다.",
      gram: [ { t: "for most of + 기간", d: "most of that week = 그 주의 대부분. 정확한 날수 대신 '대부분'으로 말하면 과장 없이 규모를 전합니다." } ] },
    { r: "The port was so congested last month that our shipment sat on the dock for nine days. Two of our production lines were left idle for most of that week{rel:, which means we will miss the delivery date}.", ko: "…그 말은 우리가 납기를 못 맞춘다는 뜻입니다.",
      gram: [ { t: ", which means + 절", d: "앞 문장 전체를 받아 '그건 곧 ~라는 뜻'이라고 결론을 붙입니다. 1회차 , which와 같은 자리지만 means가 이어져 결과를 해석합니다." } ],
      notes: [ { t: "miss the delivery date", k: "business", m: "납기를 놓치다", tip: "meet the delivery date(납기를 맞추다)의 반대. miss a deadline 도 같은 짝입니다." } ] },
    { r: "The port was so congested last month that our shipment sat on the dock for nine days. Two of our production lines were left idle for most of that week, which means we will miss the delivery date {rel:we promised our customer}.", ko: "지난달 항구가 너무 혼잡해서 우리 화물이 9일 동안 부두에 놓여 있었습니다. 그 주 대부분 동안 생산 라인 두 개가 멈춰 섰고, 그 말은 우리가 고객에게 약속한 납기를 못 맞춘다는 뜻입니다.",
      gram: [ { t: "명사 + (that) + 주어 + 동사", d: "the delivery date (that) we promised = 우리가 약속한 납기. 목적어 자리의 관계대명사는 흔히 생략합니다. 말할 때는 생략한 쪽이 더 자연스럽습니다." } ],
      notes: [ { t: "promise a customer a date", k: "business", m: "고객에게 날짜를 약속하다", tip: "promise + 사람 + 물건. commit to a date 도 비슷한 뜻입니다." } ] }
  ],
  quiz: {
    blocks: ["The port was so congested", "last month", "that our shipment sat on the dock", "for nine days.", "Two of our production lines were left idle", "for most of that week,", "which means we will miss the delivery date", "we promised our customer."],
    orders: [[0,1,2,3,4,5,6,7]]
  }
},
{
  day: 4, cat: "AI·일", level: "B2+", title: "Tools That Talk Back", titleKo: "AI 도구 — not only A but also B",
  gist: "not only A but also B · 동명사 주어 · 세미콜론 대조 · what절",
  steps: [
    { r: "{core:AI assistants have} {core:cut the time we spend on routine reports}.", ko: "AI 비서는 우리가 일상 보고서에 쓰는 시간을 줄였습니다.",
      gram: [ { t: "뼈대: 현재완료 + 목적어", d: "have cut = 지금까지 줄여 왔다(그 결과가 지금 남아 있다). the time (that) we spend on ~ = 우리가 ~에 쓰는 시간." } ],
      notes: [ { t: "spend time on ~", k: "collocation", m: "~에 시간을 쓰다", tip: "spend 다음 시간·돈, on 다음 대상. spend money on training." } ] },
    { r: "AI assistants have {focus:not only} cut the time we spend on routine reports {focus:but also changed what we expect from new hires}.", ko: "AI 비서는 우리가 일상 보고서에 쓰는 시간을 줄였을 뿐 아니라, 신입에게 기대하는 것까지 바꿔 놓았습니다.",
      gram: [ { t: "not only A but also B", d: "A와 B의 형태를 맞춥니다: not only cut … but also changed. 두 번째 효과(B)가 더 중요하다는 무게가 실립니다." } ],
      notes: [
        { t: "what we expect from ~", k: "grammar", m: "우리가 ~에게 기대하는 것", tip: "what이 이끄는 절이 목적어가 됩니다. expect A from B = B에게 A를 기대하다." },
        { t: "new hires", k: "business", m: "신규 입사자", tip: "hire가 명사로 '채용된 사람'. a recent hire." }
      ],
      trap: [ { ng: "not only cut ... but also changing ...", why: "A와 B의 형태가 같아야 합니다. cut과 changed처럼 같은 시제로 맞춥니다." } ] },
    { r: "AI assistants have not only cut the time we spend on routine reports but also changed what we expect from new hires. {add:Writing a clean first draft is no longer the skill that matters}.", ko: "…깔끔한 초안을 쓰는 것은 더 이상 중요한 기술이 아닙니다.",
      gram: [ { t: "동명사 주어 + no longer", d: "Writing a clean first draft(초안을 쓰는 것)가 주어입니다. 동명사 주어는 단수 취급(is). no longer = 더 이상 ~ 아니다." } ],
      notes: [ { t: "the skill that matters", k: "collocation", m: "정말 중요한 기술", tip: "matter = 중요하다(동사). What matters is ~ 로도 자주 씁니다." } ] },
    { r: "AI assistants have not only cut the time we spend on routine reports but also changed what we expect from new hires. Writing a clean first draft is no longer the skill that matters{contrast:; checking whether the draft is right is}.", ko: "…깔끔한 초안을 쓰는 것은 더 이상 중요한 기술이 아닙니다. 그 초안이 맞는지 검증하는 것이 중요한 기술입니다.",
      gram: [ { t: "세미콜론 + 생략된 대조", d: "A is no longer X; B is. 뒤 절에서 the skill that matters를 생략하고 is로 끝냅니다. 짧게 끊어 대비를 날카롭게 만드는 문어적 기술입니다." } ],
      notes: [ { t: "check whether ~", k: "grammar", m: "~인지 확인하다", tip: "whether 뒤 절은 '맞는지 아닌지'. if로 바꿔도 되지만 동명사 주어 안에서는 whether가 깔끔합니다." } ] },
    { r: "AI assistants have not only cut the time we spend on routine reports but also changed what we expect from new hires. Writing a clean first draft is no longer the skill that matters; checking whether the draft is right is. {add:That shift is much harder to train for}.", ko: "AI 비서는 우리가 일상 보고서에 쓰는 시간을 줄였을 뿐 아니라, 신입에게 기대하는 것까지 바꿔 놓았습니다. 깔끔한 초안을 쓰는 것은 더 이상 중요한 기술이 아니고, 그 초안이 맞는지 검증하는 것이 중요합니다. 그런 변화는 훈련으로 대비하기가 훨씬 어렵습니다.",
      gram: [ { t: "형용사 + to부정사 + 전치사로 끝내기", d: "harder to train for = 대비해 훈련하기 더 어려운. train for a shift에서 for가 끝에 남습니다. 영어는 전치사로 문장을 끝내는 것이 자연스럽습니다." } ],
      notes: [ { t: "much harder", k: "grammar", m: "훨씬 더 어려운", tip: "비교급 강조는 much·far·a lot. very harder는 쓰지 않습니다." } ] }
  ],
  quiz: {
    blocks: ["AI assistants have", "not only cut the time", "we spend on routine reports", "but also changed what we expect", "from new hires.", "Writing a clean first draft", "is no longer the skill that matters;", "checking whether the draft is right is.", "That shift is much harder to train for."],
    orders: [[0,1,2,3,4,5,6,7,8]]
  }
},
{
  day: 5, cat: "에너지·모빌리티", level: "B2", title: "Charging Ahead?", titleKo: "전기차 — unless와 whose",
  gist: "unless · 비교급 강조 far · whose 관계절 · make up",
  steps: [
    { r: "{core:Electric vehicles will not replace petrol cars}.", ko: "전기차가 휘발유차를 대체하지는 못할 것입니다.",
      gram: [ { t: "뼈대: will not + 동사 = 예측의 부정", d: "will not replace = 대체하지 못할 것이다. 단정적인 예측이라 다음 단계에서 범위와 조건을 붙여 다듬습니다." } ],
      notes: [ { t: "replace A", k: "collocation", m: "A를 대체하다", tip: "A replaces B = A가 B를 대체한다. replace B with A = B를 A로 바꾸다. 주어 자리에 주의." } ] },
    { r: "Electric vehicles will not replace petrol cars {mod:on a large scale}.", ko: "전기차가 휘발유차를 대규모로 대체하지는 못할 것입니다.",
      gram: [ { t: "범위 한정으로 주장을 정확하게", d: "on a large scale을 붙이면 '전혀 못 한다'가 아니라 '대규모로는 못 한다'가 됩니다. 단정적인 주장에 범위를 붙이는 습관이 토론에서 신뢰를 줍니다." } ],
      notes: [ { t: "on a large scale", k: "collocation", m: "대규모로", tip: "on a small scale(소규모로), at scale(대량으로)도 함께 알아 두세요." } ] },
    { r: "Electric vehicles will not replace petrol cars on a large scale {cond:unless charging becomes} {cond:more convenient}.", ko: "충전이 더 편해지지 않는 한, 전기차가 휘발유차를 대규모로 대체하지는 못할 것입니다.",
      gram: [ { t: "unless + 절 = ~하지 않는 한", d: "unless는 if … not과 같은 뜻이지만, '그 조건 하나가 열쇠'라는 느낌이 더 강합니다. unless 절 안에는 미래라도 현재형(becomes)을 씁니다." } ],
      trap: [ { ng: "unless charging will become more convenient", why: "조건절에는 will을 쓰지 않습니다. 현재형 becomes." } ] },
    { r: "Electric vehicles will not replace petrol cars on a large scale unless charging becomes {focus:far} more convenient.", ko: "충전이 훨씬 더 편해지지 않는 한, 전기차가 휘발유차를 대규모로 대체하지는 못할 것입니다.",
      gram: [ { t: "far + 비교급 = 훨씬 더", d: "차이가 크다는 것을 강조합니다. much·a lot도 되지만 far가 가장 단호하게 들립니다." } ] },
    { r: "Electric vehicles will not replace petrol cars on a large scale unless charging becomes far more convenient. {add:Drivers} {add:are the ones who hesitate most}.", ko: "…가장 망설이는 쪽은 운전자들입니다.",
      gram: [ { t: "the ones who ~ = ~하는 사람들", d: "the ones는 앞에 나온 사람들을 다시 가리킵니다. Drivers are the ones who hesitate = 망설이는 건 운전자들이다." } ],
      notes: [ { t: "hesitate", k: "colloquial", m: "망설이다", tip: "hesitate to buy, hesitate about ~. 구매 결정을 미룬다는 뜻으로 시장 분석에 자주 씁니다." } ] },
    { r: "Electric vehicles will not replace petrol cars on a large scale unless charging becomes far more convenient. Drivers {rel:whose homes have no private parking} are the ones who hesitate most.", ko: "…집에 개인 주차 공간이 없는 운전자들이 가장 망설입니다.",
      gram: [ { t: "whose + 명사 = 그 사람의 ~", d: "Drivers whose homes have no parking = 집에 주차 공간이 없는 운전자들. 주어와 동사 사이에 끼워 넣어 '어떤 운전자인지'를 좁힙니다." } ],
      trap: [ { ng: "Drivers who their homes have no private parking", why: "소유를 나타낼 때는 who + their가 아니라 whose 한 단어입니다." } ] },
    { r: "Electric vehicles will not replace petrol cars on a large scale unless charging becomes far more convenient. Drivers whose homes have no private parking are the ones who hesitate most{add:, and they make up nearly half of urban households}.", ko: "충전이 훨씬 더 편해지지 않는 한, 전기차가 휘발유차를 대규모로 대체하지는 못할 것입니다. 집에 개인 주차 공간이 없는 운전자들이 가장 망설이는데, 이들이 도시 가구의 절반 가까이를 차지합니다.",
      gram: [ { t: ", and + 절 = 무게를 더하는 덧붙임", d: "앞 문장의 사람들이 '얼마나 많은지'를 덧붙여 문제의 크기를 보여 줍니다." } ],
      notes: [ { t: "make up", k: "phrasal", m: "(비율을) 차지하다, 구성하다", tip: "Women make up 40% of the team. account for 와 비슷하지만 make up은 '구성원'에 더 자연스럽습니다." } ] }
  ],
  quiz: {
    blocks: ["Electric vehicles will not replace petrol cars", "on a large scale", "unless charging becomes", "far more convenient.", "Drivers", "whose homes have no private parking", "are the ones who hesitate most,", "and they make up nearly half", "of urban households."],
    orders: [[0,1,2,3,4,5,6,7,8]]
  }
},
{
  day: 6, cat: "채용", level: "B2", title: "Hiring for Potential", titleKo: "잠재력 채용 — whereas와 despite",
  gist: "used to · whereas · 동격 that절 · by + 비율 · despite + 명사",
  steps: [
    { r: "{core:We used to hire people for what they already knew}.", ko: "예전에 우리는 사람들을 이미 아는 것을 보고 채용했습니다.",
      gram: [ { t: "used to + 동사원형 = 예전엔 ~했다(지금은 아니다)", d: "과거의 습관과 지금의 변화를 대비할 준비를 합니다. hire A for B = B를 보고 A를 뽑다. what they already knew = 그들이 이미 아는 것." } ],
      notes: [ { t: "hire someone for ~", k: "business", m: "~를 보고 채용하다", tip: "hire for attitude, train for skill(태도를 보고 뽑고 기술은 가르친다)은 유명한 채용 격언입니다." } ] },
    { r: "We used to hire people for what they already knew{contrast:, whereas now we look for evidence}.", ko: "예전에는 이미 아는 것을 보고 채용했지만, 지금은 근거를 찾습니다.",
      gram: [ { t: ", whereas + 절 = 반면에", d: "두 사실을 나란히 놓고 대비합니다. although(양보)와 달리 whereas는 '이쪽은 이렇고 저쪽은 저렇다'는 대조입니다." } ],
      notes: [ { t: "look for evidence", k: "collocation", m: "근거를 찾다", tip: "evidence는 셀 수 없는 명사. an evidence가 아니라 a piece of evidence." } ] },
    { r: "We used to hire people for what they already knew, whereas now we look for evidence {clause:that they can learn quickly}.", ko: "예전에는 이미 아는 것을 보고 채용했지만, 지금은 빨리 배울 수 있다는 근거를 찾습니다.",
      gram: [ { t: "명사 + that절(동격) = ~라는 명사", d: "evidence that they can learn = 그들이 배울 수 있다는 근거. that절이 evidence의 내용을 풀어 줍니다. the fact that, the idea that 도 같은 틀입니다." } ] },
    { r: "We used to hire people for what they already knew, whereas now we look for evidence that they can learn quickly. {add:This approach has cut our first-year turnover}.", ko: "…이 방식으로 첫해 퇴사율이 줄었습니다.",
      gram: [ { t: "This approach + 현재완료 = 지금까지의 효과", d: "앞에서 말한 방식을 This approach로 받아 주어로 세우고, has cut으로 '지금까지 낸 결과'를 말합니다." } ],
      notes: [ { t: "first-year turnover", k: "business", m: "입사 첫해 이직률", tip: "turnover = 이직률(인사), 매출(재무) 두 뜻이 있어 문맥으로 구별합니다." } ] },
    { r: "We used to hire people for what they already knew, whereas now we look for evidence that they can learn quickly. This approach has cut our first-year turnover {quant:by a third}.", ko: "…이 방식으로 첫해 이직률이 3분의 1 줄었습니다.",
      gram: [ { t: "by + 비율", d: "1회차 by twelve percent와 같은 '변화의 폭'입니다. a third(3분의 1), half, a quarter처럼 분수로도 말합니다." } ] },
    { r: "We used to hire people for what they already knew, whereas now we look for evidence that they can learn quickly. This approach has cut our first-year turnover by a third{contrast:, despite the extra training cost}.", ko: "…추가 교육 비용이 들긴 하지만, 이 방식으로 첫해 이직률이 3분의 1 줄었습니다.",
      gram: [ { t: "despite + 명사 = ~에도 불구하고", d: "although 뒤에는 절, despite 뒤에는 명사(구)가 옵니다. despite the cost = 비용에도 불구하고." } ],
      trap: [ { ng: "despite of the extra training cost", why: "despite에는 of를 붙이지 않습니다. in spite of 는 of가 필요합니다." } ] },
    { r: "We used to hire people for what they already knew, whereas now we look for evidence that they can learn quickly. This approach has cut our first-year turnover by a third, despite the extra training cost {rel:it involves}.", ko: "예전에는 이미 아는 것을 보고 채용했지만, 지금은 빨리 배울 수 있다는 근거를 찾습니다. 그에 따르는 추가 교육 비용에도 불구하고, 이 방식으로 첫해 이직률이 3분의 1 줄었습니다.",
      gram: [ { t: "명사 + (that) + 주어 + 동사", d: "the cost (that) it involves = 그것에 따르는 비용. 3회차와 같은 생략형 관계절입니다." } ],
      notes: [ { t: "involve", k: "business", m: "수반하다, 따르다", tip: "The job involves travel(출장이 따른다). 비용·위험·노력을 말할 때 자주 씁니다." } ] }
  ],
  quiz: {
    blocks: ["We used to hire people", "for what they already knew,", "whereas now we look for evidence", "that they can learn quickly.", "This approach has cut", "our first-year turnover", "by a third,", "despite the extra training cost", "it involves."],
    orders: [[0,1,2,3,4,5,6,7,8]]
  }
},
{
  day: 7, cat: "에너지·제조", level: "B2+", title: "The Real Price of Power", titleKo: "전기 요금과 공장 — 1주차 총정리",
  gist: "총정리: account for · , which · although · therefore",
  steps: [
    { r: "{core:Electricity now accounts for} {core:a quarter of our operating costs}.", ko: "이제 전기가 우리 운영비의 4분의 1을 차지합니다.",
      gram: [ { t: "뼈대: account for + 비율", d: "account for = (비율을) 차지하다. 5회차 make up과 비슷하지만 비용·매출 같은 숫자에는 account for가 더 자연스럽습니다." } ],
      notes: [ { t: "operating costs", k: "business", m: "운영비", tip: "capital costs(설비 투자비)와 대비되는 말입니다. OPEX라고 줄여 부르기도 합니다." } ] },
    { r: "Electricity now accounts for {quant:almost} a quarter of our operating costs.", ko: "이제 전기가 우리 운영비의 4분의 1 가까이를 차지합니다.",
      gram: [ { t: "almost + 수치 = 거의", d: "정확한 숫자 대신 '거의 4분의 1'로 말하면 과장 없이 규모를 전합니다. nearly도 같은 자리에 씁니다." } ] },
    { r: "Electricity now accounts for almost a quarter of our operating costs{rel:, which was unthinkable five years ago}.", ko: "이제 전기가 우리 운영비의 4분의 1 가까이를 차지하는데, 5년 전만 해도 상상도 못 할 일이었습니다.",
      gram: [ { t: "복습: , which = 앞 내용 전체", d: "1회차와 같은 계속적 용법입니다. 앞 사실 전체를 받아 '그건 ~였다'고 평가를 붙입니다." } ],
      notes: [ { t: "unthinkable", k: "colloquial", m: "상상도 못 할", tip: "unimaginable과 비슷하지만 '있을 수 없는 일로 여겨졌다'는 느낌이 더 강합니다." } ] },
    { r: "Electricity now accounts for almost a quarter of our operating costs, which was unthinkable five years ago. {add:The solar panels on our factory roofs cover} {add:less than ten percent of what we use}.", ko: "…우리 공장 지붕의 태양광 패널은 우리가 쓰는 양의 10퍼센트도 채우지 못합니다.",
      gram: [ { t: "긴 주어: 명사 + 전치사구", d: "The solar panels on our factory roofs가 통째로 주어입니다. 동사 cover 앞까지 한 덩어리로 읽습니다." } ],
      notes: [ { t: "cover", k: "business", m: "(필요량을) 충당하다", tip: "cover costs(비용을 충당하다), cover demand(수요를 감당하다)." } ] },
    { r: "Electricity now accounts for almost a quarter of our operating costs, which was unthinkable five years ago. The solar panels on our factory roofs cover less than ten percent of what we use{contrast:, although they took two years to install}.", ko: "…설치에 2년이나 걸렸는데도, 우리 공장 지붕의 태양광 패널은 우리가 쓰는 양의 10퍼센트도 채우지 못합니다.",
      gram: [ { t: "복습: , although = 양보", d: "2회차와 같은 자리입니다. 들인 노력(2년)과 결과(10% 미만)의 대비가 문장의 요점입니다." } ],
      notes: [ { t: "take + 시간 + to부정사", k: "grammar", m: "~하는 데 (시간이) 걸리다", tip: "It took two years to install them. 사람이 주어면 It took us two years." } ] },
    { r: "Electricity now accounts for almost a quarter of our operating costs, which was unthinkable five years ago. The solar panels on our factory roofs cover less than ten percent of what we use, although they took two years to install. {add:Long-term supply contracts} {add:remain essential}.", ko: "…장기 공급 계약은 여전히 필수입니다.",
      gram: [ { t: "remain + 형용사 = 여전히 ~하다", d: "remain essential = 여전히 필수다. be동사 자리에 remain을 쓰면 '상황이 바뀌어도'라는 뜻이 더해집니다." } ],
      notes: [ { t: "long-term supply contract", k: "business", m: "장기 공급 계약", tip: "spot purchase(현물 구매)와 대비되는 말입니다." } ] },
    { r: "Electricity now accounts for almost a quarter of our operating costs, which was unthinkable five years ago. The solar panels on our factory roofs cover less than ten percent of what we use, although they took two years to install. Long-term supply contracts{link:, therefore,} remain essential.", ko: "이제 전기가 우리 운영비의 4분의 1 가까이를 차지하는데, 5년 전만 해도 상상도 못 할 일이었습니다. 설치에 2년이 걸렸는데도 공장 지붕의 태양광 패널은 우리가 쓰는 양의 10퍼센트도 채우지 못합니다. 따라서 장기 공급 계약은 여전히 필수입니다.",
      gram: [ { t: "주어 뒤에 끼우는 therefore", d: "Long-term supply contracts, therefore, remain … 처럼 주어 뒤에 쉼표로 끼우면 결론이 차분하게 들립니다. 문장 맨 앞 Therefore보다 격식 있는 보고서 말투입니다." } ],
      notes: [ { t: "therefore / however / in fact", k: "grammar", m: "연결어를 주어 뒤에", tip: "이 자리에 however, in fact도 같은 방식으로 넣을 수 있습니다." } ] }
  ],
  quiz: {
    blocks: ["Electricity now accounts for", "almost a quarter of our operating costs,", "which was unthinkable five years ago.", "The solar panels on our factory roofs cover", "less than ten percent of what we use,", "although they took two years to install.", "Long-term supply contracts,", "therefore,", "remain essential."],
    orders: [[0,1,2,3,4,5,6,7,8]]
  }
}
);
