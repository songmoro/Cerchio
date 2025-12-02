---
Guide ID: GUIDE-005
Version: 1.0.0
Last Updated: 2025-12-02
Related Contracts: [CONT-001, CONT-002, CONT-003, CONT-004, CONT-005]
---

# 검증 체크리스트

Pull Request 생성 전 자가 검증을 위한 체크리스트입니다.

## 1. 빌드 검증

### 컴파일

- [ ] 프로젝트가 빌드되는가?
- [ ] 컴파일 에러가 없는가?
- [ ] 컴파일 경고(Warning)가 없는가?

**자동 검증**:
```bash
# 빌드 체크
xcodebuild -scheme Cerchio -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' \
  build -configuration Debug -skipPackagePluginValidation -quiet 2>&1 | grep -E "error:"
```

### 의존성

- [ ] Swift Package Manager 의존성이 정상인가?
- [ ] Package.resolved가 최신 상태인가?

## 2. Contract 준수 검증

### Reactor ([CONT-001](../contracts/reactor-contract.md))

- [ ] `import UIKit`이 없는가?
- [ ] `import RealmSwift`가 없는가?
- [ ] Action, Mutation, State를 정의했는가?
- [ ] mutate()가 10줄 이하인가?
- [ ] reduce()가 순수 함수인가?
- [ ] State가 struct인가?

**자동 검증**:
```bash
# UIKit import 검증
grep -r "import UIKit" Features/*/Reactor/*Reactor.swift

# RealmSwift import 검증
grep -r "import RealmSwift" Features/*/Reactor/*Reactor.swift

# State struct 검증
grep "struct State" Features/*/Reactor/*Reactor.swift
```

### Coordinator ([CONT-002](../contracts/coordinator-contract.md))

- [ ] BaseCoordinator를 상속하는가?
- [ ] start() 메서드를 구현했는가?
- [ ] Repository를 직접 참조하지 않는가?
- [ ] 비즈니스 로직이 없는가?

**자동 검증**:
```bash
# RealmSwift import 검증
grep -r "import RealmSwift" Features/*/Coordinator/*Coordinator.swift

# start() 메서드 검증
grep "func start()" Features/*/Coordinator/*Coordinator.swift
```

### Service ([CONT-003](../contracts/service-contract.md))

- [ ] Protocol을 정의했는가?
- [ ] Observable을 반환하는가?
- [ ] ServiceFactory를 저장하지 않는가?
- [ ] `import UIKit`이 없는가?

**자동 검증**:
```bash
# UIKit import 검증
grep -r "import UIKit" Features/*/Reactor/*Service.swift

# Protocol 정의 검증
grep "protocol.*ServiceProtocol" Features/*/Reactor/*Service.swift
```

### Repository ([CONT-004](../contracts/repository-contract.md))

- [ ] BaseRepository를 상속하는가?
- [ ] Protocol을 정의했는가?
- [ ] Observable을 반환하는가?
- [ ] 비즈니스 로직이 없는가?

**자동 검증**:
```bash
# BaseRepository 상속 검증
grep "BaseRepository" Data/Repositories/*Repository.swift

# Protocol 정의 검증
grep "protocol.*RepositoryProtocol" Data/Repositories/*Repository.swift
```

### View ([CONT-005](../contracts/view-contract.md))

- [ ] BaseViewController를 상속하는가?
- [ ] setupUI()를 구현했는가?
- [ ] bind(reactor:)를 구현했는가?
- [ ] Driver를 사용하는가?
- [ ] `import RealmSwift`가 없는가?

**자동 검증**:
```bash
# RealmSwift import 검증
grep -r "import RealmSwift" Features/*/View/*ViewController.swift

# BaseViewController 상속 검증
grep "BaseViewController" Features/*/View/*ViewController.swift

# bind(reactor:) 검증
grep "func bind(reactor:" Features/*/View/*ViewController.swift
```

## 3. 코드 품질 검증

### 스타일

- [ ] SnapKit을 사용하는가? (NSLayoutConstraint 직접 사용 금지)
- [ ] Custom Font를 사용하는가? (`.systemFont()` 금지)
- [ ] Localized String을 사용하는가?
- [ ] 하드코딩된 문자열이 없는가?

**자동 검증**:
```bash
# NSLayoutConstraint 직접 사용 검증
grep -r "NSLayoutConstraint.activate" Features/

# systemFont 사용 검증
grep -r "\.systemFont" Features/

# 하드코딩 문자열 검증 (수동)
grep -r '"[가-힣]' Features/ --exclude="*.strings"
```

### 메모리 관리

- [ ] `[weak self]`를 사용하는가?
- [ ] `.disposed(by: disposeBag)`을 호출하는가?
- [ ] Coordinator가 제대로 해제되는가?
- [ ] Callback을 nil로 정리하는가?

**수동 검증**:
- Instruments Leaks 실행
- Dealloc 로그 확인

### 파일 크기

- [ ] Reactor 파일이 200줄 이하인가?
- [ ] ViewController 파일이 300줄 이하인가?
- [ ] Service 파일이 200줄 이하인가?
- [ ] Coordinator 파일이 150줄 이하인가?

**자동 검증**:
```bash
# 파일 길이 검증
find Features -name "*.swift" -exec wc -l {} \; | awk '
  /Reactor.swift/ && $1 > 200 {print "Too long Reactor: " $2}
  /ViewController.swift/ && $1 > 300 {print "Too long ViewController: " $2}
  /Service.swift/ && $1 > 200 {print "Too long Service: " $2}
  /Coordinator.swift/ && $1 > 150 {print "Too long Coordinator: " $2}
'
```

## 4. 기능 테스트

### 기본 동작

- [ ] 화면 진입이 정상적인가?
- [ ] 데이터 로딩이 동작하는가?
- [ ] 사용자 상호작용이 동작하는가?
- [ ] 네비게이션이 동작하는가?

### 에지 케이스

- [ ] 빈 데이터 상태가 처리되는가?
- [ ] 에러 상태가 처리되는가?
- [ ] 로딩 상태가 표시되는가?
- [ ] 네트워크 에러가 처리되는가? (API 사용 시)

### UI/UX

- [ ] 로딩 인디케이터가 표시되는가?
- [ ] Empty State가 표시되는가?
- [ ] Error Alert가 표시되는가?
- [ ] Haptic Feedback이 동작하는가?

## 5. 데이터 흐름 검증

### View → Reactor

- [ ] Action이 발행되는가?
- [ ] bind(to:)가 올바르게 동작하는가?

### Reactor → Service → Repository

- [ ] mutate()가 호출되는가?
- [ ] Service가 호출되는가?
- [ ] Repository가 호출되는가?
- [ ] Observable 체이닝이 올바른가?

### Repository → Service → Reactor → View

- [ ] 데이터가 반환되는가?
- [ ] DTO 변환이 동작하는가?
- [ ] Mutation이 발행되는가?
- [ ] State가 변경되는가?
- [ ] UI가 업데이트되는가?

**디버깅 도구**:
- [데이터 흐름 체크리스트](data-flow-checklist.md) 참조

## 6. 문서화 검증

### 코드 주석

- [ ] 복잡한 로직에 주석이 있는가?
- [ ] Public API에 문서 주석이 있는가?
- [ ] MARK 주석으로 섹션이 구분되어 있는가?

### Localization

- [ ] 모든 사용자 대면 문자열이 Localized인가?
- [ ] Localizable.xcstrings에 추가했는가?
- [ ] Localized enum에 추가했는가?

## 7. Git 검증

### Commit

- [ ] Commit 메시지가 명확한가?
- [ ] 하나의 Commit = 하나의 논리적 변경인가?
- [ ] 불필요한 파일이 포함되지 않았는가?

### Branch

- [ ] 올바른 브랜치에서 작업했는가?
- [ ] 최신 Development 브랜치를 merge했는가?
- [ ] Conflict가 해결되었는가?

## 8. PR 체크리스트

### 설명

- [ ] PR 제목이 명확한가?
- [ ] 변경 내용을 설명했는가?
- [ ] 스크린샷을 첨부했는가? (UI 변경 시)
- [ ] 테스트 계획을 작성했는가?

### 리뷰 준비

- [ ] Self-review를 완료했는가?
- [ ] 불필요한 코드가 제거되었는가?
- [ ] Debug 코드가 제거되었는가? (print문 등)
- [ ] TODO 주석을 정리했는가?

## 자동화 스크립트

### 전체 검증 스크립트

```bash
#!/bin/bash

echo "🔍 Starting validation..."

# 1. 컴파일 검증
echo "\n📦 Build check..."
xcodebuild -scheme Cerchio -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' \
  build -configuration Debug -skipPackagePluginValidation -quiet 2>&1 | grep -E "error:"

if [ $? -eq 0 ]; then
  echo "❌ Build failed"
  exit 1
else
  echo "✅ Build succeeded"
fi

# 2. UIKit import 검증
echo "\n🔍 Checking UIKit imports in Reactor..."
if grep -r "import UIKit" Features/*/Reactor/*Reactor.swift > /dev/null; then
  echo "❌ Found UIKit import in Reactor"
  grep -r "import UIKit" Features/*/Reactor/*Reactor.swift
  exit 1
else
  echo "✅ No UIKit import in Reactor"
fi

# 3. RealmSwift import 검증
echo "\n🔍 Checking RealmSwift imports..."
if grep -r "import RealmSwift" Features/*/Reactor/*Reactor.swift > /dev/null; then
  echo "❌ Found RealmSwift import in Reactor"
  exit 1
fi

if grep -r "import RealmSwift" Features/*/View/*ViewController.swift > /dev/null; then
  echo "❌ Found RealmSwift import in ViewController"
  exit 1
fi

echo "✅ No RealmSwift import in Reactor/ViewController"

# 4. 파일 크기 검증
echo "\n📏 Checking file sizes..."
find Features -name "*Reactor.swift" -exec wc -l {} \; | awk '$1 > 200 {print "❌ Too long Reactor: " $2; exit 1}'
find Features -name "*ViewController.swift" -exec wc -l {} \; | awk '$1 > 300 {print "❌ Too long ViewController: " $2; exit 1}'

echo "✅ File sizes OK"

echo "\n✅ All validations passed!"
```

**사용법**:
```bash
chmod +x validate.sh
./validate.sh
```

## 빠른 체크리스트

PR 생성 직전에 확인:

```
□ 빌드 성공
□ 컴파일 에러 없음
□ 경고(Warning) 없음
□ Contract 준수 (자동 스크립트 실행)
□ 기능 테스트 완료
□ UI/UX 확인
□ 메모리 누수 없음
□ Localized String 사용
□ 주석 작성 완료
□ Debug 코드 제거
□ Self-review 완료
```

## 관련 문서

**계약**:
- [CONT-001](../contracts/reactor-contract.md) - Reactor 계약
- [CONT-002](../contracts/coordinator-contract.md) - Coordinator 계약
- [CONT-003](../contracts/service-contract.md) - Service 계약
- [CONT-004](../contracts/repository-contract.md) - Repository 계약
- [CONT-005](../contracts/view-contract.md) - View 계약

**가이드**:
- [GUIDE-001](feature-implementation.md) - Feature 구현 가이드
- [GUIDE-002](data-flow-checklist.md) - 데이터 흐름 체크리스트
