# Cerchio
> 독서 활동을 기록하고 관리하는 독서 기록 애플리케이션
<br>

## 목차
- [프로젝트 소개](#프로젝트-소개)
- [기술 스택](#기술-스택)
- [아키텍처 및 디자인 패턴](#아키텍처-및-디자인-패턴)
- [주요 화면별 기술 구현](#주요-화면별-기술-구현)
- [메모리 관리 및 성능 최적화](#메모리-관리-및-성능-최적화)
- [프로젝트 구조](#프로젝트-구조)
<br>

## 프로젝트 소개
독서 활동을 체계적으로 기록하고 관리하는 iOS 애플리케이션입니다. 단방향 반응형 아키텍처와 프로토콜 기반 설계를 적용했으며, Live Activity, WidgetKit, SwiftUI Charts 등 최신 iOS 기술을 활용하여 구현했습니다.

### 주요 기능
#### 서재 관리
- 도서 추가 및 상세 정보 관리, 태그 기반 필터링
- 이미지 픽셀 샘플링 기반 Dominant 색상 추출
- 극좌표 계산 기반 동적 컨텍스트 메뉴

#### 도서 검색
- ISBN, 도서명, 작가 키워드 검색
- Offset 기반 페이지네이션과 무한 스크롤
- ISBN 기반 중복 도서 추가 방지

#### 독서 활동
- 타이머 기반 독서 시간 기록 및 통계
- SwiftUI Charts 시계열 데이터 시각화
- 문장/사진 저장, 가우시안 블러 이미지 효과

#### 독서 기록
- SVG 경로 파싱 기반 커스텀 타이머 UI
- Live Activity 실시간 타이머 업데이트 및 Dynamic Island 지원
- App Group + Darwin Notification 기반 앱-위젯 간 상태 동기화
<br>

## 기술 스택
| 분류 | 기술 |
|------|------|
| **아키텍처** | ReactorKit + MVVM-C + Coordinator Pattern |
| **UI** | UIKit (Main), SwiftUI (Charts, Widgets) |
| **반응형 프로그래밍** | RxSwift, RxCocoa |
| **데이터베이스** | RealmSwift |
| **레이아웃** | SnapKit |
| **이미지 처리** | Kingfisher, CoreImage, CoreGraphics |
| **iOS 프레임워크** | WidgetKit, ActivityKit, UserNotifications |
| **의존성 관리** | Swift Package Manager |
| **최소 배포 타겟** | iOS 16.0 |
<br>

## 아키텍처 및 디자인 패턴
### 1. Coordinator 패턴
화면 전환 로직을 ViewController에서 분리하고 부모-자식 계층 구조로 생명주기를 관리합니다.

**파일**: `Cerchio/Common/Base/BaseCoordinator.swift`
**핵심 구현**:
- `childCoordinators` 배열로 부모-자식 관계 설정
- `PublishRelay<NavigationEvent>`를 통한 반응형 네비게이션
- `viewDidDisappear`에서 부모에게 종료 이벤트 전달 → 자식 배열에서 제거 → 자동 메모리 해제
- `Coordinatable` 프로토콜과 Associated Type으로 타입 안전 의존성 주입
<br>

### 2. ReactorKit + MVVM-C
Action → Mutation → State의 단방향 데이터 흐름으로 상태 관리를 구현합니다.

**파일**: `Cerchio/Common/Base/BaseViewController.swift`, `Features/*/Reactor/*.swift`
**핵심 구현**:
- 제네릭 `BaseViewController<T: Reactor>`로 타입 안전 Reactor 바인딩
- Service Layer 분리: Reactor는 상태 관리만, 비즈니스 로직은 Service 클래스로 분리
- `distinctUntilChanged()`로 불필요한 UI 업데이트 방지

```swift
reactor.state
    .map { $0.bookDetail }
    .distinctUntilChanged()
    .asDriver(onErrorJustReturn: nil)
    .compactMap { $0 }
    .drive(onNext: { [weak self] in self?.updateUI(with: $0) })
    .disposed(by: disposeBag)
```
<br>

### 3. Service Factory 패턴
Repository 및 Service 객체 생성을 중앙화하고 환경별 설정을 분리합니다.

**파일**: `Cerchio/Data/Network/Base/ServiceFactory.swift`
**핵심 구현**:
- Concurrent DispatchQueue + barrier flag로 스레드 안전 캐싱
- `EnvironmentType` enum으로 환경 분리 (development, production)
<br>

### 4. Repository & DTO 패턴
class 타입 Realm 객체와 struct 타입 snapshot 사이의 참조 문제를 해결하기 위해 Realm 객체를 불변 DTO로 변환하여 반환합니다.

**파일**: `Cerchio/Common/Base/BaseRepository.swift`, `Cerchio/Data/Models/`

**핵심 구현**:
- 제네릭 `BaseRepository<T: Object>`로 재사용 가능한 Realm 접근 레이어
- `toModel()` / `toRealmModel()` 메서드로 Realm ↔ Domain 변환
- 단일 `realm.write` Transaction으로 cascade 삭제 (Quotes → Photos → Tags → Book)

```swift
// DTO 변환
let books = realmBooks.map { $0.toModel() }  // Realm → DTO
let realmBook = book.toRealmModel()          // DTO → Realm
```
<br>

## 주요 화면별 기술 구현
### 1. 서재 화면
#### Dominant 색상 추출
**파일**: `Cerchio/Common/Utilities/DominantColorExtractor.swift`
- 100×100 다운샘플링 + stride 5 샘플링으로 처리 속도 향상
- RGB 8단계 양자화로 색상 공간 축소 (512개 색상)
- 밝기(<0.1, >0.95) 및 알파(>0.5) 필터링
- Dictionary 빈도 계산으로 대표 색상 도출
- Swift Concurrency `Task.detached`로 백그라운드 처리
- **성능**: 2000ms → 20ms (100배 향상)

```swift
Task {
    let dominantColor = await Task.detached(priority: .userInitiated) {
        DominantColorExtractor.extract(from: image).first ?? .gray
    }.value
    await MainActor.run { self.backgroundView.backgroundColor = dominantColor }
}
```
<br>

#### 다대다 관계 설계
**파일**: `Cerchio/Data/Models/Tag.swift`, `Cerchio/Data/Repositories/TagRepository.swift`
- `RealmTag`의 `bookId` 외래 키로 Book-Tag 다대다 관계 표현
- `filterAndSort("bookId == %@")` 쿼리로 효율적 조회
- `getAllUniqueTagNames()` 메서드로 Set 중복 제거 후 정렬
<br>

#### 극좌표 기반 동적 컨텍스트 메뉴
**파일**: `Cerchio/Common/UI/Components/ContextMenu/`
- 삼각함수 `cos/sin`으로 원형 버튼 배치
- 터치 위치와 화면 사분면 감지로 동적 방향 결정
- 경계 검사로 화면 밖 배치 방지
- `LongPressGestureHandler` + 햅틱 피드백

```swift
func pointOnCircle(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
    return CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
}
```
<br>

### 2. 검색 화면
#### Offset 기반 페이지네이션
**파일**: `Cerchio/Features/Search/Reactor/SearchReactor.swift`
- Offset 계산: `start = (currentPage - 1) * display + 1`
- `scrollViewDidScroll`에서 `offsetY > contentHeight - frameHeight - 100` 감지
- `isLoadingMore` 플래그로 중복 요청 방지
- `hasMore` 플래그로 마지막 페이지 차단
<br>

#### HTTP 에러 핸들링
**파일**: `Cerchio/Data/Network/Services/BookSearchService.swift`
- 상태 코드별 에러 매핑: 400 (incorrectQuery), 404 (invalidSearchAPI), 500 (systemError)
- API 에러 응답 JSON 파싱으로 세분화된 에러 메시지
- RxSwift Observable 에러 전파
<br>

#### ISBN 중복 검사
**파일**: `Cerchio/Features/Search/Reactor/SearchReactor.swift`
- `bookRepository.bookExistsByISBN()` 선행 검사
- 존재 시 `.setError` mutation으로 사용자 피드백
- Realm 쿼리 `filter("isbn == %@")`로 중복 확인
<br>

### 3. 독서 활동 화면
#### SwiftUI Charts 시계열 데이터 시각화
**파일**: `Cerchio/Features/BookDetail/BookDetail/View/ReadingChartView.swift`
- SwiftUI Charts 프레임워크 (iOS 16+)
- **Today**: 시간별 차트, `BarMark`의 `yStart`/`yEnd`로 시간 범위 표현 (0-60분)
- **Week/Month**: 일별 차트, 날짜별 독서 시간 합산
- **Year**: 월별 차트, 12개 막대로 연간 패턴 시각화
- `UIHostingController`로 SwiftUI를 UIKit에 임베드
<br>

### 4. 독서 기록 화면
#### SVG 경로 파싱 기반 커스텀 타이머 UI
**파일**: `Cerchio/Features/BookDetail/ReadingRecord/View/SVGTimerPickerView.swift`
- 정규표현식으로 SVG path 추출: `<path[^>]*d=\"([^\"]*)\""`
- `CGAffineTransform`으로 경로 정규화 (스케일링 + 중심 이동)
- `cgPath.applyWithBlock`으로 베지어 곡선 세그먼트 순회
- Pan gesture로 터치 위치를 극좌표로 변환 → 분 단위 선택
- `UIImpactFeedbackGenerator` 햅틱 피드백
<br>

#### App Group 기반 프로세스 간 데이터 공유
**파일**: `Cerchio/Common/Managers/TimerSessionManager.swift`
- App Group 식별자: `"group.com.moro.cerchio"`
- `UserDefaults(suiteName:)`로 Shared UserDefaults 접근
- Codable `ActiveSession` 구조체를 JSON 인코딩/디코딩하여 저장
- Darwin Notification (`CFNotificationCenter`)으로 앱-위젯 간 실시간 통신
  - 위젯 → 앱: `CFNotificationCenterPostNotification`
  - 앱 → 위젯: Shared UserDefaults 갱신 + Darwin Notification

**동기화 흐름**:
1. 메인 앱: 타이머 시작 → Live Activity 시작 → Shared UserDefaults 저장
2. 위젯: `loadSession()`으로 세션 데이터 읽기 → UI 업데이트
3. 위젯: 일시정지 버튼 탭 → Darwin Notification 발송
4. 메인 앱: Notification 수신 → 타이머 일시정지 → 세션 업데이트
5. 위젯: 갱신된 세션 데이터 읽기 → UI 업데이트
<br>

#### Live Activity 실시간 업데이트
**파일**: `Widgets/WidgetsLiveActivity.swift`, `Cerchio/Common/Managers/LiveActivityManager.swift`
- **ActivityAttributes**: Static attributes (bookTitle, sessionStartTime)
- **ContentState**: Dynamic state (timerStartTime, pausedElapsedSeconds, isPaused, isCompleted)
- `Activity<ReadingTimerAttributes>.request()`로 Live Activity 시작
- `activity.update(using: updatedState)`로 상태 업데이트
- SwiftUI `Text(endDate, style: .timer)` + `.monospacedDigit()`로 실시간 카운트다운
- Dynamic Island 지원: Compact/Expanded/Minimal 프레젠테이션
- Lock Screen 위젯 통합
- Async/await Task로 Activity 상태 모니터링 (active, dismissed, ended, stale)

```swift
let endDate = context.state.timerStartTime
    .addingTimeInterval(TimeInterval(context.state.targetSeconds - context.state.pausedElapsedSeconds))
Text(endDate, style: .timer).monospacedDigit()
```

<br>

#### Use Case 패턴 타이머 생명주기 관리

**파일**: `Cerchio/Features/BookDetail/ReadingTimer/UseCases/`

**8개 UseCase**:
- TimerStartUseCase, TimerStopUseCase, TimerPauseUseCase, TimerResumeUseCase
- TimerTickUseCase, TimerBackgroundUseCase, TimerForegroundUseCase, TimerRestoreUseCase

**실제 독서 시간 계산**:
```swift
let actualReadingTime = totalSessionTime - totalPauseDuration - totalBackgroundDuration
guard actualReadingTime >= 58 else { return .setError(.sessionTooShort) }
```

**상태 전이 관리**: `TimerStateManager`로 idle → running → paused → completed 전이 검증
<br>

## 메모리 관리 및 성능 최적화
### 메모리 관리
#### 1. 약한 참조 패턴
- 모든 클로저에서 `[weak self]` 사용으로 순환 참조 방지
- Coordinator 완료 핸들러: `childCoordinator.onFinish = { [weak self] in ... }`

#### 2. Coordinator 자동 메모리 해제
- `viewDidDisappear`에서 부모에게 `finish()` 이벤트 전달
- 부모가 `childCoordinators` 배열에서 제거 → 참조 카운트 0 → 자동 해제

#### 3. DisposeBag 관리
- `BaseViewController`에서 자동 해제
- UICollectionViewCell `prepareForReuse()`에서 새 DisposeBag 생성

#### 4. Realm 스레드 안전성
- DTO 변환으로 스레드 간 안전한 데이터 전달
- 메인 스레드에서 Realm 객체 접근 → DTO 추출 → 비동기 작업에 전달

<br>

### 성능 최적화
#### 1. 이미지 처리
- 100×100 다운샘플링: 처리 속도 100배 향상
- Stride 5 샘플링: 데이터 양 25배 감소

#### 2. Swift Concurrency 병렬 처리
- `withTaskGroup`로 병렬 이미지 로딩: 1000ms → 150ms (10개 이미지 기준)

#### 3. ServiceFactory 캐싱
- Repository 인스턴스 재사용으로 생성 시간 0ms
- Concurrent queue + barrier flag로 스레드 안전 구현

#### 4. RxSwift 최적화
- `share(replay: 1)`로 여러 구독자가 동일 결과 스트림 공유
- `distinctUntilChanged()`로 동일 값 중복 처리 방지

#### 5. Prefetch
- 스크롤 위치 기반 100pt 전 다음 페이지 로드
- `isLoadingMore` 플래그로 중복 요청 방지
<br>

## 프로젝트 구조

```
Cerchio/
├── Application/                  # 앱 진입점 및 전역 설정
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   └── AppCoordinator.swift
│
├── Common/                       # 공통 모듈
│   ├── Base/
│   │   ├── BaseCoordinator.swift
│   │   ├── BaseViewController.swift
│   │   └── BaseRepository.swift
│   ├── Extensions/               # Swift/UIKit 확장
│   ├── Protocols/                # 공통 프로토콜
│   ├── UI/Components/            # 재사용 UI 컴포넌트
│   ├── Utilities/                # DominantColorExtractor, ImageStorageManager 등
│   └── Managers/                 # TimerSessionManager, LiveActivityManager 등
│
├── Data/                         # 데이터 레이어
│   ├── Models/                   # Realm 객체 및 DTO
│   │   ├── Book.swift, RealmBook.swift
│   │   ├── Quote.swift, RealmQuote.swift
│   │   ├── Photo.swift, RealmPhoto.swift
│   │   └── Tag.swift, RealmTag.swift
│   ├── Repositories/             # Repository 구현체
│   └── Network/
│       ├── Base/ServiceFactory.swift
│       └── Services/BookSearchService.swift
│
├── Features/                     # Feature 모듈 (화면별)
│   ├── Library/                  # 서재
│   │   ├── Coordinator/
│   │   ├── View/
│   │   └── Reactor/
│   ├── Search/                   # 검색
│   ├── BookDetail/               # 독서 활동
│   │   ├── BookDetail/
│   │   ├── ReadingTimer/
│   │   │   └── UseCases/         # 8개 타이머 UseCase
│   │   ├── ReadingRecord/
│   │   └── QuoteShare/
│   └── Settings/                 # 설정
│
├── Resources/                    # 리소스 파일
│   ├── Assets.xcassets
│   ├── Localizable.xcstrings
│   ├── Fonts/
│   └── SVG/
│
└── Widgets/                      # Widget Extension
    ├── Widgets.swift
    ├── WidgetsLiveActivity.swift
    └── ReadingTimerAttributes.swift
```

### 레이어별 역할
- **Application Layer**: 앱 진입점 및 최상위 Coordinator
- **Common Layer**: 재사용 Base 클래스, Extensions, UI Components
- **Data Layer**: Realm ↔ DTO 변환, Repository, ServiceFactory
- **Features Layer**: 화면별 독립 모듈 (Coordinator → View → Reactor)
- **Widgets Layer**: Widget Extension, Live Activity
<br>
