import Foundation

/// 包装原生 Iterator，用于自动追踪解析的行号和列号
struct BBScanner {
    private var iterator: String.UnicodeScalarView.Iterator
    private(set) var line: UInt = 1
    private(set) var column: UInt = 1

    init(_ string: String) {
        self.iterator = string.unicodeScalars.makeIterator()
    }

    mutating func next() -> UnicodeScalar? {
        guard let c = iterator.next() else { return nil }

        // 遇到换行符，行号+1，列号归零
        if c == UnicodeScalar("\n") {
            line += 1
            column = 1
        } else if c != UnicodeScalar("\r") {  // 忽略 \r 对列号的影响
            column += 1
        }
        return c
    }
}
