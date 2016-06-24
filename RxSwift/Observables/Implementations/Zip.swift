//
//  Zip.swift
//  RxSwift
//
//  Created by Krunoslav Zaher on 5/23/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation

protocol ZipSinkProtocol : class
{
    func next(_ index: Int)
    func fail(_ error: ErrorProtocol)
    func done(_ index: Int)
}

class ZipSink<O: ObserverType> : Sink<O>, ZipSinkProtocol {
    typealias Element = O.E
    
    let _arity: Int

    let _lock = RecursiveLock()

    // state
    private var _isDone: [Bool]
    
    init(arity: Int, observer: O) {
        _isDone = [Bool](repeating: false, count: arity)
        _arity = arity
        
        super.init(observer: observer)
    }

    func getResult() throws -> Element {
        abstractMethod()
    }
    
    func hasElements(_ index: Int) -> Bool {
        abstractMethod()
    }
    
    func next(_ index: Int) {
        var hasValueAll = true
        
        for i in 0 ..< _arity {
            if !hasElements(i) {
                hasValueAll = false
                break
            }
        }
        
        if hasValueAll {
            do {
                let result = try getResult()
                self.forwardOn(.next(result))
            }
            catch let e {
                self.forwardOn(.error(e))
                dispose()
            }
        }
        else {
            var allOthersDone = true
            
            let arity = _isDone.count
            for i in 0 ..< arity {
                if i != index && !_isDone[i] {
                    allOthersDone = false
                    break
                }
            }
            
            if allOthersDone {
                forwardOn(.completed)
                self.dispose()
            }
        }
    }
    
    func fail(_ error: ErrorProtocol) {
        forwardOn(.error(error))
        dispose()
    }
    
    func done(_ index: Int) {
        _isDone[index] = true
        
        var allDone = true
        
        for done in _isDone {
            if !done {
                allDone = false
                break
            }
        }
        
        if allDone {
            forwardOn(.completed)
            dispose()
        }
    }
}

class ZipObserver<ElementType>
    : ObserverType
    , LockOwnerType
    , SynchronizedOnType {
    typealias E = ElementType
    typealias ValueSetter = (ElementType) -> ()

    private var _parent: ZipSinkProtocol?
    
    let _lock: RecursiveLock
    
    // state
    private let _index: Int
    private let _this: Disposable
    private let _setNextValue: ValueSetter
    
    init(lock: RecursiveLock, parent: ZipSinkProtocol, index: Int, setNextValue: ValueSetter, this: Disposable) {
        _lock = lock
        _parent = parent
        _index = index
        _this = this
        _setNextValue = setNextValue
    }
    
    func on(_ event: Event<E>) {
        synchronizedOn(event)
    }

    func _synchronized_on(_ event: Event<E>) {
        if let _ = _parent {
            switch event {
            case .next(_):
                break
            case .error:
                _this.dispose()
            case .completed:
                _this.dispose()
            }
        }
        
        if let parent = _parent {
            switch event {
            case .next(let value):
                _setNextValue(value)
                parent.next(_index)
            case .error(let error):
                parent.fail(error)
            case .completed:
                parent.done(_index)
            }
        }
    }
}
