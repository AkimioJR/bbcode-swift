public enum BBTag: String, Sendable, Hashable {
    /// 特殊标签（内部虚拟节点）
    case unknown = "unknown"
    case root = "root"
    case plain = "plain"
    case paragraphStart = "paragraphStart"
    case paragraphEnd = "paragraphEnd"

    /// 换行标签
    case br = "br"

    /// 布局标签
    case center = "center"
    case left = "left"
    case right = "right"
    case align = "align"

    /// 块级标签
    case quote = "quote"
    case code = "code"
    case url = "url"
    case image = "img"

    /// 文本样式标签
    case bold = "b"
    case italic = "i"
    case font = "font"
    case underline = "u"
    case strikethrough = "s"
    case color = "color"
    case size = "size"
    case mask = "mask"
    case ruby = "ruby"

    /// 列表标签
    case list = "list"
    case listitem = "*"

    // static let unsupported: Set<Self> = [.background, .avatar, .float]

    public var isVirtualTags: Bool {
        switch self {
        case .unknown, .root, .plain, .paragraphStart, .paragraphEnd:
            return true
        default:
            return false
        }
    }
    public static let layout: Set<Self> = [
        .center,
        .left,
        .right,
        .align,
    ]
    public var isLayout: Bool {
        return Self.layout.contains(self)
    }
    public static let textStyle: Set<Self> = [
        .bold,
        .italic,
        .font,
        .underline,
        .strikethrough,
        .color,
        .size,
        .ruby,
    ]
    public var isTextStyle: Bool {
        return Self.textStyle.contains(self)
    }

    /// 标签名称
    public var label: String {
        if self.isVirtualTags {
            return ""
        } else {
            return self.rawValue
        }
    }

    /// 是否自闭合（不需要 [/xxx] 结尾）
    /// ** 虚拟标签无效 **
    public var isSelfClosing: Bool {
        switch self {
        case .br, .listitem:
            return true
        default:
            return false
        }
    }

    /// 是否允许属性（如 [color=red] / [url=xxx]）
    /// ** 虚拟标签无效 **
    public var allowAttr: Bool {
        switch self {
        case .url, .image, .font, .color, .size, .align, .ruby:
            return true
        default:
            return false
        }
    }

    /// 是否块级元素（独占一行 / 会换行）
    public var isBlock: Bool {
        switch self {
        case .root, .center, .left, .right, .align,
            .list, .listitem, .code, .quote, .image, .mask:
            return true
        default:
            return false
        }
    }

    /// 允许的子标签
    public var allowedChildren: Set<Self> {
        switch self {
        case .root:
            return [
                .plain, .br, .paragraphStart, .paragraphEnd, .mask, .quote, .code, .url, .image,
                .list,
            ]
        case .center, .left, .right, .quote:
            return [.br, .mask, .quote, .code, .url, .image]
        case .align:
            return [.br, .mask, .size, .quote, .code, .url, .image]
        case .list:
            return [.list, .listitem, .br, .url]
        case .listitem:
            return [.br, .url]
        case .url:
            return [.image, .br]
        case .bold, .italic, .underline, .strikethrough, .color, .size, .font:
            return [.br, .url, .image]
        case .mask, .ruby:
            return [.br]
        case .plain, .br, .paragraphStart, .paragraphEnd, .code, .image, .unknown:
            return []
        // default:
        //     return []
        }
    }

    static public func parseByString(_ label: String) -> Self {
        return Self(rawValue: label.lowercased()) ?? .unknown
    }
}

// MARK: - 打印与调试优化
extension BBTag: CustomStringConvertible, CustomDebugStringConvertible {

    /// 标签描述（用于面向用户的错误提示、普通日志等场景）
    /// 例如：.image 返回 "image"，.paragraphStart 返回 "paragraphStart"
    public var description: String {
        return String(describing: self)
    }

    /// 开发者调试打印（控制台 print / LLDB po 专用）
    /// 包含了 case 名称、是否为虚拟节点、以及真实的原始字符
    public var debugDescription: String {
        if self.isVirtualTags {
            return "[Virtual Tag: \(self)]"
        } else {
            return "[BBTag: \(self) | raw: '\(rawValue)']"
        }
    }
}
