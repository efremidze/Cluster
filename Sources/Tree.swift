//
//  Tree.swift
//  Cluster
//
//  Created by Lasha Efremidze on 4/13/17.
//  Copyright © 2017 efremidze. All rights reserved.
//

import MapKit

open class Tree {
    
    let rootNode = Node(mapRect: MKMapRectWorld)
    
    // - Insertion
    
    @discardableResult
    func insert(annotation: MKAnnotation) -> Bool {
        return insert(annotation: annotation, toNode: rootNode)
    }
    
    private func insert(annotation: MKAnnotation, toNode node: Node) -> Bool {
        guard node.mapRect.contains(annotation.coordinate) else { return false }
        
        if node.canAppendAnnotation() {
            node.annotations.append(annotation)
            return true
        }
        
        let siblings = node.siblings ?? node.makeSiblings()
        
        for node in siblings.all {
            if insert(annotation: annotation, toNode: node) {
                return true
            }
        }
        return false
    }
    
    // - Enumeration
    
    func enumerateAnnotationsUsingBlock(_ callback: (MKAnnotation) -> Void) {
        enumerateAnnotations(inRect: MKMapRectWorld, withNode: rootNode, callback:callback)
    }
    
    func enumerateAnnotations(inRect rect: MKMapRect, callback: (MKAnnotation) -> Void) {
        enumerateAnnotations(inRect: rect, withNode: rootNode, callback: callback)
    }
    
    private func enumerateAnnotations(inRect rect: MKMapRect, withNode node: Node, callback: (MKAnnotation) -> Void) {
        guard node.mapRect.intersects(rect) else { return }
        
        for annotation in node.annotations where rect.contains(annotation.coordinate) {
            callback(annotation)
        }
        
        guard let siblings = node.siblings else { return }
        
        for node in siblings.all {
            enumerateAnnotations(inRect: rect, withNode: node, callback: callback)
        }
    }
    
}

open class Node {
    
    let mapRect: MKMapRect
    
    init(mapRect: MKMapRect) {
        self.mapRect = mapRect
    }
    
    // - Annotations
    
    private let max = 8
    
    var annotations = [MKAnnotation]()
    
    func canAppendAnnotation() -> Bool {
        return annotations.count < max
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
