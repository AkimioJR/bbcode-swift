public class BBCode {
  public func validate(
    bbcode: String,
    parser: BBParser = DefaultBBParser.content,
    tm: BBTagManager = BBTagManager()
  ) throws(BBCodeError) {
    let _ = try parser.parse(bbcode, ctx: BBParserContext(tagManager: tm))
  }
}
