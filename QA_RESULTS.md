# QA RESULTS

## 2026-02-16 (Preliminary)

### T10 저장/복구 수동 시나리오
- 상태: DONE (자동 검증 코드 준비)
- 산출:
  - `test/data/session_repository_test.dart`
- 비고: 영구 저장 라운드트립(저장/로드/아카이브) 단위 테스트 추가됨. 수동 실행은 운영 검증에서 진행

### T11 라운드 핵심 경로 통합 테스트
- 상태: DONE (자동 점검 강화 완료)
- 산출물:
  - `test/domain/investment_engine_test.dart`
  - `test/widget/game_flow_smoke_test.dart`

### T12 성능/안정성 점검
- 상태: DONE (자동 체크 강화 완료, 실행은 대기)
- 반영 근거:
  - 라운드 측정값(`lastRoundMs`) 노출 추가: `lib/state/game_session.dart`, `lib/presentation/screens/game_screen.dart`
  - 라운드 결과 이벤트에 소요시간 payload 추가: `lib/state/game_notifier.dart`
  - 영속 저장/복구 상태에서 10회 라운드 반복 및 재시작 복구 안정성 테스트 추가: `test/state/game_notifier_stability_test.dart`
  - 저장 실패 전파를 방지하고 분석 이벤트로 이슈 기록: `lib/state/game_notifier.dart`
- 비고: `flutter test` 실행 및 체크리스트 수치 기록은 수동 실행 필요

## 다음 단계
- 모바일 브라우저 원격 접속 검증 (Termius/Tailscale 포트포워딩)
- Android 네이티브 빌드 시 `FileSessionRepository` 검증
- 10회 이상 연속 라운드 웹 안정성 검증

## 2026-02-16 (웹 검증 및 버그 수정)

### T17 pubspec.yaml 생성 및 웹 플랫폼 활성화
- 상태: DONE
- 산출물:
  - `pubspec.yaml` (신규 생성, `flutter_riverpod: ^2.4.0` 포함)
  - `web/` 디렉토리 (`flutter create --platforms web .`)
- 비고: 프로젝트에 `pubspec.yaml`이 없어 Flutter 프로젝트 실행이 불가능한 상태였음

### T18 웹 검증 시 발견 버그 5건 수정
- 상태: DONE
- 발견/수정 버그:
  1. **BUG-1** `startRound()` 상태 검증 로직 – `POST_REVIEW`에서 다음 라운드 시작 시 `StateError` 발생. 기존 코드가 `POST_REVIEW`를 거부 대상에 포함한 후 `IDLE`/`READY`만 허용하는 논리적 모순. `IDLE`, `READY`, `POST_REVIEW` 모두 허용하도록 수정.
  2. **BUG-2** `resolve()` 미션 초기화 – `copyWith(mission: null)`이 기존 값 유지. `clearMission: true` 사용으로 수정.
  3. **BUG-3** 웹 `dart:io` 호환성 – `FileSessionRepository`가 `dart:io` 의존으로 웹 컴파일 불가. `kIsWeb` 분기로 `InMemorySessionRepository` 폴백 처리.
  4. **BUG-4** `GameFlowState` import 경로 – 3개 파일에서 `domain/models/` 대신 `domain/state/`로 수정.
  5. **BUG-5** 테스트 import 형식 – 4개 테스트 파일에서 `../../lib/` → `package:commute_investment_game/`으로 수정.
- 추가 수정:
  - `GameSession.copyWith`에 `clearLastResult`, `clearLastRoundMs` 매개변수 추가
  - `proceedNextRound()`에서 `clearLastResult: true`, `clearLastRoundMs: true` 사용
  - 테스트 `initialCash: 2` → `500` (최소 투자 비용 400원 미만)
  - `test/widget_test.dart` 삭제 (`flutter create` 자동 생성, `MyApp` 참조 에러)

### T19 웹 브라우저 게임 흐름 검증
- 상태: DONE
- `flutter test` 결과: **9/9 통과**
  - `test/domain/investment_engine_test.dart`: 5/5
  - `test/data/session_repository_test.dart`: 1/1
  - `test/state/game_notifier_stability_test.dart`: 2/2
  - `test/widget/game_flow_smoke_test.dart`: 1/1
- 웹 브라우저 검증 (http://0.0.0.0:8080):
  - [x] 게임 첫 화면(DAY 1) 정상 표시
  - [x] 투자 옵션(단기 국채, 테크 ETF) 선택 가능
  - [x] 결과 패널(손익, XP) 정상 표시
  - [x] "다음 라운드" 버튼 → DAY 2 전환 성공 (BUG-1 수정 후)
  - [x] DAY 2에서 재선택 → 결과 확인 → 연속 출근 보너스 반영 확인

