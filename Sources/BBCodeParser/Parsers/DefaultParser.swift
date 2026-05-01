import Foundation
import OSLog

public class DefaultBBParser {
  public init() {}

  enum ParserState {
    case content  // 解析普通内容
    case tag  // 解析标签内容
    case tagClosing  // 解析闭合标签
    case attr  // 解析标签属性
    case end  // 解析结束
  }

  /// 解析普通内容
  func parseContent(
    _ g: inout BBScanner,
    _ ctx: BBParserContext,
  ) throws(BBError) -> ParserState {
    var newNode = BBNode(
      tag: .plain, parent: ctx.currentNode, tagManager: ctx.tagManager)
    ctx.currentNode.children.append(newNode)
    var lastWasCR = false
    while let c = g.next() {
      if c == UnicodeScalar("\n") || c == UnicodeScalar("\r") {
        if let allowedChildren = ctx.currentNode.description?.allowedChildren,
          allowedChildren.contains(.br)
        {
          if c == UnicodeScalar("\r") || (c == UnicodeScalar("\n") && !lastWasCR) {
            if newNode.value.isEmpty {
              ctx.currentNode.children.removeLast()
            }
            newNode = BBNode(tag: .br, parent: ctx.currentNode, tagManager: ctx.tagManager)
            ctx.currentNode.children.append(newNode)
            newNode = BBNode(tag: .plain, parent: ctx.currentNode, tagManager: ctx.tagManager)
            ctx.currentNode.children.append(newNode)
          }

          if c == UnicodeScalar("\r") {
            lastWasCR = true
          } else {
            lastWasCR = false
          }
        } else {
          if ctx.currentNode.tag == .code {
            newNode.value.append(Character(c))
          } else {
            Logger.parser.error("unclosed tag: \(ctx.currentNode.tag.description)")
            throw .unclosedTag(
              tag: ctx.currentNode.tag,
              context: makeContext(g: g, ctx: ctx)
            )
          }
        }
      } else {
        lastWasCR = false

        if c == UnicodeScalar("[") {  // <tag_start>
          if ctx.currentNode.description?.allowedChildren != nil {
            if newNode.value.isEmpty {
              ctx.currentNode.children.removeLast()
            }
            return .tag
          } else if !ctx.currentNode.paired {
            return .tag
          } else {
            newNode.value.append(Character(c))
          }
        } else {  // <content>
          newNode.value.append(Character(c))
        }
      }
    }
    if ctx.currentNode.tag != .root {
      if let p = ctx.currentNode.parent {
        ctx.currentNode = p
        return .content
      } else {
        // unfinished without parent
        // This should never happen
        Logger.parser.error("unfinished without parent: \(ctx.currentNode.tag.description)")
        throw .internalError("bug")
      }
    }
    return .end
  }

  /// 解析标签内容
  private func parseTag(
    _ g: inout BBScanner,
    _ ctx: BBParserContext,
  ) throws(BBError) -> ParserState {
    //<opening_tag> ::= <opening_tag_1> | <opening_tag_2>
    let newNode = BBNode(tag: .unknown, parent: ctx.currentNode, tagManager: ctx.tagManager)
    ctx.currentNode.children.append(newNode)

    var index: UInt = 0
    let tagNameMaxLength: UInt = 8
    var isFirst: Bool = true

    while let c = g.next() {
      if isFirst && c == UnicodeScalar("/") {
        if !ctx.currentNode.paired {
          //<closing_tag> ::= <tag_start> '/' <tag_name> <tag_end>
          ctx.currentNode.children.removeLast()
          return .tagClosing
        } else {
          // illegal syntax, may be an unpaired closing tag, treat it as plain text
          restoreNodeToPlain(node: newNode, c: c, ctx: ctx)
          return .content
        }
      } else if c == UnicodeScalar("=") {
        //<opening_tag_2> ::= <tag_prefix> '=' <attr> <tag_end>
        if let tag = ctx.tagManager.getTag(newNode.value),
          let desc = ctx.tagManager.getDescription(tag)
        {
          newNode.setTag(tag: tag, desc: desc)
          if let allowedChildren = ctx.currentNode.description?.allowedChildren,
            allowedChildren.contains(newNode.tag)
          {
            if (newNode.description?.allowAttr)! {
              newNode.paired = false  //isSelfClosing tag has no attr, so its must be not paired
              ctx.currentNode = newNode
              return .attr
            }
          }
        }
        restoreNodeToPlain(node: newNode, c: c, ctx: ctx)
        return .content
      } else if c == UnicodeScalar("]") {
        //<tag> ::= <opening_tag_1> | <opening_tag> <content> <closing_tag>
        if let tag = ctx.tagManager.getTag(newNode.value),
          let desc = ctx.tagManager.getDescription(tag)
        {
          newNode.setTag(tag: tag, desc: desc)
          if let allowedChildren = ctx.currentNode.description?.allowedChildren,
            allowedChildren.contains(newNode.tag)
          {
            if (newNode.description?.isSelfClosing)! {
              //<opening_tag_1> ::= <tag_prefix> <tag_end>
              return .content
            } else {
              //<opening_tag> <content> <closing_tag>
              newNode.paired = false
              ctx.currentNode = newNode
              return .content
            }
          }
        }
        restoreNodeToPlain(node: newNode, c: c, ctx: ctx)
        return .content
      } else if c == UnicodeScalar("[") {
        // illegal syntax, treat it as plain text, and restart tag parsing from this new position
        newNode.resetPlain()
        newNode.value.insert(Character(UnicodeScalar("[")), at: newNode.value.startIndex)
        return .tag
      } else {
        if index < tagNameMaxLength {
          newNode.value.append(Character(c))
        } else {
          // no such tag
          restoreNodeToPlain(node: newNode, c: c, ctx: ctx)
          return .content
        }
      }
      index += 1
      isFirst = false
    }

    Logger.parser.error("unfinished opening tag: \(ctx.currentNode.tag.description)")
    throw .unfinishedOpeningTag(
      tag: ctx.currentNode.tag,
      context: makeContext(g: g, ctx: ctx)
    )
  }

  /// 解析闭合标签
  private func parseTagClosing(
    _ g: inout BBScanner,
    _ ctx: BBParserContext,
  ) throws(BBError) -> ParserState {
    var tagName: String = ""
    while let c = g.next() {
      if c == UnicodeScalar("]") {
        if !tagName.isEmpty && tagName == ctx.currentNode.value {
          ctx.currentNode.paired = true
          guard let p = ctx.currentNode.parent else {
            // should not happen
            Logger.parser.error("bug: \(ctx.currentNode.tag.description)")
            throw .internalError("bug")
          }
          ctx.currentNode = p
          return .content
        } else {
          if let allowedChildren = ctx.currentNode.description?.allowedChildren {
            if let tag = ctx.tagManager.getTag(tagName) {
              if allowedChildren.contains(tag) {
                // not paired tag
                Logger.parser.error("unpaired tag: \(ctx.currentNode.tag.description)")
                // ctx.error = BBError.unpairedTag(
                //   unclosedTagDetail(unclosedNode: ctx.currentNode))
                return .content
              }
            }
          }

          let newNode = BBNode(
            tag: .plain, parent: ctx.currentNode, tagManager: ctx.tagManager)
          newNode.value = "[/" + tagName + "]"
          ctx.currentNode.children.append(newNode)
          return .content
        }
      } else if c == UnicodeScalar("[") {
        // illegal syntax, treat it as plain text, and restart tag parsing from this new position
        let newNode = BBNode(tag: .plain, parent: ctx.currentNode, tagManager: ctx.tagManager)
        newNode.value = "[/" + tagName
        ctx.currentNode.children.append(newNode)
        return .tag
      } else if c == UnicodeScalar("=") {
        // illegal syntax, treat it as plain text
        let newNode = BBNode(tag: .plain, parent: ctx.currentNode, tagManager: ctx.tagManager)
        newNode.value = "[/" + tagName + "="
        ctx.currentNode.children.append(newNode)
        return .content
      } else {
        tagName.append(Character(c))
      }
    }

    Logger.parser.error("unfinished closing tag: \(ctx.currentNode.tag.description)")
    throw .unfinishedClosingTag(
      tag: ctx.currentNode.tag,
      context: makeContext(g: g, ctx: ctx)
    )
  }

  /// 解析属性
  private func parseAttr(
    _ g: inout BBScanner,
    _ ctx: BBParserContext,
  ) throws(BBError) -> ParserState {
    while let c = g.next() {
      if c == UnicodeScalar("]") {
        return .content
      } else if c == UnicodeScalar("\n") || c == UnicodeScalar("\r") {
        Logger.parser.error("unfinished attr: \(ctx.currentNode.tag.description)")
        throw .unfinishedAttr(
          tag: ctx.currentNode.tag,
          context: makeContext(g: g, ctx: ctx)
        )
      } else {
        ctx.currentNode.attr.append(Character(c))
      }
    }

    //unfinished attr
    Logger.parser.error("unfinished attr: \(ctx.currentNode.tag.description)")
    throw .unfinishedAttr(
      tag: ctx.currentNode.tag,
      context: makeContext(g: g, ctx: ctx)
    )
  }

}

extension DefaultBBParser: BBParser {
  public func parse(_ bbcode: String, _ ctx: BBParserContext) throws(BBError) -> BBNode {
    var g = BBScanner(bbcode)

    var state: ParserState = .content
    repeat {
      switch state {
      case .content:
        state = try parseContent(&g, ctx)
      case .tag:
        state = try parseTag(&g, ctx)
      case .tagClosing:
        state = try parseTagClosing(&g, ctx)
      case .attr:
        state = try parseAttr(&g, ctx)
      case .end:
        break
      }
    } while state != .end

    if ctx.currentNode.tag == .root {
      return ctx.currentNode
    } else {
      throw .internalError("parse failed")
    }
  }
}
