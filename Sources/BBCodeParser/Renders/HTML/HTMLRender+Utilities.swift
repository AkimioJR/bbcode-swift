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

/// 获取字体大小字符串
/// - Parameter attr: 字体大小属性值
/// - Returns: 字体大小字符串，如果为无效值则返回 nil
func fontSizeStyle(from attr: String) -> String? {
    let attr = attr.lowercased()

    // 1. 优先处理纯数字情况
    if let size = UInt(attr), size <= 200 {
        switch size {
        case 1: return "xx-small"
        case 2: return "x-small"
        case 3: return "small"
        case 4: return "medium"
        case 5: return "large"
        case 6: return "x-large"
        case 7: return "xx-large"
        case 50...200: return "\(size)%"
        default: return "\(size)px"  // 处理 8...49
        }
    }

    // 2. 处理带 px 后缀的情况 (增加了数字有效性检查)
    if attr.hasSuffix("px") {
        let numberString = attr.dropLast(2)
        // 确保 px 前面是有效数字 (原代码直接返回，这里更健壮)
        if !numberString.isEmpty, UInt(numberString) != nil {
            return attr  // 保留用户原始输入的大小写
        }
    }

    // 3. 无效输入
    return nil
}

extension String {
    private static let htmlEntities: [Unicode.Scalar: String] = [
        "\"": "&quot;",
        "&": "&amp;",
        "'": "&#39;",
        "<": "&lt;",
        ">": "&gt;",
    ]

    private static let htmlEntityDecodeMap: [String: String] = [
        "&quot;": "\"",
        "&amp;": "&",
        "&#39;": "'",
        "&lt;": "<",
        "&gt;": ">",
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

    /// 解码 HTML 实体，将 &gt; 转换为 >，&lt; 转换为 <，等等
    var stringByDecodingHTML: String {
        var result = self

        // 按照特定顺序替换，确保不会重复处理
        // 注意：&amp; 必须最后处理，以避免影响其他实体的处理
        let entitiesToDecode: [(key: String, value: String)] = [
            ("&quot;", "\""),
            ("&#39;", "'"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&amp;", "&"),  // 必须最后处理
        ]

        for (entity, character) in entitiesToDecode {
            result = result.replacingOccurrences(of: entity, with: character)
        }

        return result
    }
}

enum HTMLAlignment: String {
    case left = "left"
    case center = "center"
    case right = "right"

    init?(_ rawValue: String) {
        switch rawValue.lowercased() {
        case "left":
            self = .left
        case "right":
            self = .right
        case "center":
            self = .center
        default:
            return nil
        }
    }

    func renderHTMLAlignment(_ inner: String) -> String {
        return "<p style=\"text-align: \(self.rawValue);\">\(inner)</p>"
    }
}
