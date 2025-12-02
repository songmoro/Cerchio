# Contracts (컴포넌트 계약)

이 디렉토리는 각 컴포넌트가 지켜야 할 **계약(Contract)**을 정의합니다.

## 계약의 특성

### 준불변성 (Semi-Immutable)
- 계약은 아키텍처 원칙을 구체적인 컴포넌트 레벨로 구현합니다
- 프레임워크가 바뀌어도 계약의 본질은 유지됩니다
- 예: ReactorKit → TCA 전환 시, "상태 관리" 계약은 유지되고 구현 방법만 변경

### 검증 가능 (Verifiable)
- 모든 계약은 체크리스트 형태로 검증 가능합니다
- Code Review 시 체크리스트를 사용하여 계약 준수 여부 확인
- CI에서 자동화 가능한 항목도 포함

## 계약 목록

1. **[reactor-contract.md](reactor-contract.md)** - Reactor (상태 관리) 계약
2. **[coordinator-contract.md](coordinator-contract.md)** - Coordinator (네비게이션) 계약
3. **[service-contract.md](service-contract.md)** - Service (비즈니스 로직) 계약
4. **[repository-contract.md](repository-contract.md)** - Repository (데이터 접근) 계약
5. **[view-contract.md](view-contract.md)** - View (UI) 계약

## 계약 읽는 법

각 계약 문서는 다음 구조를 따릅니다:

```
1. 계약 정의
2. 필수 책임 (Must)
3. 금지사항 (Must Not)
4. 구현 체크리스트
5. 코드 검증 방법
```

## 새 컴포넌트 작성 시

1. 해당 컴포넌트의 계약 문서를 읽으세요
2. "구현 체크리스트"를 따르세요
3. 완료 후 체크리스트로 검증하세요

## 계약 위반 시

코드 리뷰에서 계약 위반이 발견되면:

1. **코드를 계약에 맞게 수정**합니다
2. 계약을 변경하지 마세요
3. 계약이 잘못되었다면 팀 전체 논의 후 수정

## 관련 문서

- **../principles/** - 이 계약들이 구현하는 아키텍처 원칙
- **../guidelines/** - 계약을 따르는 실무 구현 가이드
