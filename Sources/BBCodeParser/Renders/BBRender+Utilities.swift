func handleNewlineAndParagraph(node: BBNode) {
    // The end tag may be omitted if the <p> element is immediately followed by an <address>, <article>, <aside>, <blockquote>, <div>, <dl>, <fieldset>, <footer>, <form>, <h1>, <h2>, <h3>, <h4>, <h5>, <h6>, <header>, <hr>, <menu>, <nav>, <ol>, <pre>, <section>, <table>, <ul> or another <p> element, or if there is no more content in the parent element and the parent element is not an <a> element.

    // Trim head "br"s
    while node.children.first?.tag == .br {
        node.children.removeFirst()
    }
    // Trim tail "br"s
    while node.children.last?.tag == .br {
        node.children.removeLast()
    }

    let currentIsBlock = node.tag.isBlock
    // if currentIsBlock && !(node.children.first?.description?.isBlock ?? false) && node.type != .code {
    //   node.children.insert(
    //     BBNode(type: .paragraphStart, parent: BBNode, tagManager: tagManager), at: 0)
    // }

    var brCount: UInt = 0
    var previous: BBNode? = nil
    var previousOfPrevious: BBNode? = nil
    var previousIsBlock: Bool = false
    for n in node.children {
        let isBlock = n.tag.isBlock
        if n.tag == .br {
            if previousIsBlock {
                n.tag = .plain
                previousIsBlock = false
            } else {
                previousOfPrevious = previous
                previous = n
                brCount = brCount + 1
            }
        } else {
            if brCount >= 2 && currentIsBlock {  // only block element can contain paragraphs
                previousOfPrevious?.tag = .paragraphEnd
                previous!.tag = .paragraphStart
            }
            brCount = 0
            previous = nil
            previousOfPrevious = nil

            handleNewlineAndParagraph(node: n)
        }

        previousIsBlock = isBlock
    }
}
