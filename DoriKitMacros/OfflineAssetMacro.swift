//===---*- Greatdori! -*---------------------------------------------------===//
//
// OfflineAssetMacro.swift
//
// This source file is part of the Greatdori! open source project
//
// Copyright (c) 2025 the Greatdori! project authors
// Licensed under Apache License v2.0
//
// See https://greatdori.memz.top/LICENSE.txt for license information
// See https://greatdori.memz.top/CONTRIBUTORS.txt for the list of Greatdori! project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax
import SwiftSyntaxMacros
internal import SwiftDiagnostics
internal import SwiftSyntaxBuilder

public struct OfflineAssetURLMacro: BodyMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
        in context: some MacroExpansionContext
    ) throws -> [CodeBlockItemSyntax] {
        if let body = declaration.body {
            return try expansion(of: node, forBody: body.statements, in: context)
        } else {
            throw DiagnosticsError(diagnostics: [.init(
                node: declaration,
                message: MacroExpansionErrorMessage("Macro expansion requires a body")
            )])
        }
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        providingBodyFor closure: ClosureExprSyntax,
        in context: some MacroExpansionContext
    ) throws -> [CodeBlockItemSyntax] {
        try expansion(of: node, forBody: closure.statements, in: context)
    }
    
    private static func expansion(
        of node: AttributeSyntax,
        forBody body: CodeBlockItemListSyntax,
        in context: some MacroExpansionContext
    ) throws -> [CodeBlockItemSyntax] {
        var behaviorExpr: ExprSyntax?
        if let behaviorRawArg = node.arguments {
            if let behaviorArgList = behaviorRawArg.as(LabeledExprListSyntax.self) {
                if let behaviorArg = behaviorArgList.first {
                    behaviorExpr = behaviorArg.expression
                }
            } else {
                throw DiagnosticsError(diagnostics: [.init(
                    node: behaviorRawArg,
                    message: MacroExpansionErrorMessage("Unsupported argument list")
                )])
            }
        }
        
        let rewriter = OfflineAssetURLRewriter(behaviorExpr: behaviorExpr)
        return body.map {
            rewriter.rewrite($0).cast(CodeBlockItemSyntax.self)
        }
    }
}

// See DoriKit/API/Resource.swift.gyb
private let rewriteNames: Set = [
    "iconImageURL",
    "bannerImageURL",
    "logoImageURL",
    "keyVisualImageURL",
    "coverNormalImageURL",
    "coverAfterTrainingImageURL",
    "thumbNormalImageURL",
    "thumbAfterTrainingImageURL",
    "gachaVoiceURL",
    "animationVideoURL",
    "imageURL",
    "thumbImageURL",
    "jacketImageURL"
]

private class OfflineAssetURLRewriter: SyntaxRewriter {
    let behaviorExpr: ExprSyntax?
    
    init(behaviorExpr: ExprSyntax?) {
        self.behaviorExpr = behaviorExpr
    }
    
    override func visit(_ node: MemberAccessExprSyntax) -> ExprSyntax {
        if rewriteNames.contains(node.declName.baseName.text) && node.parent?.is(FunctionCallExprSyntax.self) != true {
            let newNode = FunctionCallExprSyntax(
                callee: MemberAccessExprSyntax(
                    base: node,
                    period: .periodToken(),
                    name: .identifier("withOfflineAsset")
                )
            ) {
                if let behaviorExpr {
                    LabeledExprSyntax(label: nil, expression: behaviorExpr)
                }
            }
            return ExprSyntax(newNode)
        }
        
        return ExprSyntax(
            node
                .with(\.base, node.base != nil ? self.visit(node.base!) : nil)
                .with(\.declName, self.rewrite(node.declName).cast(DeclReferenceExprSyntax.self))
        )
    }
    
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        if let access = node.calledExpression.as(MemberAccessExprSyntax.self),
           rewriteNames.contains(access.declName.baseName.text),
           node.arguments.first?.label?.text == "in" {
            if node.parent?.is(ForceUnwrapExprSyntax.self) == true {
                let newNode = FunctionCallExprSyntax(
                    callee: MemberAccessExprSyntax(
                        base: ForceUnwrapExprSyntax(expression: node),
                        period: .periodToken(),
                        name: .identifier("withOfflineAsset")
                    )
                ) {
                    if let behaviorExpr {
                        LabeledExprSyntax(label: nil, expression: behaviorExpr)
                    }
                }
                return ExprSyntax(newNode)
            } else {
                let newNode = FunctionCallExprSyntax(
                    callee:MemberAccessExprSyntax(
                        base: OptionalChainingExprSyntax(expression: node),
                        period: .periodToken(),
                        name: .identifier("withOfflineAsset")
                    )
                ) {
                    if let behaviorExpr {
                        LabeledExprSyntax(label: nil, expression: behaviorExpr)
                    }
                }
                return ExprSyntax(newNode)
            }
        }
        
        return ExprSyntax(
            node
                .with(\.arguments, self.visit(node.arguments))
                .with(\.calledExpression, self.visit(node.calledExpression))
                .with(\.trailingClosure, node.trailingClosure != nil ? self.visit(node.trailingClosure!).cast(ClosureExprSyntax.self) : nil)
        )
    }
    
    override func visit(_ node: ForceUnwrapExprSyntax) -> ExprSyntax {
        if let call = node.expression.as(FunctionCallExprSyntax.self),
           let access = call.calledExpression.as(MemberAccessExprSyntax.self),
           rewriteNames.contains(access.declName.baseName.text),
           call.arguments.first?.label?.text == "in" {
            return ExprSyntax(call)
        }
        
        return ExprSyntax(
            node.with(\.expression, self.visit(node.expression))
        )
    }
}
