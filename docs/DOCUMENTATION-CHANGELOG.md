# Documentation Changelog

이 파일은 Cerchio 프로젝트 문서의 모든 변경사항을 기록합니다.

## [1.0.0] - 2025-12-02

### 완전 재구조화 (Breaking Change)

**변경 사유**: 코드 역참조 문제 해결 및 문서 SSOT 원칙 확립

#### 추가된 문서 구조

**principles/ (아키텍처 원칙)**:
- PRIN-001: unidirectional-data-flow.md - 단방향 데이터 흐름 원칙
- PRIN-002: separation-of-concerns.md - 관심사의 분리 원칙
- PRIN-003: immutable-state.md - 상태 불변성 원칙
- PRIN-004: reactive-programming.md - 반응형 프로그래밍 원칙
- PRIN-005: dependency-inversion.md - 의존성 역전 원칙

**contracts/ (컴포넌트 계약)**:
- CONT-001: reactor-contract.md - Reactor 계약
- CONT-002: coordinator-contract.md - Coordinator 계약
- CONT-003: service-contract.md - Service 계약
- CONT-004: repository-contract.md - Repository 계약
- CONT-005: view-contract.md - View 계약

**guidelines/ (구현 가이드)**:
- GUIDE-001: feature-implementation.md - Feature 구현 가이드
- GUIDE-002: data-flow-checklist.md - 데이터 흐름 체크리스트
- GUIDE-003: state-management-guide.md - State 관리 가이드
- GUIDE-004: testing-strategy.md - 테스트 전략
- GUIDE-005: validation-checklist.md - 검증 체크리스트

#### 제거된 디렉토리

- `docs/architecture/` - principles/와 contracts/로 대체
- `docs/patterns/` - contracts/로 대체
- `docs/guides/` - guidelines/로 대체
- `docs/layers/` - contracts/로 대체
- `docs/quickstart/` - index.md와 guidelines/로 대체

#### 수정된 문서

- `docs/index.md` - 완전 재작성, 새 문서 구조 반영
- `docs/features/_template.md` - 원칙/계약 준수 체크리스트 추가
- `CLAUDE.md` - 문서 SSOT 원칙 명시

#### 문서 철학 변경

**Before**:
```
문서 ← 코드 (문서가 코드를 설명)
"BookDetailService.swift:12-75에서 구현됨"
```

**After**:
```
문서 → 코드 (코드가 문서를 구현)
"단방향 데이터 흐름 원칙을 따라야 함"
"Reactor 계약의 모든 항목을 준수해야 함"
```

#### 주요 변경사항

1. **코드 예시**: 5-10줄 준수/위반 예시만 유지
2. **체크리스트 중심**: 모든 계약에 검증 가능한 체크리스트 포함
3. **프레임워크 독립성**: principles/는 특정 기술 언급 최소화
4. **3계층 구조**: Principles → Contracts → Guidelines
5. **문서 → 코드 의존성**: CLAUDE.md에 명시

#### 마이그레이션 가이드

**새 Feature 구현 시**:
- Old: `docs/guides/adding-new-feature.md` (코드 템플릿)
- New: `docs/guidelines/feature-implementation.md` (체크리스트)

**아키텍처 이해 시**:
- Old: `docs/architecture/*.md` (코드 예시 중심)
- New: `docs/principles/*.md` (원칙 중심)

**컴포넌트 작성 시**:
- Old: 코드 템플릿 복사
- New: `docs/contracts/{component}-contract.md` 체크리스트 확인

#### 영향

**Breaking Changes**:
- 모든 기존 문서 링크 무효화
- 새 문서 구조로 완전 전환

**유지된 부분**:
- `docs/features/` 디렉토리 (템플릿만 수정)
- `docs/DOCUMENTATION-GUIDE.md` (수정됨)
- 코드베이스는 변경 없음

#### 검증

**문서 품질**:
- [x] 모든 문서에 메타데이터 포함
- [x] 코드 예시 10줄 이하
- [x] 코드 파일 참조 없음
- [x] 3계층 구조 일관성 유지

**문서 → 코드 관계**:
- [x] CLAUDE.md에 문서 우선 원칙 명시
- [x] 각 principles/에 코드 검증 섹션 포함
- [x] 각 contracts/에 구현 체크리스트 포함

---

## 버전 관리 규칙

### Version Bump

- **PATCH (X.Y.Z+1)**: 오타 수정, 예시 추가, 링크 수정
- **MINOR (X.Y+1.0)**: 새 섹션/규칙 추가, 내용 대폭 수정
- **MAJOR (X+1.0.0)**: 문서 구조 변경, Breaking Change

### Changelog Entry 형식

```markdown
## [Version] - YYYY-MM-DD

### 카테고리

- **DOC-ID** (파일명)
  - [TYPE] 변경 내용
  - Reason: 이유
  - Impact: 영향
  - Migration: 마이그레이션 방법 (Breaking Change 시)
```

### 카테고리

- **Added**: 새 문서 추가
- **Changed**: 기존 문서 수정
- **Deprecated**: 문서 폐기 예정
- **Removed**: 문서 삭제
- **Fixed**: 오류 수정

