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
    
    var tree = QuadTree(rect: MKMapRectWorld)
    
    /**
     Controls the level from which clustering will be enabled. Min value is 2 (max zoom out), max is 20 (max zoom in).
     */
    open var zoomLevel: Int = 20 {
        didSet {
            zoomLevel = zoomLevel.clamped(to: 2...20)
        }
    }
    
    /**
     The minimum number of annotations for a cluster.
     */
    open var minimumCountForCluster: Int = 2
    
    /**
     Whether to remove invisible annotations.
     */
    open var shouldRemoveInvisibleAnnotations: Bool = true
    
    public init() {}
    
    /**
     Adds an annotation object to the cluster manager.
     
     - Parameters:
        - annotation: An annotation object. The object must conform to the MKAnnotation protocol.
     */
    open func add(_ annotation: MKAnnotation) {
        tree.add(annotation)
    }
    
    /**
     Adds an array of annotation objects to the cluster manager.
     
     - Parameters:
        - annotations: An array of annotation objects. Each object in the array must conform to the MKAnnotation protocol.
     */
    open func add(_ annotations: [MKAnnotation]) {
        for annotation in annotations {
            add(annotation)
        }
    }
    
    /**
     Removes an annotation object from the cluster manager.
     
     - Parameters:
        - annotation: An annotation object. The object must conform to the MKAnnotation protocol.
     */
    open func remove(_ annotation: MKAnnotation) {
        tree.remove(annotation)
    }
    
    /**
     Removes an array of annotation objects from the cluster manager.
     
     - Parameters:
        - annotations: An array of annotation objects. Each object in the array must conform to the MKAnnotation protocol.
     */
    open func remove(_ annotations: [MKAnnotation]) {
        for annotation in annotations {
            remove(annotation)
        }
    }
    
    /**
     Removes all the annotation objects from the cluster manager.
     */
    open func removeAll() {
        tree = QuadTree(rect: MKMapRectWorld)
    }
    
    /**
     The list of annotations associated.
     
     The objects in this array must adopt the MKAnnotation protocol. If no annotations are associated with the cluster manager, the value of this property is an empty array.
     */
    open var annotations: [MKAnnotation] {
        return tree.annotations(in: MKMapRectWorld)
    }
    
    /**
     The list of visible annotations associated.
     */
    public var visibleAnnotations = [MKAnnotation]()
    
    /**
     Reload the annotations on the map view.
     
     - Parameters:
        - mapView: The map view object to reload.
     */
    open func reload(_ mapView: MKMapView, visibleMapRect: MKMapRect) {
        let zoomScale = ZoomScale(mapView.bounds.width) / visibleMapRect.size.width
        let (toAdd, toRemove) = clusteredAnnotations(mapView, zoomScale: zoomScale, visibleMapRect: visibleMapRect)
        mapView.removeAnnotations(toRemove)
        mapView.addAnnotations(toAdd)
        visibleAnnotations.subtract(toRemove)
        visibleAnnotations.add(toAdd)
    }
    
    func clusteredAnnotations(_ mapView: MKMapView, zoomScale: ZoomScale, visibleMapRect: MKMapRect) -> (toAdd: [MKAnnotation], toRemove: [MKAnnotation]) {
        guard !zoomScale.isInfinite else { return (toAdd: [], toRemove: []) }
        
        let zoomLevel = zoomScale.zoomLevel()
        let cellSize = zoomLevel.cellSize()
        let scaleFactor = zoomScale / cellSize
        
        let minX = Int(floor(visibleMapRect.minX * scaleFactor))
        let maxX = Int(floor(visibleMapRect.maxX * scaleFactor))
        let minY = Int(floor(visibleMapRect.minY * scaleFactor))
        let maxY = Int(floor(visibleMapRect.maxY * scaleFactor))
        
        var clusteredAnnotations = [MKAnnotation]()
        
        for x in minX...maxX {
            for y in minY...maxY {
                var mapRect = MKMapRect(x: Double(x) / scaleFactor, y: Double(y) / scaleFactor, width: 1 / scaleFactor, height: 1 / scaleFactor)
                if mapRect.origin.x > MKMapPointMax.x {
                    mapRect.origin.x -= MKMapPointMax.x
                }
                
                var totalLatitude: Double = 0
                var totalLongitude: Double = 0
                var annotations = [MKAnnotation]()
                var hash = [CLLocationCoordinate2D: [MKAnnotation]]()
                
                for node in tree.annotations(in: mapRect) {
                    totalLatitude += node.coordinate.latitude
                    totalLongitude += node.coordinate.longitude
                    annotations.append(node)
                    hash[node.coordinate, defaultValue: [MKAnnotation]()] += [node]
                }
                
                for value in hash.values {
                    for (index, node) in value.enumerated() {
                        let distanceFromContestedLocation = 3 * Double(value.count) / 2
                        let radiansBetweenAnnotations = (.pi * 2) / Double(value.count)
                        let bearing = radiansBetweenAnnotations * Double(index)
                        (node as? Annotation)?.coordinate = node.coordinate.coordinate(onBearingInRadians: bearing, atDistanceInMeters: distanceFromContestedLocation)
                    }
                }
                
                let count = annotations.count
                if count >= minimumCountForCluster, Int(zoomLevel) <= self.zoomLevel {
                    let coordinate = CLLocationCoordinate2D(
                        latitude: CLLocationDegrees(totalLatitude) / CLLocationDegrees(count),
                        longitude: CLLocationDegrees(totalLongitude) / CLLocationDegrees(count)
                    )
                    let cluster = ClusterAnnotation()
                    cluster.coordinate = coordinate
                    cluster.annotations = annotations
                    cluster.type = (annotations.first as? Annotation)?.type
                    clusteredAnnotations.append(cluster)
                } else {
                    clusteredAnnotations += annotations
                }
            }
        }
        
        let before = visibleAnnotations
        let after = clusteredAnnotations
        
        var toRemove = before.subtracted(after)
        let toAdd = after.subtracted(before)
        
        if !shouldRemoveInvisibleAnnotations {
            let nonRemoving = toRemove.filter { !visibleMapRect.contains($0.coordinate) }
            toRemove.subtract(nonRemoving)
        }
        
        return (toAdd: toAdd, toRemove: toRemove)
    }
    
}
