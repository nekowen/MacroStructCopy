import Macros
import MacroTesting
import SwiftSyntaxMacrosTestSupport
import XCTest

final class StructCopyMacroTests: XCTestCase {
    override func invokeTest() {
        withMacroTesting(
            macros: ["AddCopy": StructCopyMacro.self]
        ) {
            super.invokeTest()
        }
    }

    func test_properties() {
        assertMacro {
            """
            @AddCopy
            public struct Test {
                let property1: String
                let property2: (() -> Void)?
                let property3: Fuga
                var property4: String
                var property5: (() -> Void)?
                var property6: Fuga
            }
            """
        } expansion: {
            """
            public struct Test {
                let property1: String
                let property2: (() -> Void)?
                let property3: Fuga
                var property4: String
                var property5: (() -> Void)?
                var property6: Fuga

                func copy(property1: SCArgument<String> = .noChange, property2: SCArgument<(() -> Void)?> = .noChange, property3: SCArgument<Fuga> = .noChange, property4: SCArgument<String> = .noChange, property5: SCArgument<(() -> Void)?> = .noChange, property6: SCArgument<Fuga> = .noChange) -> Self {
                    return .init(property1: property1.value(self.property1), property2: property2.value(self.property2), property3: property3.value(self.property3), property4: property4.value(self.property4), property5: property5.value(self.property5), property6: property6.value(self.property6))
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
            """
        }
    }

    func test_properties_multilple() {
        assertMacro {
            """
            @AddCopy
            public struct Test {
                let property1: String, property2: (() -> Void)?, property3: Fuga
                var property4: String, property5: (() -> Void)?, property6: Fuga
            }
            """
        } expansion: {
            """
            public struct Test {
                let property1: String, property2: (() -> Void)?, property3: Fuga
                var property4: String, property5: (() -> Void)?, property6: Fuga

                func copy(property1: SCArgument<String> = .noChange, property2: SCArgument<(() -> Void)?> = .noChange, property3: SCArgument<Fuga> = .noChange, property4: SCArgument<String> = .noChange, property5: SCArgument<(() -> Void)?> = .noChange, property6: SCArgument<Fuga> = .noChange) -> Self {
                    return .init(property1: property1.value(self.property1), property2: property2.value(self.property2), property3: property3.value(self.property3), property4: property4.value(self.property4), property5: property5.value(self.property5), property6: property6.value(self.property6))
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
            """
        }
    }

    func test_properties_static() {
        assertMacro {
            """
            @AddCopy
            public struct Test {
                static let property1: Int
                static var property2: Int
                static var property3: Int { 1 }
            }
            """
        } expansion: {
            """
            public struct Test {
                static let property1: Int
                static var property2: Int
                static var property3: Int { 1 }

                func copy() -> Self {
                    return .init()
                }
            }
            """
        }
    }

    func test_propeties_with_default_value() {
        assertMacro {
            """
            @AddCopy
            public struct Test {
                let property1: Int = 1
                let property2: Fuga = .init()
                var property3: Int = 1
                var property4: Fuga = .init()
            }
            """
        } expansion: {
            """
            public struct Test {
                let property1: Int = 1
                let property2: Fuga = .init()
                var property3: Int = 1
                var property4: Fuga = .init()

                func copy(property3: SCArgument<Int> = .noChange, property4: SCArgument<Fuga> = .noChange) -> Self {
                    return .init(property3: property3.value(self.property3), property4: property4.value(self.property4))
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
            """
        }
    }

    func test_properties_with_closure() {
        assertMacro {
            """
            @AddCopy
            public struct Test {
                let property1: Int = {
                    return 1
                }()
                var property2: Int = {
                    return 2
                }()
            }
            """
        } expansion: {
            """
            public struct Test {
                let property1: Int = {
                    return 1
                }()
                var property2: Int = {
                    return 2
                }()

                func copy(property2: SCArgument<Int> = .noChange) -> Self {
                    return .init(property2: property2.value(self.property2))
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
            """
        }
    }

    func test_nest_properties() {
        assertMacro {
            """
            @AddCopy
            public struct Test {
                let property1: Int
                @AddCopy
                public struct Test2 {
                    let property2: Int
                }
            }
            """
        } expansion: {
            """
            public struct Test {
                let property1: Int
                public struct Test2 {
                    let property2: Int

                    func copy(property2: SCArgument<Int> = .noChange) -> Self {
                        return .init(property2: property2.value(self.property2))
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

                func copy(property1: SCArgument<Int> = .noChange) -> Self {
                    return .init(property1: property1.value(self.property1))
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
            """
        }
    }

    func test_no_properties() {
        assertMacro {
            """
            @AddCopy
            public struct Test {}
            """
        } expansion: {
            """
            public struct Test {

                func copy() -> Self {
                    return .init()
                }}
            """
        }
    }

    func test_diagnostics_unsupported_decl() {
        assertMacro {
            """
            @AddCopy
            public class Test {}
            """
        } diagnostics: {
            """
            @AddCopy
            ┬───────
            ╰─ 🛑 Unsupported Declaration. Current support only structure.
            public class Test {}
            """
        }

        assertMacro {
            """
            @AddCopy
            public enum Test {}
            """
        } diagnostics: {
            """
            @AddCopy
            ┬───────
            ╰─ 🛑 Unsupported Declaration. Current support only structure.
            public enum Test {}
            """
        }

        assertMacro {
            """
            @AddCopy
            public protocol Test {}
            """
        } diagnostics: {
            """
            @AddCopy
            ┬───────
            ╰─ 🛑 Unsupported Declaration. Current support only structure.
            public protocol Test {}
            """
        }
    }
}
