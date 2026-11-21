/* BUILD-UP — 15~21회차 (3주차: 조건·가정법·완곡 — 말의 수위를 조절하기)
   형식은 days-w1.js 머리말. */
window.BU = window.BU || {};
BU.DAYS = BU.DAYS || [];
BU.DAYS.push(
{
  day: 15, cat: "가격", level: "B2", title: "Raising Prices Without Losing Clients", titleKo: "가격 인상 — if 조건과 only when",
  gist: "of + 수치 · if + 현재 → will · only when · as it did",
  steps: [
    { r: "{core:Most customers will accept a price increase}.", ko: "대부분의 고객은 가격 인상을 받아들일 것입니다.",
      gram: [ { t: "뼈대: will + 동사 = 예측", d: "Most customers will accept ~ = 대부분은 받아들일 것이다. 단정 대신 Most로 범위를 잡아 두었습니다." } ],
      notes: [ { t: "accept a price increase", k: "business", m: "가격 인상을 받아들이다", tip: "push back on a price increase(가격 인상에 반발하다)와 짝으로 기억하세요." } ] },
    { r: "Most customers will accept a price increase {quant:of five percent}.", ko: "대부분의 고객은 5퍼센트의 가격 인상을 받아들일 것입니다.",
      gram: [ { t: "명사 + of + 수치", d: "a price increase of five percent = 5% 인상. 동사 rise by 5%를 명사로 말하면 by가 of로 바뀝니다." } ],
      trap: [ { ng: "a price increase by five percent", why: "명사(increase) 뒤에서 크기를 말할 때는 of입니다. 동사 increase by 와 헷갈리기 쉽습니다." } ] },
    { r: "Most customers will accept a price increase of five percent {time:in January}.", ko: "대부분의 고객은 1월의 5퍼센트 가격 인상을 받아들일 것입니다.",
      gram: [ { t: "in + 월", d: "달 앞에는 in. 날짜까지 말하면 on January 1st." } ] },
    { r: "Most customers will accept a price increase of five percent in January {cond:if we explain it in advance}.", ko: "미리 설명하면 대부분의 고객은 1월의 5퍼센트 가격 인상을 받아들일 것입니다.",
      gram: [ { t: "if + 현재, will = 실제로 일어날 수 있는 조건", d: "if 절은 현재형(explain), 결과 절은 will. 협상에서 '이렇게 하면 이렇게 된다'를 말하는 기본 틀입니다." } ],
      notes: [ { t: "in advance", k: "collocation", m: "미리, 사전에", tip: "ahead of time 도 같은 뜻입니다. notify customers in advance." } ],
      trap: [ { ng: "if we will explain it in advance", why: "조건절에는 미래라도 will을 쓰지 않습니다." } ] },
    { r: "Most customers will accept a price increase of five percent in January if we explain it in advance. {add:They push back}.", ko: "…그들은 반발합니다.",
      gram: [ { t: "새 문장: 반대 경우", d: "받아들이는 경우를 말했으니, 이번엔 반발하는 경우를 짧게 세웁니다." } ],
      notes: [ { t: "push back", k: "phrasal", m: "반발하다, 거부하다", tip: "push back on a proposal. 명사로는 pushback(반발)." } ] },
    { r: "Most customers will accept a price increase of five percent in January if we explain it in advance. They push back {focus:only when an increase arrives without warning}.", ko: "…그들이 반발하는 건 인상이 예고 없이 닥칠 때뿐입니다.",
      gram: [ { t: "only when + 절 = ~할 때만", d: "only가 조건을 하나로 좁혀 '그 경우뿐'이라고 강조합니다. 위험이 생각보다 작다는 메시지가 됩니다." } ],
      notes: [ { t: "without warning", k: "collocation", m: "예고 없이", tip: "with little warning(거의 예고 없이)도 자주 씁니다." } ] },
    { r: "Most customers will accept a price increase of five percent in January if we explain it in advance. They push back only when an increase arrives without warning{compare:, as it did two years ago}.", ko: "미리 설명하면 대부분의 고객은 1월의 5퍼센트 가격 인상을 받아들일 것입니다. 그들이 반발하는 건 2년 전처럼 인상이 예고 없이 닥칠 때뿐입니다.",
      gram: [ { t: ", as + 주어 + did = ~가 그랬던 것처럼", d: "as it did two years ago = 2년 전에 그랬듯이. did가 arrived without warning을 대신합니다. 구체적인 과거 사례를 짧게 소환하는 기술입니다." } ] }
  ],
  quiz: {
    blocks: ["Most customers will accept", "a price increase of five percent", "in January", "if we explain it in advance.", "They push back", "only when an increase arrives without warning,", "as it did two years ago."],
    orders: [[0,1,2,3,4,5,6]]
  }
},
{
  day: 16, cat: "투자", level: "B2+", title: "The Plant We Didn't Build", titleKo: "놓친 투자 — 가정법 과거완료",
  gist: "would have p.p. · if + had p.p. · while · Instead",
  steps: [
    { r: "{core:We would have recovered the investment}.", ko: "우리는 투자금을 회수했을 것입니다.",
      gram: [ { t: "뼈대: would have + p.p. = (그랬다면) ~했을 것이다", d: "실제로는 일어나지 않은 과거를 말합니다. 아직 조건이 없어 반쪽짜리지만, 이 시제만 들어도 '아쉬움'이 전해집니다." } ],
      notes: [ { t: "recover an investment", k: "business", m: "투자금을 회수하다", tip: "pay back / pay off an investment 도 같은 뜻입니다." } ] },
    { r: "We would have recovered the investment {time:last year}.", ko: "우리는 작년에 투자금을 회수했을 것입니다.",
      gram: [ { t: "과거 시점 + would have p.p.", d: "last year가 붙어 '작년에 이미 회수했을 텐데'라는 과거의 가정임이 분명해집니다." } ] },
    { r: "We would have recovered the investment last year {cond:if we had built the solar plant}.", ko: "태양광 발전소를 지었다면 우리는 작년에 투자금을 회수했을 것입니다.",
      gram: [ { t: "if + had p.p., would have p.p. (가정법 과거완료)", d: "과거에 하지 않은 일을 뒤집어 상상합니다. if 절은 had built, 결과 절은 would have recovered. 시제를 한 칸씩 뒤로 보내는 것이 핵심입니다." } ],
      trap: [ { ng: "if we would have built the solar plant", why: "if 절에는 would를 쓰지 않습니다. had built." } ] },
    { r: "We would have recovered the investment last year if we had built the solar plant {time:while subsidies were still available}.", ko: "보조금이 아직 있을 때 태양광 발전소를 지었다면, 우리는 작년에 투자금을 회수했을 것입니다.",
      gram: [ { t: "while + 절 = ~하는 동안에(그 기간 안에)", d: "기회가 열려 있던 '기간'을 말합니다. still이 '그때는 아직'이라는 아쉬움을 더합니다." } ],
      notes: [ { t: "subsidies are available", k: "business", m: "보조금을 받을 수 있다", tip: "apply for a subsidy(보조금을 신청하다), phase out subsidies(보조금을 단계적으로 없애다)." } ] },
    { r: "We would have recovered the investment last year if we had built the solar plant while subsidies were still available. {add:Instead, we postponed the decision twice}.", ko: "…그러지 않고 우리는 결정을 두 번이나 미뤘습니다.",
      gram: [ { t: "Instead, = 그 대신 (실제로는)", d: "가정(했더라면)에서 현실(실제로는)로 돌아오는 연결어입니다. 가정법 문장 뒤에 아주 자주 따라옵니다." } ],
      notes: [ { t: "postpone a decision", k: "business", m: "결정을 미루다", tip: "put off a decision(구어), defer a decision(격식)." } ] },
    { r: "We would have recovered the investment last year if we had built the solar plant while subsidies were still available. Instead, we postponed the decision twice{result:, and the same project now costs forty percent more}.", ko: "보조금이 아직 있을 때 태양광 발전소를 지었다면 작년에 투자금을 회수했을 것입니다. 그러지 않고 결정을 두 번이나 미뤘고, 이제 같은 프로젝트에 40퍼센트를 더 들여야 합니다.",
      gram: [ { t: "the same + 명사 + now = 같은 것이 지금은", d: "the same project now costs ~ = 같은 프로젝트가 이제 ~ 든다. 바뀐 것은 시기뿐이라는 점을 강조합니다." } ],
      notes: [ { t: "cost X percent more", k: "collocation", m: "X퍼센트 더 들다", tip: "숫자 + more가 cost 바로 뒤에 붙습니다. cost 40% more than planned." } ] }
  ],
  quiz: {
    blocks: ["We would have recovered the investment", "last year", "if we had built the solar plant", "while subsidies were still available.", "Instead, we postponed the decision twice,", "and the same project now costs", "forty percent more."],
    orders: [[0,1,2,3,4,5,6]]
  }
},
{
  day: 17, cat: "인재", level: "B2+", title: "Skills We Never Built", titleKo: "키우지 않은 기술 — 혼합 가정법",
  gist: "would + 동사원형(지금) + if + had p.p.(과거) · before · rather than -ing · once it does",
  steps: [
    { r: "{core:We would not need to hire outside consultants}.", ko: "우리는 외부 컨설턴트를 쓸 필요가 없을 것입니다.",
      gram: [ { t: "뼈대: would not + 동사원형 = (그랬다면 지금) ~하지 않을 텐데", d: "16회차의 would have p.p.(과거 결과)와 달리, would + 동사원형은 '지금의 결과'입니다." } ],
      notes: [ { t: "hire outside consultants", k: "business", m: "외부 컨설턴트를 고용하다", tip: "bring in consultants 도 같은 뜻입니다. in-house(내부)와 대비됩니다." } ] },
    { r: "We would not need to hire outside consultants {time:today}.", ko: "우리는 오늘 외부 컨설턴트를 쓸 필요가 없을 것입니다.",
      gram: [ { t: "today가 시제를 고정한다", d: "today가 붙으면 결과가 '지금'이라는 것이 확실해집니다. 혼합 가정법의 앞 절입니다." } ] },
    { r: "We would not need to hire outside consultants today {cond:if we had trained our own engineers}.", ko: "우리 엔지니어를 직접 키웠다면, 지금 외부 컨설턴트를 쓸 필요가 없을 것입니다.",
      gram: [ { t: "혼합 가정법: 과거 조건 → 지금 결과", d: "if + had p.p.(과거에 하지 않은 일) + would + 동사원형(지금의 결과). 과거의 선택이 현재를 만들었다는 것을 한 문장으로 말합니다." } ],
      notes: [ { t: "our own ~", k: "grammar", m: "우리 자신의 ~", tip: "own을 붙이면 '남이 아니라 우리 것'이 강조됩니다. outside consultants와 대비." } ] },
    { r: "We would not need to hire outside consultants today if we had trained our own engineers {time:five years ago}.", ko: "5년 전에 우리 엔지니어를 직접 키웠다면, 지금 외부 컨설턴트를 쓸 필요가 없을 것입니다.",
      gram: [ { t: "두 시점이 한 문장에", d: "today(지금)와 five years ago(과거)가 한 문장에 있어 혼합 가정법의 시간 차가 눈에 보입니다." } ] },
    { r: "We would not need to hire outside consultants today if we had trained our own engineers five years ago. {add:The lesson is to invest in people}.", ko: "…교훈은 사람에게 투자하라는 것입니다.",
      gram: [ { t: "The lesson is + to부정사", d: "The lesson is to ~ = 교훈은 ~하라는 것이다. 보어 자리에 to부정사로 '해야 할 일'을 둡니다." } ],
      notes: [ { t: "invest in ~", k: "collocation", m: "~에 투자하다", tip: "전치사 in이 고정입니다. invest in training, invest in people." } ] },
    { r: "We would not need to hire outside consultants today if we had trained our own engineers five years ago. The lesson is to invest in people {time:before the shortage appears}.", ko: "…교훈은 인력난이 나타나기 전에 사람에게 투자하라는 것입니다.",
      gram: [ { t: "before + 현재형 = ~하기 전에", d: "미래의 일이라도 before 절은 현재형(appears)입니다. 조건절과 같은 규칙입니다." } ],
      notes: [ { t: "a shortage appears", k: "collocation", m: "부족 사태가 나타나다", tip: "a skills shortage(기술 인력 부족), a labor shortage(노동력 부족)." } ] },
    { r: "We would not need to hire outside consultants today if we had trained our own engineers five years ago. The lesson is to invest in people before the shortage appears{contrast:, rather than paying a premium}.", ko: "…교훈은 웃돈을 주는 대신 인력난이 오기 전에 사람에게 투자하라는 것입니다.",
      gram: [ { t: ", rather than + -ing = ~하는 대신", d: "두 선택지를 놓고 하나를 버립니다. rather than 뒤에는 -ing나 동사원형이 오는데, 문장 뒤쪽에서는 -ing가 자연스럽습니다." } ],
      notes: [ { t: "pay a premium", k: "business", m: "웃돈을 주다, 프리미엄을 내다", tip: "at a premium(웃돈을 얹어), command a premium(높은 값을 받다)." } ] },
    { r: "We would not need to hire outside consultants today if we had trained our own engineers five years ago. The lesson is to invest in people before the shortage appears, rather than paying a premium {time:once it does}.", ko: "5년 전에 우리 엔지니어를 직접 키웠다면 지금 외부 컨설턴트를 쓸 필요가 없을 것입니다. 교훈은 인력난이 닥친 뒤에 웃돈을 주는 대신, 그 전에 사람에게 투자하라는 것입니다.",
      gram: [ { t: "once it does = 일단 그렇게 되면", d: "does가 appears를 대신합니다(15회차 as it did와 같은 대동사). 같은 동사를 반복하지 않는 영어다운 마무리입니다." } ],
      notes: [ { t: "once + 절", k: "grammar", m: "일단 ~하면", tip: "once 뒤에도 미래 대신 현재형입니다. once the contract is signed." } ] }
  ],
  quiz: {
    blocks: ["We would not need to hire outside consultants", "today", "if we had trained our own engineers", "five years ago.", "The lesson is to invest in people", "before the shortage appears,", "rather than paying a premium", "once it does."],
    orders: [[0,1,2,3,4,5,6,7]]
  }
},
{
  day: 18, cat: "일하는 방식", level: "B2", title: "Flexibility With Conditions", titleKo: "유연근무 — provided that, as long as",
  gist: "provided that · between A and B · as long as · ; otherwise,",
  steps: [
    { r: "{core:Staff can choose their own hours}.", ko: "직원들은 근무 시간을 스스로 정할 수 있습니다.",
      gram: [ { t: "뼈대: can + 동사 = 허용", d: "can choose = 고를 수 있다(허용된다). 제도를 설명하는 가장 기본 문장입니다." } ],
      notes: [ { t: "choose one's own hours", k: "collocation", m: "근무 시간을 스스로 정하다", tip: "set one's own hours 도 같은 뜻입니다. flexible hours(유연근무)." } ] },
    { r: "Staff can choose their own hours {cond:provided that they are reachable}.", ko: "연락만 닿는다면 직원들은 근무 시간을 스스로 정할 수 있습니다.",
      gram: [ { t: "provided that + 절 = ~라는 조건으로", d: "if보다 계약서·규정처럼 딱딱하고 '그 조건이 지켜지는 한'이라는 뜻이 분명합니다. that은 생략하기도 합니다." } ],
      notes: [ { t: "reachable", k: "business", m: "연락이 닿는", tip: "be reachable by phone. available(응대 가능한)과 비슷한 자리에 씁니다." } ] },
    { r: "Staff can choose their own hours provided that they are reachable {time:between ten and three}.", ko: "10시부터 3시 사이에 연락만 닿는다면, 직원들은 근무 시간을 스스로 정할 수 있습니다.",
      gram: [ { t: "between A and B", d: "시간대·범위를 말하는 기본 짝입니다. from ten to three와 같은 뜻입니다." } ],
      notes: [ { t: "core hours", k: "business", m: "필수 근무 시간대", tip: "이 '10시~3시' 같은 구간을 core hours라고 부릅니다." } ] },
    { r: "Staff can choose their own hours provided that they are reachable between ten and three. {add:Meetings stay manageable}.", ko: "…회의가 감당할 만한 수준으로 유지됩니다.",
      gram: [ { t: "stay + 형용사 = ~한 상태로 유지되다", d: "7회차 remain essential처럼 be 자리에 stay를 써서 '계속 그렇다'를 말합니다." } ],
      notes: [ { t: "manageable", k: "colloquial", m: "감당할 수 있는", tip: "a manageable workload(감당할 만한 업무량). unmanageable은 반대." } ] },
    { r: "Staff can choose their own hours provided that they are reachable between ten and three. Meetings stay manageable {cond:as long as that window is respected}.", ko: "…그 시간대가 지켜지는 한 회의는 감당할 만한 수준으로 유지됩니다.",
      gram: [ { t: "as long as + 절 = ~하는 한", d: "provided that과 같은 조건이지만 더 구어적입니다. 한 글에서 둘을 섞어 쓰면 반복을 피할 수 있습니다." } ],
      notes: [ { t: "window", k: "business", m: "(시간) 구간, 창", tip: "a two-hour window(두 시간 구간), a delivery window(배송 시간대)." } ] },
    { r: "Staff can choose their own hours provided that they are reachable between ten and three. Meetings stay manageable as long as that window is respected{result:; otherwise, the system falls apart}.", ko: "…그 시간대가 지켜지는 한 회의는 감당할 만하지만, 그렇지 않으면 제도가 무너집니다.",
      gram: [ { t: "; otherwise, = 그렇지 않으면", d: "조건이 깨졌을 때의 결과를 세미콜론 뒤에 붙입니다. otherwise는 접속사가 아니라 부사라서 앞에 세미콜론이나 마침표가 필요합니다." } ],
      notes: [ { t: "fall apart", k: "phrasal", m: "무너지다, 엉망이 되다", tip: "The deal fell apart(거래가 깨졌다). 계획·제도·관계 모두에 씁니다." } ],
      trap: [ { ng: "..., otherwise the system falls apart", why: "쉼표만으로 두 절을 잇지 않습니다. 세미콜론(;)이나 마침표를 씁니다." } ] },
    { r: "Staff can choose their own hours provided that they are reachable between ten and three. Meetings stay manageable as long as that window is respected; otherwise, the system falls apart {time:within a month}.", ko: "10시부터 3시 사이에 연락만 닿는다면 직원들은 근무 시간을 스스로 정할 수 있습니다. 그 시간대가 지켜지는 한 회의는 감당할 만하지만, 그렇지 않으면 한 달도 안 돼 제도가 무너집니다.",
      gram: [ { t: "within + 기간 = ~ 안에", d: "within a month = 한 달 안에. in a month(한 달 뒤에)와 구별합니다." } ] }
  ],
  quiz: {
    blocks: ["Staff can choose their own hours", "provided that they are reachable", "between ten and three.", "Meetings stay manageable", "as long as that window is respected;", "otherwise, the system falls apart", "within a month."],
    orders: [[0,1,2,3,4,5,6]]
  }
},
{
  day: 19, cat: "전망", level: "B2+", title: "Careful With Forecasts", titleKo: "전망 말하기 — 완곡 표현",
  gist: "It seems likely that · may well · to some extent · how 명사절",
  steps: [
    { r: "{core:It seems likely that demand will recover}.", ko: "수요가 회복될 가능성이 커 보입니다.",
      gram: [ { t: "뼈대: It seems likely that + 절", d: "Demand will recover(수요가 회복된다)라고 단정하는 대신 '그럴 가능성이 커 보인다'로 말합니다. 예측은 틀릴 수 있으니 처음부터 수위를 낮춰 둡니다." } ],
      notes: [ { t: "It seems likely that ~", k: "business", m: "~할 가능성이 커 보인다", tip: "It is likely that ~ 보다 한 단계 더 조심스럽습니다. 보고서·회의에서 아주 흔합니다." } ] },
    { r: "It seems likely that demand will recover {time:in the second half}.", ko: "하반기에는 수요가 회복될 가능성이 커 보입니다.",
      gram: [ { t: "in the second half = 하반기에", d: "회계·경영에서 the first half / second half는 상반기·하반기입니다. H1, H2라고 줄이기도 합니다." } ] },
    { r: "It seems likely that demand will recover in the second half{contrast:, although the timing may well depend on interest rates}.", ko: "하반기에는 수요가 회복될 가능성이 커 보이지만, 그 시기는 금리에 따라 달라질 수도 있습니다.",
      gram: [ { t: "may well = ~할 가능성이 꽤 있다", d: "may보다 가능성이 높고, will보다는 조심스럽습니다. 양보절 안에서 '변수'를 인정하는 데 씁니다." } ],
      notes: [ { t: "depend on ~", k: "collocation", m: "~에 달려 있다", tip: "It depends on interest rates. 전치사 on이 고정입니다." } ] },
    { r: "It seems likely that demand will recover in the second half, although the timing may well depend on interest rates. {add:Our forecast is} {add:a bet}.", ko: "…우리 전망은 일종의 내기입니다.",
      gram: [ { t: "은유로 솔직하게", d: "forecast is a bet = 전망은 내기다. 불확실성을 숨기지 않고 짧은 은유로 인정합니다." } ],
      notes: [ { t: "a bet on ~", k: "idiom", m: "~에 건 내기", tip: "make a bet on ~, bet on ~ (동사)도 같은 뜻입니다." } ] },
    { r: "It seems likely that demand will recover in the second half, although the timing may well depend on interest rates. Our forecast is{hedge:, to some extent,} a bet.", ko: "…우리 전망은 어느 정도는 내기입니다.",
      gram: [ { t: ", to some extent, = 어느 정도는", d: "11회차 if anything처럼 동사 뒤에 쉼표로 끼웁니다. '내기'라는 강한 말의 날을 조금 무디게 합니다." } ],
      notes: [ { t: "to some extent", k: "collocation", m: "어느 정도는", tip: "to a large extent(상당 부분), to a certain extent도 같은 계열입니다." } ] },
    { r: "It seems likely that demand will recover in the second half, although the timing may well depend on interest rates. Our forecast is, to some extent, a bet {clause:on how quickly the central bank changes course}.", ko: "하반기에는 수요가 회복될 가능성이 커 보이지만, 그 시기는 금리에 따라 달라질 수 있습니다. 우리 전망은 어느 정도는 중앙은행이 얼마나 빨리 방향을 바꾸느냐에 건 내기입니다.",
      gram: [ { t: "전치사 + how 명사절", d: "a bet on how quickly ~ = 얼마나 빨리 ~하느냐에 건 내기. how절이 전치사 on의 목적어입니다. 어순은 평서문(the central bank changes)." } ],
      notes: [ { t: "change course", k: "idiom", m: "방향을 바꾸다", tip: "정책 전환을 말할 때 씁니다. reverse course(정반대로 돌리다)는 더 강한 표현." } ] }
  ],
  quiz: {
    blocks: ["It seems likely that demand will recover", "in the second half,", "although the timing may well depend", "on interest rates.", "Our forecast is,", "to some extent,", "a bet on how quickly", "the central bank changes course."],
    orders: [[0,1,2,3,4,5,6,7]]
  }
},
{
  day: 20, cat: "비상 계획", level: "B2+", title: "If Demand Falls", titleKo: "수요가 줄면 — should 도치 조건",
  gist: "first · , should + 주어 + 동사 · would · , in which case · before -ing",
  steps: [
    { r: "{core:We will cut the night shift}.", ko: "야간 근무조를 줄이겠습니다.",
      gram: [ { t: "뼈대: will + 동사 = 결정·계획", d: "비상 계획을 말하는 단호한 문장에서 시작합니다. 다음 단계에서 순서와 조건을 붙입니다." } ],
      notes: [ { t: "cut a shift", k: "business", m: "근무조를 줄이다(없애다)", tip: "the night shift(야간조), add a shift(근무조를 늘리다)." } ] },
    { r: "We will cut the night shift {focus:first}.", ko: "가장 먼저 야간 근무조를 줄이겠습니다.",
      gram: [ { t: "first = 맨 먼저", d: "순서를 밝히면 '다음 단계도 있다'는 것이 전해집니다. 비상 계획은 순서가 핵심입니다." } ] },
    { r: "We will cut the night shift first{cond:, should demand fall}.", ko: "수요가 줄어든다면, 가장 먼저 야간 근무조를 줄이겠습니다.",
      gram: [ { t: ", should + 주어 + 동사원형 = 혹시 ~한다면", d: "if demand should fall에서 if를 빼고 should를 앞으로 보낸 도치형입니다. '그럴 가능성은 낮지만 혹시'라는 느낌으로, 격식 있는 계획서에 어울립니다." } ],
      trap: [ { ng: ", should demand falls", why: "should 뒤에는 동사원형입니다. falls가 아니라 fall." } ] },
    { r: "We will cut the night shift first, should demand fall {compare:below last year's level}.", ko: "수요가 작년 수준 아래로 떨어진다면, 가장 먼저 야간 근무조를 줄이겠습니다.",
      gram: [ { t: "below + 기준 = 기준점을 숫자로", d: "막연한 '줄면' 대신 '작년 수준 아래로'라는 판단 기준을 박아 둡니다. 계획이 실행 가능해집니다." } ],
      notes: [ { t: "fall below ~", k: "collocation", m: "~ 아래로 떨어지다", tip: "fall below expectations(기대에 못 미치다)도 자주 씁니다." } ] },
    { r: "We will cut the night shift first, should demand fall below last year's level. {add:Overtime would go next}.", ko: "…그다음은 초과근무가 없어질 것입니다.",
      gram: [ { t: "would = (그 상황이 되면) ~할 것이다", d: "아직 일어나지 않은 가상의 순서라서 will 대신 would를 씁니다. go = 없어지다(구어)." } ],
      notes: [ { t: "go next", k: "colloquial", m: "다음으로 없어지다(잘리다)", tip: "Jobs will go(일자리가 사라질 것이다)처럼 go가 '없어지다' 뜻으로 쓰입니다." } ] },
    { r: "We will cut the night shift first, should demand fall below last year's level. Overtime would go next{rel:, in which case we would talk to the union}.", ko: "…그다음은 초과근무이고, 그 경우에는 노조와 이야기하겠습니다.",
      gram: [ { t: ", in which case + 절 = 그 경우에는", d: "앞 문장 전체를 '그런 경우'로 받아 대응을 붙입니다. 1회차 , which의 응용입니다." } ],
      notes: [ { t: "talk to the union", k: "business", m: "노조와 협의하다", tip: "consult the union(격식), negotiate with the union(협상)." } ] },
    { r: "We will cut the night shift first, should demand fall below last year's level. Overtime would go next, in which case we would talk to the union {time:before announcing anything}.", ko: "수요가 작년 수준 아래로 떨어진다면 가장 먼저 야간 근무조를 줄이겠습니다. 그다음은 초과근무이고, 그 경우에는 아무것도 발표하기 전에 노조와 먼저 이야기하겠습니다.",
      gram: [ { t: "before + -ing = ~하기 전에", d: "주어가 같으면 before 뒤에 -ing를 바로 붙입니다. before we announce anything과 같은 뜻입니다." } ] }
  ],
  quiz: {
    blocks: ["We will cut the night shift first,", "should demand fall", "below last year's level.", "Overtime would go next,", "in which case we would talk to the union", "before announcing anything."],
    orders: [[0,1,2,3,4,5]]
  }
},
{
  day: 21, cat: "조선·철강", level: "B2+", title: "Orders on the Horizon", titleKo: "조선 수주와 후판 — 3주차 총정리",
  gist: "총정리: may well · , should 도치 · 혼합 가정법 + had 도치",
  steps: [
    { r: "{core:Shipyards are fully booked}.", ko: "조선소들의 일감이 꽉 차 있습니다.",
      gram: [ { t: "뼈대: be fully booked", d: "예약·일정이 꽉 찼다는 뜻입니다. 조선소에 쓰면 '수주 잔량이 가득하다'가 됩니다." } ],
      notes: [ { t: "fully booked", k: "colloquial", m: "꽉 찬, 예약이 다 찬", tip: "호텔·식당에도 쓰는 말이라 듣기 쉽습니다. order backlog(수주 잔량)는 업계 용어입니다." } ] },
    { r: "Shipyards are fully booked {time:for the next three years}.", ko: "조선소들의 일감이 앞으로 3년 치 꽉 차 있습니다.",
      gram: [ { t: "for the next + 기간", d: "for the next three years = 앞으로 3년 동안. 미래의 기간을 말할 때 씁니다." } ] },
    { r: "Shipyards are fully booked for the next three years{hedge:, and demand for thick steel plate may well exceed what mills can supply}.", ko: "…3년 치 꽉 차 있고, 후판 수요가 제철소가 공급할 수 있는 양을 넘어설 수도 있습니다.",
      gram: [ { t: "복습: may well + what절", d: "19회차 may well로 수위를 조절하고, what mills can supply(제철소가 공급할 수 있는 것)를 목적어로 씁니다." } ],
      notes: [
        { t: "thick steel plate", k: "business", m: "후판(두꺼운 강판)", tip: "선박·교량·풍력 타워에 쓰입니다. heavy plate라고도 합니다." },
        { t: "exceed supply", k: "collocation", m: "공급을 넘어서다", tip: "demand outstrips supply(수요가 공급을 앞지르다)도 같은 뜻입니다." }
      ] },
    { r: "Shipyards are fully booked for the next three years, and demand for thick steel plate may well exceed what mills can supply{cond:, should orders keep arriving at this pace}.", ko: "…주문이 이 속도로 계속 들어온다면 후판 수요가 공급을 넘어설 수도 있습니다.",
      gram: [ { t: "복습: , should + 주어 + 동사원형", d: "20회차 도치 조건입니다. keep -ing = 계속 ~하다. at this pace = 이 속도로." } ],
      notes: [ { t: "keep arriving", k: "grammar", m: "계속 들어오다", tip: "keep + -ing. keep to arrive ✗." } ] },
    { r: "Shipyards are fully booked for the next three years, and demand for thick steel plate may well exceed what mills can supply, should orders keep arriving at this pace. {add:We would be in a far stronger position}.", ko: "…우리는 훨씬 유리한 위치에 있을 것입니다.",
      gram: [ { t: "would be = (그랬다면) 지금 ~일 것이다", d: "17회차 혼합 가정법의 앞 절입니다. 아직 조건은 없지만 '지금 상황'에 대한 아쉬움입니다." } ],
      notes: [ { t: "be in a strong position", k: "business", m: "유리한 위치에 있다", tip: "협상력이 있다는 뜻으로도 씁니다. negotiate from a position of strength." } ] },
    { r: "Shipyards are fully booked for the next three years, and demand for thick steel plate may well exceed what mills can supply, should orders keep arriving at this pace. We would be in a far stronger position {time:now}.", ko: "…지금 우리는 훨씬 유리한 위치에 있을 것입니다.",
      gram: [ { t: "now로 시점을 고정", d: "17회차 today처럼, 결과가 '지금'이라는 것을 못 박습니다." } ] },
    { r: "Shipyards are fully booked for the next three years, and demand for thick steel plate may well exceed what mills can supply, should orders keep arriving at this pace. We would be in a far stronger position now {cond:had we expanded capacity earlier}.", ko: "조선소들은 앞으로 3년 치 일감이 꽉 차 있고, 주문이 이 속도로 계속 들어온다면 후판 수요가 제철소의 공급 능력을 넘어설 수도 있습니다. 더 일찍 생산 능력을 늘렸다면 지금 우리는 훨씬 유리한 위치에 있을 것입니다.",
      gram: [ { t: "had + 주어 + p.p. = if + 주어 + had p.p. (도치)", d: "if we had expanded에서 if를 빼고 had를 앞으로 보낸 형태입니다. 20회차 should 도치와 같은 원리로, 격식 있는 글에서 씁니다." } ],
      notes: [ { t: "expand capacity", k: "business", m: "생산 능력을 늘리다", tip: "add capacity, increase capacity도 같은 뜻입니다. capacity utilization(가동률)." } ] }
  ],
  quiz: {
    blocks: ["Shipyards are fully booked", "for the next three years,", "and demand for thick steel plate", "may well exceed what mills can supply,", "should orders keep arriving at this pace.", "We would be in a far stronger position now", "had we expanded capacity earlier."],
    orders: [[0,1,2,3,4,5,6]]
  }
}
);
