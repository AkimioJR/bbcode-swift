import Foundation

public typealias PlainRender = @Sendable (BBNode, [String: Any]?) -> String

public let DefaultPlainRenders: [BBTag: PlainRender] = [
  .plain: { (n: BBNode, args: [String: Any]?) in
    return n.escapedValue
  },
  .br: { (n: BBNode, args: [String: Any]?) in
    return "\n"
  },
  .paragraphStart: { (n: BBNode, args: [String: Any]?) in
    return ""
  },
  .paragraphEnd: { (n: BBNode, args: [String: Any]?) in
    return ""
  },
  .root: { (n: BBNode, args: [String: Any]?) in
    return n.renderInnerPlain(args)
  },
  .center: { (n: BBNode, args: [String: Any]?) in
    return n.renderInnerPlain(args)
  },
  .left: { (n: BBNode, args: [String: Any]?) in
    return n.renderInnerPlain(args)
  },
  .right: { (n: BBNode, args: [String: Any]?) in
    return n.renderInnerPlain(args)
  },
  .align: { (n: BBNode, args: [String: Any]?) in
    return n.renderInnerPlain(args)
  },
  .list: { (n: BBNode, args: [String: Any]?) in
    return n.renderInnerPlain(args)
  },
  .listitem: { (n: BBNode, args: [String: Any]?) in
    return n.renderInnerPlain(args)
  },
  .code: { (n: BBNode, args: [String: Any]?) in
    return ""
  },
  .quote: { (n: BBNode, args: [String: Any]?) in
    return ""
  },
  .url: { (n: BBNode, args: [String: Any]?) in
    return ""
  },
  .image: { (n: BBNode, args: [String: Any]?) in
    return ""
  },
  .bold: { (n: BBNode, args: [String: Any]?) in
    return n.renderInnerPlain(args)
  },
  .italic: { (n: BBNode, args: [String: Any]?) in
    return n.renderInnerPlain(args)
  },
  .font: { (n: BBNode, args: [String: Any]?) in
    return n.renderInnerPlain(args)
  },
  .underline: { (n: BBNode, args: [String: Any]?) in
    return n.renderInnerPlain(args)
  },
  .strikethrough: { (n: BBNode, args: [String: Any]?) in
    return n.renderInnerPlain(args)
  },
  .color: { (n: BBNode, args: [String: Any]?) in
    return n.renderInnerPlain(args)
  },
  .size: { (n: BBNode, args: [String: Any]?) in
    return n.renderInnerPlain(args)
  },
  .mask: { (n: BBNode, args: [String: Any]?) in
    let plain = n.renderInnerPlain(args)
    return Array(repeating: "■", count: plain.count).joined()
  },
  .ruby: { (n: BBNode, args: [String: Any]?) in
    let base = n.renderInnerPlain(args)
    if n.attr.isEmpty {
      return base
    } else {
      return "\(base)(\(n.attr))"
    }
  },
]

extension BBCode {
  public func plain(
    _ bbcode: String,
    args: [String: Any]? = nil,
    plainRenders: [BBTag: PlainRender] = DefaultPlainRenders,
    parser: BBParser = DefaultBBParser.content,
    tm: BBTagManager = BBTagManager()
  ) throws(BBCodeError) -> String {
    let tree = try parser.parse(bbcode, ctx: BBParserContext(tagManager: tm))
    handleNewlineAndParagraph(node: tree)
    let render = plainRenders[tree.tag]!
    return render(tree, args)
  }
}

extension BBNode {
  func renderInnerPlain(_ args: [String: Any]?) -> String {
    var plain = ""
    for n in children {
      if let render = DefaultPlainRenders[n.tag] {
        plain.append(render(n, args))
      }
    }
    return plain
  }
}
