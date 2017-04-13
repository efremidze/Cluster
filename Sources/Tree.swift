//
//  Tree.swift
//  Cluster
//
//  Created by Lasha Efremidze on 4/13/17.
//  Copyright © 2017 efremidze. All rights reserved.
//

import MapKit

open class Node {
    
    struct Siblings {
        let northEast: Node
        let northWest: Node
        let southEast: Node
        let southWest: Node
    }
    
    private(set) var annotations = [MKAnnotation]()
    
    private(set) let boundingBox: MKMapRect
    
    var siblings: Siblings?
    
    var isLeaf: Bool {
        return siblings == nil
    }
    
    let max = 8
    
    init(boundingBox box: MKMapRect) {
        boundingBox = box
    }
    
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
    
    func makeSiblings() -> Siblings {
        let box = boundingBox
        let northEast = Node(boundingBox: MKMapRect(x0: box.xMid, y0: box.y0, xf: box.xf, yf: box.yMid))
        let northWest = Node(boundingBox: MKMapRect(x0: box.x0, y0: box.y0, xf: box.xMid, yf: box.yMid))
        let southEast = Node(boundingBox: MKMapRect(x0: box.xMid, y0: box.yMid, xf: box.xf, yf: box.yf))
        let southWest = Node(boundingBox: MKMapRect(x0: box.x0, y0: box.yMid, xf: box.xMid, yf: box.yf))
        return Siblings(northEast: northEast, northWest: northWest, southEast: southEast, southWest: southWest)
    }
    
}

// bounds rect
extension MKMapRect {
    
    var minX: Double {
        return origin.x
    }
    
    var minY: Double {
        return origin.y
    }
    
    var midX: Double {
        return maxX / 2
    }
    
    var midY: Double {
        return maxY / 2
    }
    
    var maxX: Double {
        return origin.x + size.width
    }
    
    var maxY: Double {
        return origin.y + size.height
    }
    
    init(_ mapRect: MKMapRect) {
        let topLeft = MKCoordinateForMapPoint(mapRect.origin)
        let bottomRight = MKCoordinateForMapPoint(MKMapPointMake(MKMapRectGetMaxX(mapRect), MKMapRectGetMaxY(mapRect)))
        self.init(origin: MKMapPoint(x: bottomRight.latitude, y: topLeft.longitude), size: MKMapSize(width: topLeft.latitude, height: bottomRight.longitude))
    }
    
    func intersects(_ mapRect: MKMapRect) -> Bool {
        return MKMapRectIntersectsRect(self, mapRect)
    }
    
    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        return MKMapRectContainsPoint(self, MKMapPointMake(coordinate.latitude, coordinate.longitude))
    }
    
}
