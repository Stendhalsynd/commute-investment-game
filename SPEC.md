# 출퇴근길 재테크/투자 게임 SPEC (V2 - 인사이트 반영)

## 1) 프로젝트 개요
- 목표: 출퇴근 시간(5~15분) 내 `초압축 의사결정`으로 완결되는 게임 루프 제공
- 플랫폼: Android (Galaxy 최적화, 1순위), Flutter Web(검증 채널 2순위)
- 핵심 가설: 결과 중심 피드백보다 **의사결정 복기(인과관계 중심) 피드백**이 투자 문해력 향상에 더 빠르게 작동한다
- 실시간 데이터 대기 없이 과거 이벤트/가상 시나리오를 즉시 체험하도록 설계한다

## 2) 산출 범위 (V2 MVP)
- 게임 모드
  - `스피드 시나리오`: 역사적/가상 이벤트를 1분 안에 초고속 체험
  - `데일리 챌린지`: 오늘의 경제 뉴스 톤을 반영한 단일 선택지 시나리오
  - 라운드 시작 전 모드(실시간/스피드/데일리) 선택
- 핵심 기능
  - 플레이어 자산/포트폴리오 상태 표시
  - 난이도 구간이 있는 라운드 진행
  - XP, 연속 출근 보너스, 보상 알림
  - 일일 미션(짧은 목표 1개)
  - 보류(상/하 스와이프) 라운드 스킵 경로 지원
  - AI 도슨트 인사이트: “왜 그런 결정을 했는지, 시장 맥락에서 결과가 나온 이유”를 요약
  - 결과 화면 `Review` 툴팁에 핵심 사유 50자 내외 요약 노출
  - 시나리오 모드 메타(`scenarioMode`, `scenarioId`)와 결과 인사이트 저장
  - 상단 `내 집 마련 게이지`를 통해 현금+포트폴리오 기준 자산 성장 추세를 시각화
  - 스와이프 방향/결과 인사이트의 색상 코드(상승-빨강/하락-파랑)와 햅틱 피드백으로 운전 환경 조작 부담 감소

## 3) 팀 구성(예: 2~3인)
- 기획/PM
  - 게임 루프, 수치 설계, KPI 정의
- 클라이언트
  - Flutter 화면, 상태관리, 게임 진행 연동
- 도메인/콘텐츠
  - 시나리오 카드, 리스크 메타 규칙, 인사이트 텍스트 규칙

## 4) 에이전트형 실행 구조 (개발용)
- `Spec Agent`
  - 요구사항 정합성, 우선순위 조정
- `Domain Agent`
  - 게임 규칙, 보상, 난이도, 시나리오 엔진
- `Insight Agent`
  - 투자 결과를 시장 맥락(원인-결과-교훈)으로 번역
- `Client Agent`
  - 화면/상태/UI
- `QA Agent`
  - 시나리오 테스트, QA 체크리스트, 이탈 포인트 분석

## 5) 아키텍처
- 레이어:
  - `presentation/`: 화면, 위젯, 사용자 인터랙션
  - `domain/`: 게임 규칙, 계산식, 상태 머신
  - `data/`: 로컬 저장, 시퀀스 데이터
- 상태관리: `Riverpod`
- 저장: 로컬 퍼스트(영속/메모리 캐시)

## 6) 핵심 데이터 모델
- `GameState`
  - `playerId`, `day`, `cash`, `riskProfile`, `xp`, `streak`, `portfolio`, `lastPlayedAt`
- `InvestmentOption`
  - `id`, `name`, `category`, `riskLevel`, `expectedReturn`, `volatility`, `cost`
- `MarketEvent`
  - `id`, `title`, `description`, `impactMin`, `impactMax`, `appliesTo`, `duration`, `rarity`
  - `scenarioType`, `historicalTag`, `isSynthetic`
- `RoundResult`
  - `roundId`, `before`, `after`, `profitLoss`, `xpDelta`, `reason`, `insight`, `scenarioMode`, `scenarioId`, `timeStamp`

## 7) 인터페이스(최소 정의)
- `IInvestmentEngine`
  - `startRound(int day, {RiskProfile? overrideProfile, InvestmentScenarioMode? scenarioMode, String? scenarioId})`
  - `choose(String optionId)`
  - `resolve()`
  - `setHoldPolicy(HoldPolicy policy)`
  - `snapshot()`
  - `currentScenarioMode`, `currentScenarioId()`
  - `currentHoldPolicy`
- `ISessionRepository`
  - `load(playerId)`, `save(gameState)`, `archive(playerId)`
- `IAnalyticsSink`
  - `trackEvent(name, payload)`, `trackError(code, context)`

## 8) 웹 포트포워딩 검증 가이드
- 기존 규칙 유지(8080/9000 대체 규칙, 웹 브라우저 동작 확인)

## 9) 게임 상태 머신
- `IDLE` -> `READY` -> `CHOICE` -> `SIMULATE` -> `RESULT` -> `POST_REVIEW`
- 매 라운드 종료 후 자동 READY 전환 경로는 향후 확장

## 10) UX (지하철/버스 최적화)
- 한 손 조작: CHOICE 단계에서 상/하 수직 스와이프 제스처로 빠른 선택 진입을 제공
- 한 화면당 핵심 정보 3개 이하
- 결과는 결과 수치 + 인사이트 텍스트(한 줄 요약) 동시 노출
- 색/아이콘 중심으로 텍스트량 최소화

## 11) 성공 지표(KPI)
- 1회 플레이 완료율
- 3분 세션 유지율
- D1/D7 재방문율
- `first_choice_delay`(게임 시작~첫 선택 시간)
- 1회 라운드 체감시간

## 12) 미확정/추가 항목(TODO)
- 상세 브랜딩/비주얼 톤
- 사운드 정책
- Haptic 정책(휴대폰 진동)
- 실시간 뉴스/시세 API 연동

## 13) 일정(개선안)
- Day 1~4: 기존 구현 기반 게임 규칙/UI 안정화
- Day 5: 시나리오 엔진 및 데이터셋 설계
- Day 6: 피드백 시스템 및 AI Insight 브릿지 구현
- Day 7: 안정성 점검 및 스와이프 한손 조작 준비
