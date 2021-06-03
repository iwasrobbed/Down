//
//  DownAttributedString.swift
//  Down-SwiftUI-Example
//
//  Created by Mikhail Ivanov on 01.06.2021.
//  Copyright © 2021 Down. All rights reserved.
//

import SwiftUI
import Down

class MarkdownObservable: ObservableObject {
    @Published public var textView = UITextView()
    public let text: String
    
    init(text: String) {
        self.text = text
    }
}

struct MarkdownRepresentable: UIViewRepresentable {
    @Environment(\.colorScheme) var colorScheme
    @Binding var dynamicHeight: CGFloat
    @EnvironmentObject var markdownObject: MarkdownObservable
    
    @State var test: Int = 0
    
    init(height: Binding<CGFloat>) {
        self._dynamicHeight = height
    }
    
    
    // TODO: As soon as PR: 258 is accepted - you need to uncomment
//    func makeCoordinator() -> Cordinator {
//        Cordinator(text: markdownObject.textView)
//    }
    
    func makeUIView(context: Context) -> UITextView {
        
        let down = Down(markdownString: markdownObject.text)
        
        // TODO: As soon as PR: 258 is accepted - you need to uncomment
//        let attributedText = try? down.toAttributedString(styler: DownStyler(delegate: context.coordinator))
        
        let attributedText = try? down.toAttributedString(styler: DownStyler())
        markdownObject.textView.attributedText = attributedText
        markdownObject.textView.attributedText = attributedText
        markdownObject.textView.textAlignment = .left
        markdownObject.textView.isScrollEnabled = false
        markdownObject.textView.isUserInteractionEnabled = true
        markdownObject.textView.showsVerticalScrollIndicator = false
        markdownObject.textView.showsHorizontalScrollIndicator = false
        markdownObject.textView.isEditable = false
        markdownObject.textView.backgroundColor = .clear
        
        markdownObject.textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        markdownObject.textView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        return markdownObject.textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        DispatchQueue.main.async {
            /// Allows you to change the color of the text when switching the device theme.
            /// I advise you to do it in the future through the configuration when setting up your own Styler class
            uiView.textColor = colorScheme == .dark ? UIColor.white : UIColor.black
            
            dynamicHeight = uiView.sizeThatFits(CGSize(width: uiView.bounds.width,
                                                       height: CGFloat.greatestFiniteMagnitude))
                .height
        }
    }
    
    // TODO: As soon as PR: 258 is accepted - you need to uncomment
//    class Cordinator: NSObject, AsyncImageLoadDelegate {
//
//        public var textView: UITextView
//
//        init(text: UITextView) {
//            textView = text
//        }
//
//        func textAttachmentDidLoadImage(textAttachment: AsyncImageLoad, displaySizeChanged: Bool)
//            {
//                if displaySizeChanged
//                {
//                    textView.layoutManager.setNeedsLayout(forAttachment: textAttachment)
//                }
//
//                // always re-display, the image might have changed
//                textView.layoutManager.setNeedsDisplay(forAttachment: textAttachment)
//            }
//    }
}

struct DownAttributedString: View {
    @ObservedObject private var markdownObject: MarkdownObservable
    private var markdownString: String
    
    @State private var height: CGFloat = .zero
    
    init(text: String) {
        self.markdownString = text
        self.markdownObject = MarkdownObservable(text: text)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
                MarkdownRepresentable(height: $height)
                    .frame(height: height)
                    .environmentObject(markdownObject)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
