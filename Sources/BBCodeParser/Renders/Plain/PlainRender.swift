import Foundation

@Sendable public func DefaultPlainRender<K: Hashable, V>(_ n: BBNode, _: [K: V]) -> String {
  DefaultPlainRenderImpl(n)
}

@Sendable public func DefaultPlainRenderImpl(_ n: BBNode) -> String {
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
  public func plain<K: Hashable, V>(
    _ bbcode: String,
    args: [K: V] = [:],
    render: @escaping BBRender<K, V, String>,
    parser: BBParser = DefaultBBParser.content,
    tm: BBTagManager = BBTagManager()
  ) throws(BBCodeError) -> String {
    let tree = try parser.parse(bbcode, ctx: BBParserContext(tagManager: tm))
    handleNewlineAndParagraph(node: tree)
    return render(tree, args)
  }

  public func plain(
    _ bbcode: String,
    render: @escaping (BBNode) -> String = DefaultPlainRenderImpl,
    parser: BBParser = DefaultBBParser.content,
    tm: BBTagManager = BBTagManager()
  ) throws(BBCodeError) -> String {
    let tree = try parser.parse(bbcode, ctx: BBParserContext(tagManager: tm))
    handleNewlineAndParagraph(node: tree)
    return render(tree)
  }
}

extension BBNode {
  func renderInnerPlain() -> String {
    var plain = ""
    for n in children {
      plain.append(DefaultPlainRenderImpl(n))
    }
    return plain
  }
}
