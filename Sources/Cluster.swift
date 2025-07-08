//
//  Cluster.swift
//  Cluster
//
//  Created by Lasha Efremidze on 4/13/17.
//  Copyright © 2017 efremidze. All rights reserved.
//

import CoreLocation
import MapKit

public protocol ClusterManagerDelegate: AnyObject {
    /**
     The size of each cell on the grid (The larger the size, the better the performance) at a given zoom level.
     
     - Parameters:
        - zoomLevel: The zoom level of the visible map region.
     
     - Returns: The cell size at the given zoom level. If you return nil, the cell size will automatically adjust to the zoom level.
     */
    func cellSize(for zoomLevel: Double) -> Double?
    
    /**
     Whether to cluster the given annotation.
     
     - Parameters:
        - annotation: An annotation object. The object must conform to the MKAnnotation protocol.

     - Returns: `true` to clusterize the given annotation.
     */
    func shouldClusterAnnotation(_ annotation: MKAnnotation) -> Bool
}

public extension ClusterManagerDelegate {
    func cellSize(for zoomLevel: Double) -> Double? {
        return nil
    }
    
    func shouldClusterAnnotation(_ annotation: MKAnnotation) -> Bool {
        return true
    }
}

open class ClusterManager {
    
    var tree = QuadTree(rect: .world)
    
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
     The distance in meters from contested location when the annotations have the same coordinate.

     The default is 3.
    */
    open var distanceFromContestedLocation: Double = 3

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
        dispatchQueue.async(flags: .barrier) { [weak self] in
            self?.tree.add(annotation)
        }
    }
    
    /**
     Adds an array of annotation objects to the cluster manager.
     
     - Parameters:
        - annotations: An array of annotation objects. Each object in the array must conform to the MKAnnotation protocol.
     */
    open func add(_ annotations: [MKAnnotation]) {
        operationQueue.cancelAllOperations()
        dispatchQueue.async(flags: .barrier) { [weak self] in
            for annotation in annotations {
                self?.tree.add(annotation)
            }
        }
    }
    
    /**
     Removes an annotation object from the cluster manager.
     
     - Parameters:
        - annotation: An annotation object. The object must conform to the MKAnnotation protocol.
     */
    open func remove(_ annotation: MKAnnotation) {
        operationQueue.cancelAllOperations()
        dispatchQueue.async(flags: .barrier) { [weak self] in
            self?.tree.remove(annotation)
        }
    }
    
    /**
     Removes an array of annotation objects from the cluster manager.
     
     - Parameters:
        - annotations: An array of annotation objects. Each object in the array must conform to the MKAnnotation protocol.
     */
    open func remove(_ annotations: [MKAnnotation]) {
        operationQueue.cancelAllOperations()
        dispatchQueue.async(flags: .barrier) { [weak self] in
            for annotation in annotations {
                self?.tree.remove(annotation)
            }
        }
    }
    
    /**
     Removes all the annotation objects from the cluster manager.
     */
    open func removeAll() {
        operationQueue.cancelAllOperations()
        dispatchQueue.async(flags: .barrier) { [weak self] in
            self?.tree = QuadTree(rect: .world)
        }
    }
    
    /**
     Reload the annotations on the map view.
     
     - Parameters:
        - mapView: The map view object to reload.
        - visibleMapRect: The area currently displayed by the map view.
     */
    @available(swift, obsoleted: 5.0, message: "Use reload(mapView:)")
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
        
        guard !isCancelled else { return (toAdd: [], toRemove: []) }
        
        // handle annotations on the same coordinate
        if shouldDistributeAnnotationsOnSameCoordinate {
            distributeAnnotations(tree: tree, mapRect: visibleMapRect)
        }
        
        let allAnnotations = dispatchQueue.sync {
            clusteredAnnotations(tree: tree, mapRects: mapRects, zoomLevel: zoomLevel)
        }
        
        guard !isCancelled else { return (toAdd: [], toRemove: []) }
        
        let before = visibleAnnotations
        let after = allAnnotations
        
        var toRemove = before.subtracted(after)
        let toAdd = after.subtracted(before)
        
        if !shouldRemoveInvisibleAnnotations {
            let toKeep = toRemove.filter { !visibleMapRect.contains($0.coordinate) }
            toRemove.subtract(toKeep)
        }
        
        dispatchQueue.async(flags: .barrier) { [weak self] in
            self?.visibleAnnotations.subtract(toRemove)
            self?.visibleAnnotations.add(toAdd)
        }
        
        return (toAdd: toAdd, toRemove: toRemove)
    }
    
    func clusteredAnnotations(tree: QuadTree, mapRects: [MKMapRect], zoomLevel: Double) -> [MKAnnotation] {
        var allAnnotations = [MKAnnotation]()
        for mapRect in mapRects {
            var annotations = [MKAnnotation]()
            
            // add annotations
            for node in tree.annotations(in: mapRect) {
                if delegate?.shouldClusterAnnotation(node) ?? true {
                    annotations.append(node)
                } else {
                    allAnnotations.append(node)
                }
            }
            
            // handle clustering
            let count = annotations.count
            if count >= minCountForClustering, zoomLevel <= maxZoomLevel {
                let cluster = ClusterAnnotation()
                cluster.coordinate = coordinate(annotations: annotations, position: clusterPosition, mapRect: mapRect)
                cluster.annotations = annotations
                cluster.style = (annotations.first as? Annotation)?.style
                allAnnotations += [cluster]
            } else {
                allAnnotations += annotations
            }
        }
        return allAnnotations
    }
    
    func distributeAnnotations(tree: QuadTree, mapRect: MKMapRect) {
        let annotations = dispatchQueue.sync {
            tree.annotations(in: mapRect)
        }
        let hash = Dictionary(grouping: annotations) { $0.coordinate }
        dispatchQueue.async(flags: .barrier) {
            for value in hash.values where value.count > 1 {
                for (index, annotation) in value.enumerated() {
                    tree.remove(annotation)
                    let radiansBetweenAnnotations = (.pi * 2) / Double(value.count)
                    let bearing = radiansBetweenAnnotations * Double(index)
                    (annotation as? MKPointAnnotation)?.coordinate = annotation.coordinate.coordinate(onBearingInRadians: bearing, atDistanceInMeters: self.distanceFromContestedLocation)
                    tree.add(annotation)
                }
            }
        }
    }
    
    func coordinate(annotations: [MKAnnotation], position: ClusterPosition, mapRect: MKMapRect) -> CLLocationCoordinate2D {
        switch position {
        case .center:
            return MKMapPoint(x: mapRect.midX, y: mapRect.midY).coordinate
        case .nearCenter:
            let coordinate = MKMapPoint(x: mapRect.midX, y: mapRect.midY).coordinate
            let annotation = annotations.min { coordinate.distance(from: $0.coordinate) < coordinate.distance(from: $1.coordinate) }
            return annotation!.coordinate
        case .average:
            let coordinates = annotations.map { $0.coordinate }
            let totals = coordinates.reduce((latitude: 0.0, longitude: 0.0)) { ($0.latitude + $1.latitude, $0.longitude + $1.longitude) }
            return CLLocationCoordinate2D(latitude: totals.latitude / Double(coordinates.count), longitude: totals.longitude / Double(coordinates.count))
        case .first:
            return annotations.first!.coordinate
        }
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
        if let cellSize = delegate?.cellSize(for: zoomLevel) {
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
