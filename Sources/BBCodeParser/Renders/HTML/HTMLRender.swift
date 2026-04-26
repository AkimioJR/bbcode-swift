import Foundation

@Sendable public func defaultHTMLRender(_ n: BBNode, args: [String: String]) -> String {
  switch n.tag {
  case .plain:
    return n.escapedValue
  case .br:
    return "<br>"
  case .paragraphStart:
    return "<p>"
  case .paragraphEnd:
    return "</p>"
  case .root:
    return n.renderInnerHTML(args)

  case .center:
    return HTMLAlignment.center.renderHTMLAlignment(n.renderInnerHTML(args))
  case .left:
    return HTMLAlignment.left.renderHTMLAlignment(n.renderInnerHTML(args))
  case .right:
    return HTMLAlignment.right.renderHTMLAlignment(n.renderInnerHTML(args))
  case .align:
    if let align = HTMLAlignment(n.escapedAttr) {
      return align.renderHTMLAlignment(n.renderInnerHTML(args))
    }
    return n.renderInnerHTML(args)

  case .list:
    if n.attr.isEmpty {
      return "<ul>\(n.renderInnerHTML(args))</ul>"
    } else {
      return "<ol>\(n.renderInnerHTML(args))</ol>"
    }
  case .listitem:
    return "<li>\(n.renderInnerHTML(args))</li>"

  case .code:
    return "<div class=\"code\"><pre><code>\(n.renderInnerHTML(args))</code></pre></div>"
  case .quote:
    return "<div class=\"quote\"><blockquote>\(n.renderInnerHTML(args))</blockquote></div>"

  case .url:
    let host = args["host"]
    if n.attr.isEmpty {
      let isPlain = n.children.allSatisfy { $0.tag == .plain }
      if isPlain {
        let link = n.renderInnerHTML(args)
        if let safeLink = safeUrl(url: link, defaultScheme: "https", defaultHost: host) {
          return
            "<a href=\"\(link)\" target=\"_blank\" rel=\"nofollow external noopener noreferrer\">\(safeLink)</a>"
        } else {
          return link
        }
      } else {
        return n.renderInnerHTML(args)
      }
    } else {
      let link = n.escapedAttr
      if let safeLink = safeUrl(url: link, defaultScheme: "https", defaultHost: host) {
        return
          "<a href=\"\(safeLink)\" target=\"_blank\" rel=\"nofollow external noopener noreferrer\">\(n.renderInnerHTML(args))</a>"
      } else {
        return n.renderInnerHTML(args)
      }
    }

  case .image:
    let host = args["host"]
    let content = n.renderInnerHTML(args)
    if let url = safeUrl(url: content, defaultScheme: "https", defaultHost: host) {
      if n.attr.isEmpty {
        return
          "<img src=\"\(url)\" rel=\"noreferrer\" referrerpolicy=\"no-referrer\" alt=\"\" />"
      } else {
        let values = n.attr.components(separatedBy: ",")
        if values.count == 2, let width = UInt(values[0]), let height = UInt(values[1]) {
          return
            "<img src=\"\(url)\" rel=\"noreferrer\" referrerpolicy=\"no-referrer\" alt=\"\" width=\"\(width)\" height=\"\(height)\" />"
        } else {
          return
            "<img src=\"\(url)\" rel=\"noreferrer\" referrerpolicy=\"no-referrer\" alt=\"\(n.escapedAttr)\" />"
        }
      }
    } else {
      return content
    }

  case .bold:
    return "<strong>\(n.renderInnerHTML(args))</strong>"
  case .italic:
    return "<em>\(n.renderInnerHTML(args))</em>"
  case .font:
    if n.attr.isEmpty {
      return n.renderInnerHTML(args)
    } else {
      return "<span style=\"font-family: \(n.escapedAttr);\">\(n.renderInnerHTML(args))</span>"
    }
  case .underline:
    return "<u>\(n.renderInnerHTML(args))</u>"
  case .strikethrough:
    return "<del>\(n.renderInnerHTML(args))</del>"
  case .color:
    if n.attr.isEmpty {
      return "<span style=\"color: black;\">\(n.renderInnerHTML(args))</span>"
    } else {
      var valid = false
      if [
        "black", "green", "silver", "gray", "olive", "white", "yellow", "orange", "maroon",
        "navy", "red", "blue", "purple", "teal", "fuchsia", "aqua", "violet", "pink", "lime",
        "magenta", "brown",
      ].contains(n.attr) {
        valid = true
      } else {
        if n.attr.unicodeScalars.count == 4 || n.attr.unicodeScalars.count == 7 {
          var g = n.attr.unicodeScalars.makeIterator()
          if g.next() == "#" {
            while let c = g.next() {
              if (c >= UnicodeScalar("0") && c <= UnicodeScalar("9"))
                || (c >= UnicodeScalar("a") && c <= UnicodeScalar("f"))
                || (c >= UnicodeScalar("A") && c <= UnicodeScalar("F"))
              {
                valid = true
              } else {
                valid = false
                break
              }
            }
          }
        }
      }
      if valid {
        return "<span style=\"color: \(n.attr);\">\(n.renderInnerHTML(args))</span>"
      } else {
        return "[color=\(n.escapedAttr)]\(n.renderInnerHTML(args))[/color]"
      }
    }
  case .size:
    if n.attr.isEmpty {
      return "<span>\(n.renderInnerHTML(args))</span>"
    } else {
      if let style = fontSizeStyle(from: n.attr) {
        return "<span style=\"font-size: \(style);\">\(n.renderInnerHTML(args))</span>"
      } else {
        return "[size=\(n.escapedAttr)]\(n.renderInnerHTML(args))[/size]"
      }
    }
  case .mask:
    return "<span class=\"mask\">\(n.renderInnerHTML(args))</span>"
  case .ruby:
    if n.attr.isEmpty {
      return n.renderInnerHTML(args)
    } else {
      return "<ruby>\(n.renderInnerHTML(args))<rp>(</rp><rt>\(n.escapedAttr)</rt><rp>)</rp></ruby>"
    }
  default:

    if n.children.isEmpty {
      let startLabel: String
      if n.attr.isEmpty {
        startLabel = "[\(n.tag.label)]"
      } else {
        startLabel = "[\(n.tag.label)=\(n.attr)]"
      }
      return "[\(startLabel)]\(n.value)[/\(n.tag.label)]"
    } else {
      var html: String = ""
      for child in n.children {
        html.append(child.renderInnerPlain())
      }
      return html
    }
  }

}

extension BBNode {
  /// 只有普通的节点值可以直接在渲染中使用，其他标签需要渲染子节点
  ///
  /// Only plain node value is directly usable in render, other tags needs to render subnode.
  var escapedValue: String {
    return self.value.stringByEncodingHTML
  }

  var escapedAttr: String {
    return self.attr.stringByEncodingHTML
  }

  func renderInnerHTML(
    _ args: [String: String]
  ) -> String {
    var html = ""
    for child in children {
      html.append(defaultHTMLRender(child, args: args))
    }
    return html
  }
}

public func renderBBCodeToHTML(
  _ bbcode: String,
  using parser: BBParser = DefaultBBParser(),
  tagManager: BBTagManager = DefaultBBTagManager(),
  host: String? = nil,
) throws(BBError) -> String {
  let decodedBBCode = bbcode.stringByDecodingHTML  // 先解码输入中的 HTML 实体，防止二次编码
  let domTree = try parser.parse(decodedBBCode, BBParserContext(with: tagManager))
  handleNewlineAndParagraph(node: domTree)
  let args: [String: String]
  if let host = host {
    args = ["host": host]
  } else {
    args = [:]
  }
  return defaultHTMLRender(domTree, args: args)
}

extension BBCode {
  public func renderToHTML(_ bbcode: String, host: String? = nil) throws(BBError) -> String {
    return try renderBBCodeToHTML(bbcode, using: parser, tagManager: tagManager, host: host)
  }
}
