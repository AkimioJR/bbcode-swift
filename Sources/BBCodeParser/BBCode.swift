public class BBCode {

  public init() {}

  public func validate(
    bbcode: String,
    parser: BBParser = DefaultBBParser(),
    tagManager: BBTagManager = DefaultBBTagManager()
  ) throws(BBError) {
    let _ = try parser.parse(bbcode, BBParserContext(tagManager: tagManager))
  }
}
