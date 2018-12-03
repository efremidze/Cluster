//
//  Cluster.swift
//  Cluster
//
//  Created by Lasha Efremidze on 4/13/17.
//  Copyright © 2017 efremidze. All rights reserved.
//

import CoreLocation
import MapKit

public protocol ClusterManagerDelegate: class {
    /**
     The size of each cell on the grid (The larger the size, the better the performance) at a given zoom level.
     
     - Parameters:
        - zoomLevel: The zoom level of the visible map region.
     
     - Returns: The cell size at the given zoom level.
     */
    func cellSize(for zoomLevel: Double) -> Double
    
    /**
     Whether to cluster the given annotation.
     
     - Parameters:
        - annotation: An annotation object. The object must conform to the MKAnnotation protocol.

     - Returns: `true` to clusterize the given annotation.
     */
    func shouldClusterAnnotation(_ annotation: MKAnnotation) -> Bool
}

public extension ClusterManagerDelegate {
    func cellSize(for zoomLevel: Double) -> Double {
        return 0
    }
    
    func shouldClusterAnnotation(_ annotation: MKAnnotation) -> Bool {
        return true
    }
}

open class ClusterManager {
    
    var tree = QuadTree(rect: .world)
    
    /**
     The size of each cell on the grid (The larger the size, the better the performance).
     
     If nil, automatically adjusts the cell size to zoom level. The default is nil.
     */
    @available(*, deprecated: 2.3.0, message: "Use cellSize(forZoomLevel:)")
    open var cellSize: Double?
    
    /**
     The current zoom level of the visible map region.
     
     Min value is 0 (max zoom out), max is 20 (max zoom in).
     */
    open internal(set) var zoomLevel: Double = 0
    
    /**
     The maximum zoom level before disabling clustering.
     
     Min value is 0 (max zoom out), max is 20 (max zoom in). The default is 20.
     */
    open var maxZoomLevel: Double = 20
    
    /**
     The minimum number of annotations for a cluster.
     
     The default is 2.
     */
    open var minCountForClustering: Int = 2
    
    /**
     Whether to remove invisible annotations.
     
     The default is true.
     */
    open var shouldRemoveInvisibleAnnotations: Bool = true
    
    /**
     Whether to arrange annotations in a circle if they have the same coordinate.
     
     The default is true.
     */
    open var shouldDistributeAnnotationsOnSameCoordinate: Bool = true
    
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
        return dispatchQueue.sync {
            tree.annotations(in: .world)
        }
    }
    
    /**
     The list of visible annotations associated.
     */
    open var visibleAnnotations = [MKAnnotation]()
    
    /**
     The list of nested visible annotations associated.
     */
    open var visibleNestedAnnotations: [MKAnnotation] {
        return dispatchQueue.sync {
            visibleAnnotations.reduce([MKAnnotation](), { $0 + (($1 as? ClusterAnnotation)?.annotations ?? [$1]) })
        }
    }
    
    let operationQueue = OperationQueue.serial
    let dispatchQueue = DispatchQueue(label: "com.cluster.concurrentQueue", attributes: .concurrent)
    
    open weak var delegate: ClusterManagerDelegate?
    
    public init() {}
    
    /**
     Adds an annotation object to the cluster manager.
     
     - Parameters:
        - annotation: An annotation object. The object must conform to the MKAnnotation protocol.
     */
    open func add(_ annotation: MKAnnotation) {
        operationQueue.cancelAllOperations()
        dispatchQueue.async(flags: .barrier) {
            self.tree.add(annotation)
        }
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
        operationQueue.cancelAllOperations()
        dispatchQueue.async(flags: .barrier) {
            self.tree.remove(annotation)
        }
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
        operationQueue.cancelAllOperations()
        dispatchQueue.async(flags: .barrier) {
            self.tree = QuadTree(rect: .world)
        }
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
        - completion: A closure to be executed when the reload finishes. The closure has no return value and takes a single Boolean argument that indicates whether or not the reload actually finished before the completion handler was called.
     */
    open func reload(mapView: MKMapView, completion: @escaping (Bool) -> Void = { finished in }) {
        let mapBounds = mapView.bounds
        let visibleMapRect = mapView.visibleMapRect
        let visibleMapRectWidth = visibleMapRect.size.width
        let zoomScale = Double(mapBounds.width) / visibleMapRectWidth
        operationQueue.cancelAllOperations()
        operationQueue.addBlockOperation { [weak self, weak mapView] operation in
            guard let self = self, let mapView = mapView else { return completion(false) }
            autoreleasepool {
                let (toAdd, toRemove) = self.clusteredAnnotations(zoomScale: zoomScale, visibleMapRect: visibleMapRect, operation: operation)
                DispatchQueue.main.async { [weak self, weak mapView] in
                    guard let self = self, let mapView = mapView else { return completion(false) }
                    self.display(mapView: mapView, toAdd: toAdd, toRemove: toRemove)
                    completion(true)
                }
            }
        }
    }
    
    open func clusteredAnnotations(zoomScale: Double, visibleMapRect: MKMapRect, operation: Operation? = nil) -> (toAdd: [MKAnnotation], toRemove: [MKAnnotation]) {
        var isCancelled: Bool { return operation?.isCancelled ?? false }
        
        guard !isCancelled else { return (toAdd: [], toRemove: []) }
        
        let mapRects = self.mapRects(zoomScale: zoomScale, visibleMapRect: visibleMapRect)
        
        var allAnnotations = [MKAnnotation]()
        
        dispatchQueue.sync {

        for mapRect in mapRects {
            var totalLatitude: Double = 0
            var totalLongitude: Double = 0
            var annotations = [MKAnnotation]()
            var hash = [CLLocationCoordinate2D: [MKAnnotation]]()
            
            // add annotations
            for node in tree.annotations(in: mapRect) {
                if delegate?.shouldClusterAnnotation(node) ?? true {
                    totalLatitude += node.coordinate.latitude
                    totalLongitude += node.coordinate.longitude
                    annotations.append(node)
                    hash[node.coordinate, default: [MKAnnotation]()] += [node]
                } else {
                    allAnnotations.append(node)
                }
            }
            
            // handle annotations on the same coordinate
            if shouldDistributeAnnotationsOnSameCoordinate {
                for value in hash.values where value.count > 1 {
                    for (index, node) in value.enumerated() {
                        let distanceFromContestedLocation = 3 * Double(value.count) / 2
                        let radiansBetweenAnnotations = (.pi * 2) / Double(value.count)
                        let bearing = radiansBetweenAnnotations * Double(index)
                        (node as? Annotation)?.coordinate = node.coordinate.coordinate(onBearingInRadians: bearing, atDistanceInMeters: distanceFromContestedLocation)
                    }
                }
            }
            
            // handle clustering
            let count = annotations.count
            if count >= minCountForClustering, zoomLevel <= maxZoomLevel {
                let cluster = ClusterAnnotation()
                switch clusterPosition {
                case .center:
                    cluster.coordinate = MKMapPoint(x: mapRect.midX, y: mapRect.midY).coordinate
                case .nearCenter:
                    let coordinate = MKMapPoint(x: mapRect.midX, y: mapRect.midY).coordinate
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
                allAnnotations += [cluster]
            } else {
                allAnnotations += annotations
            }
        }
        
        }
            
        guard !isCancelled else { return (toAdd: [], toRemove: []) }
        
        let before = visibleAnnotations
        let after = allAnnotations
        
        var toRemove = before.subtracted(after)
        let toAdd = after.subtracted(before)
        
        if !shouldRemoveInvisibleAnnotations {
            let nonRemoving = toRemove.filter { !visibleMapRect.contains($0.coordinate) }
            toRemove.subtract(nonRemoving)
        }
        
        dispatchQueue.async(flags: .barrier) {
            
        self.visibleAnnotations.subtract(toRemove)
        self.visibleAnnotations.add(toAdd)
            
        }
        
        return (toAdd: toAdd, toRemove: toRemove)
    }
    
    func mapRects(zoomScale: Double, visibleMapRect: MKMapRect) -> [MKMapRect] {
        guard !zoomScale.isInfinite, !zoomScale.isNaN else { return [] }
        
        zoomLevel = zoomScale.zoomLevel
        let scaleFactor = zoomScale / cellSize(for: zoomLevel)
        
        let minX = Int(floor(visibleMapRect.minX * scaleFactor))
        let maxX = Int(floor(visibleMapRect.maxX * scaleFactor))
        let minY = Int(floor(visibleMapRect.minY * scaleFactor))
        let maxY = Int(floor(visibleMapRect.maxY * scaleFactor))
        
        var mapRects = [MKMapRect]()
        for x in minX...maxX {
            for y in minY...maxY {
                var mapRect = MKMapRect(x: Double(x) / scaleFactor, y: Double(y) / scaleFactor, width: 1 / scaleFactor, height: 1 / scaleFactor)
                if mapRect.origin.x > MKMapPointMax.x {
                    mapRect.origin.x -= MKMapPointMax.x
                }
                mapRects.append(mapRect)
            }
        }
        return mapRects
    }
    
    open func display(mapView: MKMapView, toAdd: [MKAnnotation], toRemove: [MKAnnotation]) {
        assert(Thread.isMainThread, "This function must be called from the main thread.")
        mapView.removeAnnotations(toRemove)
        mapView.addAnnotations(toAdd)
    }
    
    func cellSize(for zoomLevel: Double) -> Double {
        if let cellSize = delegate?.cellSize(for: zoomLevel), cellSize > 0 {
            return cellSize
        }
        switch zoomLevel {
        case 13...15:
            return 64
        case 16...18:
            return 32
        case 19...:
            return 16
        default:
            return 88
        }
    }
    
}
