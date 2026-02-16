# 출퇴근길 재테크/투자 게임 SPEC (Galaxy Android 기준)

## 1) 프로젝트 개요
- 목표: 출퇴근 시간(5~15분) 동안 짧고 가볍게 플레이 가능한 재테크 학습형 게임 제작
- 플랫폼: Android (Galaxy 최적화, 1순위), Flutter Web(검증 채널 2순위)
- 개발 방향: 오프라인 중심, 즉시 실행 가능한 싱글 디바이스 플레이 우선
- 핵심 가설: 짧은 라운드 의사결정(리스크/수익)으로 직장인의 자투리 시간 집중도를 높일 수 있다

## 2) 산출 범위 (MVP 최소 범위)
- 게임 모드: 1개 미니게임 루프만 구현
  - `경제 이벤트 발생 -> 투자 선택 -> 결과 처리 -> 피드백`
- 핵심 기능
  - 플레이어 자산/포트폴리오 상태 표시
  - 난이도 구간이 있는 라운드 진행
  - XP, 연속 출근 보너스, 보상 알림
  - 일일 미션(짧은 목표 1개)
- 제외 항목
  - 실시간 API 연동
  - 멀티플레이/채팅
  - 결제/광고/복잡한 소셜 기능

## 3) 팀 구성(예: 2~3인)
- 기획/PM
  - 게임 루프, 밸런스 수치, KPI 정의
- 클라이언트/플레이어 루프 개발
  - Flutter 화면, 상태관리, 게임 진행 로직 연동
- 콘텐츠/데이터 설계
  - 이벤트 카드, 상품군, 스토리/문구, 튜토리얼

> 팀원/역할 확정이 필요하면 `TODO`로 남긴 후 다음 단계에서 상세 정의

## 4) 에이전트형 실행 구조 (개발용)
- `Spec Agent`
  - 요구사항 정합성, 우선순위 조정
- `Domain Agent`
  - 게임 규칙/보상/난이도 로직
- `Client Agent`
  - 화면/상태/UI/애니메이션
- `QA Agent`
  - 시나리오 테스트, QA 체크리스트, 이탈 포인트 분석

> 팀 규모·권한 분리에 따라 에이전트 수는 조정 (`TODO`)

## 5) 아키텍처
- 레이어:
  - `presentation/`: 화면, 위젯, 사용자 인터랙션
  - `domain/`: 게임 규칙, 계산식, 상태 머신
  - `data/`: 로컬 저장, 시퀀스 데이터, 마이그레이션
- 상태관리: `Riverpod` or `Bloc` 중 1개 선택
- 저장: `Hive` 또는 `SQLite`(로컬 캐시 우선)
- 오프라인 퍼스트 원칙 적용

## 6) 핵심 데이터 모델
- `GameState`
  - `playerId`, `day`, `cash`, `riskProfile`, `xp`, `streak`, `portfolio`, `lastPlayedAt`
- `InvestmentOption`
  - `id`, `name`, `category`, `riskLevel`, `expectedReturn`, `volatility`, `cost`, `cooldownSec`
- `MarketEvent`
  - `id`, `title`, `description`, `impactMin`, `impactMax`, `appliesTo`, `duration`, `rarity`
- `RoundResult`
  - `roundId`, `before`, `after`, `profitLoss`, `xpDelta`, `reason`, `timeStamp`

## 7) 인터페이스(최소 정의)
- `IInvestmentEngine`
  - `startRound()`, `choose(optionId)`, `resolve(roundInputs)`, `snapshot()`
- `ISessionRepository`
  - `load(playerId)`, `save(gameState)`, `archive(playerId)`
- `IAnalyticsSink`
  - `trackEvent(name, payload)`, `trackError(code, context)`

## 8) 웹 포트포워딩 검증 가이드
- 실행 기본값
  - Flutter 실행 명령: `flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8080`
  - 맥 로컬 접속: `http://127.0.0.1:8080`
  - Tailscale 직접 접속: `http://<맥-Tailscale-IP>:8080`
- Termius(또는 유사 SSH 앱) 포트포워딩 설정
  - 터널 유형: `Local` (로컬 포트 포워딩)
  - Local listen(소스): `127.0.0.1:8080`
  - Destination(목적지): `127.0.0.1:8080`
  - 모바일 브라우저 접속: `http://127.0.0.1:8080`
- 기본 규칙
  - `로컬포트 = 목적지포트`(기본 8080)로 맞춘다.
  - 필요 시 대체 포트 사용 시에도 동일 규칙 유지(예: 9000→9000).
- 충돌 시
  - 8080 포트 사용 중이면 `--web-port=9000`으로 변경하고, 포워딩도 9000으로 동일하게 변경.
- 검증 체크리스트(웹)
  - [x] 맥에서 브라우저 진입 -> 게임 첫 화면 표시 확인 (2026-02-16 완료)
  - [ ] 모바일 브라우저에서 게임 라운드 1회(시작→선택→결과) 진행 확인
  - [ ] 저장/복구 기본 동작(웹 세션) 확인 — 웹은 InMemorySessionRepository 사용
  - [ ] 포워딩 직접 접속(Tailscale/IP) 및 앱 내장 포워딩(localhost) 모두 200 응답 확인

## 9) 게임 상태 머신
- `IDLE` -> `READY` -> `CHOICE` -> `SIMULATE` -> `RESULT` -> `POST_REVIEW` -> `IDLE`
- 매 라운드 종료 후 자동으로 `READY` 전환 가능(다음 라운드 지연시간 포함)

## 10) UX(출퇴근 시간 최적화)
- 60~90초 내 초단위로 완결되는 라운드 구성
- 한 화면당 핵심 정보 3개 이하로 표시
- 선택 후 즉시 시각적 피드백 + 요약 툴팁

## 11) 성공 지표(KPI)
- 1회 플레이 완료율
- 3분 세션 유지율
- D1/D7 재방문율
- `first_choice_delay`(게임 시작~첫 선택 시간)
- 웹 원격 검증 통과율(동일 맥 설정에서 모바일 브라우저 접속성)

## 12) 미확정/추가 항목(TODO)
- 상세 브랜딩/비주얼 톤
- 사운드 정책
- 확장형 과금/광고 정책
- 실시간 뉴스/시세 연동
- 리텐션 실험 설계(A/B)

## 13) 일정(초안)
- Day 1: 핵심 게임 규칙 및 수치 설계
- Day 2~3: 도메인 모델 + 상태 머신 구현
- Day 4~5: 1개 게임 루프 UI 구현
- Day 6: 로컬 저장/복구 + 튜닝
- Day 7: 버그 수정, APK 베타 빌드
