import SwiftCompilerPlugin
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct StructCopyMacro: MemberMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        guard declaration.kind == .structDecl else {
            context.diagnose(StructCopyMacroDiagnostic.unsupportedDecl.diagnose(at: node))
            return []
        }

        let storedProperties = extractStoredProperty(declaration)
        return [
            buildCopyFunction(storedProperties),
            buildSCArgumentEnum(storedProperties),
        ]
    }

    private static func mapStoredProperties(_ variableDecl: VariableDeclSyntax) -> [StoredProperty] {
        return variableDecl.bindings.compactMap { (binding: PatternBindingSyntax) -> StoredProperty? in
            guard isStoredProperty(variableDecl, binding: binding) else {
                return nil
            }

            let typeAnnotation = binding.typeAnnotation!
            return StoredProperty(type: typeAnnotation.type.trimmedDescription, identifier: binding.pattern.trimmedDescription)
        }
    }

    private static func isStoredProperty(_ variableDecl: VariableDeclSyntax, binding: PatternBindingSyntax) -> Bool {
        guard variableDecl.modifiers.allSatisfy({ $0.name.text != "static" }), // ignore static properties
              !(variableDecl.bindingSpecifier.text == "let" && binding.initializer != nil), // ignore let and set default value properties
              binding.accessorBlock == nil // ignore computed properties
        else {
            return false
        }

        guard binding.typeAnnotation != nil else {
            return false
        }

        return true
    }

    private static func extractStoredProperty(_ declGroupSyntax: DeclGroupSyntax) -> [StoredProperty] {
        let result: [StoredProperty] = declGroupSyntax.memberBlock.members
            .compactMap { (members: MemberBlockItemSyntax) -> VariableDeclSyntax? in members.decl.as(VariableDeclSyntax.self) }
            .flatMap { (variableDeclSyntax: VariableDeclSyntax) -> [StoredProperty] in mapStoredProperties(variableDeclSyntax) }

        return result
    }

    private static func buildCopyFunction(_ storedProperties: [StoredProperty]) -> DeclSyntax {
        DeclSyntax(
            FunctionDeclSyntax(
                name: TokenSyntax.identifier("copy"),
                signature: FunctionSignatureSyntax(
                    parameterClause: FunctionParameterClauseSyntax(
                        parameters: FunctionParameterListSyntax {
                            for property in storedProperties {
                                FunctionParameterSyntax(
                                    firstName: .identifier(property.identifier),
                                    colon: .colonToken(),
                                    type: IdentifierTypeSyntax(
                                        name: "SCArgument",
                                        genericArgumentClause: GenericArgumentClauseSyntax(arguments: GenericArgumentListSyntax {
                                            .init(argument: IdentifierTypeSyntax(name: .identifier(property.type)))
                                        })
                                    ),
                                    defaultValue: InitializerClauseSyntax(value: MemberAccessExprSyntax(name: "noChange"))
                                )
                            }
                        }
                    ),
                    returnClause: ReturnClauseSyntax(
                        type: IdentifierTypeSyntax(name: "Self")
                    )
                )
            ) {
                ReturnStmtSyntax(
                    expression: SequenceExprSyntax {
                        FunctionCallExprSyntax(
                            calledExpression: MemberAccessExprSyntax(name: "init"),
                            leftParen: .leftParenToken(),
                            arguments: LabeledExprListSyntax {
                                for property in storedProperties {
                                    LabeledExprSyntax(
                                        label: .identifier(property.identifier),
                                        colon: .colonToken(),
                                        expression: FunctionCallExprSyntax(
                                            calledExpression: MemberAccessExprSyntax(base: DeclReferenceExprSyntax(baseName: .identifier(property.identifier)), name: "value"),
                                            leftParen: .leftParenToken(),
                                            arguments: LabeledExprListSyntax {
                                                LabeledExprSyntax(expression: MemberAccessExprSyntax(base: DeclReferenceExprSyntax(baseName: "self"), name: .identifier(property.identifier)))
                                            },
                                            rightParen: .rightParenToken()
                                        )
                                    )
                                }
                            },
                            rightParen: .rightParenToken()
                        )
                    }
                )
            }
        )
    }

    private static func buildSCArgumentEnum(_ storedProperties: [StoredProperty]) -> DeclSyntax {
        guard !storedProperties.isEmpty else {
            return DeclSyntax(stringLiteral: "")
        }

        return DeclSyntax(
            """
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
            """
        )
    }
}
