//
//  UnfairLock.swift
//  NGScrollViewContentExample
//
//  Created by Noah Gilmore on 11/20/19.
//  Copyright © 2019 Noah Gilmore. All rights reserved.
//

import Foundation

public final class UnfairLock: NSObject, NSLocking {
    private var mutex = os_unfair_lock()

    public func lock() {
        os_unfair_lock_lock(&self.mutex)
    }

    public func unlock() {
        os_unfair_lock_unlock(&self.mutex)
    }

    @objc(lock:)
    public func _objcLock(_ closure: () -> Void) {
        self.lock(closure)
    }
}

extension NSLocking {

    /// Convenience helper that calls lock, then the closure, then unlock
    ///
    /// - Parameter closure: critical block of code to call inside area protected by the receiver
    /// - Returns: the value returned from closure
    /// - Throws: the error thrown from the closure
    public func lock<T>(_ closure: () throws -> T) rethrows -> T {
        defer {
            self.unlock()
        }
        self.lock()
        return try closure()
    }

    /// Convenience helper that calls lock, then the closure, then unlock
    ///
    /// - Parameter closure: critical block of code to call inside area protected by the receiver
    /// - Throws: the error thrown from the closure
    public func lock(_ closure: () throws -> Void) rethrows {
        defer {
            self.unlock()
        }
        self.lock()
        try closure()
    }
}
