//
//  CollectionViewUpdater.swift
//  DTCollectionViewManager
//
//  Created by Denys Telezhkin on 03.09.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

import Foundation
import UIKit
import DTModelStorage

/// `CollectionViewUpdater` is responsible for updating `UICollectionView`, when it receives storage updates.
open class CollectionViewUpdater : StorageUpdating {
    
    /// collection view, that will be updated
    weak var collectionView: UICollectionView?
    
    /// closure to be executed before content is updated
    open var willUpdateContent: ((StorageUpdate?) -> Void)? = nil
    
    /// closure to be executed after content is updated
    open var didUpdateContent: ((StorageUpdate?) -> Void)? = nil
    
    /// Closure to be executed, when reloading an item.
    ///
    /// - SeeAlso: `DTCollectionViewManager.updateCellClosure()` method and `DTCollectionViewManager.coreDataUpdater()` method.
    open var reloadItemClosure : ((IndexPath,Any) -> Void)?
    
    /// When this property is true, move events will be animated as delete event and insert event.
    open var animateMoveAsDeleteAndInsert: Bool
    
    /// Boolean property, that indicates whether batch updates are completed.
    /// - Note: this can be useful if you are deciding whether to run another batch of animations - insertion, deletions etc. UICollectionView is not very tolerant to multiple performBatchUpdates, executed at once.
    open var batchUpdatesInProgress: Bool = false
    
    /// Creates updater.
    public init(collectionView: UICollectionView,
                reloadItem: ((IndexPath,Any) -> Void)? = nil,
                animateMoveAsDeleteAndInsert: Bool = false) {
        self.collectionView = collectionView
        self.reloadItemClosure = reloadItem
        self.animateMoveAsDeleteAndInsert = animateMoveAsDeleteAndInsert
    }
    
    open func storageDidPerformUpdate(_ update : StorageUpdate)
    {
        willUpdateContent?(update)
        collectionView?.performBatchUpdates({ [weak self] in
            self?.applyObjectChanges(from: update)
            self?.applySectionChanges(from: update)
            }, completion: { [weak self] _ in
                if update.sectionChanges.count > 0 {
                    self?.collectionView?.reloadData()
                }
        })
        didUpdateContent?(update)
    }
    
    private func applyObjectChanges(from update: StorageUpdate) {
        for (change,indexPaths) in update.objectChanges {
            switch change {
            case .insert:
                if let indexPath = indexPaths.first {
                    collectionView?.insertItems(at: [indexPath])
                }
            case .delete:
                if let indexPath = indexPaths.first {
                    collectionView?.deleteItems(at: [indexPath])
                }
            case .update:
                if let indexPath = indexPaths.first {
                    if let closure = reloadItemClosure, let model = update.updatedObjects[indexPath] {
                        closure(indexPath,model)
                    } else {
                        collectionView?.reloadItems(at: [indexPath])
                    }
                }
            case .move:
                if let source = indexPaths.first, let destination = indexPaths.last {
                    if animateMoveAsDeleteAndInsert {
                        collectionView?.moveItem(at: source, to: destination)
                    } else {
                        collectionView?.deleteItems(at: [source])
                        collectionView?.insertItems(at: [destination])                    }
                }
            }
        }
    }
    
    private func applySectionChanges(from update: StorageUpdate) {
        for (change,indices) in update.sectionChanges {
            switch change {
            case .delete:
                if let index = indices.first {
                    collectionView?.deleteSections([index])
                }
            case .insert:
                if let index = indices.first {
                    collectionView?.insertSections([index])
                }
            case .update:
                if let index = indices.first {
                    collectionView?.reloadSections([index])
                }
            case .move:
                if let source = indices.first, let destination = indices.last {
                    collectionView?.moveSection(source, toSection: destination)
                }
            }
        }
    }
    
    /// Call this method, if you want UITableView to be reloaded, and beforeContentUpdate: and afterContentUpdate: closures to be called.
    open func storageNeedsReloading()
    {
        willUpdateContent?(nil)
        collectionView?.reloadData()
        didUpdateContent?(nil)
    }
}
