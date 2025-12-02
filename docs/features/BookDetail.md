---
Document ID: DOC-FEAT-003
Version: 1.0.0
Last Updated: 2025-12-01
Status: Active
Related Documents: [DOC-ARCH-002, DOC-PATTERN-002, DOC-LAYER-004]
---

# BookDetail Feature

## TL;DR

BookDetail은 Cerchio에서 가장 복잡한 Feature로, 도서의 모든 독서 활동을 관리합니다. 13개의 하위 Feature를 가지고 있으며, 독서 타이머 (Live Activity), 독서 기록, 문장 저장, 사진 관리, 태그 관리, 통계 시각화 등을 포함합니다. Service 레이어를 사용하여 복잡한 비즈니스 로직을 Reactor에서 분리했습니다.

## 언제 이 문서를 읽어야 하나?

- ✅ BookDetail Feature를 수정해야 할 때
- ✅ BookDetail의 복잡한 아키텍처를 이해하고 싶을 때
- ✅ BookDetail에 새로운 기능을 추가하고 싶을 때
- ✅ 하위 Feature (ReadingTimer, QuoteSave 등)의 구조를 파악하고 싶을 때
- ❌ 새 Feature 구현 방법 (→ `guides/adding-new-feature.md`)

---

## 목차

1. [아키텍처 개요](#아키텍처-개요)
2. [하위 Feature 구조](#하위-feature-구조)
3. [데이터 흐름](#데이터-흐름)
4. [주요 컴포넌트](#주요-컴포넌트)
5. [의존성](#의존성)
6. [확장 가이드](#확장-가이드)
7. [관련 Feature](#관련-feature)

---

## 아키텍처 개요

### Coordinator

**역할**: BookDetail 화면 및 13개 하위 Feature의 네비게이션 관리

**주요 책임**:
- BookDetailViewController 생성 및 표시
- 13개 하위 Coordinator 생명주기 관리
- 하위 Feature 결과 수신 및 BookDetailReactor 액션 트리거
- ServiceFactory 의존성 주입

### Reactor

**역할**: BookDetail의 상태 관리 및 비즈니스 로직 조율

**상태 관리**:
- 도서 상세 정보 (BookDetail)
- 독서 진행 상황 (ReadingProgress)
- 독서 통계 (ReadingStatistics)
- 사진 목록 (PhotoItem[])
- 문장 목록 (QuoteItem[])
- 태그 목록 (TagItem[])

### Service

**역할**: 복잡한 비즈니스 로직 처리, Reactor에서 분리

**비즈니스 로직**:
- 사진 로딩: Swift Concurrency로 병렬 이미지 로딩
- 독서 통계 계산: 여러 Repository 데이터 조합
- 독서 차트 데이터 생성: 기간별 데이터 집계

### View

**역할**: 도서 상세 정보 표시 및 하위 Feature 진입점 제공

**UI 컴포넌트**:
- BookInfoView: 도서 기본 정보 (제목, 작가, 표지)
- ReadingStatisticsView: 독서 통계 (총 시간, 평균 시간, 완독률)
- ReadingChartView: SwiftUI Charts 기반 독서 그래프
- TabNavigationView: 독서 활동/사진/문장 탭 전환
- UICollectionView (Diffable DataSource): 사진, 문장, 세션 목록

---

## 하위 Feature 구조

BookDetail은 **13개의 독립적인 하위 Feature**로 구성됩니다. 각 하위 Feature는 자체 Coordinator-Reactor-ViewController를 가집니다.

```
BookDetail/
├── BookDetail/              # 메인 Feature
├── ReadingTimer/            # 독서 타이머 (UseCase 패턴)
├── ReadingRecord/           # 독서 기록 (SVG 타이머)
├── ReadingSessionList/      # 독서 세션 목록
├── QuoteList/               # 문장 목록
├── QuoteSave/               # 문장 저장
├── QuoteShare/              # 문장 공유
├── PhotoList/               # 사진 목록
├── EditBookInfo/            # 도서 정보 수정
├── ReadingInfoEdit/         # 독서 정보 수정
├── TagEdit/                 # 태그 편집
├── ResetAndDelete/          # 초기화 및 삭제
└── Model/                   # 공유 모델
```

### 1. BookDetail (메인)

**파일**: 18개
**역할**: 도서 상세 정보 표시, 하위 Feature 진입점

**주요 컴포넌트**:
- `BookDetailViewController`: 메인 화면
- `BookDetailReactor`: 상태 관리
- `BookDetailService`: 비즈니스 로직 (사진 로딩, 통계 계산)

**독특한 기능**:
- **SwiftUI Charts**: ReadingChartView로 독서 통계 시각화
- **Diffable DataSource**: 사진, 문장, 세션 목록
- **TabNavigationView**: 독서 활동/사진/문장 탭

### 2. ReadingTimer

**파일**: 12개
**역할**: 독서 타이머, Live Activity 관리

**아키텍처 패턴**: **UseCase 패턴** (8개 UseCase)

**UseCases**:
- `TimerStartUseCase`: 타이머 시작, Live Activity 시작
- `TimerStopUseCase`: 타이머 종료, **실제 독서 시간 계산**
- `TimerPauseUseCase`: 일시정지, Live Activity 업데이트
- `TimerResumeUseCase`: 재개
- `TimerTickUseCase`: 1초마다 상태 업데이트
- `TimerBackgroundUseCase`: 백그라운드 진입 시간 기록
- `TimerForegroundUseCase`: 포그라운드 복귀 시간 계산
- `TimerRestoreUseCase`: 앱 재시작 시 세션 복구

**실제 독서 시간 계산**:
```swift
actualReadingTime = totalSessionTime - totalPauseDuration - totalBackgroundDuration
```

**Dependencies**:
- `TimerSessionManager`: App Group 기반 세션 관리
- `LiveActivityManager`: Live Activity 생명주기
- `ReadingSessionRepository`: 세션 데이터 저장

### 3. ReadingRecord

**파일**: 7개
**역할**: 독서 기록 생성, SVG 경로 기반 커스텀 타이머

**독특한 기능**:
- **SVG 경로 기반 타이머**: `SVGTimerPickerView`
- Pan gesture로 터치 위치를 각도로 변환 → 분 단위 선택
- 극좌표 변환: `SVGPathParser`
- Haptic 피드백

### 4. QuoteList

**파일**: 6개
**역할**: 저장한 문장 목록 표시

**UI**: UICollectionView (Waterfall Layout)

### 5. QuoteSave

**파일**: 3개
**역할**: 문장 저장 (페이지 번호, 메모)

**UI**: UITextView (InsetTextView), UITextField

### 6. QuoteShare

**파일**: 10개
**역할**: 문장 공유 (이미지 생성)

**독특한 기능**:
- 가우시안 블러 배경 이미지 생성
- Dominant 색상 추출: `DominantColorExtractor`
- UIGraphicsImageRenderer로 합성

### 7. PhotoList

**파일**: 6개
**역할**: 사진 목록 표시

**독특한 기능**:
- **Swift Concurrency**: `withTaskGroup`으로 병렬 이미지 로딩
- `PhotoImageCache`: 메모리 캐시

### 8-13. 기타 하위 Feature

- **EditBookInfo**: 도서 정보 수정 (커스텀 제목/작가/표지)
- **ReadingInfoEdit**: 독서 정보 수정 (총 페이지, 시작일, 종료일)
- **TagEdit**: 태그 편집 (다대다 관계)
- **ReadingSessionList**: 독서 세션 목록 (날짜별 그룹화)
- **ResetAndDelete**: 독서 기록 초기화, 도서 삭제 (Cascade)

---

## 데이터 흐름

### 기본 흐름

```
사용자 액션
   ↓
BookDetailViewController
   ↓
BookDetailReactor.action
   ↓
BookDetailService
   ↓
Multiple Repositories (Book, Quote, Photo, Tag, ReadingSession)
   ↓
Realm
   ↓
State 업데이트
   ↓
UI 업데이트
```

### 특수 데이터 흐름

#### 1. 사진 로딩 (Swift Concurrency)

```
BookDetailReactor.action(.loadPhotos)
   ↓
BookDetailService.loadPhotos(bookId:)
   ↓
MainActor.run {
    Realm에서 사진 경로 추출
}
   ↓
withTaskGroup {
    병렬 이미지 로딩
}
   ↓
Observable<[UIImage]>
   ↓
Mutation.setPhotos([PhotoItem])
```

**코드**:
```swift
func loadPhotos(bookId: String) async throws -> [UIImage] {
    // 1. Realm에서 경로 추출 (Main Thread)
    let imagePaths = try await MainActor.run {
        let realm = try Realm()
        let photos = realm.objects(RealmPhoto.self)
            .filter("bookId == %@", bookId)
        return Array(photos.map { $0.localImagePath })
    }

    // 2. 병렬 이미지 로딩 (Background)
    return await withTaskGroup(of: UIImage?.self) { group in
        for path in imagePaths {
            group.addTask {
                ImageStorageManager.shared.loadImage(fromPath: path)
            }
        }

        var images: [UIImage] = []
        for await image in group {
            if let image = image {
                images.append(image)
            }
        }
        return images
    }
}
```

#### 2. 독서 통계 계산 (다중 Repository 조합)

```
BookDetailReactor.action(.loadReadingStatistics)
   ↓
BookDetailService.calculateReadingStatistics(bookId:)
   ↓
ReadingSessionRepository.getSessions(for: bookId)
   ↓
집계: totalTime, avgTime, completionRate
   ↓
Observable<ReadingStatistics>
   ↓
Mutation.setReadingStatistics(ReadingStatistics)
```

#### 3. 하위 Feature 결과 수신

```
사용자: "문장 저장" 버튼 탭
   ↓
BookDetailCoordinator.showQuoteSave()
   ↓
QuoteSaveCoordinator 생성 및 start()
   ↓
QuoteSaveViewController에서 저장
   ↓
QuoteSaveCoordinator.result.onNext(.quoteSaved)
   ↓
BookDetailCoordinator가 result 수신
   ↓
BookDetailReactor.action.onNext(.loadQuotes)
   ↓
문장 목록 새로고침
```

---

## 주요 컴포넌트

### Coordinator

**파일**: `Features/BookDetail/BookDetail/Coordinator/BookDetailCoordinator.swift`

**자식 Coordinators** (13개):
- `ReadingTimerCoordinator`: 독서 타이머
- `ReadingRecordCoordinator`: 독서 기록 생성
- `ReadingSessionListCoordinator`: 세션 목록
- `QuoteListCoordinator`: 문장 목록
- `QuoteSaveCoordinator`: 문장 저장
- `QuoteShareCoordinator`: 문장 공유
- `PhotoListCoordinator`: 사진 목록
- `EditBookInfoCoordinator`: 도서 정보 수정
- `ReadingInfoEditCoordinator`: 독서 정보 수정
- `TagEditCoordinator`: 태그 편집
- `ResetAndDeleteCoordinator`: 초기화 및 삭제
- (기타 2개 Coordinator)

**Result 타입**:
```swift
enum Result {
    case bookDeleted
    case bookUpdated(Book)
}
```

### Reactor

**파일**: `Features/BookDetail/BookDetail/Reactor/BookDetailReactor.swift`

**주요 Actions**:
```swift
enum Action {
    case loadBookDetail           // 도서 상세 정보 로드
    case updateReadingProgress    // 독서 진행 상황 업데이트
    case toggleFavorite           // 즐겨찾기 토글
    case loadReadingStatistics    // 독서 통계 로드
    case loadReadingChartData     // 차트 데이터 로드

    case loadPhotos               // 사진 로드
    case savePhoto(UIImage)       // 사진 저장
    case deletePhoto(String)      // 사진 삭제

    case loadQuotes               // 문장 로드
    case deleteQuote(String)      // 문장 삭제

    case loadTags                 // 태그 로드
    case saveTags([String])       // 태그 저장
}
```

**주요 Mutations**:
```swift
enum Mutation {
    case setBookDetail(BookDetail)
    case setPhotos([PhotoItem])
    case setQuotes([QuoteItem])
    case setTags([TagItem])
    case setReadingStatistics(ReadingStatistics)
    case setReadingChartData(ReadingChartData)
    case setLoading(Bool)
    case setError(Error?)
}
```

**주요 States**:
```swift
struct State {
    var book: Book
    var bookDetail: BookDetail?
    var photos: [PhotoItem] = []
    var quotes: [QuoteItem] = []
    var tags: [TagItem] = []
    var readingStatistics: ReadingStatistics?
    var readingChartData: ReadingChartData?
    var isLoading: Bool = false
    var error: Error?
}
```

### Service

**파일**: `Features/BookDetail/BookDetail/Reactor/BookDetailService.swift`

**주요 메서드**:
- `loadPhotos(bookId:) async throws -> [UIImage]`: Swift Concurrency 병렬 이미지 로딩
- `calculateReadingStatistics(bookId:) -> Observable<ReadingStatistics>`: 독서 통계 계산
- `loadReadingChartData(bookId:, period:) -> Observable<ReadingChartData>`: 차트 데이터 생성

**Service를 사용하는 이유**:
1. **다중 Repository 조합**: Book, Quote, Photo, Tag, ReadingSession
2. **Swift Concurrency**: async/await 사용
3. **복잡한 계산**: 독서 통계 집계

### ViewController

**파일**: `Features/BookDetail/BookDetail/View/BookDetailViewController.swift`

**주요 UI 컴포넌트**:
- `bookInfoView: BookInfoView`: 도서 기본 정보
- `readingStatisticsView: ReadingStatisticsView`: 독서 통계
- `readingChartView: ReadingChartView`: SwiftUI Charts
- `tabNavigationView: TabNavigationView`: 독서 활동/사진/문장 탭
- `collectionView: UICollectionView`: Diffable DataSource

**Diffable DataSource 섹션**:
```swift
enum Section {
    case readingStatistics
    case photos
    case quotes
    case readingSessions
    case settings
}
```

---

## 의존성

### Repositories

이 Feature가 사용하는 Repository:

- **BookRepository**: 도서 정보 CRUD, 즐겨찾기 토글
- **QuoteRepository**: 문장 CRUD
- **PhotoRepository**: 사진 메타데이터 CRUD
- **TagRepository**: 태그 CRUD (다대다 관계)
- **ReadingSessionRepository**: 독서 세션 CRUD

### Managers

이 Feature가 사용하는 Manager:

- **ImageStorageManager**: 로컬 이미지 저장/로딩/삭제
- **PhotoImageCache**: 이미지 메모리 캐시
- **HapticFeedbackManager**: 햅틱 피드백
- **DominantColorExtractor**: 이미지 대표 색상 추출

### Models

이 Feature에서 사용하는 데이터 모델:

- **Book**: 도서 정보 DTO
- **BookDetail**: 도서 상세 정보 (독서 진행, 통계 포함)
- **Quote**: 문장 DTO
- **Photo**: 사진 DTO
- **Tag**: 태그 DTO
- **ReadingSession**: 독서 세션 DTO
- **ReadingStatistics**: 독서 통계
- **ReadingChartData**: 차트 데이터

---

## 확장 가이드

### 이 Feature에 새 기능 추가 시

#### 예시: "메모" 기능 추가

1. **새 Repository 생성** (필요 시):
   ```swift
   // Data/Repositories/MemoRepository.swift
   final class MemoRepository: BaseRepository<RealmMemo> { ... }
   ```

2. **ServiceFactory에 추가**:
   ```swift
   func createMemoRepository() -> MemoRepository {
       return MemoRepository()
   }
   ```

3. **BookDetailReactor에 Action 추가**:
   ```swift
   enum Action {
       case loadMemos
       case saveMemo(String)
   }
   ```

4. **BookDetailService에 메서드 추가**:
   ```swift
   func loadMemos(bookId: String) -> Observable<[Memo]> { ... }
   ```

5. **BookDetailViewController에 UI 추가**:
   ```swift
   private let memoSection = ...
   ```

### 새 하위 Feature 추가 시

#### 예시: "북마크" Feature 추가

1. **디렉토리 생성**:
   ```bash
   mkdir -p Features/BookDetail/Bookmark/{Coordinator,View,Reactor}
   ```

2. **Coordinator-Reactor-ViewController 구현** (`guides/adding-new-feature.md` 참조)

3. **BookDetailCoordinator에 메서드 추가**:
   ```swift
   func showBookmark() {
       let coordinator = BookmarkCoordinator(
           navigationController: navigationController
       )
       addChildCoordinator(coordinator)

       coordinator.result
           .subscribe(onNext: { [weak self] result in
               switch result {
               case .bookmarkSaved:
                   self?.currentReactor?.action.onNext(.loadBookmarks)
               case .cancelled:
                   break
               }
               self?.removeChildCoordinator(coordinator)
           })
           .disposed(by: disposeBag)

       coordinator.start(with: BookmarkDependencies(
           serviceFactory: serviceFactory,
           bookId: currentBook.id
       ))
   }
   ```

4. **BookDetailViewController에서 호출**:
   ```swift
   button.rx.tap
       .subscribe(onNext: { [weak self] in
           self?.coordinator?.showBookmark()
       })
       .disposed(by: disposeBag)
   ```

5. **이 문서 업데이트** (하위 Feature 섹션에 추가)

---

## 관련 Feature

- **Library**: BookDetail로 이동 (LibraryCoordinator → BookDetailCoordinator)
- **Search**: 도서 추가 후 BookDetail로 이동

---

## 파일 경로 요약

```
Features/BookDetail/
├── BookDetail/
│   ├── Coordinator/
│   │   └── BookDetailCoordinator.swift
│   ├── View/
│   │   ├── BookDetailViewController.swift
│   │   ├── BookInfoView.swift
│   │   ├── ReadingStatisticsView.swift
│   │   ├── ReadingChartView.swift (SwiftUI)
│   │   ├── TabNavigationView.swift
│   │   └── (기타 14개 View 파일)
│   └── Reactor/
│       ├── BookDetailReactor.swift
│       └── BookDetailService.swift
├── ReadingTimer/
│   ├── Coordinator/ReadingTimerCoordinator.swift
│   ├── View/ReadingTimerViewController.swift
│   ├── Reactor/ReadingTimerReactor.swift
│   └── UseCases/ (8개 UseCase)
├── ReadingRecord/
│   ├── Coordinator/ReadingRecordCoordinator.swift
│   ├── View/
│   │   ├── ReadingRecordViewController.swift
│   │   └── SVGTimerPickerView.swift
│   └── Reactor/ReadingRecordReactor.swift
└── (기타 10개 하위 Feature)
```

---

## 관련 문서

- [guides/adding-new-feature.md](../guides/adding-new-feature.md) - 새 Feature 추가 가이드
- [architecture/data-flow.md](../architecture/data-flow.md) - 데이터 흐름 패턴
- [patterns/service-layer.md](../patterns/service-layer.md) - Service 레이어 분리 패턴
- [layers/data-layer.md](../layers/data-layer.md) - Repository, Realm, DTO 패턴
