//
//  RxCollectionViewReactiveArrayDataSource.swift
//  RxCocoa
//
//  Created by Krunoslav Zaher on 6/29/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(tvOS)

import Foundation
import UIKit
#if !RX_NO_MODULE
import RxSwift
#endif

// objc monkey business
class _RxCollectionViewReactiveArrayDataSource
    : NSObject
    , UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func _collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _collectionView(collectionView, numberOfItemsInSection: section)
    }

    @nonobjc func _collectionView(_ collectionView: UICollectionView, cellForItemAtIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        rxAbstractMethod()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return _collectionView(collectionView, cellForItemAtIndexPath: indexPath)
    }
}

class RxCollectionViewReactiveArrayDataSourceSequenceWrapper<S: Sequence>
    : RxCollectionViewReactiveArrayDataSource<S.Iterator.Element>
    , RxCollectionViewDataSourceType {
    typealias Element = S

    override init(cellFactory: CellFactory) {
        super.init(cellFactory: cellFactory)
    }
    
    func collectionView(_ collectionView: UICollectionView, observedEvent: Event<S>) {
        UIBindingObserver(uiElement: self) { collectionViewDataSource, sectionModels in
            let sections = Array(sectionModels)
            collectionViewDataSource.collectionView(collectionView, observedElements: sections)
        }.on(observedEvent)
    }
}


// Please take a look at `DelegateProxyType.swift`
class RxCollectionViewReactiveArrayDataSource<Element>
    : _RxCollectionViewReactiveArrayDataSource
    , SectionedViewDataSourceType {
    
    typealias CellFactory = (UICollectionView, Int, Element) -> UICollectionViewCell
    
    var itemModels: [Element]? = nil
    
    func modelAtIndex(_ index: Int) -> Element? {
        return itemModels?[index]
    }

    func modelAtIndexPath(_ indexPath: IndexPath) throws -> Any {
        precondition((indexPath as NSIndexPath).section == 0)
        guard let item = itemModels?[(indexPath as NSIndexPath).item] else {
            throw RxCocoaError.itemsNotYetBound(object: self)
        }
        return item
    }
    
    var cellFactory: CellFactory
    
    init(cellFactory: CellFactory) {
        self.cellFactory = cellFactory
    }
    
    // data source
    
    override func _collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemModels?.count ?? 0
    }
    
    override func _collectionView(_ collectionView: UICollectionView, cellForItemAtIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        return cellFactory(collectionView, (indexPath as NSIndexPath).item, itemModels![(indexPath as NSIndexPath).item])
    }
    
    // reactive
    
    func collectionView(_ collectionView: UICollectionView, observedElements: [Element]) {
        self.itemModels = observedElements
        
        collectionView.reloadData()
    }
}

#endif
