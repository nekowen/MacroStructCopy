# StructCopyMacro

[![Test](https://github.com/nekowen/StructCopyMacro/actions/workflows/run-test.yml/badge.svg)](https://github.com/nekowen/StructCopyMacro/actions/workflows/run-test.yml)

Swift macros automatically generates a copy function that can modify structure properties.

## Usage

Annotate a struct with `@AddCopy`. it will add a copy function and dedicated Enum used in the argument to inline structure.

> [!NOTE]
> The copy function uses the Memberwise initializer. If the structure has the original initializer, you need to manually add the same initializer as the Memberwise initializer.

```swift
struct Example {
    let value1: Int
    let value2: String?
    
    /** Expanded Code below **/
    func copy(id: SCArgument<Int> = .noChange, name: SCArgument<String?> = .noChange) -> Self {
        return .init(id: id.value(self.id), name: name.value(self.name))
    }
    
    enum SCArgument<T> {
        case noChange
        case value(T)
        
        func value(_ currentValue: T) -> T {
            switch self {
            case .noChange:
                return currentValue
            case let .value(val):
                return val
            }
        }
    }
}
```

Copy function arguments have a default value `noChange` case. If the omitted argument, properties are inherited by the newly generated structure.

```swift
let oldData = Example(id: 1, name: "John")
let newData = data.copy() // Example(id: 1, name: Optional("John"))
```

If the specified argument uses the `value` case, overwritten into the newly generated structure.

```swift
let oldData = Example(id: 1, name: "John")
let newData = data.copy(id: .value(2)) // Example(id: 2, name: Optional("John"))

// or

let newData = data.copy(name: .value(nil)) // Example(id: 1, name: nil)
```

## Installation

Add a dependency in Package.swift.

```swift
dependencies: [
    .package(url: "https://github.com/nekowen/StructCopyMacro.git", from: "0.1.0")
]
```

## License

Distributed under the MIT License. See [LICENSE](https://github.com/nekowen/StructCopyMacro/blob/main/LICENSE) for more information.