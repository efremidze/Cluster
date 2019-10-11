//
//  Atomic.swift
//  Cluster
//
//  Created by Lasha Efremidze on 10/10/19.
//  Copyright © 2019 efremidze. All rights reserved.
//

import Foundation

@propertyWrapper
final class Atomic<Value> {
    private let queue = DispatchQueue(label: "Atomic serial queue", attributes: .concurrent)
    
    private var _value: Value
    
    init(wrappedValue value: Value) {
        self._value = value
    }
    
    var wrappedValue: Value {
        get { return load() }
        set { store(newValue: newValue) }
    }
    
    func load() -> Value {
        return queue.sync { _value }
    }
    
    func store(newValue: Value) {
        queue.async(flags: .barrier) { [weak self] in
            self?._value = newValue
        }
    }
}
