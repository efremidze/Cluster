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
    
    let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
        return queue
    }()
    
    /**
     Controls the level from which clustering will be enabled. Min value is 2 (max zoom out), max is 20 (max zoom in).
     */
    open var zoomLevel: Int = 20 {
        didSet {
            zoomLevel = zoomLevel.clamped(to: 2...20)
        }
    }

    open var minimumCountForCluster: Int = 2

    // Sets whether to remove the non visible annotations when panning / zooming
    var removeNonVisibleAnnotations:Bool=true
    
    open func setRemoveNonVisibleAnnotations(needToRemove:Bool){
        self.removeNonVisibleAnnotations=needToRemove
    }
    
    open func getRemoveNonVisibleAnnotations() -> Bool {
        return self.removeNonVisibleAnnotations
    }
    
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
     The complete list of annotations associated.
     
     The objects in this array must adopt the MKAnnotation protocol. If no annotations are associated with the cluster manager, the value of this property is an empty array.
     */
    open var annotations: [MKAnnotation] {
        return tree.annotations(in: MKMapRectWorld)
    }
    
    /**
     Reload the annotations on the map view.
     
     - Parameters:
        - mapView: The map view object to reload.
     */
    open func reload(_ mapView: MKMapView, visibleMapRect: MKMapRect, completion: (() -> Void)? = nil) {
        let zoomScale = ZoomScale(mapView.bounds.width) / visibleMapRect.size.width
        let operation = BlockOperation()
        operation.addExecutionBlock { [weak self, weak mapView] in
            guard let strongSelf = self, let mapView = mapView else { return }
            let (toAdd, toRemove) = strongSelf.clusteredAnnotations(mapView, zoomScale: zoomScale, visibleMapRect: visibleMapRect, operation: operation)
            if !operation.isCancelled {
                DispatchQueue.main.async { [weak mapView] in
                    guard let mapView = mapView else { return }
                    mapView.removeAnnotations(toRemove)
                    mapView.addAnnotations(toAdd)
                    completion?()
                }
            }
        }
        queue.cancelAllOperations()
        queue.addOperation(operation)
    }
    
    func clusteredAnnotations(_ mapView: MKMapView, zoomScale: ZoomScale, visibleMapRect: MKMapRect, operation: Operation) -> (toAdd: [MKAnnotation], toRemove: [MKAnnotation]) {
        guard !zoomScale.isInfinite else { return (toAdd: [], toRemove: []) }
        
        let zoomLevel = zoomScale.zoomLevel()
        let cellSize = zoomLevel.cellSize()
        let scaleFactor = zoomScale / cellSize
        
        let minX = Int(floor(visibleMapRect.minX * scaleFactor))
        let maxX = Int(floor(visibleMapRect.maxX * scaleFactor))
        let minY = Int(floor(visibleMapRect.minY * scaleFactor))
        let maxY = Int(floor(visibleMapRect.maxY * scaleFactor))
        
        var clusteredAnnotations = [MKAnnotation]()
        
        for x in minX...maxX where !operation.isCancelled {
            for y in minY...maxY where !operation.isCancelled {
                var mapRect = MKMapRect(x: Double(x) / scaleFactor, y: Double(y) / scaleFactor, width: 1 / scaleFactor, height: 1 / scaleFactor)
                if mapRect.origin.x > MKMapPointMax.x {
                    mapRect.origin.x -= MKMapPointMax.x
                }
                
                var totalLatitude: Double = 0
                var totalLongitude: Double = 0
                var annotations = [MKAnnotation]()
                
                for node in tree.annotations(in: mapRect) {
                    totalLatitude += node.coordinate.latitude
                    totalLongitude += node.coordinate.longitude
                    annotations.append(node)
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
                    clusteredAnnotations.append(cluster)
                } else {
                    clusteredAnnotations += annotations
                }
            }
        }
        
        if operation.isCancelled { return (toAdd: [], toRemove: []) }

        let before = Set<NSObject>(mapView.annotations as! Array<NSObject>)
        let after = Set<NSObject>(clusteredAnnotations as! Array<NSObject>)

        let toRemove = before.subtracting(after)
        let toAdd = after.subtracting(before)
        
         if !self.removeNonVisibleAnnotations {            
            var nonRemoving = Set<NSObject>()
            for point in toRemove.allObjects {
                if !visibleMapRect.contains((point as AnyObject).coordinate) {
                    nonRemoving.insert(point as! NSObject)
                }
            }
            
            if nonRemoving.count > 0 {
                toRemove.minus(nonRemoving)
            }
        }

        return (toAdd: Array(toAdd) as! Array<MKAnnotation>, toRemove: Array(toRemove) as! Array<MKAnnotation>)
    }
    
}
