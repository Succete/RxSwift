//
//  UITableView+Rx.swift
//  RxCocoa
//
//  Created by Krunoslav Zaher on 4/2/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(tvOS)

import Foundation
#if !RX_NO_MODULE
import RxSwift
#endif
import UIKit

// Items

extension UITableView {
    
    /**
    Binds sequences of elements to table view rows.
    
    - parameter source: Observable sequence of items.
    - parameter cellFactory: Transform between sequence elements and view cells.
    - returns: Disposable object that can be used to unbind.
    */
    public func rx_itemsWithCellFactory<S: Sequence, O: ObservableType where O.E == S>
        (_ source: O)
        -> (cellFactory: (UITableView, Int, S.Iterator.Element) -> UITableViewCell)
        -> Disposable {
        return { cellFactory in
            let dataSource = RxTableViewReactiveArrayDataSourceSequenceWrapper<S>(cellFactory: cellFactory)
            
            return self.rx_itemsWithDataSource(dataSource)(source: source)
        }
    }

    /**
    Binds sequences of elements to table view rows.
    
    - parameter cellIdentifier: Identifier used to dequeue cells.
    - parameter source: Observable sequence of items.
    - parameter configureCell: Transform between sequence elements and view cells.
    - parameter cellType: Type of table view cell.
    - returns: Disposable object that can be used to unbind.
    */
    public func rx_itemsWithCellIdentifier<S: Sequence, Cell: UITableViewCell, O : ObservableType where O.E == S>
        (_ cellIdentifier: String, cellType: Cell.Type = Cell.self)
        -> (source: O)
        -> (configureCell: (Int, S.Iterator.Element, Cell) -> Void)
        -> Disposable {
        return { source in
            return { configureCell in
                let dataSource = RxTableViewReactiveArrayDataSourceSequenceWrapper<S> { (tv, i, item) in
                    let indexPath = IndexPath(row: i, section: 0)
                    let cell = tv.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! Cell
                    configureCell(i, item, cell)
                    return cell
                }
                return self.rx_itemsWithDataSource(dataSource)(source: source)
            }
        }
    }
    
    /**
    Binds sequences of elements to table view rows using a custom reactive data used to perform the transformation.
    
    - parameter dataSource: Data source used to transform elements to view cells.
    - parameter source: Observable sequence of items.
    - returns: Disposable object that can be used to unbind.
    */
    public func rx_itemsWithDataSource<
            DataSource: protocol<RxTableViewDataSourceType, UITableViewDataSource>,
            O: ObservableType where DataSource.Element == O.E
        >
        (_ dataSource: DataSource)
        -> (source: O)
        -> Disposable  {
        return { source in
            return source.subscribeProxyDataSourceForObject(self, dataSource: dataSource, retainDataSource: false) { [weak self] (_: RxTableViewDataSourceProxy, event) -> Void in
                guard let tableView = self else {
                    return
                }
                dataSource.tableView(tableView, observedEvent: event)
            }
        }
    }
}

extension UITableView {
 
    /**
    Factory method that enables subclasses to implement their own `rx_delegate`.
    
    - returns: Instance of delegate proxy that wraps `delegate`.
    */
    public override func rx_createDelegateProxy() -> RxScrollViewDelegateProxy {
        return RxTableViewDelegateProxy(parentObject: self)
    }

    /**
    Factory method that enables subclasses to implement their own `rx_dataSource`.
    
    - returns: Instance of delegate proxy that wraps `dataSource`.
    */
    public func rx_createDataSourceProxy() -> RxTableViewDataSourceProxy {
        return RxTableViewDataSourceProxy(parentObject: self)
    }
    
    /**
    Reactive wrapper for `dataSource`.
    
    For more information take a look at `DelegateProxyType` protocol documentation.
    */
    public var rx_dataSource: DelegateProxy {
        return RxTableViewDataSourceProxy.proxyForObject(self)
    }
   
    /**
    Installs data source as forwarding delegate on `rx_dataSource`.
    
    It enables using normal delegate mechanism with reactive delegate mechanism.
    
    - parameter dataSource: Data source object.
    - returns: Disposable object that can be used to unbind the data source.
    */
    public func rx_setDataSource(_ dataSource: UITableViewDataSource)
        -> Disposable {
        return RxTableViewDataSourceProxy.installForwardDelegate(dataSource, retainDelegate: false, onProxyForObject: self)
    }
    
    // events
    
    /**
    Reactive wrapper for `delegate` message `tableView:didSelectRowAtIndexPath:`.
    */
    public var rx_itemSelected: ControlEvent<IndexPath> {
        let source = rx_delegate.observe(#selector(UITableViewDelegate.tableView(_:didSelectRowAt:)))
            .map { a in
                return try castOrThrow(IndexPath.self, a[1])
            }

        return ControlEvent(events: source)
    }

    /**
     Reactive wrapper for `delegate` message `tableView:didDeselectRowAtIndexPath:`.
     */
    public var rx_itemDeselected: ControlEvent<IndexPath> {
        let source = rx_delegate.observe(#selector(UITableViewDelegate.tableView(_:didDeselectRowAt:)))
            .map { a in
                return try castOrThrow(IndexPath.self, a[1])
            }

        return ControlEvent(events: source)
    }

    /**
     Reactive wrapper for `delegate` message `tableView:accessoryButtonTappedForRowWithIndexPath:`.
     */
    public var rx_itemAccessoryButtonTapped: ControlEvent<IndexPath> {
        let source: Observable<IndexPath> = rx_delegate.observe(#selector(UITableViewDelegate.tableView(_:accessoryButtonTappedForRowWith:)))
            .map { a in
                return try castOrThrow(IndexPath.self, a[1])
            }
        
        return ControlEvent(events: source)
    }
    
    /**
    Reactive wrapper for `delegate` message `tableView:commitEditingStyle:forRowAtIndexPath:`.
    */
    public var rx_itemInserted: ControlEvent<IndexPath> {
        let source = rx_dataSource.observe(#selector(UITableViewDataSource.tableView(_:commit:forRowAt:)))
            .filter { a in
                return UITableViewCellEditingStyle(rawValue: (try castOrThrow(NSNumber.self, a[1])).intValue) == .insert
            }
            .map { a in
                return (try castOrThrow(IndexPath.self, a[2]))
        }
        
        return ControlEvent(events: source)
    }
    
    /**
    Reactive wrapper for `delegate` message `tableView:commitEditingStyle:forRowAtIndexPath:`.
    */
    public var rx_itemDeleted: ControlEvent<IndexPath> {
        let source = rx_dataSource.observe(#selector(UITableViewDataSource.tableView(_:commit:forRowAt:)))
            .filter { a in
                return UITableViewCellEditingStyle(rawValue: (try castOrThrow(NSNumber.self, a[1])).intValue) == .delete
            }
            .map { a in
                return try castOrThrow(IndexPath.self, a[2])
            }
        
        return ControlEvent(events: source)
    }
    
    /**
    Reactive wrapper for `delegate` message `tableView:moveRowAtIndexPath:toIndexPath:`.
    */
    public var rx_itemMoved: ControlEvent<ItemMovedEvent> {
        let source: Observable<ItemMovedEvent> = rx_dataSource.observe(#selector(UITableViewDataSource.tableView(_:moveRowAt:to:)))
            .map { a in
                return (try castOrThrow(IndexPath.self, a[1]), try castOrThrow(IndexPath.self, a[2]))
            }
        
        return ControlEvent(events: source)
    }

    /**
    Reactive wrapper for `delegate` message `tableView:willDisplayCell:forRowAtIndexPath:`.
    */
    public var rx_willDisplayCell: ControlEvent<WillDisplayCellEvent> {
        let source: Observable<DidEndDisplayingCellEvent> = rx_delegate.observe(#selector(UITableViewDelegate.tableView(_:willDisplay:forRowAt:)))
            .map { a in
                return (try castOrThrow(UITableViewCell.self, a[1]), try castOrThrow(IndexPath.self, a[2]))
            }

        return ControlEvent(events: source)
    }

    /**
    Reactive wrapper for `delegate` message `tableView:didEndDisplayingCell:forRowAtIndexPath:`.
    */
    public var rx_didEndDisplayingCell: ControlEvent<DidEndDisplayingCellEvent> {
        let source: Observable<DidEndDisplayingCellEvent> = rx_delegate.observe(#selector(UITableViewDelegate.tableView(_:didEndDisplaying:forRowAt:)))
            .map { a in
                return (try castOrThrow(UITableViewCell.self, a[1]), try castOrThrow(IndexPath.self, a[2]))
            }

        return ControlEvent(events: source)
    }

    /**
    Reactive wrapper for `delegate` message `tableView:didSelectRowAtIndexPath:`.
    
    It can be only used when one of the `rx_itemsWith*` methods is used to bind observable sequence,
    or any other data source conforming to `SectionedViewDataSourceType` protocol.
    
     ```
        tableView.rx_modelSelected(MyModel.self)
            .map { ...
     ```
    */
    public func rx_modelSelected<T>(_ modelType: T.Type) -> ControlEvent<T> {
        let source: Observable<T> = rx_itemSelected.flatMap { [weak self] indexPath -> Observable<T> in
            guard let view = self else {
                return Observable.empty()
            }

            return Observable.just(try view.rx_modelAtIndexPath(indexPath))
        }
        
        return ControlEvent(events: source)
    }

    /**
     Reactive wrapper for `delegate` message `tableView:didDeselectRowAtIndexPath:`.

     It can be only used when one of the `rx_itemsWith*` methods is used to bind observable sequence,
     or any other data source conforming to `SectionedViewDataSourceType` protocol.

     ```
        tableView.rx_modelDeselected(MyModel.self)
            .map { ...
     ```
     */
    public func rx_modelDeselected<T>(_ modelType: T.Type) -> ControlEvent<T> {
         let source: Observable<T> = rx_itemDeselected.flatMap { [weak self] indexPath -> Observable<T> in
             guard let view = self else {
                 return Observable.empty()
             }

           return Observable.just(try view.rx_modelAtIndexPath(indexPath))
        }

        return ControlEvent(events: source)
    }

    /**
     Synchronous helper method for retrieving a model at indexPath through a reactive data source.
     */
    public func rx_modelAtIndexPath<T>(_ indexPath: IndexPath) throws -> T {
        let dataSource: SectionedViewDataSourceType = castOrFatalError(self.rx_dataSource.forwardToDelegate(), message: "This method only works in case one of the `rx_items*` methods was used.")
        
        let element = try dataSource.modelAtIndexPath(indexPath)

        return castOrFatalError(element)
    }
}

#endif

#if os(tvOS)
    
    extension UITableView {
        
        /**
         Reactive wrapper for `delegate` message `tableView:didUpdateFocusInContext:withAnimationCoordinator:`.
         */
        public var rx_didUpdateFocusInContextWithAnimationCoordinator: ControlEvent<(context: UIFocusUpdateContext, animationCoordinator: UIFocusAnimationCoordinator)> {
            
            let source = rx_delegate.observe(#selector(UITableViewDelegate.tableView(_:didUpdateFocusInContext:withAnimationCoordinator:)))
                .map { a -> (context: UIFocusUpdateContext, animationCoordinator: UIFocusAnimationCoordinator) in
                    let context = a[1] as! UIFocusUpdateContext
                    let animationCoordinator = try castOrThrow(UIFocusAnimationCoordinator.self, a[2])
                    return (context: context, animationCoordinator: animationCoordinator)
            }
            
            return ControlEvent(events: source)
        }
    }
#endif
