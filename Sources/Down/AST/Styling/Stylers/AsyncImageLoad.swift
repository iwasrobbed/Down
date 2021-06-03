//
//  AsyncImageLoad.swift
//  Down
//
//  Created by Mikhail Ivanov on 03.06.2021.
//  Copyright © 2021 Down. All rights reserved.
//

#if canImport(UIKit)

import UIKit

#elseif canImport(AppKit)

import AppKit

#endif

public protocol AsyncImageLoadDelegate
{
    func textAttachmentDidLoadImage(textAttachment: AsyncImageLoad, displaySizeChanged: Bool)
}

final public class AsyncImageLoad: NSTextAttachment
{
    public var imageURL: URL?
    
    public var displaySize: CGSize?
    
    public var maximumDisplayWidth: CGFloat?
    
    public var delegate: AsyncImageLoadDelegate?
    
    weak var textContainer: NSTextContainer?
    
    private var originalImageSize: CGSize?
    
    public init(imageURL: URL? = nil, delegate: AsyncImageLoadDelegate? = nil)
    {
        self.imageURL = imageURL
        self.delegate = delegate
        super.init(data: nil, ofType: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    #if os(macOS)
    override public var image: NSImage? {
        didSet {
            originalImageSize = image?.size
        }
    }
    #else
    override public var image: UIImage? {
        didSet {
            originalImageSize = image?.size
        }
    }
    #endif
    
    // MARK: - Function
    
    private func startAsyncImageDownload()
    {
        guard let imageURL = imageURL,
              contents == nil
        else {
            return
        }
        
        URLSession.shared.dataTask(with: imageURL) { (data, response, error) in
            
            guard let data = data,
                  error == nil else {
                print(error?.localizedDescription as Any)
                return
            }
            
            var displaySizeChanged = false
            
            self.contents = data
            
            #if os(macOS)
            if let image = NSImage(data: data)
            {
                let imageSize = image.size
                
                if self.displaySize == nil
                {
                    displaySizeChanged = true
                }
                
                self.originalImageSize = imageSize
            }
            #else
            if let image = UIImage(data: data)
            {
                let imageSize = image.size
                
                if self.displaySize == nil
                {
                    displaySizeChanged = true
                }
                
                self.originalImageSize = imageSize
            }
            #endif
            
            DispatchQueue.main.async {
                if displaySizeChanged
                {
                    self.textContainer?.layoutManager?.setNeedsLayout(forAttachment: self)
                }
                else
                {
                    self.textContainer?.layoutManager?.setNeedsDisplay(forAttachment: self)
                }
                
                // notify the optional delegate
                self.delegate?.textAttachmentDidLoadImage(textAttachment: self, displaySizeChanged: displaySizeChanged)
            }
            
        }.resume()
    }
    
    #if os(macOS)
    public override func image(forBounds imageBounds: CGRect, textContainer: NSTextContainer?, characterIndex charIndex: Int) -> NSImage?
    {
        if let image = image { return image }
        
        guard let contents = contents, let image = NSImage(data: contents) else
        {
            self.textContainer = textContainer
            
            startAsyncImageDownload()
            
            return nil
        }
        
        return image
    }
    #else
    public override func image(forBounds imageBounds: CGRect, textContainer: NSTextContainer?, characterIndex charIndex: Int) -> UIImage?
    {
        if let image = image { return image }
        
        guard let contents = contents, let image = UIImage(data: contents) else
        {
            self.textContainer = textContainer
            
            startAsyncImageDownload()
            
            return nil
        }
        
        return image
    }
    #endif
    
    public override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect
    {
        if let displaySize = displaySize
        {
            return CGRect(origin: CGPoint.zero, size: displaySize)
        }
        
        if let imageSize = originalImageSize
        {
            let maxWidth = maximumDisplayWidth ?? lineFrag.size.width
            let factor = maxWidth / imageSize.width
            
            return CGRect(origin: CGPoint.zero, size:CGSize(width: Int(imageSize.width * factor), height: Int(imageSize.height * factor)))
        }
        
        return CGRect.zero
    }
}

extension NSLayoutManager
{
    /// Determine the character ranges for an attachment
    private func rangesForAttachment(attachment: NSTextAttachment) -> [NSRange]?
    {
        guard let attributedString = self.textStorage else
        {
            return nil
        }
        
        // find character range for this attachment
        let range = NSRange(location: 0, length: attributedString.length)
        
        var refreshRanges = [NSRange]()
        
        attributedString.enumerateAttribute(NSAttributedString.Key.attachment, in: range, options: []) { (value, effectiveRange, nil) in
            
            guard let foundAttachment = value as? NSTextAttachment, foundAttachment == attachment else
            {
                return
            }
            
            // add this range to the refresh ranges
            refreshRanges.append(effectiveRange)
        }
        
        if refreshRanges.count == 0
        {
            return nil
        }
        
        return refreshRanges
    }
    
    /// Trigger a relayout for an attachment
    public func setNeedsLayout(forAttachment attachment: NSTextAttachment)
    {
        guard let ranges = rangesForAttachment(attachment: attachment) else
        {
            return
        }
        
        // invalidate the display for the corresponding ranges
        for range in ranges.reversed() {
            self.invalidateLayout(forCharacterRange: range, actualCharacterRange: nil)
            
            // also need to trigger re-display or already visible images might not get updated
            self.invalidateDisplay(forCharacterRange: range)
        }
    }
    
    /// Trigger a re-display for an attachment
    public func setNeedsDisplay(forAttachment attachment: NSTextAttachment)
    {
        guard let ranges = rangesForAttachment(attachment: attachment) else
        {
            return
        }
        
        // invalidate the display for the corresponding ranges
        for range in ranges.reversed() {
            self.invalidateDisplay(forCharacterRange: range)
        }
    }
}
