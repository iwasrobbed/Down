//
//  CustomInline.swift
//  Down
//
//  Created by John Nguyen on 09.04.19.
//

import Foundation
import libcmark

public class CustomInline: Node {
    
    public var cmarkNode: CMarkNode
    
    public var debugDescription: String { return "Custom Inline - \(literal ?? "nil")" }
    
    /// The custom content, if present.
    lazy var literal: String? = cmarkNode.literal
    
    init?(cmarkNode: CMarkNode) {
        guard cmarkNode.type == CMARK_NODE_CUSTOM_INLINE else { return nil }
        self.cmarkNode = cmarkNode
    }
}
