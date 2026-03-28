import XCTest

@testable import BBCodeParser

class HTMLTests: XCTestCase {

  func testBold() {
    XCTAssertEqual(try BBCode().renderHTML("我是[b]粗体字[/b]"), "我是<strong>粗体字</strong>")
  }

  func testItalic() {
    XCTAssertEqual(try BBCode().renderHTML("我是[i]斜体字[/i]"), "我是<em>斜体字</em>")
  }

  func testUnderline() {
    XCTAssertEqual(
      try BBCode().renderHTML("我是[u]下划线文字[/u]"),
      "我是<u>下划线文字</u>")
  }

  func testStrikeThrough() {
    XCTAssertEqual(
      try BBCode().renderHTML("我是[s]删除线文字[/s]"),
      "我是<del>删除线文字</del>")
  }

  func testCenter() {
    XCTAssertEqual(
      try BBCode().renderHTML("[center]居中文字[/center]"),
      "<p style=\"text-align: center;\">居中文字</p>")
  }

  func testLeft() {
    XCTAssertEqual(
      try BBCode().renderHTML("[left]居左文字[/left]"),
      "<p style=\"text-align: left;\">居左文字</p>")
  }

  func testRight() {
    XCTAssertEqual(
      try BBCode().renderHTML("[right]居右文字[/right]"),
      "<p style=\"text-align: right;\">居右文字</p>")
  }

  func testAlign() {
    XCTAssertEqual(
      try BBCode().renderHTML("[align=center]居中文字[/align]"),
      "<p style=\"text-align: center;\">居中文字</p>")
  }

  func testMask() {
    XCTAssertEqual(
      try BBCode().renderHTML("我是[mask]马赛克文字[/mask]"),
      "我是<span class=\"mask\">马赛克文字</span>")
  }

  func testColor() {
    XCTAssertEqual(
      try BBCode().renderHTML(
        "我是[color=red]彩[/color][color=green]色[/color][color=blue]的[/color][color=orange]哟[/color]"),
      "我是<span style=\"color: red;\">彩</span><span style=\"color: green;\">色</span><span style=\"color: blue;\">的</span><span style=\"color: orange;\">哟</span>"
    )
  }

  func testSize() {
    XCTAssertEqual(
      try BBCode().renderHTML("[size=10]不同[/size][size=14]大小的[/size][size=18]文字[/size]效果也可实现"),
      "<span style=\"font-size: 10px;\">不同</span><span style=\"font-size: 14px;\">大小的</span><span style=\"font-size: 18px;\">文字</span>效果也可实现"
    )
  }

  func testLink() {
    XCTAssertEqual(
      try BBCode().renderHTML("Bangumi 番组计划: [url]https://chii.in/[/url]"),
      "Bangumi 番组计划: <a href=\"https://chii.in/\" target=\"_blank\" rel=\"nofollow external noopener noreferrer\">https://chii.in/</a>"
    )
  }

  func testURL() {
    XCTAssertEqual(
      try BBCode().renderHTML("带文字说明的网站链接：[url=https://chii.in]Bangumi 番组计划[/url]"),
      "带文字说明的网站链接：<a href=\"https://chii.in\" target=\"_blank\" rel=\"nofollow external noopener noreferrer\">Bangumi 番组计划</a>"
    )
  }

  func testImage() {
    XCTAssertEqual(
      try BBCode().renderHTML("存放于其他网络服务器的图片：[img]https://chii.in/img/ico/bgm88-31.gif[/img]"),
      "存放于其他网络服务器的图片：<img src=\"https://chii.in/img/ico/bgm88-31.gif\" rel=\"noreferrer\" referrerpolicy=\"no-referrer\" alt=\"\" />"
    )
  }

  func testCode() {
    XCTAssertEqual(
      try BBCode().renderHTML("代码片段：[code]print(\"Hello, World!\")[/code]"),
      "代码片段：<div class=\"code\"><pre><code>print(&quot;Hello, World!&quot;)</code></pre></div>"
    )
  }

  func testQuote() {
    XCTAssertEqual(
      try BBCode().renderHTML("引用文字：[quote]这是一段引用文字[/quote]"),
      "引用文字：<div class=\"quote\"><blockquote>这是一段引用文字</blockquote></div>"
    )
  }

  func testParenthesesAtEnd() {
    // Test case for text ending with '(' that should be treated as plain text
    XCTAssertEqual(
      try BBCode().renderHTML("这是一些文字("),
      "这是一些文字("
    )
  }

  func testParenthesesAtEndWithNewline() {
    // Test case for text ending with '(' followed by newline
    XCTAssertEqual(
      try BBCode().renderHTML("这是一些文字(\n"),
      "这是一些文字(<br>"
    )
  }

  func testParenthesesAtEndWithCarriageReturn() {
    // Test case for text ending with '(' followed by carriage return
    XCTAssertEqual(
      try BBCode().renderHTML("这是一些文字(\r"),
      "这是一些文字(<br>"
    )
  }

  func testParenthesesAtEndWithCarriageReturnNewline() {
    // Test case for text ending with '(' followed by CRLF
    XCTAssertEqual(
      try BBCode().renderHTML("这是一些文字(\r\n"),
      "这是一些文字(<br>"
    )
  }

  func testParenthesesAtEndWithContent() {
    // Test case for text ending with '(' that has some content but no closing ')'
    XCTAssertEqual(
      try BBCode().renderHTML("这是一些文字(bgm"),
      "这是一些文字(bgm"
    )
  }

  func testFont() {
    XCTAssertEqual(
      try BBCode().renderHTML("使用字体：[font=Arial]这是Arial[font=宋体]字体[/font][/font]"),
      "使用字体：<span style=\"font-family: Arial;\">这是Arial<span style=\"font-family: 宋体;\">字体</span></span>"
    )
  }
}
