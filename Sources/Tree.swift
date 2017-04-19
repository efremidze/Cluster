//
//  Tree.swift
//  Cluster
//
//  Created by Lasha Efremidze on 4/13/17.
//  Copyright © 2017 efremidze. All rights reserved.
//

import MapKit

class Tree {
    
    let rootNode = Node(mapRect: MKMapRectWorld)
    
    // - Insertion
    
    @discardableResult
    func insert(_ annotation: MKAnnotation, to node: Node? = nil) -> Bool {
        let node = node ?? rootNode
        
        guard node.mapRect.contains(annotation.coordinate) else { return false }
        
        if node.shouldAddAnnotation() {
            node.annotations.append(annotation)
            return true
        }
        
        let siblings = node.siblings ?? node.makeSiblings()
        
        for node in siblings.all {
            if insert(annotation, to: node) {
                return true
            }
        }
        return false
    }
    
    // - Enumeration
    
    func enumerate(rootNode node: Node? = nil, in mapRect: MKMapRect? = nil, callback: (MKAnnotation) -> Void) {
        let node = node ?? rootNode
        let mapRect = mapRect ?? node.mapRect
        
        guard node.mapRect.intersects(mapRect) else { return }
        
        for annotation in node.annotations where mapRect.contains(annotation.coordinate) {
            callback(annotation)
        }
        
        guard let siblings = node.siblings else { return }
        
        for node in siblings.all {
            enumerate(rootNode: node, in: mapRect, callback: callback)
        }
    }
    
}

class Node {
    
    let mapRect: MKMapRect
    
    init(mapRect: MKMapRect) {
        self.mapRect = mapRect
    }
    
    // - Annotations
    
    let maxAnnotations = 8
    
    var annotations = [MKAnnotation]()
    
    func shouldAddAnnotation() -> Bool {
        return annotations.count < maxAnnotations
    }
    
    // - Siblings
    
    struct Siblings {
        let northWest: Node
        let northEast: Node
        let southWest: Node
        let southEast: Node
        var all: [Node] {
            return [northWest, northEast, southWest, southEast]
        }
        init(mapRect: MKMapRect) {
            self.northWest = Node(mapRect: MKMapRect(minX: mapRect.minX, minY: mapRect.minY, maxX: mapRect.midX, maxY: mapRect.midY))
            self.northEast = Node(mapRect: MKMapRect(minX: mapRect.midX, minY: mapRect.minY, maxX: mapRect.maxX, maxY: mapRect.midY))
            self.southWest = Node(mapRect: MKMapRect(minX: mapRect.minX, minY: mapRect.midY, maxX: mapRect.midX, maxY: mapRect.maxY))
            self.southEast = Node(mapRect: MKMapRect(minX: mapRect.midX, minY: mapRect.midY, maxX: mapRect.maxX, maxY: mapRect.maxY))
        }
    }
    
    var siblings: Siblings?
    
    func makeSiblings() -> Siblings {
        let siblings = Siblings(mapRect: mapRect)
        self.siblings = siblings
        return siblings
    }
    
}
