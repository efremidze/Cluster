//
//  Tree.swift
//  Cluster
//
//  Created by Lasha Efremidze on 4/13/17.
//  Copyright © 2017 efremidze. All rights reserved.
//

import MapKit

open class Tree {
    
    let rootNode = Node(rect: MKMapRectWorld)
    
    // -
    
    func insert(annotation: MKAnnotation) -> Bool {
        return insert(annotation: annotation, toNode: rootNode)
    }
    
    private func insert(annotation: MKAnnotation, toNode node: Node) -> Bool {
        if !node.rect.contains(annotation.coordinate) {
            return false
        }
        
        if node.canAppendAnnotation() {
            return node.append(annotation: annotation)
        }
        
        let siblings = node.siblings ?? node.makeSiblings()
        
        for node in siblings.all {
            if insert(annotation: annotation, toNode: node) {
                return true
            }
        }
        return false
    }
    
    // -
    
    func enumerateAnnotationsUsingBlock(_ callback: (MKAnnotation) -> Void) {
        enumerateAnnotations(inRect: MKMapRectWorld, withNode: rootNode, callback:callback)
    }
    
    func enumerateAnnotations(inRect rect: MKMapRect, callback: (MKAnnotation) -> Void) {
        enumerateAnnotations(inRect: rect, withNode: rootNode, callback: callback)
    }
    
    private func enumerateAnnotations(inRect rect: MKMapRect, withNode node: Node, callback: (MKAnnotation) -> Void) {
        guard node.rect.intersects(rect) else { return }
        
        for annotation in node.annotations where rect.contains(annotation.coordinate) {
            callback(annotation)
        }
        
        guard let siblings = node.siblings, !node.isLeaf else { return }
        
        for node in siblings.all {
            enumerateAnnotations(inRect: rect, withNode: node, callback: callback)
        }
    }
}

open class Node {
    
    let rect: MKMapRect
    
    init(rect: MKMapRect) {
        self.rect = rect
    }
    
    // -
    
    private let max = 8
    
    private(set) var annotations = [MKAnnotation]()
    
    func canAppendAnnotation() -> Bool {
        return annotations.count < max
    }
    
    func append(annotation: MKAnnotation) -> Bool {
        if canAppendAnnotation() {
            annotations.append(annotation)
            return true
        }
        return false
    }
    
    // -
    
    struct Siblings {
        let northWest: Node
        let northEast: Node
        let southWest: Node
        let southEast: Node
        var all: [Node] {
            return [northWest, northEast, southWest, southEast]
        }
    }
    
    var siblings: Siblings?
    
    var isLeaf: Bool {
        return siblings == nil
    }
    
    func makeSiblings() -> Siblings {
        let northWest = Node(rect: MKMapRect(minX: rect.minX, minY: rect.minY, maxX: rect.midX, maxY: rect.midY))
        let northEast = Node(rect: MKMapRect(minX: rect.midX, minY: rect.minY, maxX: rect.maxX, maxY: rect.midY))
        let southWest = Node(rect: MKMapRect(minX: rect.minX, minY: rect.midY, maxX: rect.midX, maxY: rect.maxY))
        let southEast = Node(rect: MKMapRect(minX: rect.midX, minY: rect.midY, maxX: rect.maxX, maxY: rect.maxY))
        let siblings = Siblings(northWest: northWest, northEast: northEast, southWest: southWest, southEast: southEast)
        self.siblings = siblings
        return siblings
    }
    
}

extension MKMapRect {
    init(minX: Double, minY: Double, maxX: Double, maxY: Double) {
        self.init(x: minX, y: minY, width: abs(maxX - minX), height: abs(maxY - minY))
    }
    init(x: Double, y: Double, width: Double, height: Double) {
        self.init(origin: MKMapPoint(x: x, y: y), size: MKMapSize(width: width, height: height))
    }
    var minX: Double { return MKMapRectGetMinX(self) }
    var minY: Double { return MKMapRectGetMinY(self) }
    var midX: Double { return MKMapRectGetMidX(self) }
    var midY: Double { return MKMapRectGetMidY(self) }
    var maxX: Double { return MKMapRectGetMaxX(self) }
    var maxY: Double { return MKMapRectGetMaxY(self) }
    func intersects(_ rect: MKMapRect) -> Bool {
        return MKMapRectIntersectsRect(self, rect)
    }
    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        return MKMapRectContainsPoint(self, MKMapPointForCoordinate(coordinate))
    }
}
