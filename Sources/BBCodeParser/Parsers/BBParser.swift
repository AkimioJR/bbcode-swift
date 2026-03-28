public typealias BBParser =
    @Sendable (_ bbcode: String, _ ctx: BBParserContext) throws(BBCodeError) -> BBNode
