public class BBCode<P: BBParser, T: BBTagManager> {
    let parser: P
    let tagManager: T

    public init(
        parser: P = DefaultBBParser(),
        tagManager: T = DefaultBBTagManager()
    ) {
        self.parser = parser
        self.tagManager = tagManager
    }

    public func parse(_ bbcode: String) throws(BBError) -> BBNode {
        return try parser.parse(bbcode, BBParserContext(with: tagManager))
    }
}
