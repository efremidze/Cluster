//
//  Cluster.swift
//  Cluster
//
//  Created by Lasha Efremidze on 4/13/17.
//  Copyright © 2017 efremidze. All rights reserved.
//

import CoreLocation
import MapKit

open class ClusterManager {
    
    var tree = Tree()
    
    public init() {}
    
    open func add(annotations: [MKAnnotation]) {
        for annotation in annotations {
            tree.insert(annotation: annotation)
        }
    }
    
    open func removeAll() {
        tree = Tree()
    }
    
    open func annotations() -> [MKAnnotation] {
        var annotations = [MKAnnotation]()
        tree.enumerateAnnotationsUsingBlock {
            annotations.append($0)
        }
        return annotations
    }
    
    open func clusteredAnnotations(withinMapRect rect: MKMapRect, zoomScale: Double) -> [MKAnnotation] {
        guard !zoomScale.isInfinite else { return [] }
        
        let cellSize = ZoomLevel(MKZoomScale(zoomScale)).cellSize()
        
        let scaleFactor = zoomScale / Double(cellSize)
        
        let minX = Int(floor(rect.minX * scaleFactor))
        let maxX = Int(floor(rect.maxX * scaleFactor))
        let minY = Int(floor(rect.minY * scaleFactor))
        let maxY = Int(floor(rect.maxY * scaleFactor))
        
        var clusteredAnnotations = [MKAnnotation]()
        
        for i in minX...maxX {
            for j in minY...maxY {
                let mapPoint = MKMapPoint(x: Double(i) / scaleFactor, y: Double(j) / scaleFactor)
                let mapSize = MKMapSize(width: 1.0 / scaleFactor, height: 1.0 / scaleFactor)
                let mapRect = MKMapRect(origin: mapPoint, size: mapSize)
                
                var totalLatitude: Double = 0
                var totalLongitude: Double = 0
                
                var annotations = [MKAnnotation]()
                
                tree.enumerateAnnotations(inRect: mapRect) { obj in
                    totalLatitude += obj.coordinate.latitude
                    totalLongitude += obj.coordinate.longitude
                    annotations.append(obj)
                }
                
                let count = annotations.count
                
                switch count {
                case 0: break
                case 1:
                    clusteredAnnotations += annotations
                default:
                    let coordinate = CLLocationCoordinate2D(
                        latitude: CLLocationDegrees(totalLatitude) / CLLocationDegrees(count),
                        longitude: CLLocationDegrees(totalLongitude) / CLLocationDegrees(count)
                    )
                    let cluster = ClusterAnnotation()
                    cluster.coordinate = coordinate
                    cluster.annotations = annotations
                    clusteredAnnotations.append(cluster)
                }
            }
        }
        
        return clusteredAnnotations
    }
    
    open func display(annotations: [MKAnnotation], onMapView mapView: MKMapView) {
        let before = NSMutableSet(array: mapView.annotations)
        before.remove(mapView.userLocation)
        
        let after = NSSet(array: annotations)
        
        let toKeep = NSMutableSet(set: before)
        toKeep.intersect(after as Set<NSObject>)
        
        let toAdd = NSMutableSet(set: after)
        toAdd.minus(toKeep as Set<NSObject>)
        
        let toRemove = NSMutableSet(set: before)
        toRemove.minus(after as Set<NSObject>)
        
        if let toAddAnnotations = toAdd.allObjects as? [MKAnnotation] {
            mapView.addAnnotations(toAddAnnotations)
        }
        
        if let removeAnnotations = toRemove.allObjects as? [MKAnnotation] {
            mapView.removeAnnotations(removeAnnotations)
        }
    }
    
}

typealias ZoomLevel = Int
extension ZoomLevel {
    
    init(scale: MKZoomScale) {
        let totalTilesAtMaxZoom = MKMapSizeWorld.width / 256
        let zoomLevelAtMaxZoom = Int(log2(totalTilesAtMaxZoom))
        let floorLog2ScaleFloat = floor(log2f(Float(scale))) + 0.5
        if !floorLog2ScaleFloat.isInfinite {
            self = altmax(0, zoomLevelAtMaxZoom + Int(floorLog2ScaleFloat))
        } else {
            self = floorLog2ScaleFloat.sign == .plus ? 0 : 19
        }
    }
    
    func cellSize() -> CGFloat {
        switch (self) {
        case 13...15:
            return 64
        case 16...18:
            return 32
        case 18 ..< .max:
            return 16
        default: // Less than 13
            return 88
        }
    }
    
}

// Required due to conflict with Int static variable 'max'
func altmax<T : Comparable>(_ x: T, _ y: T) -> T {
    return max(x, y)
}
