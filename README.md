# 출퇴근길 재테크 게임

A Flutter MVP for an offline, single-device mini-game optimized for short commuting-time sessions.

## 목표
- 출퇴근 시간 5~15분 내 완결 가능한 투자 의사결정 루프 제공
- 라운드 단위로 자산, XP, 연속 출근 보너스, 일일 미션을 학습형으로 연출
- 네트워크 의존 없이 즉시 실행 가능한 단일 루프 게임 경험 제공

## 핵심 기능
- 경제 이벤트 발생 → 투자 옵션 선택 → 결과 처리 → 피드백 흐름
- 상태 머신 기반 게임 상태 관리 (`IDLE/READY/CHOICE/SIMULATE/RESULT/POST_REVIEW/IDLE`)
- 오프라인 저장/복구(현재 파일 기반 저장소 기본, 향후 Hive/SQLite 마이그레이션 고려)
- 라운드 소요시간 추적, 결과 이벤트 트래킹 훅, 기본 QA 체크리스트

## 프로젝트 구조
- `lib/domain/`: 게임 규칙, 모델, 엔진 인터페이스
- `lib/domain/services/`: 기본 투자 엔진 구현
- `lib/data/`: 세션 저장소 인터페이스 및 구현
- `lib/state/`: Riverpod 기반 상태 결합
- `lib/presentation/`: 게임 화면
- `test/`: 도메인/위젯/상태 안정성 테스트
- `PLAN.md` / `TASK.md`: 실행 계획 및 작업 추적
- `QA_RESULTS.md` / `QA_CHECKLIST.md`: 검증 기록
- `HANDOFF.md`: 작업 핸드오프 로그(커밋 제외 대상)

## 실행 요건
- Flutter SDK 필요
- 오프라인 환경에서 기본 동작

## 현재 상태
- MVP 단일 루프 구현 및 저장/복구, 안정성 테스트 골격/보강이 완료된 상태입니다.

- Repository now includes the implementation and governance docs from local workspace sync as baseline on main.
