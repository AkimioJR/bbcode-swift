import Foundation
import OSLog

public func defaultBBParser(
  _ bbcode: String,
  _ ctx: BBParserContext,
) throws(BBCodeError) -> BBNode {
  var g = bbcode.unicodeScalars.makeIterator()
  var parser: DefaultParser? = .content
  while let p = parser {
    parser = try p.internalParse(&g, ctx)
  }
  if ctx.currentNode.tag == .root {
    return ctx.currentNode
  } else {
    throw .internalError("parse faild")
  }
}

enum DefaultParser {
  case content
  case tag
  case tagClosing
  case attr

  /// 入口解析函数
  func internalParse(
    _ g: inout String.UnicodeScalarView.Iterator,
    _ ctx: BBParserContext
  ) throws(BBCodeError) -> Self? {
    switch self {
    case .content:
      return try parseContent(&g, ctx)
    case .tag:
      return try parseTag(&g, ctx)
    case .tagClosing:
      return try parseTagClosing(&g, ctx)
    case .attr:
      return try parseAttr(&g, ctx)
    }
  }

  /// 解析普通内容
  func parseContent(
    _ g: inout String.UnicodeScalarView.Iterator,
    _ ctx: BBParserContext,
  ) throws(BBCodeError) -> Self? {
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
            throw BBCodeError.unclosedTag(unclosedTagDetail(unclosedNode: ctx.currentNode))
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
    return nil
  }

  /// 解析标签内容
  private func parseTag(
    _ g: inout String.UnicodeScalarView.Iterator,
    _ ctx: BBParserContext,
  ) throws(BBCodeError) -> Self? {
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
    throw BBCodeError.unfinishedOpeningTag(
      unclosedTagDetail(unclosedNode: ctx.currentNode))
  }

  /// 解析闭合标签
  private func parseTagClosing(
    _ g: inout String.UnicodeScalarView.Iterator,
    _ ctx: BBParserContext,
  ) throws(BBCodeError) -> Self? {
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
                // ctx.error = BBCodeError.unpairedTag(
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
    throw .unfinishedClosingTag(unclosedTagDetail(unclosedNode: ctx.currentNode))
  }

  /// 解析属性
  private func parseAttr(
    _ g: inout String.UnicodeScalarView.Iterator,
    _ ctx: BBParserContext,
  ) throws(BBCodeError) -> Self? {
    while let c = g.next() {
      if c == UnicodeScalar("]") {
        return .content
      } else if c == UnicodeScalar("\n") || c == UnicodeScalar("\r") {
        Logger.parser.error("unfinished attr: \(ctx.currentNode.tag.description)")
        throw .unfinishedAttr(unclosedTagDetail(unclosedNode: ctx.currentNode))
      } else {
        ctx.currentNode.attr.append(Character(c))
      }
    }

    //unfinished attr
    Logger.parser.error("unfinished attr: \(ctx.currentNode.tag.description)")
    throw BBCodeError.unfinishedAttr(unclosedTagDetail(unclosedNode: ctx.currentNode))
  }
}
