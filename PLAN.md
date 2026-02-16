# Commuter Investment Game PLAN

## 1) 목표 및 범위
- SPEC.md 기반 단일 미니게임 루프 MVP 구현을 시작한다.
- 범위는 `경제 이벤트 발생 -> 투자 선택 -> 결과 처리 -> 피드백` 한 라운드 루프와 핵심 상태/저장/보상 UI만 다룬다.
- 플랫폼 기본값: Flutter + Riverpod + File-first 영속 스토리지(향후 Hive/SQLite 이동 준비).

## 2) 아키텍처/스택
- presentation/: 화면/위젯
- domain/: 게임 규칙, 상태 머신, 모델, 인터페이스
- data/: 저장소/로컬 영속화
- state: Riverpod 기반 게임 상태 결합
- 오프라인 퍼스트로 동작

## 3) 공개 인터페이스/타입
- `lib/domain/interfaces/investment_engine.dart`
  - `startRound(int day, {RiskProfile? overrideProfile})`
  - `choose(String optionId)`
  - `resolve()`
  - `snapshot()`
- `lib/data/interfaces/session_repository.dart`
  - `load(String playerId)`
  - `save(GameState state)`
  - `archive(String playerId)`
- `lib/analytics/interfaces/analytics_sink.dart`
  - `trackEvent(String name, Map<String, Object?> payload)`
  - `trackError(String code, Map<String, Object?> context)`

## 4) 상태 머신
- `IDLE -> READY -> CHOICE -> SIMULATE -> RESULT -> POST_REVIEW -> IDLE`
- 매 라운드 종료 시 자동으로 READY 전이 준비(지연은 구현 단계에서 보완)

## 5) 현재 단계
- Phase: `team-plan` 완료, `team-prd` 완료, `team-exec` 완료, `team-verify` 진행
- 최근 상태: Riverpod 상태관리/1회 라운드 UI/QA 체크리스트/통합 테스트 골격까지 완성
- 최근 상태: 영속 저장소 기본 주입을 파일 기반으로 전환하고, 저장/복구 라운드트립 테스트 코드 작성 완료
- 최근 상태: **웹 검증 완료** — `pubspec.yaml` 생성, 5건 버그 수정, `flutter test` 9/9 통과, 웹 브라우저 DAY 1→2 전환 확인

## 6) 일정(초안)
- Day 1: 도메인 모델/상태머신/인터페이스 확정 (`완료`)
- Day 2: 투자 엔진 초안 및 라운드 계산 로직 구현 (`완료`)
- Day 3: 리포지토리 인터페이스 + 임시 저장 구현 + 분석 인터페이스 (`완료`)
- Day 4: Flutter + Riverpod 상태결합 및 화면 UI (`완료`)
- Day 5: 로컬 저장/복구 + 일일 미션/보상 반영 (`완료`)
- Day 6: 통합/기능 검증 (`완료` — 웹 검증 포함)
- Day 7: QA 체크리스트 정리 및 베타 준비 (`진행 중`)

## 7) 에이전트 가정
- 팀 규모: 4인 (Spec/PM, Domain, Client, QA)
- `swarm` 실행 규칙: 단계 종료 시점 기준으로 PLAN/TASK 갱신

## 8) 위험 요인
- 영속 스토리지 전환(Hive/SQLite) 시 직렬화/역직렬화 스키마 정합성 이슈
- 무작위 이벤트 모델이 지나치게 단순해 게임 밸런스가 급격히 편향될 수 있음
- 랜덤 결과에서 플레이어 체감 지연이 생길 경우 라운드 체감시간 악화
- 웹에서 `dart:io` 직접 사용 불가 — `FileSessionRepository`는 네이티브 전용, 웹은 `InMemorySessionRepository` 폴백
- `copyWith` nullable 필드 패턴 — `null` 전달 시 기존 값이 유지되므로 `clear*` 매개변수를 사용해야 함 (GameState.clearMission, GameSession.clearLastResult 등)

## 9) 다음 액션
- QA: 모바일 브라우저 원격 접속 검증(T16) 수행
- Client: Android 네이티브 빌드 시 `FileSessionRepository` 활성화 확인
- QA: 10회 이상 연속 라운드 웹 안정성 확인

## 진행 하이라이트
- 완료: Domain 모델/인터페이스, 투자 엔진, 라운드 해석 로직, Riverpod 노티파이어, 1회 라운드 화면 1차 구현
- 완료: 일일 미션 보너스/연속 출근 표시 반영, 라운드 소요시간 측정(최근 라운드 지표) 도입
- 완료: `FileSessionRepository` 기본 주입, `test/data/session_repository_test.dart`와 `test/state/game_notifier_stability_test.dart` 추가로 T10/T12 보강 완료
- **완료**: `flutter test` 9/9 통과 — `pubspec.yaml` 생성, 5건 버그 수정(상태 전이, copyWith nullable 패턴, import 경로, 웹 호환성, 테스트 import)
- **완료**: 웹 브라우저 DAY 1→DAY 2 전환 및 게임 흐름 검증
- 진행: 모바일 브라우저 원격 접속 검증, Android 빌드 검증
