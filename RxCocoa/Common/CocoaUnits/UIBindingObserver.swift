//
//  UIBindingObserver.swift
//  Rx
//
//  Created by Krunoslav Zaher on 2/7/16.
//  Copyright © 2016 Krunoslav Zaher. All rights reserved.
//

import Foundation
#if !RX_NO_MODULE
    import RxSwift
#endif

/**
Observer that enforces interface binding rules:
 * can't bind errors (in debug builds binding of errors causes `fatalError` in release builds errors are being logged)
 * ensures binding is performed on main thread
 
`UIBindingObserver` doesn't retain target interface and in case owned interface element is released, element isn't bound.
*/
public class UIBindingObserver<UIElementType, Value where UIElementType: AnyObject> : ObserverType {
    public typealias E = Value

    weak var uiElement: UIElementType?

    let binding: (UIElementType, Value) -> Void

    /**
     Initializes `ViewBindingObserver` using
    */
    public init(uiElement: UIElementType, binding: (UIElementType, Value) -> Void) {
        self.uiElement = uiElement
        self.binding = binding
    }

    /**
     Binds next element to owner view as described in `binding`.
    */
    public func on(_ event: Event<Value>) {
        MainScheduler.ensureExecutingOnScheduler("Element can be bound to user interface only on MainThread.")

        switch event {
        case .next(let element):
            if let view = self.uiElement {
                binding(view, element)
            }
        case .error(let error):
            bindingErrorToInterface(error)
        case .completed:
            break
        }
    }

    /**
     Erases type of observer.

     - returns: type erased observer.
     */
    public func asObserver() -> AnyObserver<Value> {
        return AnyObserver(eventHandler: on)
    }
}
