import BBCodeParser

func generateHTML(from bbcode: String) -> String {
    do {
        let body = try renderBBCodeToHTML(bbcode)

        return """
            <!doctype html>
            <html>

            <head>
              <meta charset="utf-8">
              <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no, shrink-to-fit=yes'>
              <style type="text/css">
                /* 根变量配置：自动适配系统深色/浅色模式 */
                :root {
                  color-scheme: light dark;
                }

                img {
                  max-width: 100%; /* 最大宽度100% → 永远不会超出屏幕/容器宽度 */
                  height: auto; /* 高度自动 → 保持图片原始比例，不变形拉伸 */
                }

                /* 列表项：最后一个li下方增加间距，排版更松散 */
                li:last-child {
                  margin-bottom: 1em;
                }

                /* 链接样式 */
                a {
                  color: #0084B4; /* 设置颜色 */
                  text-decoration: none; /* 去掉下划线 */
                }

               /****************************************************************************
                * 马赛克遮罩文字（hover 显示）
                * 默认背景色和文字色一致，隐藏内容；鼠标悬停显示白色文字
                ***************************************************************************/
                span.mask {
                  background-color: #555;
                  color: #555;
                  border-radius: 2px;
                  box-shadow: #555 0 0 5px;
                  -webkit-transition: all .5s linear;
                  /* 平滑过渡动画 */
                }

                /* 鼠标悬浮在马赛克文字上时，显示文字 */
                span.mask:hover {
                  color: #FFF;
                }

                /* 代码块样式：边框、圆角、内边距、滚动条 */
                pre code {
                  border: 1px solid #EEE;
                  border-radius: 0.5em;
                  padding: 1em;
                  display: block;
                  overflow: auto;
                }

                /* 引用块样式：文字颜色偏灰 */
                blockquote {
                  display: inline-block;
                  color: #666;
                }

                /* 引用块左侧引号 */
                blockquote:before {
                  content: open-quote;
                  display: inline;
                  line-height: 0;
                  position: relative;
                  left: -0.5em;
                  color: #CCC;
                  font-size: 1em;
                }

                /* 引用块右侧引号 */
                blockquote:after {
                  content: close-quote;
                  display: inline;
                  line-height: 0;
                  position: relative;
                  left: 0.5em;
                  color: #CCC;
                  font-size: 1em;
                }
              </style>
            </head>

            <body>
              \(body)
            </body>

            </html>
            """
    } catch (let error) {
        return "解析BBCode错误: \(error.localizedDescription)"
    }
}
