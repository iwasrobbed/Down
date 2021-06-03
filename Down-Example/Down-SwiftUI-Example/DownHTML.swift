//
//  DownHTML.swift
//  Down-SwiftUI-Example
//
//  Created by Mikhail Ivanov on 01.06.2021.
//  Copyright © 2021 Down. All rights reserved.
//

import SwiftUI
import WebKit
import Down

class MarkdownSize: ObservableObject {
    @Published var height: CGFloat = 0
}

struct DownViewSwiftUI: UIViewRepresentable {
    var markdown: String

    @EnvironmentObject var markdownSize: MarkdownSize

    func makeUIView(context: Context) -> DownView {

        let webView = try? DownView(frame: UIScreen.main.bounds, markdownString: markdown)
        webView?.navigationDelegate = context.coordinator
        return webView!

    }

    class Coordinator: NSObject, WKNavigationDelegate {
        private var markdownSize: MarkdownSize

        init(_ markdownSize: MarkdownSize) {
                    self.markdownSize = markdownSize
                }

        func webView(_ webView: WKWebView,
                     didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.documentElement.scrollHeight") { (height, _) in

                if let height = height as? CGFloat {

                    self.markdownSize.height = height
                }
            }
        }
    }

    func makeCoordinator() -> DownViewSwiftUI.Coordinator {
            Coordinator(markdownSize)
        }

    func updateUIView(_ uiView: DownView, context: Context) {

    }

}


struct DownHTML: View {
    /// This class has a float variable in it to get data about the length of the resulting markup
    @ObservedObject private var markdownSize = MarkdownSize()
    
    var markdownString: String
    var body: some View {
        DownViewSwiftUI(markdown: markdownString).environmentObject(markdownSize)
            .navigationBarTitleDisplayMode(.inline)
    }
}
