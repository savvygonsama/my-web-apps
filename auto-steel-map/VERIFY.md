# 웹 검증 기록 (2026-10-10)

내연차편 데이터를 공개 자료(철강사 데이터시트, 업계 가이드라인, 특허·논문)와 대조했습니다.
웹 검색 요약으로만 확인했기 때문에 규격 원문(JIS·JFS·VDA)을 직접 연 것은 아닙니다. **TS 검수를 대신하지 않습니다.**

## 규격명

| 항목 | 결과 | 반영 |
|---|---|---|
| BH: JFS JSC340H, JIS SPFC340H | 실재 확인 (ArcelorMittal: JSC340H ≈ CR210BH ≈ HC220B) | "확인 필요" 해제 |
| DP: JFS JSC590Y·JSC780Y·JSC980Y, JIS SPFC590Y·780Y·980Y | 실재 확인 (AHSS Guidelines, ArcelorMittal) | JIS DP590을 **SPFC590 → SPFC590Y**로 정정 |
| VDA CR330Y590T-DP = HCT590X, CR440Y780T-DP = HCT780X | 확인 | 유지 |
| VDA CR590Y980T-DP | 공개 자료로 확인 못 함 | "VDA 명칭 확인 필요" 표시, 근거 없는 CR700Y980T-DP 삭제 |
| VDA CR700Y980T-DH (= HCT980XH) | 확인 | 3세대 AHSS에 반영 |
| VDA CR900Y1180T-CP, CR1220Y1500T-MS | 확인 (ESB, SSAB) | "확인 필요" 해제 |
| VDA 239-500 CR1500T-MB, CR1900T-MB(34MnB5), 도금 AS80·AS150 | 확인 | 반영 |
| 열연 FB 590: EN 10338 | **HDT580X는 오류**, 맞는 이름은 HDT580F | 정정 |
| HR660Y760T-CP = HDT760C, JFS JSH590R·JSH780R, JIS SPFH590Y | 확인 | 반영 |
| HSLA: JFS JSC390W | 확인 못 함 | 삭제, JSC440W·JSC440R로 |
| 스테인리스 SUS439, SUS441 | JIS에 해당 이름 없음 (439 ≈ SUS430LX, 441은 JIS 대응 없음) | 정정 |
| 스프링강 | SUP7도 대표 강종 | 추가 |

## 부품 값

| 부품 | 결과 | 반영 |
|---|---|---|
| 도어·후드·루프·트렁크·펜더 외판 | BH180/220급, 0.65~0.8mm가 일반적 | 두께 0.65~0.8로 조정 |
| 사이드 아우터 | 초심가공 IF강(DC06·DX56D) | BH 제외 유지 |
| B필러 보강 | 22MnB5 + Al-Si가 주력(유럽 76% 이상), 하단 연질부 약 500MPa | 유지 |
| 범퍼빔 | 롤포밍 MS1500 약 1.0mm부터, 통상 1.1~2.0mm | 1.0~2.0으로 |
| 도어 임팩트빔 | 1470MPa 전봉 강관, 1500MPa 롤포밍, 핫스탬핑 모두 사용 | 유지, 강관 규격 보강 |
| 프론트 로어암 | 열연 590 FB·780 CP, 2.9~3.2mm 예 | 유지 |
| 서브프레임 | FB590 1.8~1.9mm 사례 | 1.8~3.5로 |
| CTBA | 보론강(20MnB5·22MnB5) 강관 열처리, DP780 | 강종 보강 |
| 휠 디스크 | 열연 DP 2.95~5.5mm, 15인치 승용 590급 | 3.0~5.5로, 확신도 상향 |
| 코일 스프링 | 일반 1,600~1,800MPa, 경량 고강도 2,000MPa 이상 | 등급 표기 정정 |
| 연료탱크 | 도금은 Al-Si·Sn-Zn·아연+니켈, HDPE가 시장 60~80%, PHEV 밀폐식(약 350mbar) | 반영 |
| 머플러 | 409(L)·439, 알루미늄도금강판 | 유지 |
| 시트 레일 / 리클라이너 | DP980·CP980·TRIP1180 / 고연성 열연 HSLA~CP1000 | 정정 |
| EV 배터리 프레임 | 냉연 MS는 약 2.1mm까지, 무거운 팩은 열연 MS 2~4mm | 반영 |
| 모터 코어 | 0.20~0.35mm | 유지 |
| GA / GI | 일본계 GA, 유럽·미국계 GI. 국내 OEM 근거는 못 찾음 | 용어 풀이 정정 |
| 후드 알루미늄 | 북미는 다수가 알루미늄으로 전환 전망 | 경쟁 소재 문구 정정 |

## 근거를 찾지 못해 그대로 둔 것 (TS 확인 필요)

휠 림 두께, 시트 리클라이너 두께, 배터리 하부 플레이트·크로스멤버·상부 커버 두께, VDA CR590Y980T-DP 명칭, 국내 OEM의 GA/GI 비중, 모든 부품의 OEM별 실제 강종.

## 주요 출처

- ArcelorMittal Automotive: [BH](https://automotive.arcelormittal.com/products/flat/HYTSS/BH), [DP](https://automotive.arcelormittal.com/products/flat/first_gen_AHSS/DP), [FB](https://automotive.arcelormittal.com/products/flat/first_gen_AHSS/FB), [DH](https://automotive.arcelormittal.com/products/flat/third_gen_AHSS/DH), [EV front chassis](https://automotive.arcelormittal.com/s-in_motion_solutions/EVfrontchassis)
- AHSS Guidelines: [JIS G3135](https://ahssinsights.org/tag/jis-g3135/), [Bake Hardenable](https://ahssinsights.org/metallurgy/steel-grades/ahss/bake-hardenable-steel/), [PHS grades](https://ahssinsights.org/metallurgy/steel-grades/phs-grades/)
- ESB Group: [VDA 239-100 DP·MP steels](https://www.esb-group.com/en/products-vda-239-100-2/dual-phase-and-multiphase-steels-according-to-vda-239-100/)
- SSAB: [Bumpers](https://www.ssab.com/en-us/brands-and-products/docol/applications/bumpers), [Car seats](https://www.ssab.com/en-us/brands-and-products/ssab-docol/applications/car-seats), [EV battery protection](https://www.ssab.com/en-us/brands-and-products/ssab-docol/applications/ev-battery-crash-protection)
- thyssenkrupp: [BHZ](https://www.thyssenkrupp-steel.com/media/content_1/publikationen/produktinformationen/bhz/thyssenkrupp_bhz_product_information_steel_en.pdf), [MBW](https://www.thyssenkrupp-steel.com/media/content_1/publikationen/produktinformationen/mbw/thyssenkrupp_mbw_product_information_steel_en.pdf)
- Tata Steel: [HR660Y760T-CP](https://products.tatasteelnederland.com/sites/producttsn/files/tata-steel-automotive-hr-cp800-uc-hr660y760t-cp-datasheet-DE.pdf)
- Nippon Steel: [Pb-free fuel tank sheet](https://www.nipponsteel.com/en/tech/report/nsc/pdf/n8812.pdf)
- JFE Steel: [540–780MPa hot-rolled](https://www.jfe-steel.co.jp/en/research/report/018/pdf/018-23-2.pdf), [door impact beam sheet](https://www.jfe-steel.co.jp/en/products/sheets/c23.html)
- Hyundai Steel (SAE): [780MPa lower control arm](https://www.sae.org/publications/technical-papers/content/2013-01-0665/)
- TI Fluid Systems: [PHEV sealed fuel tanks](https://tifluidsystems.com/tifs-blog-7/)
- Outokumpu: [stainless fuel tanks](https://www.outokumpu.com/en/expertise/2022/sustainable-stainless-steel-fuel-tanks-for-hybrid-and-ice-vehicles)
- AISI: [Bumper fact sheet](https://www.steel.org/wp-content/uploads/2020/10/AISI-Bumper-Team-Fact-Sheet-06242020.pdf)

## 기준 변경: 일본계 OEM (2026-10-10)

일본계 완성차를 상대하는 조직 기준으로 자료를 맞췄습니다.

- 도금: 일본계 주력인 **GA** 기준으로 표기 (미국·유럽계는 GI 중심). 일본계 GA 선호는 도장 밀착성 때문이라는 설명이 있음 ([ITB 강연 요약](https://itb.ac.id/news/dr-daisuke-mizuno-corrosion-and-protection-in-automotives/5438))
- 규격명: JIS·JFS를 기준, EN·VDA는 유럽계 대응 참고
- 초고강도: 일본계 OEM·1차 협력사는 1.5GPa급까지 냉간 프레스 비중을 늘리는 중 ([SSAB](https://www.ssab.com/en-us/brands-and-products/ssab-docol/automotive-steel-resources/automotive-insights/cold-stamping-1500-and-1700-mpa-automotive-steels)), 닛산 로그 B필러는 SHF980·SHF1180 TWB 냉간 성형 ([AHSS Guidelines](https://ahssinsights.org/tag/hot-forming/))
- 일본계 OEM 자체 소재 규격 번호는 공개 자료로 확인할 수 없어 적지 않음

## 2차 검증: 부품별 품종·규격 (2026-10-11)

**발견한 근본 오류**: 품종이 GA(도금)인 차체 부품에 비도금 냉연 규격명(JFS **JSC**)을 붙였음. 일본계 자동차용 강판 규격은 바탕재·도금으로 이름이 갈림.

| 바탕재·도금 | 일본계 규격 | 근거 |
|---|---|---|
| 냉연 + GA (차체 대부분) | JFS A 3011 **JAC** (JAC270C·D·E·F, JAC260G, JAC340H, JAC440W, JAC590R·Y, JAC780Y, JAC980Y, JAC1180YL) | [JAC 계열 목록](https://www.steelestores.com/standard/jfs-a3011/), [혼다 GA 품목 JAC270F·JAH270C](http://steel-coils-sheets.mststeel.com/item/galvannealed-steel/c071-04-honda-galvannealed-steel/jac270f), [JFE GA 1180·닛산 JAC1180YL 채용](https://www.jfe-steel.co.jp/en/products/sheets/c33.html) |
| 냉연 비도금 (시트·롤포밍) | JFS A 2001 **JSC**, JIS G3135 **SPFC** (SPFC980Y 등), JSC1180Y·YL·YH | [AHSS Guidelines JFS A2001](https://ahssinsights.org/tag/jfs-a2001/), [SPFC980Y](http://steeljis.com/jis_steel_datasheet.php?name_id=369) |
| 열연 PO (섀시) | JIS G3113 **SAPH**310~440, JIS G3134 **SPFH**490~590, JFS A 1001 **JSH** | [Kobe Steel](https://www.kobelco.co.jp/english/products/download/steel-aluminum/files/heating.pdf), [CSVC PO 카탈로그](https://www.csvc.com.vn/pdf/201502%20PO%20Catalogue.pdf) |
| 열연 + GA | JFS A 3011 **JAH** (JAH270C, JAH440W, JAH590R) | [JAH 계열](https://www.steelestores.com/grade/jfs-jah440w-jfs-a3011.html) |
| 핫스탬핑 | JFS 규격명 없음. 22MnB5 계열, 철강사 규격 | [ArcelorMittal Usibor](https://automotive.arcelormittal.com/products/flat/PHS/usibor_ductibor) |
| 1310·1470MPa 마르텐사이트 (범퍼·임팩트빔 롤포밍) | JFS 규격명 없음. 철강사 규격 (JFE·고베제강) | [JFE 1470MPa](https://www.jfe-steel.co.jp/en/release/2016/161124.html), [Kobelco 1300·1500MPa](https://www.kobelco.co.jp/english/r-d/technology-review/pdf/35_034-038.pdf) |

**반영**
- 부품마다 대표 규격명(`sp`)을 직접 지정해 말풍선에 표시 (81개 + EV 5개 전부)
- GA 차체 부품: JSC → **JAC**로 전면 교체 (외판 JAC340H, 내판 JAC270E·F, 골격 JAC590Y~JAC1180YL)
- 범퍼빔·도어 임팩트빔·롤포밍재: 품종을 "비도금"으로, 규격은 1310·1470MPa급 마르텐사이트(철강사 규격)
- 시트 프레임·레일: 비도금 SPFC 계열 (SPFC980Y 등)
- 섀시: SAPH440·SPFH590·JSH590R~JSH780R
- 오일팬: SPCD·SPCE ([STEELMAX](https://steelmax.co.kr/2015/01/08/spce-steel-plate-cold-deep-drawn-extra/)), 쇼크업소버 외통: STKM 전봉관 ([특허](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/4880087))
- 연료탱크: 용융알루미늄도금 또는 Sn-Zn 도금 (일본제철 ECOKOTE-S) ([일본제철](https://www.nipponsteel.com/en/tech/report/nsc/pdf/103-17.pdf))
- 규격 분류(CLS) 설명도 "GA: JAC / 비도금: JSC·SPFC"로 나눠 표기

**남은 한계**: 부품별로 어느 등급(예: JAC590Y냐 JAC780Y냐)을 쓰는지는 OEM·차종마다 다름. 표기는 일본계에서 흔한 범위의 대표값이며 실제는 고객 승인 사양서로 확인.
