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
    
    /**
     Adds an array of annotation objects to the cluster manager.
     
     - Parameters:
        - annotations: An array of annotation objects. Each object in the array must conform to the MKAnnotation protocol.
     */
    open func add(_ annotations: [MKAnnotation]) {
        for annotation in annotations {
            tree.insert(annotation)
        }
    }
    
    /**
     Removes all the annotation objects from the cluster manager.
     */
    open func removeAll() {
        tree = Tree()
    }
    
    /**
     The complete list of annotations associated.
     
     The objects in this array must adopt the MKAnnotation protocol. If no annotations are associated with the cluster manager, the value of this property is an empty array.
     */
    open var annotations: [MKAnnotation] {
        var annotations = [MKAnnotation]()
        tree.enumerate {
            annotations.append($0)
        }
        return annotations
    }
    
    /**
     Reload the annotations on the map view.
     
     - Parameters:
        - mapView: The map view object to reload.
     */
    open func reload(_ mapView: MKMapView) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self, weak mapView] in
            guard let strongSelf = self, let mapView = mapView else { return }
            let (toAdd, toRemove) = strongSelf.clusteredAnnotations(mapView)
            DispatchQueue.main.async { [weak mapView] in
                guard let mapView = mapView else { return }
                mapView.removeAnnotations(toRemove)
                mapView.addAnnotations(toAdd)
            }
        }
    }
    
    func clusteredAnnotations(_ mapView: MKMapView) -> (toAdd: [MKAnnotation], toRemove: [MKAnnotation]) {
        let rect = mapView.visibleMapRect
        let zoomScale = ZoomScale(mapView.bounds.width) / rect.size.width
        
        guard !zoomScale.isInfinite else { return (toAdd: [], toRemove: []) }
        
        let cellSize = zoomScale.zoomLevel().cellSize()
        let scaleFactor = zoomScale / Double(cellSize)
        
        let minX = Int(floor(rect.minX * scaleFactor))
        let maxX = Int(floor(rect.maxX * scaleFactor))
        let minY = Int(floor(rect.minY * scaleFactor))
        let maxY = Int(floor(rect.maxY * scaleFactor))
        
        var clusteredAnnotations = [MKAnnotation]()
        
        for i in minX...maxX {
            for j in minY...maxY {
                let mapRect = MKMapRect(x: Double(i) / scaleFactor, y: Double(j) / scaleFactor, width: 1 / scaleFactor, height: 1 / scaleFactor)
                
                var totalLatitude: Double = 0
                var totalLongitude: Double = 0
                var annotations = [MKAnnotation]()
                
                tree.enumerate(in: mapRect) { node in
                    totalLatitude += node.coordinate.latitude
                    totalLongitude += node.coordinate.longitude
                    annotations.append(node)
                }
                
                let count = annotations.count
                if count > 1 {
                    let coordinate = CLLocationCoordinate2D(
                        latitude: CLLocationDegrees(totalLatitude) / CLLocationDegrees(count),
                        longitude: CLLocationDegrees(totalLongitude) / CLLocationDegrees(count)
                    )
                    let cluster = ClusterAnnotation()
                    cluster.coordinate = coordinate
                    cluster.annotations = annotations
                    clusteredAnnotations.append(cluster)
                } else {
                    clusteredAnnotations += annotations
                }
            }
        }
        
        let before = NSMutableSet(array: mapView.annotations)
        before.remove(mapView.userLocation)
        
        let after = NSSet(array: clusteredAnnotations)
        
        let toKeep = NSMutableSet(set: before)
        toKeep.intersect(after as Set<NSObject>)
        
        let toAdd = NSMutableSet(set: after)
        toAdd.minus(toKeep as Set<NSObject>)
        
        let toRemove = NSMutableSet(set: before)
        toRemove.minus(after as Set<NSObject>)
        
        return (toAdd: toAdd.allObjects as? [MKAnnotation] ?? [], toRemove: toRemove.allObjects as? [MKAnnotation] ?? [])
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
        case 19:
            return 16
        default:
            return 88
        }
    }
    
}
