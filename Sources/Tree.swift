//
//  Tree.swift
//  Cluster
//
//  Created by Lasha Efremidze on 4/13/17.
//  Copyright © 2017 efremidze. All rights reserved.
//

import MapKit

open class Node {
    
    let max = 8
    
    let boundingBox: MKMapRect
    
    struct Siblings {
        let northWest: Node
        let northEast: Node
        let southWest: Node
        let southEast: Node
    }
    
    var siblings: Siblings?
    
    var isLeaf: Bool {
        return siblings == nil
    }
    
//    private(set) var annotations = [MKAnnotation]()
    
    init(boundingBox: MKMapRect) {
        self.boundingBox = boundingBox
    }
    
//    func canAppendAnnotation() -> Bool {
//        return annotations.count < max
//    }
//    
//    func append(annotation: MKAnnotation) -> Bool {
//        if canAppendAnnotation() {
//            annotations.append(annotation)
//            return true
//        }
//        return false
//    }
    
    func makeSiblings() -> Siblings {
        let box = boundingBox
        let northWest = Node(boundingBox: MKMapRect(minX: box.minX, minY: box.minY, maxX: box.midX, maxY: box.midY))
        let northEast = Node(boundingBox: MKMapRect(minX: box.midX, minY: box.minY, maxX: box.maxX, maxY: box.midY))
        let southWest = Node(boundingBox: MKMapRect(minX: box.minX, minY: box.midY, maxX: box.midX, maxY: box.maxY))
        let southEast = Node(boundingBox: MKMapRect(minX: box.midX, minY: box.midY, maxX: box.maxX, maxY: box.maxY))
        return Siblings(northWest: northWest, northEast: northEast, southWest: southWest, southEast: southEast)
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
}
