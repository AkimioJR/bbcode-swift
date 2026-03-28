public protocol BBParser {
    func parse(_ bbcode: String, ctx: BBParserContext) throws(BBCodeError) -> BBNode
}
