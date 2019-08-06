//
//  StylerTestSuite.swift
//  DownTests
//
//  Created by John Nguyen on 27.07.19.
//  Copyright © 2019 Glazed Donut, LLC. All rights reserved.
//

import XCTest
import SnapshotTesting
@testable import Down

class StylerTestSuite: XCTestCase {

    // MARK: - Properties

    var styler: DefaultStyler!

    var enableHardBreaks = false

    private let fonts = FontCollection(
        heading1: .systemFont(ofSize: 28),
        heading2: .systemFont(ofSize: 24),
        heading3: .systemFont(ofSize: 20),
        body: .systemFont(ofSize: 17),
        quote: .systemFont(ofSize: 17),
        code: UIFont(name: "menlo", size: 17)!,
        listItemPrefix: .monospacedDigitSystemFont(ofSize: 17, weight: .regular))

    private let colors = ColorCollection(
        heading1: #colorLiteral(red: 0.7803921569, green: 0, blue: 0.2235294118, alpha: 1),
        heading2: #colorLiteral(red: 1, green: 0.3411764706, blue: 0.2, alpha: 1),
        heading3: #colorLiteral(red: 1, green: 0.7647058824, blue: 0.05882352941, alpha: 1),
        body: .black,
        quote: .lightGray,
        code: .darkGray,
        thematicBreak: #colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1),
        listItemPrefix: .gray)

    private let paragraphStyles: ParagraphStyleCollection = {
        let headingStyle = NSMutableParagraphStyle()
        headingStyle.paragraphSpacing = 8

        let bodyStyle = NSMutableParagraphStyle()
        bodyStyle.paragraphSpacingBefore = 8
        bodyStyle.paragraphSpacing = 8

        return ParagraphStyleCollection(
            heading1: headingStyle,
            heading2: headingStyle,
            heading3: headingStyle,
            body: bodyStyle,
            quote: bodyStyle,
            code: bodyStyle)
    }()

    private let listItemOptions = ListItemOptions(
        maxPrefixDigits: 2,
        spacingAfterPrefix: 8,
        spacingAbove: 4,
        spacingBelow: 8)

    private let quoteStripeOptions = QuoteStripeOptions(
        color: #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1),
        thickness: 3,
        spacingAfter: 8)

    private let thematicBreakOptions = ThematicBreakOptions(
        thickness: 1,
        indentation: 0)


    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        styler = DefaultStyler(listItemOptions: listItemOptions, quoteStripeOptions: quoteStripeOptions, thematicBreakOptions: thematicBreakOptions)
        styler.fonts = fonts
        styler.colors = colors
        styler.paragraphStyles = paragraphStyles
    }

    override func tearDown() {
        styler = nil
        super.tearDown()
    }


    // MARK: - Helpers

    func assertStyle(
        for markdown: String,
        width: Width,
        record recording: Bool = false,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line) {

        let view = self.view(for: markdown, width: width)
        let failure = verifySnapshot(matching: view, as: .image, record: recording, file: file, testName: testName, line: line)

        guard let message = failure else { return }
        XCTFail(message, file: file, line: line)
    }

    func view(for markdown: String, width: Width) -> DownTextView {
        let textView = DownTextView(width: width)
        textView.attributedText = attributedString(for: markdown)
        textView.resizeToContentSize()
        return textView
    }

    private func attributedString(for markdown: String) -> NSAttributedString {
        let down = Down(markdownString: markdown)
        return try! down.toAttributedString(enableHardBreaks ? .hardBreaks : [], styler: styler)
    }
}


extension StylerTestSuite {

    enum Width: CGFloat {
        case narrow = 300
        case wide = 600
    }
}


private extension DownTextView {

    convenience init(width: StylerTestSuite.Width) {
        self.init(frame: .init(origin: .zero, size: .init(width: width.rawValue, height: 0)))
    }

    func resizeToContentSize() {
        frame = .init(origin: frame.origin, size: .init(width: contentSize.width, height: contentSize.height))
    }
}
