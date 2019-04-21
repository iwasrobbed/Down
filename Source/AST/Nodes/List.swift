//
//  List.swift
//  Down
//
//  Created by John Nguyen on 09.04.19.
//

import Foundation
import libcmark

public class List: Node {
    
    public enum ListType: CustomDebugStringConvertible {
        case bullet
        case ordered(start: Int)
        
        public var debugDescription: String {
            switch self {
            case .bullet: return "Bullet"
            case .ordered(let start): return "Ordered (start: \(start)"
            }
        }
        
        init?(cmarkNode: CMarkNode) {
            switch cmarkNode.listType {
            case CMARK_BULLET_LIST: self = .bullet
            case CMARK_ORDERED_LIST: self = .ordered(start: cmarkNode.listStart)
            default: return nil
            }
        }
    }
    
    ///////////////////////////////////////////////////////////////////////////
    
    public let cmarkNode: CMarkNode
    
    /// The type of the list, either bullet or ordered.
    public lazy var listType: ListType = {
        guard let type = ListType(cmarkNode: cmarkNode) else {
            fatalError("List node should have list type.")
        }
        
        return type
    }()
    
    /// The number of items in the list.
    public lazy var numberOfItems: Int = childen.count
    
    /// Attempts to wrap the given `CMarkNode`.
    ///
    /// This will fail if `cmark_node_get_type(cmarkNode) != CMARK_NODE_LIST`
    ///
    /// - parameter cmarkNode: the node to wrap.
    ///
    public init?(cmarkNode: CMarkNode) {
        guard cmarkNode.type == CMARK_NODE_LIST else { return nil }
        self.cmarkNode = cmarkNode
    }
}


// MARK: - Debug

extension List: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return "List - type: \(listType)"
    }
}
