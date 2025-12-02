---
Principle ID: PRIN-001
Version: 1.0.0
Last Updated: 2025-12-02
Status: Active
Related Documents: [PRIN-002, PRIN-003]
---

# 단방향 데이터 흐름 원칙

## 원칙 정의

데이터는 한 방향으로만 흐르며, 역방향 참조를 금지한다.

```
상위 계층 → 하위 계층 (허용)
하위 계층 → 상위 계층 (금지)
```

## 문제 배경 (Why)

### 양방향 데이터 흐름위반 시 발생하는 문제

**1. 순환 의존성 (Circular Dependency)**
```
A → B → C → A
```
- 어느 컴포넌트부터 수정해야 할지 불명확
- 한 컴포넌트 수정이 전체 시스템에 영향
- 테스트 불가능 (순환 참조로 Mock 불가)

**2. 디버깅 어려움**
```
User Action → ? → ? → ? → UI Update
```
- 데이터가 어디서 변경되었는지 추적 불가
- 상태 변화의 원인 파악 어려움
- 버그 재현 어려움

**3. 예측 불가능한 상태 변화**
```
Component A가 B를 변경
Component B가 A를 변경
→ 무한 루프 또는 예측 불가능한 상태
```

### 단방향 흐름특성

**1. 예측 가능성 (Predictability)**
```
User Action → Reactor → Service → Repository → Database
                ↓
            State Update
                ↓
            UI Render
```
- 데이터 흐름이 명확함
- 각 단계를 독립적으로 추적 가능

**2. 테스트 용이성 (Testability)**
```
Mock Repository → Service → Reactor → State
```
- 하위 계층을 Mock으로 교체 가능
- 각 계층을 독립적으로 테스트

**3. 유지보수성 (Maintainability)**
```
변경 영향 범위 = 현재 계층 + 상위 계층
```
- 하위 계층 변경이 상위에 영향 없음
- 인터페이스 유지 시 구현 교체 가능

## 제약조건 (Constraints)

### 1. 계층 간 의존성 방향

**허용**:
```
Presentation → Domain → Data → Infrastructure
```

**금지**:
```
Data → Presentation (X)
Domain → Presentation (X)
```

### 2. 데이터 흐름 방향

**Action (위→아래)**:
```
User Event → ViewController → Reactor → Service → Repository
```

**State (아래→위)**:
```
Repository → Service → Reactor → ViewController → UI
```

### 3. 이벤트 전파 방향

**허용**:
```
Child → Parent (이벤트 발행)
Parent → Child (의존성 주입)
```

**금지**:
```
Parent → Child → Parent (순환)
```

## 코드 검증

### 자동 검증 (CI 가능)

**1. 순환 Import 검사**
```bash
# Swift 파일에서 import 순환 검사
find . -name "*.swift" -exec grep "^import " {} \; | sort | uniq
```

**2. Dependency Graph 검증**
```
Tools: swift-dependency-graph
Check: Graph가 DAG (Directed Acyclic Graph)인가?
```

### 수동 검증 (Code Review)

**체크리스트**:
- [ ] Presentation 계층이 Data 계층을 직접 import하는가? (금지)
- [ ] Repository가 Reactor를 import하는가? (금지)
- [ ] Service가 ViewController를 import하는가? (금지)
- [ ] 하위 계층이 상위 계층 타입을 파라미터로 받는가? (금지)

준수 예시:
```swift
// Reactor → Service → Repository (단방향)
class MyReactor {
    let service: MyService

    func mutate(action: Action) -> Observable<Mutation> {
        return service.loadData()
            .map { .setData($0) }
    }
}
```

위반 예시:
```swift
// Repository → Reactor (역방향)
class MyRepository {
    weak var reactor: MyReactor? // 금지

    func onDataChanged() {
        reactor?.action.onNext(.refresh) // 역방향 호출
    }
}
```

### 위반 시 조치

**시나리오**: Repository가 데이터 변경을 Reactor에 알려야 함

**잘못된 해결책**:
```swift
// Repository가 Reactor 참조 (역방향)
repository.reactor = reactor
```

**올바른 해결책**:
```swift
// Repository가 Observable 반환 (순방향 유지)
repository.observeChanges()
    .subscribe(onNext: { data in
        reactor.action.onNext(.dataChanged(data))
    })
```

## 관련 원칙

- **[PRIN-002](separation-of-concerns.md)**: 계층별 책임 분리
- **[PRIN-003](immutable-state.md)**: 상태 불변성
- **[PRIN-004](reactive-programming.md)**: 반응형 프로그래밍

## 계약

이 원칙을 구현하는 계약:
- **[CONT-001](../contracts/reactor-contract.md)**: Reactor 계약
- **[CONT-002](../contracts/coordinator-contract.md)**: Coordinator 계약
- **[CONT-003](../contracts/service-contract.md)**: Service 계약
