//
//  DebugTracked.swift
//  BuphagusAfricanus
//
//  Created by Iris on 2025-02-20.
//

import Combine
import Foundation

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

@propertyWrapper
public final class PublishedDebugTracked1<T> {
    @Published private var publishedValue: T
    let name: String

    public var wrappedValue: T {
        get { publishedValue }
        set {
            publishedValue = newValue
            if baGlobalConfig.shared.isDebugMode {
                baDebugState.shared.updateWatchVariable(
                    name: name,
                    value: newValue,
                    type: String(describing: type(of: newValue))
                )
            }
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

@propertyWrapper
struct Trimmed {
    private var value: String

    var wrappedValue: String {
        get { value }
        set { value = newValue.trimmingCharacters(in: .whitespaces) }
    }

    init(wrappedValue: String) {
        self.value = wrappedValue.trimmingCharacters(in: .whitespaces)
    }
}

// 使用示例
class User {
    @Trimmed var name: String = "  John Doe  " // 会自动去除空格

    func printName() {
        print(name) // 输出: "John Doe"
    }
}

@propertyWrapper
struct Logged<T> {
    private var value: T
    let key: String

    var wrappedValue: T {
        get { value }
        set {
            print("[\(key)] 将要从 \(value) 变更为 \(newValue)")
            value = newValue
            print("[\(key)] 已经变更为 \(value)")
        }
    }

    init(wrappedValue: T, _ key: String) {
        self.value = wrappedValue
        self.key = key
    }
}

// 使用示例
class UserProfile {
    @Logged("用户名") var username: String = ""
    @Logged("年龄") var age: Int = 0

    func updateProfile(name: String, age: Int) {
        self.username = name
        self.age = age
    }
}
