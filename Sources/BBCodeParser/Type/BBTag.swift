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

    public static let virtualTags: Set<Self> = [
        .unknown,
        .root,
        .plain,
        .paragraphStart,
        .paragraphEnd,
    ]
    public static let layout: Set<Self> = [
        .center,
        .left,
        .right,
        .align,
    ]
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

    /// 标签名称
    public var label: String {
        if Self.virtualTags.contains(self) {
            return ""
        } else {
            return self.rawValue
        }
    }

    /// 标签描述（用于错误提示等场景）
    public var description: String {
        switch self {
        case .unknown: return "unknown"
        case .root: return "root"
        case .plain: return "plain"
        case .br: return "br"
        case .paragraphStart: return "paragraphStart"
        case .paragraphEnd: return "paragraphEnd"
        case .center: return "center"
        case .left: return "left"
        case .right: return "right"
        case .align: return "align"
        case .quote: return "quote"
        case .code: return "code"
        case .url: return "url"
        case .image: return "image"
        case .bold: return "bold"
        case .italic: return "italic"
        case .font: return "font"
        case .underline: return "underline"
        case .strikethrough: return "strikethrough"
        case .color: return "color"
        case .size: return "size"
        case .mask: return "mask"
        case .ruby: return "ruby"
        case .list: return "list"
        case .listitem: return "listitem"
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
            return [.br, .url]
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
