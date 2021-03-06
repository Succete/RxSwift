//
//  NSNotificationCenter+Rx.swift
//  RxCocoa
//
//  Created by Krunoslav Zaher on 5/2/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation
#if !RX_NO_MODULE
import RxSwift
#endif

extension NotificationCenter {
    /**
    Transforms notifications posted to notification center to observable sequence of notifications.
    
    - parameter name: Filter notifications by name.
    - parameter object: Optional object used to filter notifications.
    - returns: Observable sequence of posted notifications.
    */
    @warn_unused_result(message:"http://git.io/rxs.uo")
    public func rx_notification(_ name: String, object: AnyObject? = nil) -> Observable<Notification> {
        return Observable.create { [weak object] observer in
            let nsObserver = self.addObserver(forName: NSNotification.Name(name), object: object, queue: nil) { notification in
                observer.on(.next(notification))
            }
            
            return AnonymousDisposable {
                self.removeObserver(nsObserver)
            }
        }
    }
}
