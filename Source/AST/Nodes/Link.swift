//
//  Link.swift
//  Down
//
//  Created by John Nguyen on 09.04.19.
//

import Foundation
import libcmark

public class Link: Node {
    
    public var cmarkNode: CMarkNode
    
    public var debugDescription: String {
        return "Link - title: \(title ?? "None"), url: \(url ?? "None")"
    }
    
    var title: String? {
        guard let cString = cmark_node_get_title(cmarkNode) else { return nil }
        let result = String(cString: cString)
        return result.isEmpty ? nil : result
    }
    
    var url: String? {
        guard let cString = cmark_node_get_url(cmarkNode) else { return nil }
        let result = String(cString: cString)
        return result.isEmpty ? nil : result
    }
    
    init?(cmarkNode: CMarkNode) {
        guard cmarkNode.type == CMARK_NODE_LINK else { return nil }
        self.cmarkNode = cmarkNode
    }
}

