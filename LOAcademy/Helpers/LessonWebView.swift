import SwiftUI
import WebKit

struct LessonWebView: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 1)
        webView.scrollView.backgroundColor = webView.backgroundColor
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let wrapped = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
        <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, system-ui, sans-serif;
            background: #0a0a0f;
            color: #d4d4dc;
            padding: 16px;
            font-size: 17px;
            line-height: 1.7;
            -webkit-text-size-adjust: 100%;
        }
        h2 { font-size: 1.4rem; font-weight: 600; margin: 2rem 0 0.75rem; color: #f5f5f7; }
        h3 { font-size: 1.15rem; font-weight: 600; margin: 1.5rem 0 0.5rem; color: #f5f5f7; }
        p { margin-bottom: 1rem; }
        ul, ol { margin-bottom: 1rem; padding-left: 1.25rem; }
        li { margin-bottom: 0.4rem; }
        code {
            font-family: 'SF Mono', Menlo, monospace;
            font-size: 0.85em;
            background: rgba(255,255,255,0.06);
            padding: 2px 6px;
            border-radius: 4px;
            color: #c084fc;
        }
        pre {
            background: #161622;
            border: 1px solid #27272a;
            border-radius: 8px;
            padding: 16px;
            overflow-x: auto;
            margin: 1.25rem 0;
        }
        pre code { background: none; padding: 0; color: #d4d4dc; font-size: 0.85rem; }
        a { color: #c084fc; text-decoration: underline; }
        strong { color: #f5f5f7; font-weight: 600; }
        blockquote {
            border-left: 3px solid #a855f7;
            padding-left: 16px;
            margin: 1.25rem 0;
            color: #a1a1aa;
            font-style: italic;
        }
        table { width: 100%; border-collapse: collapse; margin: 1.25rem 0; font-size: 0.9rem; }
        th { text-align: left; padding: 8px 12px; font-weight: 600; color: #f5f5f7; background: rgba(255,255,255,0.03); border-bottom: 2px solid #27272a; }
        td { padding: 8px 12px; border-bottom: 1px solid #27272a; color: #a1a1aa; }
        img { max-width: 100%; height: auto; border-radius: 8px; }

        /* Visual aid system */
        .lo-vis { background: #161622; border: 1px solid #27272a; border-radius: 12px; padding: 16px; margin: 1.25rem 0; }
        .lo-step { padding: 10px 14px; border-radius: 8px; margin: 6px 0; }
        .lo-step--green { background: rgba(52,211,153,0.08); border-left: 3px solid #34d399; }
        .lo-step--purple { background: rgba(168,85,247,0.08); border-left: 3px solid #a855f7; }
        .lo-step--orange { background: rgba(251,146,60,0.08); border-left: 3px solid #fb923c; }

        .learn-card { background: #1a1a24; border: 1px solid #27272a; border-radius: 12px; padding: 16px; margin: 1rem 0; }
        .learn-card h3 { font-size: 1rem; margin: 0 0 8px; }

        .quiz-block { background: #1a1a24; border: 1px solid #27272a; border-radius: 12px; padding: 16px; margin: 1.25rem 0; }
        .quiz-option { padding: 12px 16px; border: 1px solid #27272a; border-radius: 8px; margin: 6px 0; cursor: pointer; }
        .quiz-correct { border-color: #34d399; background: rgba(52,211,153,0.08); }
        .quiz-wrong { border-color: #f87171; background: rgba(248,113,113,0.08); }
        </style>
        </head>
        <body>
        \(html)
        </body>
        </html>
        """
        webView.loadHTMLString(wrapped, baseURL: nil)
    }
}
