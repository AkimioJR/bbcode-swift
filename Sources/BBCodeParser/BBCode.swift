public class BBCode {

  public init() {}

  public func validate(
    bbcode: String,
    parser: BBParser = defaultBBParser,
    tagManager: BBTagManager = BBTagManager()
  ) throws(BBCodeError) {
    let _ = try parser(bbcode, BBParserContext(tagManager: tagManager))
  }
}
