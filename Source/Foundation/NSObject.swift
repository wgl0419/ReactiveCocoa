//
//  NSObject.swift
//  Rex
//
//  Created by Neil Pankey on 5/28/15.
//  Copyright (c) 2015 Neil Pankey. All rights reserved.
//

import Foundation
import ReactiveCocoa
import enum Result.NoError

extension NSObject {
    /// Creates a strongly-typed producer to monitor `keyPath` via KVO. The caller
    /// is responsible for ensuring that the associated value is castable to `T`.
    ///
    /// Swift classes deriving `NSObject` must declare properties as `dynamic` for
    /// them to work with KVO. However, this is not recommended practice.
    public func rex_producerForKeyPath<T>(keyPath: String) -> SignalProducer<T, NoError> {
        return self.rac_valuesForKeyPath(keyPath, observer: nil)
            .toSignalProducer()
            .map { $0 as! T }
            .flatMapError { error in
                // Errors aren't possible, but the compiler doesn't know that.
                assertionFailure("Unexpected error from KVO signal: \(error)")
                return .empty
        }
    }
    
    /// Creates a signal that will be triggered when the object
    /// is deallocated.
    public final func willDeallocSignal() -> Signal<(), NoError> {
        return self
            .rac_willDeallocSignal()
            .toTriggerSignal()
    }
}

extension SignalProducerType {
    /// Forwards events from `self` until `object` is deallocated,
    /// at which point the returned producer will complete.
    public final func takeUntilObjectDeallocates(object: NSObject) -> SignalProducer<Self.Value, Self.Error> {
        return self.lift { $0.takeUntilObjectDeallocates(object) }
    }    
}

extension SignalType {
    /// Forwards events from `self` until `object` is deallocated,
    /// at which point the returned signal will complete.
    public final func takeUntilObjectDeallocates(object: NSObject) -> Signal<Self.Value, Self.Error> {
        return self.takeUntil(object.willDeallocSignal())
    }
}