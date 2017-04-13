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
    
    let boundingBox: Bounds
    
    var siblings: Siblings?
    
    var isLeaf: Bool {
        return siblings == nil
    }
    
    let max = 8
    
    init(boundingBox box: Bounds) {
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

extension MKMapRect {
    var minX: Double { return MKMapRectGetMinX(self) }
    var minY: Double { return MKMapRectGetMinY(self) }
    var midX: Double { return MKMapRectGetMidX(self) }
    var midY: Double { return MKMapRectGetMidY(self) }
    var maxX: Double { return MKMapRectGetMaxX(self) }
    var maxY: Double { return MKMapRectGetMaxY(self) }
}

struct Bounds {
    
    let topLeft, bottomRight: CLLocationCoordinate2D
    
    var mapRect: MKMapRect {
        return [topLeft, bottomRight].map { MKMapPointForCoordinate($0) }.map { MKMapRect(origin: $0, size: MKMapSize()) }.reduce(MKMapRectNull, MKMapRectUnion)
//        return MKMapRect(origin: MKMapPointForCoordinate(topLeft), size: MKMapSize(width: bottomRight.latitude - topLeft.latitude, height: bottomRight.longitude - topLeft.longitude))
    }
    
    var midLatitude: CLLocationDegrees {
        return (topLeft.latitude + bottomRight.latitude) / 2
    }
    
    var midLongitude: CLLocationDegrees {
        return (topLeft.longitude + bottomRight.longitude) / 2
    }
    
    static func make(_ mapRect: MKMapRect) -> Bounds {
        let topLeft = MKCoordinateForMapPoint(MKMapPointMake(MKMapRectGetMinX(mapRect), MKMapRectGetMinY(mapRect)))
        let bottomRight = MKCoordinateForMapPoint(MKMapPointMake(MKMapRectGetMaxX(mapRect), MKMapRectGetMaxY(mapRect)))
        return Bounds(topLeft: topLeft, bottomRight: bottomRight)
    }
    
    func intersects(_ bounds: Bounds) -> Bool {
        return MKMapRectIntersectsRect(mapRect, bounds.mapRect)
    }
    
    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        return MKMapRectContainsPoint(mapRect, MKMapPointForCoordinate(coordinate))
    }
    
}
