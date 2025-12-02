---
Feature ID: FEAT-XXX
Version: 1.0.0
Last Updated: YYYY-MM-DD
Status: Active
---

# {FeatureName} Feature

## 개요

**목적**: {이 Feature가 해결하는 문제}

**복잡도**: 낮음/중간/높음

**Service 레이어**: 있음/없음

## 원칙 준수 (Compliance)

이 Feature가 준수하는 아키텍처 원칙:

- [ ] [PRIN-001 단방향 데이터 흐름](../principles/unidirectional-data-flow.md)
- [ ] [PRIN-002 관심사의 분리](../principles/separation-of-concerns.md)
- [ ] [PRIN-003 상태 불변성](../principles/immutable-state.md)
- [ ] [PRIN-004 반응형 프로그래밍](../principles/reactive-programming.md)
- [ ] [PRIN-005 의존성 역전](../principles/dependency-inversion.md)

## 계약 준수 (Contracts)

이 Feature의 각 컴포넌트가 준수하는 계약:

### Reactor
- [ ] [CONT-001 Reactor 계약](../contracts/reactor-contract.md) 모든 항목 준수
- [ ] State가 struct
- [ ] mutate() 메서드가 10줄 이하
- [ ] UI/Database import 없음

### Coordinator
- [ ] [CONT-002 Coordinator 계약](../contracts/coordinator-contract.md) 모든 항목 준수
- [ ] Child Coordinator 생명주기 관리
- [ ] Repository 접근 없음

### Service (있는 경우)
- [ ] [CONT-003 Service 계약](../contracts/service-contract.md) 모든 항목 준수
- [ ] Observable 반환
- [ ] UI 로직 없음

### Repository
- [ ] [CONT-004 Repository 계약](../contracts/repository-contract.md) 모든 항목 준수
- [ ] Protocol 구현
- [ ] CRUD Observable 반환

### View
- [ ] [CONT-005 View 계약](../contracts/view-contract.md) 모든 항목 준수
- [ ] bind(reactor:) 구현
- [ ] 비즈니스 로직 없음

## 아키텍처 결정 (Decisions)

### Service 레이어

**결정**: Service 있음/없음

**이유**:
- {Service가 필요한/불필요한 이유}
- {예: Repository 3개 조합, 복잡한 계산 로직 등}

### 데이터 소스

**사용 Repository**:
- `{Repository1}`: {사용 목적}
- `{Repository2}`: {사용 목적}

**사용 Manager**:
- `{Manager1}`: {사용 목적}

### 네비게이션 패턴

**Child Coordinators**:
- `{SubCoordinator1}`: {역할}
- `{SubCoordinator2}`: {역할}

**Result 타입**:
```swift
enum Result {
    case {result1}
    case {result2}
}
```

## 주요 컴포넌트

### Coordinator

**파일**: `Features/{FeatureName}/Coordinator/{FeatureName}Coordinator.swift`

**책임**:
- {책임 1}
- {책임 2}

### Reactor

**파일**: `Features/{FeatureName}/Reactor/{FeatureName}Reactor.swift`

**주요 Actions** (사용자 의도):
- `.{action1}`: {설명}
- `.{action2}`: {설명}

**주요 State** (UI 데이터):
- `{state1}: {Type}`: {설명}
- `{state2}: {Type}`: {설명}

### Service (있는 경우)

**파일**: `Features/{FeatureName}/Reactor/{FeatureName}Service.swift`

**주요 메서드**:
- `{method1}()`: {설명}
- `{method2}()`: {설명}

### View

**파일**: `Features/{FeatureName}/View/{FeatureName}ViewController.swift`

**주요 UI 컴포넌트**:
- `{component1}`: {설명}
- `{component2}`: {설명}

## 데이터 흐름

### 기본 흐름

```
User Action → ViewController → Reactor.Action
                                    ↓
                            Service (있는 경우)
                                    ↓
                                Repository
                                    ↓
                            Reactor.Mutation
                                    ↓
                            Reactor.State
                                    ↓
                            ViewController (UI Update)
```

### 특수 흐름

{이 Feature만의 특별한 데이터 흐름이 있다면 설명}

예시:
- **{흐름 이름}**: {설명}

## 확장 포인트

### 새 Action 추가 시

1. **원칙 확인**: [PRIN-001 단방향 데이터 흐름](../principles/unidirectional-data-flow.md)
2. **계약 확인**: [CONT-001 Reactor 계약](../contracts/reactor-contract.md)
3. **구현 가이드**: [GUIDE-001 Feature 구현](../guidelines/feature-implementation.md)

**체크리스트**:
- [ ] Action이 사용자 의도를 명확히 표현하는가?
- [ ] State에 필요한 데이터가 포함되어 있는가?
- [ ] mutate()가 10줄 이하인가?

### 새 Repository 추가 시

1. **계약 확인**: [CONT-004 Repository 계약](../contracts/repository-contract.md)
2. Service에서 ServiceFactory를 통해 생성
3. Service 메서드에서 사용

### 새 하위 Feature 추가 시

1. **가이드 참조**: [GUIDE-001 Feature 구현](../guidelines/feature-implementation.md)
2. Coordinator에 `show{SubFeature}()` 메서드 추가
3. 이 문서의 "Child Coordinators" 섹션 업데이트

## 검증 체크리스트

### PR 전 자가 검증

**원칙 준수**:
- [ ] 모든 principles/ 원칙 준수
- [ ] 단방향 데이터 흐름 유지
- [ ] 계층 분리 명확

**계약 준수**:
- [ ] 모든 contracts/ 체크리스트 통과
- [ ] Reactor가 상태 관리만 수행
- [ ] View가 UI만 담당

**코드 품질**:
- [ ] 파일 길이: Reactor < 200줄, ViewController < 300줄
- [ ] mutate() 메서드 < 10줄
- [ ] 테스트 작성 완료

**문서**:
- [ ] 이 문서 업데이트 (새 컴포넌트 추가 시)
- [ ] Action/State 설명 추가

## 관련 문서

**원칙**:
- [PRIN-001](../principles/unidirectional-data-flow.md)
- [PRIN-002](../principles/separation-of-concerns.md)

**계약**:
- [CONT-001](../contracts/reactor-contract.md)
- [CONT-002](../contracts/coordinator-contract.md)

**가이드**:
- [GUIDE-001](../guidelines/feature-implementation.md)
- [GUIDE-002](../guidelines/data-flow-checklist.md)

## 파일 구조

```
Features/{FeatureName}/
├── Coordinator/
│   └── {FeatureName}Coordinator.swift
├── View/
│   ├── {FeatureName}ViewController.swift
│   └── Cells/ (필요 시)
├── Reactor/
│   ├── {FeatureName}Reactor.swift
│   └── {FeatureName}Service.swift (있는 경우)
└── Model/ (Feature 전용 모델이 있는 경우)
    └── {FeatureName}Models.swift
```
