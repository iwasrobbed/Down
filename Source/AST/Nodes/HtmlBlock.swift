//
//  HtmlBlock.swift
//  Down
//
//  Created by John Nguyen on 09.04.19.
//

import Foundation
import libcmark

public class HtmlBlock: Node {
    
    public var cmarkNode: CMarkNode
    
    public var debugDescription: String { return "Html Block - \(literal ?? "nil")" }
    
    /// The html content, if present.
    lazy var literal: String? = cmarkNode.literal
    
    init?(cmarkNode: CMarkNode) {
        guard cmarkNode.type == CMARK_NODE_HTML_BLOCK else { return nil }
        self.cmarkNode = cmarkNode
    }
}
