public protocol BBParser {
    func parse(_ bbcode: String, _ ctx: BBParserContext) throws(BBError) -> BBNode
}
