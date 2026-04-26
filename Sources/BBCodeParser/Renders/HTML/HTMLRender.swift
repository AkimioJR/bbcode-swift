import Foundation

@Sendable public func defaultHTMLRender(
  _ n: BBNode,
  args: [String: String],
  into buffer: inout String,
) {
  switch n.tag {
  case .plain:
    buffer.append(n.escapedValue)
  case .br:
    buffer.append("<br>")
  case .paragraphStart:
    buffer.append("<p>")
  case .paragraphEnd:
    buffer.append("</p>")
  case .root:
    return n.renderInnerHTML(args, into: &buffer)

  case .center:
    HTMLAlignment.center.renderHTMLAlignment(n, args: args, into: &buffer)
  case .left:
    HTMLAlignment.left.renderHTMLAlignment(n, args: args, into: &buffer)
  case .right:
    HTMLAlignment.right.renderHTMLAlignment(n, args: args, into: &buffer)
  case .align:
    if let align = HTMLAlignment(n.escapedAttr) {
      align.renderHTMLAlignment(n, args: args, into: &buffer)
    } else {
      n.renderInnerHTML(args, into: &buffer)
    }

  case .list:
    if n.attr.isEmpty {
      buffer.append("<ul>")
      n.renderInnerHTML(args, into: &buffer)
      buffer.append("</ul>")
    } else {
      buffer.append("<ol>")
      n.renderInnerHTML(args, into: &buffer)
      buffer.append("</ol>")
    }
  case .listitem:
    buffer.append("<li>")
    n.renderInnerHTML(args, into: &buffer)
    buffer.append("</li>")

  case .code:
    buffer.append("<div class=\"code\"><pre><code>")
    n.renderInnerHTML(args, into: &buffer)
    buffer.append("</code></pre></div>")

  case .quote:
    buffer.append("<div class=\"quote\"><blockquote>")
    n.renderInnerHTML(args, into: &buffer)
    buffer.append("</blockquote></div>")

  case .url:
    let host = args["host"]
    if n.attr.isEmpty {
      let isPlain = n.children.allSatisfy { $0.tag == .plain }
      if isPlain {
        var link = ""
        n.renderInnerHTML(args, into: &link)
        if let safeLink = safeUrl(url: link, defaultScheme: "https", defaultHost: host) {
          buffer.append(
            "<a href=\"\(link)\" target=\"_blank\" rel=\"nofollow external noopener noreferrer\">\(safeLink)</a>"
          )
        } else {
          buffer.append(link)
        }
      } else {
        n.renderInnerHTML(args, into: &buffer)
      }
    } else {
      let link = n.escapedAttr
      if let safeLink = safeUrl(url: link, defaultScheme: "https", defaultHost: host) {
        buffer.append(
          "<a href=\"\(safeLink)\" target=\"_blank\" rel=\"nofollow external noopener noreferrer\">"
        )
        n.renderInnerHTML(args, into: &buffer)
        buffer.append("</a>")
      } else {
        n.renderInnerHTML(args, into: &buffer)
      }
    }

  case .image:
    let host = args["host"]
    var content = ""
    n.renderInnerHTML(args, into: &content)
    if let url = safeUrl(url: content, defaultScheme: "https", defaultHost: host) {
      if n.attr.isEmpty {
        buffer.append(
          "<img src=\"\(url)\" rel=\"noreferrer\" referrerpolicy=\"no-referrer\" alt=\"\" />"
        )
      } else {
        let values = n.attr.components(separatedBy: ",")
        if values.count == 2, let width = UInt(values[0]), let height = UInt(values[1]) {
          buffer.append(
            "<img src=\"\(url)\" rel=\"noreferrer\" referrerpolicy=\"no-referrer\" alt=\"\" width=\"\(width)\" height=\"\(height)\" />"
          )
        } else {
          buffer.append(
            "<img src=\"\(url)\" rel=\"noreferrer\" referrerpolicy=\"no-referrer\" alt=\"\(n.escapedAttr)\" />"
          )

        }
      }
    } else {
      buffer.append(content)
    }

  case .bold:
    buffer.append("<strong>")
    n.renderInnerHTML(args, into: &buffer)
    buffer.append("</strong>")
  case .italic:
    buffer.append("<em>")
    n.renderInnerHTML(args, into: &buffer)
    buffer.append("</em>")
  case .font:
    if n.attr.isEmpty {
      n.renderInnerHTML(args, into: &buffer)
    } else {
      buffer.append("<span style=\"font-family: \(n.escapedAttr);\">")
      n.renderInnerHTML(args, into: &buffer)
      buffer.append("</span>")
    }
  case .underline:
    buffer.append("<u>")
    n.renderInnerHTML(args, into: &buffer)
    buffer.append("</u>")
  case .strikethrough:
    buffer.append("<del>")
    n.renderInnerHTML(args, into: &buffer)
    buffer.append("</del>")
  case .color:
    if n.attr.isEmpty {
      buffer.append("<span style=\"color: black;\">")
      n.renderInnerHTML(args, into: &buffer)
      buffer.append("</span>")
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
        buffer.append("<span style=\"color: \(n.attr);\">")
        n.renderInnerHTML(args, into: &buffer)
        buffer.append("</span>")
      } else {
        buffer.append("[color=\(n.escapedAttr)]")
        n.renderInnerHTML(args, into: &buffer)
        buffer.append("[/color]")
      }
    }
  case .size:
    if n.attr.isEmpty {
      buffer.append("<span>")
      n.renderInnerHTML(args, into: &buffer)
      buffer.append("</span>")
    } else {
      if let style = fontSizeStyle(from: n.attr) {
        buffer.append("<span style=\"font-size: \(style);\">")
        n.renderInnerHTML(args, into: &buffer)
        buffer.append("</span>")
      } else {
        buffer.append("[size=\(n.escapedAttr)]")
        n.renderInnerHTML(args, into: &buffer)
        buffer.append("[/size]")
      }
    }
  case .mask:
    buffer.append("<span class=\"mask\">")
    n.renderInnerHTML(args, into: &buffer)
    buffer.append("</span>")
  case .ruby:
    if n.attr.isEmpty {
      n.renderInnerHTML(args, into: &buffer)
    } else {
      buffer.append("<ruby>")
      n.renderInnerHTML(args, into: &buffer)
      buffer.append("<rp>(</rp><rt>\(n.escapedAttr)</rt><rp>)</rp></ruby>")
    }
  default:

    if n.children.isEmpty {
      let startLabel: String
      if n.attr.isEmpty {
        startLabel = "[\(n.tag.label)]"
      } else {
        startLabel = "[\(n.tag.label)=\(n.attr)]"
      }
      buffer.append("[\(startLabel)]\(n.value)[/\(n.tag.label)]")
    } else {
      var html: String = ""
      for child in n.children {
        html.append(child.renderInnerPlain())
      }
      buffer.append(html)
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

  func renderInnerHTML(_ args: [String: String], into buffer: inout String) {
    for child in children {
      defaultHTMLRender(child, args: args, into: &buffer)
    }
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
  var buffer = ""
  buffer.reserveCapacity(bbcode.count * 4)  // 预估 HTML 长度，避免频繁扩容
  defaultHTMLRender(domTree, args: args, into: &buffer)
  return buffer
}

extension BBCode {
  public func renderToHTML(_ bbcode: String, host: String? = nil) throws(BBError) -> String {
    return try renderBBCodeToHTML(bbcode, using: parser, tagManager: tagManager, host: host)
  }
}
