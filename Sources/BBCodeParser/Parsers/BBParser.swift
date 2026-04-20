public typealias BBParser =
    @Sendable (_ bbcode: String, _ ctx: BBParserContext) throws(BBError) -> BBNode
