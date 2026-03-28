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
    /// Returns the String with all special HTML characters encoded.
    var stringByEncodingHTML: String {
        var ret = ""
        var g = self.unicodeScalars.makeIterator()
        while let c = g.next() {
            if c < UnicodeScalar(0x0009) {
                if let scale = UnicodeScalar(0x0030 + UInt32(c)) {
                    ret.append("&#x")
                    ret.append(String(Character(scale)))
                    ret.append(";")
                }
            } else if c == UnicodeScalar(0x0022) {
                ret.append("&quot;")
            } else if c == UnicodeScalar(0x0026) {
                ret.append("&amp;")
            } else if c == UnicodeScalar(0x0027) {
                ret.append("&#39;")
            } else if c == UnicodeScalar(0x003C) {
                ret.append("&lt;")
            } else if c == UnicodeScalar(0x003E) {
                ret.append("&gt;")
            } else if c >= UnicodeScalar(0x3000 as UInt16)! && c <= UnicodeScalar(0x303F as UInt16)!
            {
                // CJK 标点符号 (3000-303F)
                ret.append(Character(c))
            } else if c >= UnicodeScalar(0x3400 as UInt16)! && c <= UnicodeScalar(0x4DBF as UInt16)!
            {
                // CJK Unified Ideographs Extension A (3400–4DBF) Rare
                ret.append(Character(c))
            } else if c >= UnicodeScalar(0x4E00 as UInt16)! && c <= UnicodeScalar(0x9FFF as UInt16)!
            {
                // CJK Unified Ideographs (4E00-9FFF) Common
                ret.append(Character(c))
            } else if c >= UnicodeScalar(0xFF00 as UInt16)! && c <= UnicodeScalar(0xFFEF as UInt16)!
            {
                // 全角ASCII、全角中英文标点、半宽片假名、半宽平假名、半宽韩文字母 (FF00-FFEF)
                ret.append(Character(c))
            } else if c >= UnicodeScalar(0x20000 as UInt32)!
                && c <= UnicodeScalar(0x2A6DF as UInt32)!
            {
                // CJK Unified Ideographs Extension B (20000-2A6DF) Rare, historic
                ret.append(Character(c))
            } else if c >= UnicodeScalar(0x2A700 as UInt32)!
                && c <= UnicodeScalar(0x2B73F as UInt32)!
            {
                // CJK Unified Ideographs Extension C (2A700–2B73F) Rare, historic
                ret.append(Character(c))
            } else if c >= UnicodeScalar(0x2B740 as UInt32)!
                && c <= UnicodeScalar(0x2B81F as UInt32)!
            {
                // CJK Unified Ideographs Extension D (2B740–2B81F) Uncommon, some in current use
                ret.append(Character(c))
            } else if c >= UnicodeScalar(0x2B820 as UInt32)!
                && c <= UnicodeScalar(0x2CEAF as UInt32)!
            {
                // CJK Unified Ideographs Extension E (2B820–2CEAF) Rare, historic
                ret.append(Character(c))
            } else if c > UnicodeScalar(0x7E) {
                ret.append("&#\(UInt32(c));")
            } else {
                ret.append(String(Character(c)))
            }
        }
        return ret
    }
}
