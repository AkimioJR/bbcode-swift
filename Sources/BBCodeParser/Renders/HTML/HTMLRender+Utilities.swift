import Foundation

func safeUrl(url: String, defaultScheme: String?, defaultHost: String?) -> String? {
    if var components = URLComponents(string: url) {
        if components.scheme == nil {
            if defaultScheme != nil {
                components.scheme = defaultScheme!
            } else {
                return nil
            }
        }
        if components.host == nil {
            if defaultHost != nil {
                components.host = defaultHost!
            } else {
                return nil
            }
        }
        return components.url?.absoluteString
    }
    return nil
}

func getFontSizeString(size: Int) -> String {
    switch size {
    case 1:
        return "x-small"
    case 2:
        return "small"
    case 3:
        return "medium"
    case 4:
        return "large"
    case 5:
        return "x-large"
    case 6:
        return "xx-large"
    case 7:
        return "xxx-large"
    default:
        return "\(size)px"
    }
}

extension String {
    private static let htmlEntities: [Unicode.Scalar: String] = [
        "\"": "&quot;",
        "&": "&amp;",
        "'": "&#39;",
        "<": "&lt;",
        ">": "&gt;",
    ]

    var stringByEncodingHTML: String {
        var result = ""
        // 性能优化：预分配容量，减少字符串内存重分配
        result.reserveCapacity(utf16.count * 2)

        for scalar in unicodeScalars {
            switch scalar {
            // 1. 优先处理高频 HTML 实体转义
            case let s where Self.htmlEntities.keys.contains(s):
                result.append(Self.htmlEntities[s]!)

            // 2. 处理 0x0000-0x0008 控制字符
            case "\0"..<"\t":
                result.append("&#x\(String(UInt32(scalar), radix: 16));")

            // 3. 处理 CJK 及全角字符范围 (直接保留)
            case "\u{3000}"..."\u{303F}",  // CJK 标点
                "\u{3400}"..."\u{4DBF}",  // CJK 扩展 A
                "\u{4E00}"..."\u{9FFF}",  // CJK 统一汉字
                "\u{FF00}"..."\u{FFEF}",  // 全角字符
                "\u{20000}"..."\u{2A6DF}",  // CJK 扩展 B
                "\u{2A700}"..."\u{2B73F}",  // CJK 扩展 C
                "\u{2B740}"..."\u{2B81F}",  // CJK 扩展 D
                "\u{2B820}"..."\u{2CEAF}":  // CJK 扩展 E
                result.append(Character(scalar))

            // 4. 处理 ASCII 0x7E (~) 以上的字符
            case let s where s > "~":
                result.append("&#\(UInt32(s));")

            // 5. 普通 ASCII 字符，直接追加
            default:
                result.append(Character(scalar))
            }
        }

        return result
    }
}
