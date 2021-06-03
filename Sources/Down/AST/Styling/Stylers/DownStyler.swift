//
//  DownStyler.swift
//  Down
//
//  Created by John Nguyen on 22.06.19.
//  Copyright © 2016-2019 Down. All rights reserved.
//

#if !os(watchOS) && !os(Linux)

#if canImport(UIKit)

import UIKit

#elseif canImport(AppKit)

import AppKit

#endif

/// A default `Styler` implementation that supports a variety of configurable
/// properties for font, text color and paragraph styling, as well as formatting
/// of nested lists and quotes.

open class DownStyler: Styler {

    // MARK: - Properties

    public let fonts: FontCollection
    public let colors: ColorCollection
    public let paragraphStyles: ParagraphStyleCollection

    public let quoteStripeOptions: QuoteStripeOptions
    public let thematicBreakOptions: ThematicBreakOptions
    public let codeBlockOptions: CodeBlockOptions

    private let itemParagraphStyler: ListItemParagraphStyler

    private var listPrefixAttributes: [NSAttributedString.Key: Any] {[
        .font: fonts.listItemPrefix,
        .foregroundColor: colors.listItemPrefix]
    }
    
    private var delegate: AsyncImageLoadDelegate?

    // MARK: - Life cycle

    public init(configuration: DownStylerConfiguration = DownStylerConfiguration(), delegate: AsyncImageLoadDelegate? = nil) {
        fonts = configuration.fonts
        colors = configuration.colors
        paragraphStyles = configuration.paragraphStyles
        quoteStripeOptions = configuration.quoteStripeOptions
        thematicBreakOptions = configuration.thematicBreakOptions
        codeBlockOptions = configuration.codeBlockOptions
        itemParagraphStyler = ListItemParagraphStyler(options: configuration.listItemOptions,
                                                      prefixFont: fonts.listItemPrefix)
        self.delegate = delegate
    }

    // MARK: - Styling

    open func style(document str: NSMutableAttributedString) {

    }

    open func style(blockQuote str: NSMutableAttributedString, nestDepth: Int) {
        let stripeAttribute = QuoteStripeAttribute(level: nestDepth + 1,
                                                   color: colors.quoteStripe,
                                                   options: quoteStripeOptions)

        str.updateExistingAttributes(for: .paragraphStyle) { (style: NSParagraphStyle) in
            style.indented(by: stripeAttribute.layoutWidth)
        }

        str.addAttributeInMissingRanges(for: .quoteStripe, value: stripeAttribute)
        str.addAttribute(for: .foregroundColor, value: colors.quote)
    }

    open func style(list str: NSMutableAttributedString, nestDepth: Int) {

    }

    open func style(listItemPrefix str: NSMutableAttributedString) {
        str.setAttributes(listPrefixAttributes)
    }

    open func style(item str: NSMutableAttributedString, prefixLength: Int) {
        let paragraphRanges = str.paragraphRanges()

        guard let leadingParagraphRange = paragraphRanges.first else { return }

        indentListItemLeadingParagraph(in: str, prefixLength: prefixLength, in: leadingParagraphRange)

        paragraphRanges.dropFirst().forEach {
            indentListItemTrailingParagraph(in: str, inRange: $0)
        }
    }

    open func style(codeBlock str: NSMutableAttributedString, fenceInfo: String?) {
        styleGenericCodeBlock(in: str)
    }

    open func style(htmlBlock str: NSMutableAttributedString) {
        styleGenericCodeBlock(in: str)
    }

    open func style(customBlock str: NSMutableAttributedString) {

    }

    open func style(paragraph str: NSMutableAttributedString) {
        str.addAttribute(for: .paragraphStyle, value: paragraphStyles.body)
    }

    open func style(heading str: NSMutableAttributedString, level: Int) {
        let (font, color, paragraphStyle) = headingAttributes(for: level)

        str.updateExistingAttributes(for: .font) { (currentFont: DownFont) in
            var newFont = font

            if currentFont.isMonospace {
                newFont = newFont.monospace
            }

            if currentFont.isEmphasized {
                newFont = newFont.emphasis
            }

            if currentFont.isStrong {
                newFont = newFont.strong
            }

            return newFont
        }

        str.addAttributes([
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle])
    }

    open func style(thematicBreak str: NSMutableAttributedString) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = thematicBreakOptions.indentation
        let attr = ThematicBreakAttribute(thickness: thematicBreakOptions.thickness, color: colors.thematicBreak)
        str.addAttribute(for: .thematicBreak, value: attr)
        str.addAttribute(for: .paragraphStyle, value: paragraphStyle)
    }

    open func style(text str: NSMutableAttributedString) {
        str.setAttributes([
            .font: fonts.body,
            .foregroundColor: colors.body])
    }

    open func style(softBreak str: NSMutableAttributedString) {

    }

    open func style(lineBreak str: NSMutableAttributedString) {

    }

    open func style(code str: NSMutableAttributedString) {
        styleGenericInlineCode(in: str)
    }

    open func style(htmlInline str: NSMutableAttributedString) {
        styleGenericInlineCode(in: str)
    }

    open func style(customInline str: NSMutableAttributedString) {

    }

    open func style(emphasis str: NSMutableAttributedString) {
        str.updateExistingAttributes(for: .font) { (font: DownFont) in
            font.emphasis
        }
    }

    open func style(strong str: NSMutableAttributedString) {
        str.updateExistingAttributes(for: .font) { (font: DownFont) in
            font.strong
        }
    }

    open func style(link str: NSMutableAttributedString, title: String?, url: String?) {
        guard let url = url else { return }
        styleGenericLink(in: str, url: url)
    }

    open func style(image str: NSMutableAttributedString, title: String?, url: String?) {
        guard let url = url,
              let urlImg = URL(string: url) else { return }
        styleGenericImg(in: str, url: urlImg)
    }

    // MARK: - Common Styling

    private func styleGenericCodeBlock(in str: NSMutableAttributedString) {
        let blockBackgroundAttribute = BlockBackgroundColorAttribute(
            color: colors.codeBlockBackground,
            inset: codeBlockOptions.containerInset)

        let adjustedParagraphStyle = paragraphStyles.code.inset(by: blockBackgroundAttribute.inset)

        str.setAttributes([
            .font: fonts.code,
            .foregroundColor: colors.code,
            .paragraphStyle: adjustedParagraphStyle,
            .blockBackgroundColor: blockBackgroundAttribute])
    }

    private func styleGenericInlineCode(in str: NSMutableAttributedString) {
        str.setAttributes([
            .font: fonts.code,
            .foregroundColor: colors.code])
    }

    private func styleGenericLink(in str: NSMutableAttributedString, url: String) {
        str.addAttributes([
            .link: url,
            .foregroundColor: colors.link])
    }
    
    private func styleGenericImg(in str: NSMutableAttributedString, url: URL) {
        let image1Attachment = AsyncImageLoad(imageURL: url, delegate: delegate)
        let image1String = NSAttributedString(attachment: image1Attachment)
        
        str.setAttributedString(image1String)
    }

    // MARK: - Helpers

    private func headingAttributes(for level: Int) -> (DownFont, DownColor, NSParagraphStyle) {
        switch level {
        case 1: return (fonts.heading1, colors.heading1, paragraphStyles.heading1)
        case 2: return (fonts.heading2, colors.heading2, paragraphStyles.heading2)
        case 3: return (fonts.heading3, colors.heading3, paragraphStyles.heading3)
        case 4: return (fonts.heading4, colors.heading4, paragraphStyles.heading4)
        case 5: return (fonts.heading5, colors.heading5, paragraphStyles.heading5)
        case 6: return (fonts.heading6, colors.heading6, paragraphStyles.heading6)
        default: return (fonts.heading1, colors.heading1, paragraphStyles.heading1)
        }
    }

    private func indentListItemLeadingParagraph(in str: NSMutableAttributedString,
                                                prefixLength: Int,
                                                in range: NSRange) {

        str.updateExistingAttributes(for: .paragraphStyle, in: range) { (existingStyle: NSParagraphStyle) in
            existingStyle.indented(by: itemParagraphStyler.indentation)
        }

        let attributedPrefix = str.prefix(with: prefixLength)
        let prefixWidth = attributedPrefix.size().width

        let defaultStyle = itemParagraphStyler.leadingParagraphStyle(prefixWidth: prefixWidth)
        str.addAttributeInMissingRanges(for: .paragraphStyle, value: defaultStyle, within: range)
    }

    private func indentListItemTrailingParagraph(in str: NSMutableAttributedString, inRange range: NSRange) {
        str.updateExistingAttributes(for: .paragraphStyle, in: range) { (existingStyle: NSParagraphStyle) in
            existingStyle.indented(by: itemParagraphStyler.indentation)
        }

        let defaultStyle = itemParagraphStyler.trailingParagraphStyle
        str.addAttributeInMissingRanges(for: .paragraphStyle, value: defaultStyle, within: range)

        indentListItemQuotes(in: str, inRange: range)
    }

    private func indentListItemQuotes(in str: NSMutableAttributedString, inRange range: NSRange) {
        str.updateExistingAttributes(for: .quoteStripe, in: range) { (stripe: QuoteStripeAttribute) in
            stripe.indented(by: itemParagraphStyler.indentation)
        }
    }

}

// MARK: - Helper Extensions

private extension NSParagraphStyle {

    func indented(by indentation: CGFloat) -> NSParagraphStyle {
        guard let result = mutableCopy() as? NSMutableParagraphStyle else { return self }
        result.firstLineHeadIndent += indentation
        result.headIndent += indentation

        result.tabStops = tabStops.map {
            NSTextTab(textAlignment: $0.alignment, location: $0.location + indentation, options: $0.options)
        }

        return result
    }

    func inset(by amount: CGFloat) -> NSParagraphStyle {
        guard let result = mutableCopy() as? NSMutableParagraphStyle else { return self }
        result.paragraphSpacingBefore += amount
        result.paragraphSpacing += amount
        result.firstLineHeadIndent += amount
        result.headIndent += amount
        result.tailIndent = -amount
        return result
    }

}

private extension NSAttributedString {

    func prefix(with length: Int) -> NSAttributedString {
        guard length <= self.length else { return self }
        guard length > 0 else { return NSAttributedString() }
        return attributedSubstring(from: NSRange(location: 0, length: length))
    }

}

#endif
