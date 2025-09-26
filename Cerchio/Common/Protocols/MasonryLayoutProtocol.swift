//
//  MasonryLayoutProtocol.swift
//  Cerchio
//
//  Created by 송재훈 on 9/24/25.
//

import UIKit

protocol MasonryLayoutProtocol: AnyObject {
    func collectionView(_ collectionView: UICollectionView, heightAtIndexPath indexPath: IndexPath) -> CGFloat
}
