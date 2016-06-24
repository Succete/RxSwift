//
//  DispatchQueueSchedulerQOS.swift
//  RxSwift
//
//  Created by John C. "Hsoi" Daub on 12/30/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation

/**
Identifies one of the global concurrent dispatch queues with specified quality of service class.
*/
public enum DispatchQueueSchedulerQOS {
    
    /**
    Identifies global dispatch queue with `QOS_CLASS_USER_INTERACTIVE`
    */
    case userInteractive
    
    /**
    Identifies global dispatch queue with `QOS_CLASS_USER_INITIATED`
    */
    case userInitiated
    
    /**
    Identifies global dispatch queue with `QOS_CLASS_DEFAULT`
    */
    case `default`

    /**
     Identifies global dispatch queue with `QOS_CLASS_UTILITY`
     */
    case utility
    
    /**
     Identifies global dispatch queue with `QOS_CLASS_BACKGROUND`
     */
    case background
}


@available(iOS 8, OSX 10.10, *)
extension DispatchQueueSchedulerQOS {
    var QOSClass: qos_class_t {
        switch self {
        case .userInteractive: return QOS_CLASS_USER_INTERACTIVE//DispatchQueueAttributes.qosUserInteractive
        case .userInitiated:   return QOS_CLASS_USER_INITIATED//DispatchQueueAttributes.qosUserInitiated
        case .default:         return QOS_CLASS_DEFAULT//DispatchQueueAttributes.qosDefault
        case .utility:         return QOS_CLASS_UTILITY//DispatchQueueAttributes.qosUtility
        case .background:      return QOS_CLASS_BACKGROUND//DispatchQueueAttributes.qosBackground
        }
    }
}
