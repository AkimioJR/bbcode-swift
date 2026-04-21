#if canImport(UIKit)

  import BBCodeParser
  import SwiftUI
  import WebKit
  import UIKit

  class InlineWebView: WKWebView {
    private var contentSizeObservation: NSKeyValueObservation?

    init(frame: CGRect) {
      let prefs = WKWebpagePreferences()
      prefs.allowsContentJavaScript = false  // 静态HTML可关闭JS（不影响图片加载）
      let config = WKWebViewConfiguration()
      config.defaultWebpagePreferences = prefs

      // 关闭不需要的媒体功能（完全不影响图片）
      config.allowsAirPlayForMediaPlayback = false
      config.allowsPictureInPictureMediaPlayback = false
      super.init(frame: frame, configuration: config)

      self.scrollView.bounces = false
      self.scrollView.isScrollEnabled = false  // 直接在 init 禁用滚动

      setupObserver()
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    // 设置 KVO 监听
    private func setupObserver() {
      // 监听 scrollView 的 contentSize 属性
      contentSizeObservation = self.scrollView.observe(\.contentSize, options: [.new]) {
        [weak self] (scrollView, change) in
        guard let self = self else { return }

        // 只要内容尺寸发生任何变化（无论是横竖屏切换、图片加载完、还是 JS 动态展开内容）
        // 都通知 Auto Layout 重新获取 intrinsicContentSize
        Task { @MainActor in
          self.invalidateIntrinsicContentSize()
        }
      }
    }

    override var intrinsicContentSize: CGSize {
      // 直接返回当前真实的 contentSize
      // 赋予一个极小的默认高度，防止在最初阶段因为高度为 0 被彻底隐藏
      let height = self.scrollView.contentSize.height
      return CGSize(width: UIView.noIntrinsicMetric, height: height > 0 ? height : 1.0)
    }

    deinit {
      self.contentSizeObservation?.invalidate()
    }
  }

  struct BBCodeWebView: UIViewRepresentable {
    let bbcode: String

    func makeUIView(context: Context) -> InlineWebView {
      return InlineWebView(frame: .zero)
    }

    func updateUIView(_ uiView: InlineWebView, context: Context) {
      uiView.loadHTMLString(generateHTML(from: bbcode), baseURL: nil)
    }
  }

#Preview("基础测试") {
    let bbcode = """
        我是[b]粗体字[/b]
        我是[i]斜体字[/i]
        我是[u]下划线文字[/u]
        我是[s]删除线文字[/s]
        [center]居中文字[/center]
        [left]居左文字[/left]
        [right]居右文字[/right]
        我是[mask]马赛克文字[/mask]
        我是[color=red]彩[/color][color=green]色[/color][color=blue]的[/color][color=orange]哟[/color]
        [size=10]不同[/size][size=14]大小的[/size][size=18]文字[/size]效果也可实现
        Bangumi 番组计划: [url]https://chii.in/[/url]
        带文字说明的网站链接：[url=https://chii.in]Bangumi 番组计划[/url]
        存放于其他网络服务器的图片：[img]https://chii.in/img/ico/bgm88-31.gif[/img]
        代码片段：[code]print("Hello, World!")[/code]
        [quote]引用的片段[/quote]

        传说中性能超强的人型电脑，故事第一话时被人弃置在垃圾场，[i]后被我们的本须和秀树发现，[s]并抱[u]回家[/u][/s][/i]。[color=red]由于开始时唧只会[b]'唧，唧'[/b]的这样叫[/color]，所以秀树为其取名 '唧' [mask]TV版第二话「[s]ちぃでかける[/s]」[/mask]时发现小唧本身并没有安OS，不过因为拥有“学习程式”，所以可以通过对话和教导让她‘成长’起来 (bgm38)。

         ruby测试1：[ruby=あさ]朝[/ruby]ruby测试2:[ruby=a i u e o]あいうえお[/ruby]
        「诶。那就[ruby=ナンジャモンジャ]怪物指名[/ruby]，[ruby=ゾンかまパ—ティ—]僵尸感染派对[/ruby]和UNO吧。」（注：这几个游戏的平均游戏时长都在10分钟之内。）
            [img]https://res.lightnovel.fun/recom/547ab9485bccf42ce89a2e7d0179d203.jpg?m=blixhTqqgXFPldam-Itw0Q&t=1774346959[/img]
        """
    
    ScrollView {
      BBCodeWebView(bbcode: bbcode)
        .padding()
    }
}

  #Preview("字体大小测试") {
    let bbcode = """
      [b] 字体大小测试（size=1~7，从小到大）[/b]
      [size=1]这是 size=1 的文字，对应 footnote 最小字体[/size]
      [size=2]这是 size=2 的文字，对应 subheadline 字体[/size]
      [size=3]这是 size=3 的文字，对应 callout 字体[/size]
      [size=4]这是 size=4 的文字，对应 body 默认正文字体[/size]
      [size=5]这是 size=5 的文字，对应 headline 加粗正文字体[/size]
      [size=6]这是 size=6 的文字，对应 title 大标题字体[/size]
      [size=7]这是 size=7 的文字，对应 largeTitle 最大标题字体[/size]

      这是默认字体（和size=4的body大小一致，用来做对比）
      """

    ScrollView {
      BBCodeWebView(bbcode: bbcode)
        .padding()
    }
  }

#endif
