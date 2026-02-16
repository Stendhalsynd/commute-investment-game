# Commuter Investment Game TASK

| ID | 작업명 | 오너 | 우선순위 | 상태 | 선행조건 | 산출물 | 다음 액션 | 블로커 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T1 | SPEC 해석본 정리 및 Scope 확정 | PM/Spec | P0 | DONE | 없음 | PLAN.md 업데이트 | 다음 작업 정합성 검토 | 없음 |
| T2 | 공통 도메인 모델 및 상태머신 구현 | Domain | P0 | DONE | 없음 | lib/domain/models/*, lib/domain/state/game_flow_state.dart | T4, T7로 전달 | T1 |
| T3 | IInvestmentEngine 인터페이스 및 기본 구현 골격 작성 | Domain | P0 | DONE | T2 | lib/domain/interfaces/investment_engine.dart, lib/domain/services/investment_engine.dart | T4 | T2 |
| T4 | 게임 라운드 이벤트/결과 계산 로직 작성 | Domain | P0 | DONE | T3 | lib/domain/services/investment_engine.dart | UI/QA 전달 | T3 |
| T5 | 세션 저장소 인터페이스 및 임시/영구 저장 구현 | Domain | P0 | DONE | T2 | lib/data/interfaces/session_repository.dart, lib/data/repositories/*.dart | T7,T10 | T2 |
| T6 | 분석 트래킹 인터페이스 구현 | Domain | P1 | DONE | T2 | lib/analytics/interfaces/analytics_sink.dart | QA 연동 지표 수집 | T2 |
| T7 | Riverpod 게임 상태 관리자 연동 | Client | P0 | DONE | T3,T4,T5 | lib/state/*.dart | UI 렌더링 파이프라인 시작 | T3,T4,T5 |
| T8 | MVP 화면 1회 라운드 루프 UI 구현 | Client | P0 | DONE | T7 | lib/presentation/*.dart | 일일미션/보상 노출 추가 | T7 |
| T9 | 일일 미션/XP/연속 출근 보너스 UI | Client | P1 | DONE | T8 | lib/presentation/*.dart | 보상 규칙 반영 | T8 |
| T10 | 저장/복구 수동 시나리오 검증 | QA | P0 | DONE | T5,T7 | QA 체크리스트, test/domain/*, test/data/session_repository_test.dart | T12으로 인수 조건 전달 | 없음 |
| T11 | 라운드 핵심 경로 통합 테스트 | QA | P0 | DONE | T4,T8 | test/domain/*, test/widget/* | 기능 합격 판정 | T4,T8 |
| T12 | 성능/안정성 기본 점검 (기능 우선 범위) | QA | P1 | DONE | T11 | QA 체크리스트, test/state/game_notifier_stability_test.dart | QA 보고 | 없음 |
| T13 | 웹 포트포워딩 검증 가이드 문서화 | Spec | P1 | DONE | T1 | SPEC.md | T14 | 없음 |
| T14 | 웹 실행/포워딩 체크리스트 정합성 업데이트 | QA | P1 | DONE | T13 | QA_CHECKLIST.md, TASK.md | T15 | T13 |
| T15 | Termius/Tailscale 포트포워딩 규칙 실행 규격 정리 | QA | P1 | DONE | T14 | SPEC.md, TASK.md | T16 | T14 |
| T16 | 모바일 브라우저 원격 웹 검증 수행 | QA | P1 | IN_PROGRESS | T15 | QA_RESULTS.md, QA_CHECKLIST.md | 다음 릴리스 계획 반영 | T15 |
| T17 | pubspec.yaml 생성 및 웹 플랫폼 활성화 | Client | P0 | DONE | T1 | pubspec.yaml, web/ | T18 | 없음 |
| T18 | 웹 검증 시 발견 버그 5건 수정 | Domain/Client | P0 | DONE | T17 | lib/domain/services/*, lib/state/*, test/** | T19 | T17 |
| T19 | 웹 브라우저 게임 흐름 검증 (DAY 전환 포함) | QA | P0 | DONE | T18 | QA_RESULTS.md | T16 완료 조건 연결 | T18 |

## 진행 규칙
- 상태 갱신은 단계 종료 시점 또는 블로커 발생 시 즉시 반영한다.
- 블로커는 반드시 `블로커` 칼럼에 선행 작업 ID로 기입한다.
- 완료 조건: 해당 산출물이 생성/수정되었고, 의존 과업의 진입 조건이 충족된 경우.
