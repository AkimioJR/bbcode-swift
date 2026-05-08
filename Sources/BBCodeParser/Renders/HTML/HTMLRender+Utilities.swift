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

    func renderHTMLAlignment(
        _ inner: BBNode,
        args: DefaultHTMLRenderArgs,
        into buffer: inout String
    ) {
        buffer.append("<p style=\"text-align: \(self.rawValue);\">")
        inner.renderInnerHTML(args, into: &buffer)
        buffer.append("</p>")
    }
}
