import Foundation

public struct DefaultHTMLRenderArgs {
    var host: String?
    var allowRawHTML: Bool

    public init(host: String? = nil, allowRawHTML: Bool = false) {
        self.host = host
        self.allowRawHTML = allowRawHTML
    }
}

@Sendable public func defaultHTMLRender(
    _ n: BBNode,
    args: DefaultHTMLRenderArgs,
    into buffer: inout String,
) {
    switch n.tag {
    case .plain:
        // Keep code block content escaped, but allow native HTML passthrough in regular plain text.
        if n.parent?.tag == .code {
            buffer.append(n.escapedValue)
        } else {
            buffer.append(n.escapedHTMLValue)
        }
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
        let host = args.host
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
        let host = args.host
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
                "navy", "red", "blue", "purple", "teal", "fuchsia", "aqua", "violet", "pink",
                "lime",
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
    static private let htmlEntities: [Unicode.Scalar: String] = [
        "\"": "&quot;",
        "&": "&amp;",
        "'": "&#39;",
        "<": "&lt;",
        ">": "&gt;",
    ]

    static private func isASCIILetter(_ scalar: Unicode.Scalar) -> Bool {
        return (scalar >= "a" && scalar <= "z") || (scalar >= "A" && scalar <= "Z")
    }

    static private func isASCIIDigit(_ scalar: Unicode.Scalar) -> Bool {
        return scalar >= "0" && scalar <= "9"
    }

    static private func isHTMLTagNameCharacter(_ scalar: Unicode.Scalar) -> Bool {
        return isASCIILetter(scalar) || isASCIIDigit(scalar) || scalar == ":" || scalar == "_"
            || scalar == "-"
    }

    static private func htmlTagEndIndex(startingAt index: String.Index, in text: String) -> String
        .Index?
    {
        guard index < text.endIndex, text[index] == "<" else { return nil }

        var cursor = text.index(after: index)
        guard cursor < text.endIndex else { return nil }

        if text[cursor] == "!" {
            let tail = text[cursor...]
            if tail.hasPrefix("!--") {
                let commentStart = text.index(cursor, offsetBy: 3)
                guard
                    let commentEnd = text.range(
                        of: "-->",
                        range: commentStart..<text.endIndex
                    )?.upperBound
                else {
                    return nil
                }
                return commentEnd
            }
        }

        if text[cursor] == "/" {
            cursor = text.index(after: cursor)
            guard cursor < text.endIndex else { return nil }
        }

        let first = text[cursor]
        guard let firstScalar = first.unicodeScalars.first, first.unicodeScalars.count == 1 else {
            return nil
        }
        guard isASCIILetter(firstScalar) else { return nil }

        cursor = text.index(after: cursor)
        while cursor < text.endIndex {
            let ch = text[cursor]
            guard let scalar = ch.unicodeScalars.first, ch.unicodeScalars.count == 1 else {
                break
            }
            if isHTMLTagNameCharacter(scalar) {
                cursor = text.index(after: cursor)
            } else {
                break
            }
        }

        var quote: Character? = nil
        while cursor < text.endIndex {
            let ch = text[cursor]
            if let currentQuote = quote {
                if ch == currentQuote {
                    quote = nil
                }
            } else {
                if ch == "\"" || ch == "'" {
                    quote = ch
                } else if ch == ">" {
                    return text.index(after: cursor)
                }
            }
            cursor = text.index(after: cursor)
        }

        return nil
    }

    static private func isValidHTMLEntity(startingAt index: String.Index, in text: String) -> Bool {
        // 检测是否为有效的 HTML 实体
        // 格式：&name; 或 &#123; 或 &#xABC;
        guard index < text.endIndex else { return false }

        let afterAmpersand = text.index(after: index)
        guard afterAmpersand < text.endIndex else { return false }

        let firstChar = text[afterAmpersand]

        switch firstChar {
        case "#":
            // 数字实体：&#123; 或 &#xABC;
            let afterHash = text.index(after: afterAmpersand)
            guard afterHash < text.endIndex else { return false }

            let secondChar = text[afterHash]
            var checkIndex = afterHash

            switch secondChar {
            case "x", "X":
                // 16进制：&#xABC;
                checkIndex = text.index(after: checkIndex)
                while checkIndex < text.endIndex && text[checkIndex] != ";" {
                    let c = text[checkIndex]
                    if !((c >= "0" && c <= "9") || (c >= "a" && c <= "f") || (c >= "A" && c <= "F"))
                    {
                        return false
                    }
                    checkIndex = text.index(after: checkIndex)
                }
                return checkIndex < text.endIndex && text[checkIndex] == ";"

            default:
                // 10进制：&#123;
                while checkIndex < text.endIndex && text[checkIndex] != ";" {
                    let c = text[checkIndex]
                    if !(c >= "0" && c <= "9") {
                        return false
                    }
                    checkIndex = text.index(after: checkIndex)
                }
                return checkIndex < text.endIndex && text[checkIndex] == ";"
            }

        default:
            // 命名实体：&name;
            var checkIndex = afterAmpersand
            var nameLength = 0
            while checkIndex < text.endIndex && text[checkIndex] != ";" && nameLength < 32 {
                let c = text[checkIndex]
                if !((c >= "a" && c <= "z") || (c >= "A" && c <= "Z") || (c >= "0" && c <= "9")) {
                    return false
                }
                checkIndex = text.index(after: checkIndex)
                nameLength += 1
            }
            return checkIndex < text.endIndex && text[checkIndex] == ";" && nameLength > 0
        }
    }

    static private func stringByEncodingHTML(from text: String, allowingRawHTMLTags: Bool = false)
        -> String
    {
        var result = ""
        // 性能优化：预分配容量，减少字符串内存重分配
        result.reserveCapacity(text.utf16.count * 2)

        var index = text.startIndex
        while index < text.endIndex {
            let scalar = text.unicodeScalars[index]

            switch scalar {
            // 1. 优先处理 & 符号：检查是否为已转义的 HTML 实体
            case "&":
                if isValidHTMLEntity(startingAt: index, in: text) {
                    // 这是一个有效的 HTML 实体，直接保留
                    result.append("&")
                } else {
                    // 不是实体，需要转义
                    result.append("&amp;")
                }
                index = text.index(after: index)
                continue

            case "<" where allowingRawHTMLTags:
                if let endIndex = htmlTagEndIndex(startingAt: index, in: text) {
                    result.append(contentsOf: text[index..<endIndex])
                    index = endIndex
                    continue
                }
                result.append("&lt;")
                index = text.index(after: index)
                continue

            // 2. 处理其他高频 HTML 实体
            case let s where Self.htmlEntities.keys.contains(s):
                result.append(Self.htmlEntities[s]!)

            // 3. 处理 0x0000-0x0008 控制字符
            case "\0"..<"\t":
                result.append("&#x\(String(UInt32(scalar), radix: 16));")

            // 4. 处理 CJK 及全角字符范围 (直接保留)
            case "\u{3000}"..."\u{303F}",  // CJK 标点
                "\u{3400}"..."\u{4DBF}",  // CJK 扩展 A
                "\u{4E00}"..."\u{9FFF}",  // CJK 统一汉字
                "\u{FF00}"..."\u{FFEF}",  // 全角字符
                "\u{20000}"..."\u{2A6DF}",  // CJK 扩展 B
                "\u{2A700}"..."\u{2B73F}",  // CJK 扩展 C
                "\u{2B740}"..."\u{2B81F}",  // CJK 扩展 D
                "\u{2B820}"..."\u{2CEAF}":  // CJK 扩展 E
                result.append(Character(scalar))

            // 5. 处理 ASCII 0x7E (~) 以上的字符
            case let s where s > "~":
                result.append("&#\(UInt32(s));")

            // 6. 普通 ASCII 字符，直接追加
            default:
                result.append(Character(scalar))
            }

            index = text.index(after: index)
        }

        return result
    }

    var escapedValue: String {
        return Self.stringByEncodingHTML(from: self.value)
    }

    var escapedHTMLValue: String {
        return Self.stringByEncodingHTML(from: self.value, allowingRawHTMLTags: true)
    }

    var escapedAttr: String {
        return Self.stringByEncodingHTML(from: self.attr)
    }

    func renderInnerHTML(_ args: DefaultHTMLRenderArgs, into buffer: inout String) {
        for child in children {
            defaultHTMLRender(child, args: args, into: &buffer)
        }
    }
}

public func renderBBCodeToHTML(
    _ bbcode: String,
    using parser: BBParser = DefaultBBParser(),
    tagManager: BBTagManager = DefaultBBTagManager(),
    args: DefaultHTMLRenderArgs = DefaultHTMLRenderArgs(),
) throws(BBError) -> String {
    let domTree = try parser.parse(bbcode, BBParserContext(with: tagManager))
    handleNewlineAndParagraph(node: domTree)
    var buffer = ""
    buffer.reserveCapacity(bbcode.count * 4)  // 预估 HTML 长度，避免频繁扩容
    defaultHTMLRender(domTree, args: args, into: &buffer)
    return buffer
}

extension BBCode {
    public func renderToHTML(_ bbcode: String, host: String? = nil) throws(BBError) -> String {
        return try renderBBCodeToHTML(
            bbcode,
            using: parser,
            tagManager: tagManager,
            args: DefaultHTMLRenderArgs(),
        )
    }
}
