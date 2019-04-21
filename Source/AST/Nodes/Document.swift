//
//  Document.swift
//  Down
//
//  Created by John Nguyen on 09.04.19.
//

import Foundation
import libcmark

public class Document: Node {
    
    public let cmarkNode: CMarkNode
    
    /// Attempts to wrap the given `CMarkNode`.
    ///
    /// This will fail if `cmark_node_get_type(cmarkNode) != CMARK_NODE_DOCUMENT`
    ///
    /// - parameter cmarkNode: the node to wrap.
    ///
    public init?(cmarkNode: CMarkNode) {
        guard cmarkNode.type == CMARK_NODE_DOCUMENT else { return nil }
        self.cmarkNode = cmarkNode
    }
    
    deinit {
        // Frees the node and all its children.
        cmark_node_free(cmarkNode)
    }
    
    /// Accepts the given visitor and return its result.
    public func accept<T: Visitor>(_ visitor: T) -> T.Result {
        return visitor.visit(document: self)
    }
}


// MARK: - Debug

extension Document: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return "Document"
    }
}
