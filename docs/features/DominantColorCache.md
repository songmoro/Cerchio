---
Feature ID: FEAT-DOMCOLOR
Version: 1.1.0
Last Updated: 2025-12-03
Status: Active
Related Contracts: [CONT-004]
Related Principles: [PRIN-002, PRIN-004]
---

# Dominant Color Cache

책 표지 이미지의 dominant color를 캐싱하여 Library 화면 스크롤 성능을 최적화하는 기능.

## 목적

LibraryCollectionViewCell에서 매번 계산되는 dominant color 추출(50-100ms)을 캐싱하여:
- 스크롤 시 반복 계산 제거
- 앱 재시작 후에도 빠른 로딩
- UI 응답성 향상

## 아키텍처

### 계층 구조

```
LibraryCollectionViewCell (Consumer)
         ↓
DominantColorCache (Manager)
         ├─ NSCache (메모리 캐시)
         └─ ColorCacheRepository (영구 캐시)
                  ↓
           RealmColorCache (Realm 모델)
```

### 데이터 흐름

```
1. getColors(imageKey) 호출
   ↓
2. 메모리 캐시 확인
   ├─ HIT → 즉시 반환 (<1ms)
   └─ MISS → 3단계로
   ↓
3. Realm 캐시 확인 (preload 시)
   ├─ HIT → 메모리 로드 후 반환 (~10ms)
   └─ MISS → nil 반환
   ↓
4. DominantColorExtractor.extract() 실행 (50-100ms)
   ↓
5. setColors() → 메모리 + Realm 저장
```

## 구현 상세

### 1. 캐시 정책

#### 메모리 캐시 (NSCache)

```swift
var memoryCacheCountLimit: Int = 100              // 최대 100개 항목
var memoryCacheTotalCostLimit: Int = 5 * 1024 * 1024  // 최대 5MB
```

**제한 기준:**
- 한 화면 최대 6개 노출
- 이미지당 평균 50KB
- 100개 × 50KB = 약 5MB

**자동 제거:**
- NSCache의 LRU 알고리즘으로 자동 관리
- countLimit 또는 totalCostLimit 초과 시 오래된 항목부터 제거

**메모리 경고 처리:**
- 시스템 메모리 부족 시 자동으로 메모리 캐시 정리
- Realm 데이터는 보존 (재로딩 가능)
- NotificationCenter 기반 자동 감지

#### 영구 캐시 (Realm)

```swift
final class RealmColorCache: Object {
    @Persisted(primaryKey: true) var imageKey: String
    @Persisted var colorData: Data
    @Persisted var colorCount: Int
    @Persisted var lastAccessDate: Date
    @Persisted var createdAt: Date
}
```

**정리 정책:**
- 시간 기반: 30일 이상 미사용 항목 삭제 (앱 시작 시 자동 실행)
- LRU 기반: 최근 200개만 유지 (앱 시작 시 자동 실행)
- 실행 시점: AppDelegate.didFinishLaunchingWithOptions
- 실행 스레드: Main (비동기)

### 2. 핵심 컴포넌트

#### DominantColorCache (Manager)

**책임:**
- 메모리 캐시 관리 (NSCache)
- Realm 캐시와의 조율
- Scope 기반 메모리 관리
- 통계 추적

**주요 메서드:**

```swift
// 캐시 조회
func getColors(forImageKey imageKey: String) -> [UIColor]?

// 캐시 저장
func setColors(_ colors: [UIColor], forImageKey imageKey: String, scope: String?)

// 비동기 preload (Realm → 메모리)
func loadAndCacheColors(imageKeys: [String], scope: String?) async

// 정리 정책
func cleanupOldCaches(maxAge: TimeInterval)
func cleanupLeastRecentlyUsed(keepCount: Int)

// 통계
func getStatistics() -> DominantColorCacheStats
func printStatistics()
```

#### ColorCacheRepository

**책임:**
- Realm CRUD 작업
- Observable 기반 비동기 처리
- 메인 스레드 격리 (Realm 제약)

**계약 준수:**
- BaseRepository<RealmColorCache> 상속
- Protocol 기반 인터페이스
- 비즈니스 로직 없음

### 3. 통합 지점

#### LibraryCollectionViewCell

```swift
private func extractAndApplyDominantColor(from image: UIImage, imageKey: String) {
    Task {
        // Step 1: 캐시 확인
        if let cachedColors = DominantColorCache.shared.getColors(forImageKey: imageKey),
           let dominantColor = cachedColors.first {
            // 즉시 UI 업데이트
            return
        }

        // Step 2: 캐시 미스 → 추출
        let dominantColor = await Task.detached {
            DominantColorExtractor.extract(from: image).first ?? .gray
        }.value

        // Step 3: 캐시 저장
        DominantColorCache.shared.setColors([dominantColor], forImageKey: imageKey, scope: "library")
    }
}
```

#### LibraryViewController

```swift
private func updateData(books: [Book]?) {
    dataSource.apply(snapshot, animatingDifferences: true)

    // Preloading: Realm → 메모리
    preloadColorsForBooks(books)
}

private func preloadColorsForBooks(_ books: [Book]) {
    let imageKeys = books.map { $0.customCoverImagePath ?? $0.image }

    Task {
        await DominantColorCache.shared.loadAndCacheColors(
            imageKeys: imageKeys,
            scope: "library"
        )
    }
}
```

### 4. Scope 관리

**목적:** Feature별 메모리 캐시 분리 관리

```swift
// Library 화면 진입 시 (자동)
// LibraryViewController.updateData() -> preloadColorsForBooks() 호출

// Library 화면 이탈 시 (자동)
// LibraryViewController.viewDidDisappear() -> clearScope("library") 호출
```

**동작:**
- 메모리 캐시만 제거 (Realm 유지)
- 다음 진입 시 preload로 자동 복원
- 수동 호출 불필요 (ViewController 생명주기에 통합)

## 성능 지표

### 응답 시간

| 시나리오 | 시간 | 설명 |
|---------|------|------|
| 메모리 캐시 HIT | <1ms | NSCache 조회 |
| Realm 캐시 HIT | ~10ms | Realm 조회 + 메모리 로드 |
| 캐시 MISS | 50-100ms | 색상 추출 + 저장 |

### 히트율 예상

| 사용 시점 | 메모리 | Realm | 추출 |
|----------|--------|-------|------|
| 첫 실행 | 0% | 0% | 100% |
| 첫 스크롤 후 | 80% | 0% | 20% |
| 앱 재시작 | 0% | 90% | 10% |
| 1주일 사용 | 85% | 10% | 5% |

### 메모리 사용량

```
최대 메모리: 5MB (100개 × 50KB)
평균 사용량: 300KB (6개 화면 × 50KB)
```

## 통계 추적

### 로그 출력

```
✅ [ColorCache] Memory HIT: https://image.aladin...
💿 [ColorCache] Persistent HIT: https://image.aladin...
🔍 [ColorCache] Memory MISS: https://image.aladin... - extracting color
💾 [ColorCache] Saving to cache: https://image.aladin...
```

### 통계 API

```swift
// 포맷된 통계 출력
DominantColorCache.shared.printStatistics()

// 프로그래밍 방식 조회
let stats = DominantColorCache.shared.getStatistics()

// 통계 초기화
DominantColorCache.shared.resetStatistics()
```

## 확장성

### 다른 Feature 적용

```swift
// BookDetail의 Photo 이미지 캐싱
let imageKey = photo.localImagePath
DominantColorCache.shared.setColors(colors, forImageKey: imageKey, scope: "bookDetail")
```

### 정책 커스터마이징

```swift
// 더 많은 항목 캐싱 (라이브러리가 큰 경우)
DominantColorCache.shared.memoryCacheCountLimit = 200
DominantColorCache.shared.memoryCacheTotalCostLimit = 10 * 1024 * 1024

// 더 자주 정리
DominantColorCache.shared.cleanupOldCaches(maxAge: 7 * 24 * 60 * 60)
DominantColorCache.shared.cleanupLeastRecentlyUsed(keepCount: 100)
```

## 제약사항

### 메모리 캐시

- ❌ 앱 종료 시 초기화
- ❌ 메모리 부족 시 NSCache가 자동 제거 가능
- ✅ Thread-safe (NSCache 내장)

### Realm 캐시

- ✅ 앱 시작 시 자동 정리 (30일/200개 정책)
- ❌ 메인 스레드에서만 접근 (Realm 제약)
- ✅ 앱 재시작 후에도 유지

### 이미지 키

- imageKey = `book.customCoverImagePath ?? book.image`
- 동일한 URL/경로는 하나의 캐시로 관리
- 키 충돌 시 덮어쓰기 (Upsert)

## 디버깅

### Xcode 콘솔 로그

모든 캐시 작업이 자동으로 로깅됩니다:
- ✅ 메모리 히트
- 💿 Realm 히트 (preload)
- 🔍 캐시 미스
- 💾 캐시 저장

### 통계 확인

```swift
#if DEBUG
// AppDelegate 또는 적절한 위치에서
DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
    DominantColorCache.shared.printStatistics()
}
#endif
```

## 관련 문서

- **Repository 계약**: [docs/contracts/repository-contract.md](../contracts/repository-contract.md)
- **관심사 분리 원칙**: [docs/principles/separation-of-concerns.md](../principles/separation-of-concerns.md)
- **반응형 프로그래밍**: [docs/principles/reactive-programming.md](../principles/reactive-programming.md)
- **참고 구현**: PhotoImageCache (Common/Managers/PhotoImageCache.swift)

## 변경 이력

### v1.1.0 (2025-12-03)
- 앱 시작 시 자동 정리 추가 (AppDelegate)
  - 시간 기반 정리 (30일)
  - LRU 정리 (200개)
  - 메인 스레드 비동기 실행
- 메모리 경고 자동 처리
  - UIApplication.didReceiveMemoryWarningNotification 등록
  - 메모리 캐시 자동 정리
- Library 화면 이탈 시 Scope 자동 정리
  - viewDidDisappear 통합
  - 메모리 효율성 개선

### v1.0.0 (2025-12-02)
- 초기 구현
- 2단계 캐싱 (메모리 + Realm)
- 통계 추적 기능
- Preloading 지원
- 최대 100개, 5MB 제한
