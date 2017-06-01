//
//  Extensions.swift
//  Cluster
//
//  Created by Lasha Efremidze on 4/15/17.
//  Copyright © 2017 efremidze. All rights reserved.
//

import MapKit

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

let CLLocationCoordinate2DMax = CLLocationCoordinate2D(latitude: 90, longitude: 180)
let MKMapPointMax = MKMapPointForCoordinate(CLLocationCoordinate2DMax)

extension CLLocationCoordinate2D: Hashable, Equatable {
    public var hashValue: Int {
        return latitude.hashValue ^ longitude.hashValue
    }
    public static func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

typealias ZoomScale = Double
extension ZoomScale {
    func zoomLevel() -> Double {
        let totalTilesAtMaxZoom = MKMapSizeWorld.width / 256
        let zoomLevelAtMaxZoom = log2(totalTilesAtMaxZoom)
        return max(0, zoomLevelAtMaxZoom + floor(log2(self) + 0.5))
    }
    func cellSize() -> Double {
        switch self {
        case 13...15:
            return 64
        case 16...18:
            return 32
        case 19 ..< .greatestFiniteMagnitude:
            return 16
        default: // Less than 13
            return 88
        }
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
