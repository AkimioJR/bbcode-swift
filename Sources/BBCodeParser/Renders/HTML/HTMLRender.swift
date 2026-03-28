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
    var html: String
    html = "<p style=\"text-align: center;\">"
    html.append(n.renderInnerHTML(args))
    html.append("</p>")
    return html
  case .left:
    var html: String
    html = "<p style=\"text-align: left;\">"
    html.append(n.renderInnerHTML(args))
    html.append("</p>")
    return html
  case .right:
    var html: String
    html = "<p style=\"text-align: right;\">"
    html.append(n.renderInnerHTML(args))
    html.append("</p>")
    return html
  case .align:
    var html: String
    var align = ""
    switch n.escapedAttr.lowercased() {
    case "left":
      align = "left"
    case "right":
      align = "right"
    case "center":
      align = "center"
    default:
      align = ""
    }
    if align.isEmpty {
      return n.renderInnerHTML(args)
    }
    html = "<p style=\"text-align: \(align);\">"
    html.append(n.renderInnerHTML(args))
    html.append("</p>")
    return html

  case .list:
    var html: String
    if n.attr.isEmpty {
      html = "<ul>"
    } else {
      html = "<ol>"
    }
    html.append(n.renderInnerHTML(args))
    if n.attr.isEmpty {
      html.append("</ul>")
    } else {
      html.append("</ol>")
    }
    return html
  case .listitem:
    var html: String = "<li>"
    html.append(n.renderInnerHTML(args))
    html.append("</li>")
    return html

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
    var html: String
    var link: String
    if n.attr.isEmpty {
      var isPlain = true
      for child in n.children {
        if child.tag != .plain {
          isPlain = false
        }
      }
      if isPlain {
        link = n.renderInnerHTML(args)
        if let safeLink = safeUrl(url: link, defaultScheme: "https", defaultHost: host) {
          html =
            "<a href=\"\(link)\" target=\"_blank\" rel=\"nofollow external noopener noreferrer\">\(safeLink)</a>"
        } else {
          html = link
        }
      } else {
        html = n.renderInnerHTML(args)
      }
    } else {
      link = n.escapedAttr
      if let safeLink = safeUrl(url: link, defaultScheme: "https", defaultHost: host) {
        html =
          "<a href=\"\(safeLink)\" target=\"_blank\" rel=\"nofollow external noopener noreferrer\">\(n.renderInnerHTML(args))</a>"
      } else {
        html = n.renderInnerHTML(args)
      }
    }
    return html

  case .image:
    let host = args["host"]
    var html: String
    let link: String = n.renderInnerHTML(args)
    if let safeLink = safeUrl(url: link, defaultScheme: "https", defaultHost: host) {
      if n.attr.isEmpty {
        html =
          "<img src=\"\(safeLink)\" rel=\"noreferrer\" referrerpolicy=\"no-referrer\" alt=\"\" />"
      } else {
        let values = n.attr.components(separatedBy: ",").compactMap { Int($0) }
        if values.count == 2 && values[0] > 0 && values[0] <= 4096 && values[1] > 0
          && values[1] <= 4096
        {
          html =
            "<img src=\"\(safeLink)\" rel=\"noreferrer\" referrerpolicy=\"no-referrer\" alt=\"\" width=\"\(values[0])\" height=\"\(values[1])\" />"
        } else {
          html =
            "<img src=\"\(safeLink)\" rel=\"noreferrer\" referrerpolicy=\"no-referrer\" alt=\"\(n.escapedAttr)\" />"
        }
      }
      return html
    } else {
      return link
    }

  case .bold:
    var html: String = "<strong>"
    html.append(n.renderInnerHTML(args))
    html.append("</strong>")
    return html
  case .italic:
    var html: String = "<em>"
    html.append(n.renderInnerHTML(args))
    html.append("</em>")
    return html
  case .font:
    var html: String
    if n.attr.isEmpty {
      html = n.renderInnerHTML(args)
    } else {
      html = "<span style=\"font-family: \(n.escapedAttr);\">\(n.renderInnerHTML(args))</span>"
    }
    return html
  case .underline:
    var html: String = "<u>"
    html.append(n.renderInnerHTML(args))
    html.append("</u>")
    return html
  case .strikethrough:
    var html: String = "<del>"
    html.append(n.renderInnerHTML(args))
    html.append("</del>")
    return html
  case .color:
    var html: String
    if n.attr.isEmpty {
      html = "<span style=\"color: black;\">\(n.renderInnerHTML(args))</span>"
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
        html = "<span style=\"color: \(n.attr);\">\(n.renderInnerHTML(args))</span>"
      } else {
        html = "[color=\(n.escapedAttr)]\(n.renderInnerHTML(args))[/color]"
      }
    }
    return html
  case .size:
    var html: String
    if n.attr.isEmpty {
      html = "<span style=\"color: black;\">\(n.renderInnerHTML(args))</span>"
    } else {
      var valid = false
      let size = Int(n.attr)
      if size != nil {
        valid = true
      }
      if valid {
        html =
          "<span style=\"font-size: \(getFontSizeString(size: size!));\">\(n.renderInnerHTML(args))</span>"
      } else {
        html = "[size=\(n.escapedAttr)]\(n.renderInnerHTML(args))[/size]"
      }
    }
    return html
  case .mask:
    var html: String = "<span class=\"mask\">"
    html.append(n.renderInnerHTML(args))
    html.append("</span>")
    return html
  case .ruby:
    var html: String
    if n.attr.isEmpty {
      html = n.renderInnerHTML(args)
    } else {
      html =
        "<ruby>\(n.renderInnerHTML(args))<rp>(</rp><rt>\(n.escapedAttr)</rt><rp>)</rp></ruby>"
    }
    return html
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

extension BBCode {
  public func renderHTML(
    _ bbcode: String,
    using parser: BBParser = defaultBBParser,
    tagManager: BBTagManager = BBTagManager(),
    host: String? = nil,
  ) throws(BBCodeError) -> String {
    let domTree = try parser(bbcode, BBParserContext(tagManager: tagManager))
    handleNewlineAndParagraph(node: domTree)
    let args: [String: String]
    if let host = host {
      args = ["host": host]
    } else {
      args = [:]
    }
    return defaultHTMLRender(domTree, args: args)
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

// func BBCodeToHTML(code: String, textSize: Int) -> String {
//   guard let body = try? BBCode().renderHTML(code, args: ["textSize": textSize]) else {
//     return code
//   }
//   let html = """
//     <!doctype html>
//       <html>
//       <head>
//         <meta charset="utf-8">
//         <meta name='viewport' content='width=device-width, shrink-to-fit=YES' initial-scale='1.0' maximum-scale='1.0' minimum-scale='1.0' user-scalable='no'>
//         <style type="text/css">
//           :root {
//             color-scheme: light dark;
//           }
//           body {
//             font-size: \(textSize)px;
//             font-family: sans-serif;
//           }
//           li:last-child {
//             margin-bottom: 1em;
//           }
//           a {
//             color: #0084B4;
//             text-decoration: none;
//           }
//           span.mask {
//             background-color: #555;
//             color: #555;
//             border-radius: 2px;
//             box-shadow: #555 0 0 5px;
//             -webkit-transition: all .5s linear;
//           }
//           span.mask:hover {
//             color: #FFF;
//           }
//           pre code {
//             border: 1px solid #EEE;
//             border-radius: 0.5em;
//             padding: 1em;
//             display: block;
//             overflow: auto;
//           }
//           blockquote {
//             display: inline-block;
//             color: #666;
//           }
//           blockquote:before {
//             content: open-quote;
//             display: inline;
//             line-height: 0;
//             position: relative;
//             left: -0.5em;
//             color: #CCC;
//             font-size: 1em;
//           }
//           blockquote:after {
//             content: close-quote;
//             display: inline;
//             line-height: 0;
//             position: relative;
//             left: 0.5em;
//             color: #CCC;
//             font-size: 1em;
//           }
//         </style>
//       </head>
//       <body>
//         \(body)
//       </body>
//       </html>
//     """
//   return html
// }
