//
//  DownStyler.swift
//  Down
//
//  Created by John Nguyen on 22.06.19.
//  Copyright © 2019 Glazed Donut, LLC. All rights reserved.
//

#if canImport(UIKit)

import Foundation
import UIKit

open class DownStyler: Styler {

    // MARK: - Properties

    public let fonts: FontCollection
    public let colors: ColorCollection
    public let paragraphStyles: ParagraphStyleCollection
    public let quoteStripeOptions: QuoteStripeOptions
    public let thematicBreakOptions: ThematicBreakOptions

    public let codeBlockInset: CGFloat

    private let itemParagraphStyler: ListItemParagraphStyler

    private var listPrefixAttributes: [NSAttributedString.Key : Any] {[
        .font: fonts.listItemPrefix,
        .foregroundColor: colors.listItemPrefix]
    }

    // MARK: - Init

    public init(configuration: DownStylerConfiguration = DownStylerConfiguration()) {
        fonts = configuration.fonts
        colors = configuration.colors
        paragraphStyles = configuration.paragraphStyles
        quoteStripeOptions = configuration.quoteStripeOptions
        thematicBreakOptions = configuration.thematicBreakOptions
        codeBlockInset = configuration.codeBlockInset
        itemParagraphStyler = ListItemParagraphStyler(options: configuration.listItemOptions, prefixFont: fonts.listItemPrefix)
    }

    // MARK: - Styling

    open func style(document str: NSMutableAttributedString) {

    }

    open func style(blockQuote str: NSMutableAttributedString, nestDepth: Int) {
        let stripeAttribute = QuoteStripeAttribute(level: nestDepth + 1, color: colors.quoteStripe, options: quoteStripeOptions)

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

        indentListItemLeadingParagraph(in: str, prefixLength: prefixLength, inRange: leadingParagraphRange)

        paragraphRanges.dropFirst().forEach {
            indentListItemTrailingParagraph(in: str, inRange: $0)
        }
    }

    private func indentListItemLeadingParagraph(in str: NSMutableAttributedString, prefixLength: Int, inRange range: NSRange) {
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

    open func style(codeBlock str: NSMutableAttributedString, fenceInfo: String?) {
        let blockBackgroundAttribute = BlockBackgroundColorAttribute(
            color: colors.codeBlockBackground,
            inset: codeBlockInset)

        let adjustedParagraphStyle = paragraphStyles.code.inset(by: blockBackgroundAttribute.inset)

        str.setAttributes([
            .font: fonts.code,
            .foregroundColor: colors.code,
            .paragraphStyle: adjustedParagraphStyle,
            .blockBackgroundColor: blockBackgroundAttribute])
    }

    open func style(htmlBlock str: NSMutableAttributedString) {
        let blockBackgroundAttribute = BlockBackgroundColorAttribute(
            color: colors.codeBlockBackground,
            inset: codeBlockInset)

        let adjustedParagraphStyle = paragraphStyles.code.inset(by: blockBackgroundAttribute.inset)

        str.setAttributes([
            .font: fonts.code,
            .foregroundColor: colors.code,
            .paragraphStyle: adjustedParagraphStyle,
            .blockBackgroundColor: blockBackgroundAttribute])
    }

    open func style(customBlock str: NSMutableAttributedString) {

    }


    open func style(paragraph str: NSMutableAttributedString) {
        str.addAttribute(for: .paragraphStyle, value: paragraphStyles.body)
    }

    open func style(heading str: NSMutableAttributedString, level: Int) {
        let (font, color, paragraphStyle) = headingAttributes(for: level)

        str.updateExistingAttributes(for: .font) { (currentFont: UIFont) in
            var newFont = font

            if (currentFont.isMonospace) {
                newFont = newFont.monospace
            }
            
            if (currentFont.isItalic) {
                newFont = newFont.italic
            }

            if (currentFont.isBold) {
                newFont = newFont.bold
            }

            return newFont
        }

        str.addAttributes([
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle])
    }

    private func headingAttributes(for level: Int) -> (UIFont, UIColor, NSParagraphStyle) {
        switch level {
        case 1: return (fonts.heading1, colors.heading1, paragraphStyles.heading1)
        case 2: return (fonts.heading2, colors.heading2, paragraphStyles.heading2)
        case 3...6: return (fonts.heading3, colors.heading3, paragraphStyles.heading3)
        default: return (fonts.heading1, colors.heading1, paragraphStyles.heading1)
        }
    }

    open func style(thematicBreak str: NSMutableAttributedString) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = thematicBreakOptions.indentation
        str.addAttribute(for: .thematicBreak, value: ThematicBreakAttribute(thickness: thematicBreakOptions.thickness, color: colors.thematicBreak))
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
        str.setAttributes([
            .font: fonts.code,
            .foregroundColor: colors.code])
    }

    open func style(htmlInline str: NSMutableAttributedString) {
        str.setAttributes([
            .font: fonts.code,
            .foregroundColor: colors.code])
    }

    open func style(customInline str: NSMutableAttributedString) {

    }

    open func style(emphasis str: NSMutableAttributedString) {
        str.updateExistingAttributes(for: .font) { (font: UIFont) in
            font.italic
        }
    }

    open func style(strong str: NSMutableAttributedString) {
        str.updateExistingAttributes(for: .font) { (font: UIFont) in
            font.bold
        }
    }

    open func style(link str: NSMutableAttributedString, title: String?, url: String?) {
        guard let url = url else { return }

        str.addAttributes([
            .link: url,
            .foregroundColor: colors.link])
    }

    open func style(image str: NSMutableAttributedString, title: String?, url: String?) {
        guard let url = url else { return }

        str.addAttributes([
            .link: url,
            .foregroundColor: colors.link])
    }
}

// MARK: - Helper Extensions

private extension NSParagraphStyle {

    // TODO: test
    func indented(by indentation: CGFloat) -> NSParagraphStyle {
        let result = mutableCopy() as! NSMutableParagraphStyle
        result.firstLineHeadIndent += indentation
        result.headIndent += indentation

        result.tabStops = tabStops.map {
            NSTextTab(textAlignment: $0.alignment, location: $0.location + indentation, options: $0.options)
        }

        return result
    }

    // TODO: test
    func inset(by amount: CGFloat) -> NSParagraphStyle {
        let result = mutableCopy() as! NSMutableParagraphStyle
        result.paragraphSpacingBefore += amount
        result.paragraphSpacing += amount
        result.firstLineHeadIndent += amount
        result.headIndent += amount
        result.tailIndent = -amount
        return result
    }
}

#endif
