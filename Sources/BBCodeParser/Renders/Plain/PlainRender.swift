import Foundation

@Sendable public func defaultPlainRender(_ n: BBNode) -> String {
  switch n.tag {
  case .plain:
    return n.escapedValue
  case .br:
    return "\n"
  case .paragraphStart, .paragraphEnd,
    .code, .quote, .url, .image:
    return ""
  case .root, .center, .left, .right, .align, .list, .listitem,
    .bold, .italic, .font, .underline, .strikethrough, .color, .size:
    return n.renderInnerPlain()
  case .mask:
    let plain = n.renderInnerPlain()
    return Array(repeating: "■", count: plain.count).joined()
  case .ruby:
    let base = n.renderInnerPlain()
    if n.attr.isEmpty {
      return base
    } else {
      return "\(base)(\(n.attr))"
    }
  default:
    return ""
  }
}

extension BBCode {
  public func renderPlain(
    _ bbcode: String,
    using parser: BBParser = defaultBBParser,
    tagManager: BBTagManager = BBTagManager()
  ) throws(BBCodeError) -> String {
    let tree = try parser(bbcode, BBParserContext(tagManager: tagManager))
    handleNewlineAndParagraph(node: tree)
    return defaultPlainRender(tree)
  }
}

extension BBNode {
  func renderInnerPlain() -> String {
    var plain = ""
    for n in children {
      plain.append(defaultPlainRender(n))
    }
    return plain
  }
}
