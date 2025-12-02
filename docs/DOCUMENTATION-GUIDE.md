---
Document ID: DOC-META-002
Version: 1.0.0
Last Updated: 2025-12-01
Status: Active
Related Documents: [DOC-META-001]
---

# Documentation Management Guide

## 1. Overview

이 가이드는 Cerchio 프로젝트 문서를 수정하거나 새로 작성할 때 따라야 할 프로세스를 설명합니다.

**Quick Reference**: 변경사항은 반드시 `DOCUMENTATION-CHANGELOG.md` (DOC-META-001)에 기록하세요.

---

## 2. Before Making Changes

### 2.1 Check Current Documentation Status

**Reference**: DOC-META-GUIDE-001

```bash
# 1. 변경하려는 문서의 메타데이터 확인
head -10 docs/architecture/data-flow.md

# 2. 현재 Version 확인
# Version: X.Y.Z

# 3. Related Documents 확인
# 영향 받는 문서들을 미리 파악
```

### 2.2 Determine Change Type

**Reference**: DOC-META-GUIDE-002

| 변경 유형 | Version Bump | 예시 |
|-----------|--------------|------|
| PATCH | Z+1 | 오타 수정, 예시 추가, 링크 수정 |
| MINOR | Y+1, Z=0 | 새 규칙/섹션 추가, 내용 대폭 수정 |
| MAJOR | X+1, Y=0, Z=0 | 문서 구조 변경, Breaking Change |
| NEW | 1.0.0 | 새 문서 생성 |

---

## 3. Making Changes

### 3.1 Standard Update Process

**Reference**: DOC-META-GUIDE-003

```bash
# Step 1: 문서 수정
vim docs/path/to/document.md

# Step 2: 메타데이터 업데이트
# - Version 증가
# - Last Updated 날짜 변경
# - Related Documents 확인 및 업데이트 (필요 시)

# Step 3: 변경사항 기록
vim docs/DOCUMENTATION-CHANGELOG.md
# 새 entry 추가 (Section 4 참조)

# Step 4: Cross-references 확인
# - docs/index.md 업데이트 필요한지 확인
# - Related Documents에 나열된 문서들 확인
```

### 3.2 Creating New Document

**Reference**: DOC-META-GUIDE-004

```bash
# Step 1: 적절한 디렉토리 선택
# quickstart/ | architecture/ | layers/ | patterns/ | guides/ | features/ | reference/

# Step 2: Document ID 할당
# 규칙: DOC-{CATEGORY}-{NUMBER}
# 예: DOC-PATTERN-005 (다음 사용 가능한 번호)

# Step 3: 템플릿 사용
cp docs/features/_template.md docs/patterns/new-pattern.md

# Step 4: 메타데이터 작성
---
Document ID: DOC-PATTERN-005
Version: 1.0.0
Last Updated: 2025-12-01
Status: Active
Related Documents: []
---

# Step 5: 내용 작성
# - TL;DR 섹션 필수
# - ISO 스타일 넘버링 (1, 1.1, 1.2 등)
# - 각 규칙/패턴에 Reference 번호 부여

# Step 6: index.md에 등록
vim docs/index.md
# Section 3의 해당 카테고리에 추가

# Step 7: CHANGELOG 업데이트
vim docs/DOCUMENTATION-CHANGELOG.md
```

---

## 4. Changelog Entry Format

### 4.1 Template

**Reference**: DOC-META-GUIDE-005

```markdown
## [Version] - YYYY-MM-DD

### [Change Type] Documents

- **DOC-XXX-YYY** (document-name.md)
  - [TYPE] Brief description of change
  - Reason: 변경 이유 설명
  - Impact: 영향 받는 다른 문서/코드
  - (Breaking Change인 경우) Migration: 마이그레이션 방법
```

### 4.2 Examples

#### Example 1: Patch Update

```markdown
## [1.0.1] - 2025-12-02

### Changed Documents

- **DOC-ARCH-002** (architecture/data-flow.md)
  - [PATCH] Fixed typo in Section 3.2 "mutate()" → "mutate()"
  - [PATCH] Added code example for error handling in Section 5.2
  - Reason: 명확성 개선 및 사용자 피드백 반영
  - Impact: None
```

#### Example 2: Minor Update (New Rule)

```markdown
## [1.1.0] - 2025-12-02

### Changed Documents

- **DOC-GUIDE-101** (guides/adding-new-feature.md)
  - [MINOR] Added Section 9: "Testing with async/await"
  - [MINOR] New rule DOC-GUIDE-101-R9: Async Repository testing pattern
  - Reason: Swift Concurrency 사용 증가로 테스트 가이드 필요
  - Impact:
    - 새 Feature 구현 시 Section 9 참조 가능
    - DOC-ARCH-002에 async/await 예시 추가 예정
```

#### Example 3: Major Update (Breaking Change)

```markdown
## [2.0.0] - 2025-12-02

### Changed Documents

- **DOC-PATTERN-002** (patterns/service-layer.md)
  - [MAJOR] **BREAKING CHANGE**: Service initialization 패턴 변경
  - [MAJOR] Old rule DOC-PATTERN-002-R3 deprecated → 새 규칙 DOC-PATTERN-002-R10
  - Reason: ServiceFactory API 변경 (v2.0.0)
  - Impact:
    - 기존 코드: 계속 동작하지만 deprecated warning
    - 새 코드: 새 패턴 사용 필수
    - 영향 받는 문서: DOC-GUIDE-101, DOC-FEAT-003
  - Migration:
    1. Old: `ServiceFactory.shared.createService()`
    2. New: `serviceFactory.createService(for: context)`
    3. Migration guide in Section 10.1
  - Deprecation Period: 2025-12-02 ~ 2025-12-16 (2 weeks)
```

#### Example 4: New Document

```markdown
## [1.2.0] - 2025-12-02

### NEW Documents

- **DOC-PATTERN-005** (patterns/error-handling.md)
  - [NEW] Error handling best practices documentation
  - Reason: 에러 처리 패턴 표준화 필요
  - Impact:
    - DOC-GUIDE-101 Section 4에 에러 처리 참조 추가
    - DOC-ARCH-002에 에러 흐름 다이어그램 추가 예정
```

---

## 5. Special Cases

### 5.1 Breaking Changes

**Reference**: DOC-META-GUIDE-006

Breaking Change 발생 시 반드시 다음을 포함하세요:

1. **BREAKING CHANGE 태그** (굵게 표시)
2. **Old Rule Reference** (deprecated 표시)
3. **New Rule Reference**
4. **Migration Guide** (마이그레이션 방법 상세 설명)
5. **Deprecation Period** (최소 1주일)
6. **영향 받는 모든 문서 리스트**

### 5.2 Deprecating Documents

**Reference**: DOC-META-GUIDE-007

문서를 폐기할 때:

```markdown
---
Document ID: DOC-PATTERN-OLD
Version: 1.5.0
Last Updated: 2025-12-02
Status: Deprecated
Deprecated Date: 2025-12-02
Replacement: DOC-PATTERN-NEW
Related Documents: [DOC-PATTERN-NEW]
---

# Old Pattern (DEPRECATED)

## DEPRECATION NOTICE

**Status**: DEPRECATED as of 2025-12-02

**Reason**: 새로운 접근 방식으로 대체됨

**Replacement**: [New Pattern](../patterns/new-pattern.md) (DOC-PATTERN-NEW)

**Migration Guide**: [Migration Guide](../patterns/new-pattern.md#migration-from-old-pattern)

---

(기존 내용은 참고용으로 유지)
```

### 5.3 Cross-Document Updates

**Reference**: DOC-META-GUIDE-008

한 문서를 변경할 때 확인해야 할 곳:

```bash
# 1. docs/index.md
# - Section 2: Decision Tree (경로/규칙 변경 시)
# - Section 3: Documentation Map (설명 업데이트)

# 2. Related Documents (메타데이터에 나열된 문서들)
# - 해당 문서들의 "관련 문서" 섹션 확인

# 3. CLAUDE.md (주요 변경사항인 경우)
# - 상단 빠른 링크 업데이트

# 4. Grep으로 참조 검색
grep -r "DOC-XXX-YYY" docs/
# 해당 문서를 참조하는 모든 곳 확인
```

---

## 6. Quality Checklist

### 6.1 Before Committing

**Reference**: DOC-META-GUIDE-009

- [ ] 메타데이터 업데이트됨 (Version, Last Updated)
- [ ] CHANGELOG에 entry 추가됨
- [ ] ISO 스타일 넘버링 일관성 유지
- [ ] 새 규칙에 Reference 번호 부여됨
- [ ] 이모지/이모티콘 없음
- [ ] 코드 예시 검증됨 (컴파일 가능)
- [ ] 링크 확인됨 (모든 링크 유효)
- [ ] Related Documents 업데이트됨
- [ ] index.md 확인 및 업데이트 (필요 시)
- [ ] Breaking Change인 경우 Migration Guide 작성됨

---

## 7. Document ID Allocation

### 7.1 Category Prefixes

**Reference**: DOC-META-GUIDE-010

| Prefix | Category | Number Range |
|--------|----------|--------------|
| DOC-QS | Quickstart | 001-099 |
| DOC-ARCH | Architecture | 001-099 |
| DOC-LAYER | Layers | 001-099 |
| DOC-PATTERN | Patterns | 001-099 |
| DOC-GUIDE | Guides | 101-199 |
| DOC-FEAT | Features | 001-999 |
| DOC-REF | Reference | 001-099 |
| DOC-META | Meta (문서 관리) | 001-099 |

### 7.2 Finding Next Available ID

```bash
# 예: 다음 Pattern 문서 ID 찾기
grep -r "DOC-PATTERN-" docs/ | grep "Document ID:" | sort

# 출력:
# DOC-PATTERN-001
# DOC-PATTERN-002
# DOC-PATTERN-003
# DOC-PATTERN-004

# → 다음 사용 가능: DOC-PATTERN-005
```

---

## 8. Common Mistakes to Avoid

### 8.1 Mistakes

**Reference**: DOC-META-GUIDE-011

1. **메타데이터 미업데이트**
   - ❌ Version 그대로 두기
   - ✅ 변경사항에 맞게 Version 증가

2. **CHANGELOG 누락**
   - ❌ 문서만 수정하고 CHANGELOG 안씀
   - ✅ 모든 변경사항 CHANGELOG에 기록

3. **Reference 번호 중복**
   - ❌ 같은 번호 재사용
   - ✅ 새 규칙은 항상 새 번호

4. **Breaking Change 표시 안함**
   - ❌ 중요한 변경인데 표시 없음
   - ✅ BREAKING CHANGE 명시 + Migration Guide

5. **Cross-reference 미업데이트**
   - ❌ 관련 문서 업데이트 안함
   - ✅ Related Documents 모두 확인

---

## 9. Quick Commands

### 9.1 Useful Commands

**Reference**: DOC-META-GUIDE-012

```bash
# 전체 문서 목록
find docs -name "*.md" | sort

# 특정 Document ID 찾기
grep -r "DOC-ARCH-002" docs/

# 모든 Version 확인
grep -r "^Version:" docs/ | sort

# 최근 업데이트된 문서
grep -r "^Last Updated:" docs/ | sort -k3 -r | head -10

# CHANGELOG 최신 entry 보기
head -50 docs/DOCUMENTATION-CHANGELOG.md

# Deprecated 문서 찾기
grep -r "Status: Deprecated" docs/
```

---

## 10. Related Documents

- **DOC-META-001**: [DOCUMENTATION-CHANGELOG.md](DOCUMENTATION-CHANGELOG.md) - 변경 이력
- **DOC-INDEX**: [index.md](index.md) - 문서 허브
