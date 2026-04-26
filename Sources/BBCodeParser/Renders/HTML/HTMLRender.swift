import Foundation

private enum RenderTask {
  case enter(BBNode)
  case exit(BBNode)
}

@Sendable public func defaultHTMLRender(_ root: BBNode, args: [String: String]) -> String {
  var stack: [RenderTask] = [.enter(root)]
  var stringStack: [String] = []

  // 预留足够空间，减少数组动态扩容的开销
  stringStack.reserveCapacity(128)

  while let task = stack.popLast() {
    switch task {
    case .enter(let n):
      stack.append(.exit(n))  // 1. 将退出任务压入栈中（等子节点处理完后执行）
      for child in n.children.reversed() {  // 2. 将子节点逆序压入栈中（保证出栈时是正序处理的）
        stack.append(.enter(child))
      }
    case .exit(let n):  // 此时该节点的所有子节点均已处理完毕，存在 stringStack 的末尾
      var innerHTML = ""
      let childCount = n.children.count
      if childCount > 0 {
        // 从结果栈中取出属于当前节点的所有子节点的 HTML
        let childStrings = stringStack.suffix(childCount)
        innerHTML = childStrings.joined()
        // 移除已合并的子节点字符串
        stringStack.removeLast(childCount)
      }
      let nodeHTML = renderSingleNode(n, innerHTML: innerHTML, args: args)  // 3. 执行具体的标签渲染逻辑，将渲染出的字符串压入 stringStack
      stringStack.append(nodeHTML)
    }
  }

  // 最终栈里只会剩下根节点的渲染结果
  return stringStack.first ?? ""

}
@Sendable private func renderSingleNode(
  _ n: BBNode,
  innerHTML: String,
  args: [String: String]
) -> String {

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
    return innerHTML

  case .center:
    return "<p style=\"text-align: center;\">\(innerHTML)</p>"
  case .left:
    return "<p style=\"text-align: left;\">\(innerHTML)</p>"
  case .right:
    return "<p style=\"text-align: right;\">\(innerHTML)</p>"
  case .align:
    let align: String
    switch n.escapedAttr.lowercased() {
    case "left":
      align = "left"
    case "right":
      align = "right"
    case "center":
      align = "center"
    default:
      return "[align=\(n.escapedAttr)]\(innerHTML)[/align]"
    }
    if align.isEmpty {
      return n.renderInnerHTML(args)
    }
    return "<p style=\"text-align: \(align);\">\(innerHTML)</p>"

  case .list:
    var html: String
    if n.attr.isEmpty {
      return "<ul>\(innerHTML)</ul>"
    } else {
      return "<ol>\(innerHTML)</ol>"
    }

  case .listitem:
    return "<li>\(innerHTML)</li>"

  case .code:
    var html = "<div class=\"code\"><pre><code>"
    html.append(n.renderInnerHTML(args))
    html.append("</code></pre></div>")
    return html
  case .quote:
    var html: String
    html = "<div class=\"quote\"><blockquote>"
    html.append(n.renderInnerHTML(args))
    html.append("</blockquote></div>")
    return html

  case .url:
    let host = args["host"]
    var link: String
    if n.attr.isEmpty {
      // 原逻辑判断子节点是否全为 plain
      let isPlain = n.children.allSatisfy { $0.tag == .plain }
      if isPlain {
        link = innerHTML
        if let safeLink = safeUrl(url: link, defaultScheme: "https", defaultHost: host) {
          return
            "<a href=\"\(link)\" target=\"_blank\" rel=\"nofollow external noopener noreferrer\">\(safeLink)</a>"
        } else {
          return link
        }
      } else {
        return innerHTML
      }
    } else {
      link = n.escapedAttr
      if let safeLink = safeUrl(url: link, defaultScheme: "https", defaultHost: host) {
        return
          "<a href=\"\(safeLink)\" target=\"_blank\" rel=\"nofollow external noopener noreferrer\">\(innerHTML)</a>"
      } else {
        return innerHTML
      }
    }

  case .image:
    let host = args["host"]
    if let url = safeUrl(url: innerHTML, defaultScheme: "https", defaultHost: host) {
      let html: String
      if n.attr.isEmpty {
        html =
          "<img src=\"\(url)\" rel=\"noreferrer\" referrerpolicy=\"no-referrer\" alt=\"\" />"
      } else {
        let values = n.attr.components(separatedBy: ",")
        if values.count == 2, let width = UInt(values[0]), let height = UInt(values[1]) {
          html =
            "<img src=\"\(url)\" rel=\"noreferrer\" referrerpolicy=\"no-referrer\" alt=\"\" width=\"\(width)\" height=\"\(height)\" />"
        } else {
          html =
            "<img src=\"\(url)\" rel=\"noreferrer\" referrerpolicy=\"no-referrer\" alt=\"\(n.escapedAttr)\" />"
        }
      }
      return html
    } else {
      return innerHTML
    }

  case .bold:
    return "<strong>\(innerHTML)</strong>"
  case .italic:
    return "<em>\(innerHTML)</em>"
  case .font:
    if n.attr.isEmpty {
      return innerHTML
    } else {
      return "<span style=\"font-family: \(n.escapedAttr);\">\(innerHTML)</span>"
    }

  case .underline:
    return "<u>\(innerHTML)</u>"
  case .strikethrough:
    return "<del>\(innerHTML)</del>"
  case .color:
    if n.attr.isEmpty {
      return "<span style=\"color: black;\">\(innerHTML)</span>"
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
        return "<span style=\"color: \(n.attr);\">\(innerHTML)</span>"
      } else {
        return "[color=\(n.escapedAttr)]\(innerHTML))[/color]"
      }
    }

  case .size:
    if n.attr.isEmpty {
      return "<span>\(innerHTML)</span>"
    } else {
      if let style = fontSizeStyle(from: n.attr) {
        return "<span style=\"font-size: \(style);\">\(innerHTML)</span>"
      } else {
        return "[size=\(n.escapedAttr)]\(innerHTML)[/size]"
      }
    }

  case .mask:
    return "<span class=\"mask\">\(innerHTML)</span>"
  case .ruby:
    if n.attr.isEmpty {
      return innerHTML
    } else {
      return "<ruby>\(innerHTML)<rp>(</rp><rt>\(n.escapedAttr)</rt><rp>)</rp></ruby>"
    }
  default:
    if n.children.isEmpty {
      let startLabel = n.attr.isEmpty ? "[\(n.tag.label)]" : "[\(n.tag.label)=\(n.attr)]"
      return "\(startLabel)\(n.value)[/\(n.tag.label)]"
    } else {
      // 注意：原代码的 default 包含对子节点调用 renderInnerPlain() 的逻辑
      // 如果你这里只是返回子节点的纯文本拼接，可能需要稍微调整，但通常降级渲染 HTML 直接返回 innerHTML 即可
      return innerHTML
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
