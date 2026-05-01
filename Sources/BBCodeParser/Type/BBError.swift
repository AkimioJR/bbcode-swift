import Foundation

/// 错误上下文，携带精准的位置和节点源码信息
public struct BBErrorContext {
    public let line: UInt
    public let column: UInt
    public let nodeDetail: String  // 发生错误时的节点片段内容

    public var locationString: String {
        return "第 \(line) 行, 第 \(column) 列"
    }
}

public enum BBError: Error {
    case internalError(String)
    case unfinishedOpeningTag(tag: BBTag, context: BBErrorContext)
    case unfinishedClosingTag(tag: BBTag, context: BBErrorContext)
    case unfinishedAttr(tag: BBTag, context: BBErrorContext)
    case unpairedTag(tag: BBTag, context: BBErrorContext)
    case unclosedTag(tag: BBTag, context: BBErrorContext)
}

// MARK: - 给用户和 UI 层看的信息 (LocalizedError)
extension BBError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .internalError: return "解析器内部发生错误"
        case .unfinishedOpeningTag(let tag, _): return "标签 [\(tag)] 的起始部分不完整"
        case .unfinishedClosingTag(let tag, _): return "标签 [/\(tag)] 的闭合部分不完整"
        case .unfinishedAttr(let tag, _): return "标签 [\(tag)] 的属性未正确结束"
        case .unpairedTag(let tag, _): return "发现未配对的标签 [\(tag)]"
        case .unclosedTag(let tag, _): return "标签 [\(tag)] 缺少闭合标记"
        }
    }

    public var failureReason: String? {
        switch self {
        case .internalError(let msg): return msg
        case .unfinishedOpeningTag(_, let ctx),
            .unfinishedClosingTag(_, let ctx),
            .unfinishedAttr(_, let ctx),
            .unpairedTag(_, let ctx),
            .unclosedTag(_, let ctx):
            return "在 \(ctx.locationString) 附近解析失败。\n异常片段: \(ctx.nodeDetail)"
        }
    }
}

// MARK: - 给开发者调试看的信息 (CustomDebugStringConvertible)
extension BBError: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .internalError(let msg):
            return "[BBError.internalError] \(msg)"
        case .unfinishedOpeningTag(let tag, let ctx):
            return
                "[BBError.unfinishedOpeningTag] tag='\(tag.debugDescription)', line=\(ctx.line), col=\(ctx.column)\nContext: \(ctx.nodeDetail)"
        case .unfinishedClosingTag(let tag, let ctx):
            return
                "[BBError.unfinishedClosingTag] tag='\(tag.debugDescription)', line=\(ctx.line), col=\(ctx.column)\nContext: \(ctx.nodeDetail)"
        case .unfinishedAttr(let tag, let ctx):
            return
                "[BBError.unfinishedAttr] tag='\(tag.debugDescription)', line=\(ctx.line), col=\(ctx.column)\nContext: \(ctx.nodeDetail)"
        case .unpairedTag(let tag, let ctx):
            return
                "[BBError.unpairedTag] tag='\(tag.debugDescription)', line=\(ctx.line), col=\(ctx.column)\nContext: \(ctx.nodeDetail)"
        case .unclosedTag(let tag, let ctx):
            return
                "[BBError.unclosedTag] tag='\(tag.debugDescription)', line=\(ctx.line), col=\(ctx.column)\nContext: \(ctx.nodeDetail)"
        }
    }
}
