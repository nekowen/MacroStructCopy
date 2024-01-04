import SwiftDiagnostics
import SwiftSyntax

public enum StructCopyMacroDiagnostic {
    case unsupportedDecl
}

extension StructCopyMacroDiagnostic: DiagnosticMessage {
    func diagnose(at node: some SyntaxProtocol) -> Diagnostic {
        Diagnostic(node: Syntax(node), message: self)
    }

    public var message: String {
        switch self {
        case .unsupportedDecl:
            return "Unsupported Declaration. Current support only structure."
        }
    }

    public var severity: DiagnosticSeverity { .error }

    public var diagnosticID: MessageID {
        MessageID(domain: "Swift", id: "StructCopyMacro.\(self)")
    }
}
