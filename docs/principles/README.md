# Principles (아키텍처 원칙)

이 디렉토리는 Cerchio 프로젝트의 **불변 아키텍처 원칙**을 정의합니다.

## 원칙의 특성

### 불변성 (Immutable)
- 이 원칙들은 기술 스택이나 프레임워크와 무관합니다
- UIKit, SwiftUI, ReactorKit, TCA 등 어떤 기술을 사용하더라도 유효합니다
- 원칙이 변경되는 경우는 극히 드뭅니다

### SSOT (Single Source of Truth)
- 코드는 이 원칙을 구현한 것입니다
- 코드가 원칙을 위반하면 **코드를 수정**해야 합니다
- 원칙을 코드에 맞춰 변경하지 마세요

## 원칙 목록

1. **[unidirectional-data-flow.md](unidirectional-data-flow.md)** - 단방향 데이터 흐름
2. **[separation-of-concerns.md](separation-of-concerns.md)** - 관심사의 분리
3. **[immutable-state.md](immutable-state.md)** - 상태 불변성
4. **[reactive-programming.md](reactive-programming.md)** - 반응형 프로그래밍
5. **[dependency-inversion.md](dependency-inversion.md)** - 의존성 역전

## 원칙 읽는 법

각 원칙 문서는 다음 구조를 따릅니다:

```
1. 원칙 정의 (What)
2. 문제 배경 (Why)
3. 제약조건 (Constraints)
4. 코드 검증 (Validation)
```

## 새 Feature 구현 시

1. 관련 원칙 문서를 먼저 읽으세요
2. `../contracts/` 에서 해당 컴포넌트의 계약을 확인하세요
3. `../guidelines/` 에서 구현 가이드를 따르세요

## 원칙 위반 시

코드 리뷰나 개발 중 원칙 위반을 발견하면:

1. **코드를 원칙에 맞게 수정**합니다
2. 원칙을 변경하지 마세요
3. 원칙 자체가 잘못되었다면 팀 전체 논의가 필요합니다
