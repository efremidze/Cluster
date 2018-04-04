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
     The size of each cell on the grid (The larger the size, the better the performance).
     
     If nil, automatically adjusts the cell size to zoom level. Defaults to nil.
     */
    open var cellSize: Double?
    
    /**
     The current zoom level of the visible map region.
     
     Min value is 0 (max zoom out), max is 20 (max zoom in).
     */
    open internal(set) var zoomLevel: Double = 0
    
    /**
     The maximum zoom level before disabling clustering.
     
     Min value is 0 (max zoom out), max is 20 (max zoom in).
     */
    open var maxZoomLevel: Double = .maxZoomLevel
    
    /**
     The minimum number of annotations for a cluster.
     */
    open var minCountForClustering: Int = 2
    
    /**
     Whether to remove invisible annotations.
     */
    open var shouldRemoveInvisibleAnnotations: Bool = true
    
    /**
     The position of the cluster annotation.
     */
    public enum ClusterPosition {
        /**
         Placed in the center of the grid.
         */
        case center
        
        /**
         Placed on the coordinate of the annotation closest to center of the grid.
         */
        case nearCenter
        
        /**
         Placed on the computed average of the coordinates of all annotations in a cluster.
         */
        case average
        
        /**
         Placed on the coordinate of first annotation in a cluster.
         */
        case first
    }
    
    /**
     The position of the cluster annotation. The default is `.nearCenter`.
     */
    open var clusterPosition: ClusterPosition = .nearCenter
    
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
    open var visibleAnnotations = [MKAnnotation]()
    
    open var queue = OperationQueue()
    
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
     Reload the annotations on the map view.
     
     - Parameters:
        - mapView: The map view object to reload.
        - visibleMapRect: The area currently displayed by the map view.
     */
    @available(*, deprecated: 2.1.4, message: "Use reload(mapView:)")
    open func reload(_ mapView: MKMapView, visibleMapRect: MKMapRect) {
        reload(mapView: mapView)
    }
    
    /**
     Reload the annotations on the map view.
     
     - Parameters:
        - mapView: The map view object to reload.
     */
    open func reload(mapView: MKMapView) {
        let mapBounds = mapView.bounds
        let visibleMapRect = mapView.visibleMapRect
        let visibleMapRectWidth = visibleMapRect.size.width
        let zoomScale = Double(mapBounds.width) / visibleMapRectWidth
        queue.cancelAllOperations()
        queue.addOperation { [unowned self, unowned mapView] operation in
            autoreleasepool {
                let (toAdd, toRemove) = self.clusteredAnnotations(zoomScale: zoomScale, visibleMapRect: visibleMapRect)
                guard !operation.isCancelled else { return }
                DispatchQueue.main.async { [unowned self, unowned mapView] in
                    self.display(mapView: mapView, toAdd: toAdd, toRemove: toRemove)
                }
            }
        }
    }
    
    open func clusteredAnnotations(zoomScale: Double, visibleMapRect: MKMapRect) -> (toAdd: [MKAnnotation], toRemove: [MKAnnotation]) {
        guard !zoomScale.isInfinite else { return (toAdd: [], toRemove: []) }
        
        zoomLevel = zoomScale.zoomLevel
        let scaleFactor = zoomScale / (cellSize ?? zoomScale.cellSize)
        
        let minX = Int(floor(visibleMapRect.minX * scaleFactor))
        let maxX = Int(floor(visibleMapRect.maxX * scaleFactor))
        let minY = Int(floor(visibleMapRect.minY * scaleFactor))
        let maxY = Int(floor(visibleMapRect.maxY * scaleFactor))
        
        var allAnnotations = [MKAnnotation]()
        
//        mapView.removeOverlays(mapView.overlays)
//        mapView.add(MKBasePolyline(mapRect: visibleMapRect))
        
        for x in minX...maxX {
            for y in minY...maxY {
                var mapRect = MKMapRect(x: Double(x) / scaleFactor, y: Double(y) / scaleFactor, width: 1 / scaleFactor, height: 1 / scaleFactor)
                if mapRect.origin.x > MKMapPointMax.x {
                    mapRect.origin.x -= MKMapPointMax.x
                }
                
//                mapView.add(MKPolyline(mapRect: mapRect))
                
                var totalLatitude: Double = 0
                var totalLongitude: Double = 0
                var annotations = [MKAnnotation]()
                var hash = [CLLocationCoordinate2D: [MKAnnotation]]()
                
                // add annotations
                for node in tree.annotations(in: mapRect) {
                    totalLatitude += node.coordinate.latitude
                    totalLongitude += node.coordinate.longitude
                    annotations.append(node)
                    hash[node.coordinate, default: [MKAnnotation]()] += [node]
                }
                
                // handle annotations on the same coordinate
                for value in hash.values where value.count > 1 {
                    for (index, node) in value.enumerated() {
                        let distanceFromContestedLocation = 3 * Double(value.count) / 2
                        let radiansBetweenAnnotations = (.pi * 2) / Double(value.count)
                        let bearing = radiansBetweenAnnotations * Double(index)
                        (node as? Annotation)?.coordinate = node.coordinate.coordinate(onBearingInRadians: bearing, atDistanceInMeters: distanceFromContestedLocation)
                    }
                }
                
                // handle clustering
                let count = annotations.count
                if count >= minCountForClustering, zoomLevel <= maxZoomLevel {
                    let cluster = ClusterAnnotation()
                    switch clusterPosition {
                    case .center:
                        cluster.coordinate = MKCoordinateForMapPoint(MKMapPoint(x: mapRect.midX, y: mapRect.midY))
                    case .nearCenter:
                        let coordinate = MKCoordinateForMapPoint(MKMapPoint(x: mapRect.midX, y: mapRect.midY))
                        if let annotation = annotations.min(by: { coordinate.distance(from: $0.coordinate) < coordinate.distance(from: $1.coordinate) }) {
                            cluster.coordinate = annotation.coordinate
                        }
                    case .average:
                        cluster.coordinate = CLLocationCoordinate2D(
                            latitude: CLLocationDegrees(totalLatitude) / CLLocationDegrees(count),
                            longitude: CLLocationDegrees(totalLongitude) / CLLocationDegrees(count)
                        )
                    case .first:
                        if let annotation = annotations.first {
                            cluster.coordinate = annotation.coordinate
                        }
                    }
                    cluster.annotations = annotations
                    cluster.style = (annotations.first as? Annotation)?.style
                    allAnnotations += [cluster]
                } else {
                    allAnnotations += annotations
                }
            }
        }
        
        let before = visibleAnnotations
        let after = allAnnotations
        
        var toRemove = before.subtracted(after)
        let toAdd = after.subtracted(before)
        
        if !shouldRemoveInvisibleAnnotations {
            let nonRemoving = toRemove.filter { !visibleMapRect.contains($0.coordinate) }
            toRemove.subtract(nonRemoving)
        }
        
        return (toAdd: toAdd, toRemove: toRemove)
    }
    
    open func display(mapView: MKMapView, toAdd: [MKAnnotation], toRemove: [MKAnnotation]) {
        mapView.removeAnnotations(toRemove)
        mapView.addAnnotations(toAdd)
        visibleAnnotations.subtract(toRemove)
        visibleAnnotations.add(toAdd)
    }
    
}

//public class MKBasePolyline: MKPolyline {}
