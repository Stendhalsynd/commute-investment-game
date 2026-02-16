# Commuter Investment Game PLAN (V2)

## 1) 목표 및 범위
- 상용 앱 대비 복잡한 정보량을 줄이고, 출퇴근 시간 조건에서의 `Decision-making under pressure`에 집중한다.
- 결과 표시 + 문해력 피드백을 결합해, 단발 게임 점수가 아닌 `투자 성향 보고서`(복기 데이터) 누적을 남긴다.
- 이번 단계는 **문서 정비 + 도메인 코어 + 트래킹 강화**를 완료한다.

## 2) 핵심 목표(이번 사이클)
- `InvestmentEngine`에 시나리오 모드 추가
  - `speedScenario`: 사전 설계된 역사적/가상 이벤트 큐로 1분 내 초압축 라운드 진행
  - `dailyChallenge`: 매일 시나리오 선택 경로 확장
- `RoundResult` 확장
  - `insight`, `scenarioMode`, `scenarioId` 필드 추가
  - `IInvestmentEngine`으로 시나리오 메타 조회 API 제공
- AI Insight(규칙 기반) 생성
  - 라운드 결과에 “왜 그 선택이 맞거나 어긋났는지” 요약 문장 생성

## 3) API/타입 변경
- `lib/domain/interfaces/investment_engine.dart`
  - `InvestmentScenarioMode` enum 추가
  - `startRound(int day, {RiskProfile? overrideProfile, InvestmentScenarioMode? scenarioMode, String? scenarioId})`
  - `currentScenarioMode`, `currentScenarioId()`
- `lib/domain/models/market_event.dart`
  - `scenarioType`, `historicalTag`, `isSynthetic` 추가
- `lib/domain/models/round_result.dart`
  - `insight`, `scenarioMode`, `scenarioId` 추가

## 4) 구현 상태(고정)
- Domain:
  - IInvestmentEngine 인터페이스 확장 완료
  - DefaultInvestmentEngine 시나리오 이벤트/해석 엔진, 규칙 기반 인사이트 반영
  - 이벤트/결과 모델 확장
  - `hold()` 라운드 스킵 액션 추가
- State:
  - 결과 이벤트(`round_resolved`)에 시나리오/인사이트 메타 추가
  - `round_skipped` 추적 이벤트로 보류 라운드 분석 로깅 추가
  - 보류 정책 A/B(`flat/supportBeginner/punishHesitation`)와 Review 밀도 설정(Compact/Standard/Readable) 세션 반영
- QA:
  - 테스트에 시나리오 모드 및 insight 채움 검증 항목 추가
 - Client:
  - CHOICE 단계에서 수직 스와이프 제스처로 매수/보류 인터랙션으로 전환 (보류는 라운드 스킵으로 실제 전이)
  - 결과 화면에 50자 내외 복기 툴팁(마우스/롱프레스 Tooltip) 노출
  - 라운드 시작 전 시나리오 모드(실시간/스피드/데일리) 선택 반영
  - 보류 정책/Review 밀도 토글 UI 추가로 A/B 실험 가설 수행 준비
  - 상단 상태에 내 집 마련(자산 성장) 게이지를 표시해 보상 체계를 자산 관점으로 확장
  - 스와이프 방향/결과 인사이트에 색상 기반(상승-빨강/하락-파랑) 아이콘 가시성 추가

## 5) 상태 머신
- 기존: `IDLE -> READY -> CHOICE -> SIMULATE -> RESULT -> POST_REVIEW`
- 유지: 라운드 전이 구조, 시나리오 모드는 라운드 시작 시점에서 선택

## 6) 일정(수정안)
- Day 1~4: 기존 구현 안정화
- Day 5: 시나리오 엔진 및 시나리오 데이터셋 설계/연동
- Day 6: 인사이트 메시지 로직, 이벤트 메타 트래킹 연동
- Day 7: 한손 스와이프 UX 옵션 검토 및 다음 주차 반영 우선순위 정의

## 7) 위험 요인
- 정보 과부하: 텍스트 증가로 이탈율 상승 가능성 → 1줄 인사이트/아이콘 기반 보조문구로 대응
- 밸런스 붕괴: 초보자 지속 손실 시 리텐션 저하 → 기초 난이도 가드 또는 보정 보상 정책 고려
- 오해 리스크: 인사이트가 판단을 암시하지 않도록 "왜"를 설명하되 과신 유도 문구 금지

## 8) 다음 액션(우선순위)
1. 보류 정책 × Review 밀도 조합별 KPI 비교(라운드 유지/재시작율/초보자 잔존율)
2. 실제 체류 데이터 기반으로 지원/벌점 정책 임계값 조정
