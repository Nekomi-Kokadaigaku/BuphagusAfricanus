//
//  DebugTracked.swift
//  BuphagusAfricanus
//
//  Created by Iris on 2025-02-20.
//

import Foundation
import Combine

@propertyWrapper
public struct DebugTracked<T> {
    private var value: T
    let name: String

    public var wrappedValue: T {
        get { value }
        set {
            value = newValue
            baDebugState.shared.updateWatchVariable(
                name: name,
                value: newValue,
                type: String(describing: type(of: newValue))
            )
        }
    }

    public init(wrappedValue: T, _ name: String) {
        self.value = wrappedValue
        self.name = name
    }
}
@propertyWrapper
public final class PublishedDebugTracked<T> {
    @Published private var publishedValue: T
    let name: String

    public var wrappedValue: T {
        get { publishedValue }
        set {
            publishedValue = newValue
            baDebugState.shared.updateWatchVariable(
                name: name,
                value: newValue,
                type: String(describing: type(of: newValue))
            )
        }
    }

    public var projectedValue: Published<T>.Publisher {
        _publishedValue.projectedValue
    }

    public init(wrappedValue: T, _ name: String) {
        self._publishedValue = Published(wrappedValue: wrappedValue)
        self.name = name
    }
}
