import SwiftUI
import WebKit

struct GIFView: UIViewRepresentable {
    let name: String
    var maxHeight: CGFloat = 200

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.backgroundColor = .clear

        
        let html = """
        <html>
          <head>
            <meta name='viewport' content='initial-scale=1, maximum-scale=1, user-scalable=no'>
            <style>
              html, body {
                margin: 0;
                padding: 0;
                background: transparent;
                height: 100%;
                width: 100%;
                display: flex;
                align-items: center;
                justify-content: center;
              }
              img {
                max-width: 100%;
                max-height: 100%;
                width: auto;
                height: auto;
                object-fit: contain;
              }
            </style>
          </head>
          <body>
            <img src="\(name).gif">
          </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        
    }
}
