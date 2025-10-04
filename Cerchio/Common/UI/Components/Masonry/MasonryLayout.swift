//
//  MasonryLayout.swift
//  Cerchio
//
//  Created by 송재훈 on 9/24/25.
//

import UIKit

final class MasonryLayout: UICollectionViewLayout {
    weak var delegate: MasonryLayoutProtocol?
    private let numberOfColumns = MasonryConstants.Layout.numberOfColumns
    private let cellPadding: CGFloat = MasonryConstants.Layout.cellPadding
    private var cache: [UICollectionViewLayoutAttributes] = []
    private var contentHeight: CGFloat = 0

    private var contentWidth: CGFloat {
        guard let collectionView = collectionView else { return 0 }
        let insets = collectionView.contentInset
        return collectionView.bounds.width - (insets.left + insets.right)
    }

    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }

    override func prepare() {
        guard cache.isEmpty, let collectionView = collectionView else { return }

        // diffable data source 호환성을 위한 안전 체크
        let numberOfSections = collectionView.numberOfSections
        guard numberOfSections > 0 else { return }

        let columnWidth = contentWidth / CGFloat(numberOfColumns)
        var xOffset: [CGFloat] = []
        for column in 0..<numberOfColumns {
            xOffset.append(CGFloat(column) * columnWidth)
        }

        var column = 0
        var yOffset: [CGFloat] = .init(repeating: 0, count: numberOfColumns)

        // 모든 섹션을 처리 (현재는 주로 섹션 0만 사용하지만 확장 가능)
        for section in 0..<numberOfSections {
            let numberOfItems = collectionView.numberOfItems(inSection: section)

            for item in 0..<numberOfItems {
                let indexPath = IndexPath(item: item, section: section)

                let cellHeight = delegate?.collectionView(collectionView, heightAtIndexPath: indexPath) ?? MasonryConstants.Layout.defaultCellHeight
                let height = cellPadding * 2 + cellHeight
                let frame = CGRect(x: xOffset[column],
                                   y: yOffset[column],
                                   width: columnWidth,
                                   height: height)

                // 좌우 패딩 대칭 적용
                let isLeftColumn = column == 0
                let leftInset = isLeftColumn ? 8.0 : 2.0
                let rightInset = isLeftColumn ? 2.0 : 8.0

                let insetFrame = CGRect(
                    x: frame.minX + leftInset,
                    y: frame.minY + cellPadding,
                    width: frame.width - leftInset - rightInset,
                    height: frame.height - cellPadding * 2
                )

                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = insetFrame
                cache.append(attributes)

                contentHeight = max(contentHeight, frame.maxY)
                yOffset[column] = yOffset[column] + height

                column = column < (numberOfColumns - 1) ? (column + 1) : 0
            }
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var visibleLayoutAttributes: [UICollectionViewLayoutAttributes] = []

        for attributes in cache {
            if attributes.frame.intersects(rect) {
                visibleLayoutAttributes.append(attributes)
            }
        }
        return visibleLayoutAttributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.item < cache.count else { return nil }
        return cache[indexPath.item]
    }

    // diffable data source 호환성을 위한 메서드들
    override func invalidateLayout() {
        super.invalidateLayout()
        cache.removeAll()
        contentHeight = 0
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView = collectionView else { return false }
        return !newBounds.size.equalTo(collectionView.bounds.size)
    }
}