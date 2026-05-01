extension DefaultBBParser {
    // 辅助构建上下文的闭包，减少重复代码
    func makeContext(g: BBScanner, ctx: BBParserContext) -> BBErrorContext {
        return BBErrorContext(
            line: g.line,
            column: g.column,
            nodeDetail: unclosedTagDetail(unclosedNode: ctx.currentNode)
        )
    }

    func restoreNodeToPlain(node: BBNode, c: UnicodeScalar, ctx: BBParserContext) {
        node.resetPlain()
        node.value.insert(Character(UnicodeScalar("[")), at: node.value.startIndex)
        node.value.append(Character(c))
    }

    /// 用于未关闭标记错误处理
    func unclosedTagDetail(unclosedNode: BBNode) -> String {
        if unclosedNode.tag == .root {
            // should not be here
            return ""
        }
        var text: String =
            "[" + unclosedNode.value
            + (unclosedNode.attr.isEmpty ? "]" : "=" + unclosedNode.attr + "]")
        for child in unclosedNode.children {
            text = text + nodeContext(node: child)
        }
        return text
    }

    /// 由unclosedTagDetail调用
    func nodeContext(node: BBNode) -> String {
        switch node.tag {
        case .root:
            return ""  // should not be here
        case .plain:
            return node.value

        default:
            if !BBTag.virtualTags.contains(node.tag) && node.tag.isSelfClosing {
                return "[" + node.value + "]"
            } else {
                var text: String =
                    "[" + node.value + (node.attr.isEmpty ? "]" : "=" + node.attr + "]")
                for child in node.children {
                    text = text + nodeContext(node: child)
                }
                text = text + "[/" + node.value + "]"

                return text
            }
        }
    }
}
