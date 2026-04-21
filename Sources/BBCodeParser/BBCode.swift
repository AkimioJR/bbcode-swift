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

  public func validate(_ bbcode: String) throws(BBError) {
    let _ = try parser.parse(bbcode, BBParserContext(with: tagManager))
  }
}
