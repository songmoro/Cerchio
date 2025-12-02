# Cerchio Documentation

## 문서 철학

### 문서가 SSOT (Single Source of Truth)

이 프로젝트에서 **문서는 코드보다 우선**합니다.

```
문서 (원칙/계약) → 코드 (구현)
```

- 코드는 문서에 정의된 원칙과 계약을 구현한 것입니다
- 코드가 원칙을 위반하면 **코드를 수정**해야 합니다
- 문서를 코드에 맞춰 변경하지 마세요

### 3계층 문서 구조

```
1. Principles (원칙) - 불변, 프레임워크 무관
   ↓
2. Contracts (계약) - 준불변, 검증 가능
   ↓
3. Guidelines (가이드) - 가변, 체크리스트
```

---

## 빠른 시작

### 처음 프로젝트를 접한다면

1. 이 문서를 끝까지 읽으세요 (5분)
2. [principles/README.md](principles/README.md) - 아키텍처 원칙 개요
3. 아래 "상황별 문서 결정 트리"에서 작업에 맞는 경로 따라가기

### 새 Feature를 구현한다면

1. [guidelines/feature-implementation.md](guidelines/feature-implementation.md) - 단계별 가이드
2. 필요한 [principles/](principles/) 문서 읽기
3. 해당 [contracts/](contracts/) 체크리스트 확인

### 기존 Feature를 수정한다면

1. [features/{FeatureName}.md](features/) - Feature 문서 찾기
2. 해당 Feature의 원칙 준수 상태 확인
3. 수정 후 계약 체크리스트 검증

---

## 상황별 문서 결정 트리

### 1. 새 Feature 구현

```
새 Feature 구현 필요
  ↓
1단계: guidelines/feature-implementation.md 읽기
  ↓
2단계: 필요에 따라 principles/ 문서 읽기
  - unidirectional-data-flow.md (데이터 흐름 이해 필요 시)
  - separation-of-concerns.md (계층 분리 이해 필요 시)
  ↓
3단계: contracts/ 체크리스트 확인
  - reactor-contract.md (Reactor 작성 시)
  - service-contract.md (Service 작성 시)
  - coordinator-contract.md (Coordinator 작성 시)
  ↓
4단계: features/_template.md 복사하여 Feature 문서 작성
```

**예상 시간**: 처음 20분, 이후 10분

### 2. 기존 Feature 수정

```
기존 Feature 수정 필요
  ↓
1단계: features/{FeatureName}.md 읽기
  ↓
2단계: 해당 컴포넌트 수정
  - Reactor 수정 → contracts/reactor-contract.md 확인
  - Service 수정 → contracts/service-contract.md 확인
  - View 수정 → contracts/view-contract.md 확인
  ↓
3단계: 체크리스트로 검증
  - guidelines/validation-checklist.md
```

**예상 시간**: 5-10분

### 3. 데이터 흐름 디버깅

```
데이터가 예상대로 흐르지 않음
  ↓
1단계: guidelines/data-flow-checklist.md
  - 계층별 체크리스트로 문제 진단
  ↓
2단계: 문제 계층의 계약 확인
  - Reactor 문제 → contracts/reactor-contract.md
  - Service 문제 → contracts/service-contract.md
  - Repository 문제 → contracts/repository-contract.md
  ↓
3단계: 원칙 위반 여부 확인
  - principles/unidirectional-data-flow.md
  - principles/reactive-programming.md
```

**예상 시간**: 10-15분

### 4. 아키텍처 학습

```
아키텍처를 깊이 이해하고 싶음
  ↓
1단계: principles/ 모든 문서 읽기 (순서대로)
  1. unidirectional-data-flow.md
  2. separation-of-concerns.md
  3. immutable-state.md
  4. reactive-programming.md
  5. dependency-inversion.md
  ↓
2단계: contracts/ 모든 문서 읽기
  - 각 컴포넌트의 계약 이해
  ↓
3단계: guidelines/ 실무 가이드 읽기
```

**예상 시간**: 60-90분 (한번만)

---

## 문서 디렉토리

### [principles/](principles/) - 아키텍처 원칙

**특성**: 불변, 프레임워크 무관

**포함**:
- [README.md](principles/README.md) - 원칙 개요
- [unidirectional-data-flow.md](principles/unidirectional-data-flow.md) - 단방향 데이터 흐름
- [separation-of-concerns.md](principles/separation-of-concerns.md) - 관심사의 분리
- [immutable-state.md](principles/immutable-state.md) - 상태 불변성
- [reactive-programming.md](principles/reactive-programming.md) - 반응형 프로그래밍
- [dependency-inversion.md](principles/dependency-inversion.md) - 의존성 역전

**읽어야 할 때**:
- 아키텍처 철학을 이해하고 싶을 때
- "왜 이렇게 하는가?"를 알고 싶을 때
- 프레임워크 교체를 고려할 때 (UIKit→SwiftUI, ReactorKit→TCA)

### [contracts/](contracts/) - 컴포넌트 계약

**특성**: 준불변, 검증 가능 체크리스트

**포함**:
- [README.md](contracts/README.md) - 계약 개요
- [reactor-contract.md](contracts/reactor-contract.md) - Reactor 계약
- [coordinator-contract.md](contracts/coordinator-contract.md) - Coordinator 계약
- [service-contract.md](contracts/service-contract.md) - Service 계약
- [repository-contract.md](contracts/repository-contract.md) - Repository 계약
- [view-contract.md](contracts/view-contract.md) - View 계약

**읽어야 할 때**:
- 새 컴포넌트를 작성할 때
- Code Review 시 검증할 때
- 계약 위반을 의심할 때

### [guidelines/](guidelines/) - 구현 가이드

**특성**: 가변, 실무 체크리스트

**포함**:
- [README.md](guidelines/README.md) - 가이드 개요
- [feature-implementation.md](guidelines/feature-implementation.md) - Feature 구현 가이드
- [data-flow-checklist.md](guidelines/data-flow-checklist.md) - 데이터 흐름 체크리스트
- [state-management-guide.md](guidelines/state-management-guide.md) - State 관리 가이드
- [testing-strategy.md](guidelines/testing-strategy.md) - 테스트 전략
- [validation-checklist.md](guidelines/validation-checklist.md) - 검증 체크리스트

**읽어야 할 때**:
- 실제로 코드를 작성할 때
- 단계별 가이드가 필요할 때
- 의사결정이 필요할 때 (Service 필요 여부 등)

### [features/](features/) - Feature 문서

**특성**: Feature별 아키텍처 문서

**포함**:
- [_template.md](features/_template.md) - Feature 문서 템플릿
- 각 Feature별 문서 (BookDetail.md 등)

**읽어야 할 때**:
- 특정 Feature를 수정할 때
- Feature의 아키텍처를 이해하고 싶을 때

---

## 문서 작성 규칙

### 새 문서 작성 시

1. 적절한 디렉토리 선택:
   - **principles/**: 프레임워크 무관한 원칙
   - **contracts/**: 컴포넌트별 계약
   - **guidelines/**: 실무 가이드

2. 메타데이터 포함:
   ```markdown
   ---
   Document ID: PRIN-XXX / CONT-XXX / GUIDE-XXX
   Version: 1.0.0
   Last Updated: YYYY-MM-DD
   Status: Active
   Related Documents: [...]
   ---
   ```

3. 코드 예시 제한:
   - 5-10줄 이하로 제한
   - 준수/위반 예시 위주
   - 전체 파일 복사 금지
   - "파일명:라인번호" 참조 금지

### 문서 수정 시

1. Version 증가:
   - PATCH: 오타 수정, 예시 추가
   - MINOR: 새 섹션 추가, 내용 대폭 수정
   - MAJOR: 구조 변경, Breaking Change

2. Last Updated 갱신

3. DOCUMENTATION-CHANGELOG.md에 기록

---

## 검증 방법

### 원칙 준수 검증

**자동화 가능**:
```bash
# 순환 import 검사
find Features -name "*.swift" -exec grep "^import " {} \; | sort | uniq

# 계약 위반 검사 (예: Reactor에 UIKit import)
grep "import UIKit" Features/*/Reactor/*.swift
```

**수동 검증**:
- Code Review 시 해당 계약 체크리스트 사용
- PR 전 [guidelines/validation-checklist.md](guidelines/validation-checklist.md) 확인

### 문서 품질 검증

- [ ] 메타데이터가 있는가?
- [ ] 코드 예시가 10줄 이하인가?
- [ ] 파일 경로 참조가 없는가?
- [ ] Related Documents가 정확한가?

---

## 자주 묻는 질문

**Q: 원칙과 계약의 차이는?**

A:
- **원칙**: 프레임워크 무관, "왜"에 집중 (예: 단방향 흐름)
- **계약**: 컴포넌트별, "무엇"에 집중 (예: Reactor는 상태 관리만)

**Q: 코드와 문서가 충돌하면?**

A:
1. 문서가 맞다면 → 코드 수정
2. 문서가 틀렸다면 → 팀 논의 후 문서 수정

**Q: 새 패턴을 도입하려면?**

A:
1. principles/에 새 원칙 문서 추가
2. contracts/에 새 계약 문서 추가 (필요 시)
3. guidelines/에 구현 가이드 추가
4. 이 index.md 업데이트

**Q: 문서 없이 코드만 보면 안되나?**

A: 코드는 "어떻게(How)"만 알려줍니다. 문서는 "왜(Why)"와 "무엇(What)"을 알려줍니다. 문서 없이는 다음을 알 수 없습니다:
- 왜 이런 구조인가?
- 어떤 제약이 있는가?
- 어떻게 확장하는가?

---

## 관련 문서

- [CLAUDE.md](../CLAUDE.md) - AI 코드 작성 가이드
- [DOCUMENTATION-CHANGELOG.md](DOCUMENTATION-CHANGELOG.md) - 문서 변경 이력
- [DOCUMENTATION-GUIDE.md](DOCUMENTATION-GUIDE.md) - 문서 작성 가이드

---

## 문서 통계

**총 문서 수**: 23개
- principles/: 6개 (README + 5개 원칙)
- contracts/: 6개 (README + 5개 계약)
- guidelines/: 6개 (README + 5개 가이드)
- features/: 1개 (템플릿)
- 기타: 4개 (index, CHANGELOG, GUIDE, CLAUDE.md 링크)

**마지막 업데이트**: 2025-12-02
**문서 버전**: 1.0.0
