# Guidelines

실무 중심의 개발 가이드라인과 체크리스트를 제공합니다.

## 📋 가이드 목록

### [Feature 구현 가이드](feature-implementation.md)
- 새 Feature 추가 시 단계별 체크리스트
- Service 필요 여부 판단 의사결정 트리
- Principles 및 Contracts 통합 참조

### [데이터 흐름 체크리스트](data-flow-checklist.md)
- 데이터 흐름 검증 체크리스트
- 계층별 디버깅 방법
- 일반적인 문제 해결법

### [State 관리 가이드](state-management-guide.md)
- State 설계 원칙
- Derived State vs Stored State
- State 최적화 기법

### [테스팅 전략](testing-strategy.md)
- 계층별 테스트 전략
- Mock 객체 생성 방법
- 테스트 가능한 코드 작성법

### [검증 체크리스트](validation-checklist.md)
- PR 전 자가 검증 체크리스트
- Code Review 포인트
- 자동화 스크립트 활용법

## 📖 사용 방법

1. **새 Feature 개발 시**
   - [Feature 구현 가이드](feature-implementation.md)부터 시작
   - 각 단계별 체크리스트 확인
   - 관련 Contracts 및 Principles 참조

2. **버그 디버깅 시**
   - [데이터 흐름 체크리스트](data-flow-checklist.md) 활용
   - 계층별 문제 원인 파악
   - 디버깅 도구 활용

3. **PR 생성 전**
   - [검증 체크리스트](validation-checklist.md) 실행
   - 모든 항목 통과 확인
   - Code Review 준비

## 🔗 관련 문서

- [Principles](../principles/) - 아키텍처 원칙
- [Contracts](../contracts/) - 계층별 계약
- [Architecture](../architecture/) - 상세 아키텍처 문서
