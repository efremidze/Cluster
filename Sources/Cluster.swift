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
    open func reload(_ mapView: MKMapView, visibleMapRect: MKMapRect) {
        let operation = BlockOperation()
        operation.addExecutionBlock { [weak self, weak mapView] in
            guard let strongSelf = self, let mapView = mapView else { return }
            let (toAdd, toRemove) = strongSelf.clusteredAnnotations(mapView, visibleMapRect: visibleMapRect, operation: operation)
            if !operation.isCancelled {
                DispatchQueue.main.async { [weak mapView] in
                    guard let mapView = mapView else { return }
                    mapView.removeAnnotations(toRemove)
                    mapView.addAnnotations(toAdd)
                }
            }
        }
        queue.cancelAllOperations()
        queue.addOperation(operation)
    }
    
    func clusteredAnnotations(_ mapView: MKMapView, visibleMapRect: MKMapRect, operation: Operation) -> (toAdd: [MKAnnotation], toRemove: [MKAnnotation]) {
        let zoomScale = ZoomScale(mapView.bounds.width) / visibleMapRect.size.width
        
        guard !zoomScale.isInfinite else { return (toAdd: [], toRemove: []) }
        
        let zoomLevel = zoomScale.zoomLevel()
        let cellSize = zoomLevel.cellSize()
        let scaleFactor = zoomScale / cellSize
        
        let minX = Int(floor(visibleMapRect.minX * scaleFactor))
        let maxX = Int(floor(visibleMapRect.maxX * scaleFactor))
        let minY = Int(floor(visibleMapRect.minY * scaleFactor))
        let maxY = Int(floor(visibleMapRect.maxY * scaleFactor))
        
        var clusteredAnnotations = [MKAnnotation]()
        
//        print("visibleMapRect")
        print(visibleMapRect)
        
//        print("annotations")
//        annotations.forEach { print(MKMapPointForCoordinate($0.coordinate)); print(visibleMapRect.contains($0.coordinate)) }
        
        print("X: \(visibleMapRect.minX / 1000000) -> \(visibleMapRect.maxX / 1000000)")
        print("Y: \(visibleMapRect.minY / 1000000) -> \(visibleMapRect.maxY / 1000000)")
        
        print("X: \(minX) -> \(maxX)")
        print("Y: \(minY) -> \(maxY)")
        
        print("-----> looping")
        
        DispatchQueue.main.async { [unowned mapView] in
            mapView.removeOverlays(mapView.overlays)
        }
        
        DispatchQueue.main.async { [unowned mapView] in
            mapView.add(MKCustomPolyline(points: [
                MKMapPoint(x: visibleMapRect.minX, y: visibleMapRect.minY),
                MKMapPoint(x: visibleMapRect.maxX, y: visibleMapRect.minY),
                MKMapPoint(x: visibleMapRect.maxX, y: visibleMapRect.maxY),
                MKMapPoint(x: visibleMapRect.minX, y: visibleMapRect.maxY),
                MKMapPoint(x: visibleMapRect.minX, y: visibleMapRect.minY)
            ], count: 5))
        }
        
        for x in minX...maxX where !operation.isCancelled {
//            for y in 0...0 where !operation.isCancelled {
            for y in minY...maxY where !operation.isCancelled {
                
                let a = Double(x) / scaleFactor
                let b = MKMapPointForCoordinate(CLLocationCoordinate2D(latitude: 0, longitude: 180)).x
                let c = a <= b ? a : a - b
                
                let point = MKMapPoint(x: c, y: Double(y) / scaleFactor)
                let coordinate = MKCoordinateForMapPoint(point)
                print(coordinate)
                
                let mapRect = MKMapRect(origin: point, size: MKMapSize(width: 1 / scaleFactor, height: 1 / scaleFactor))
                
                DispatchQueue.main.async { [unowned mapView] in
                    mapView.add(MKPolyline(points: [
                        MKMapPoint(x: mapRect.minX, y: mapRect.minY),
                        MKMapPoint(x: mapRect.maxX, y: mapRect.minY),
                        MKMapPoint(x: mapRect.maxX, y: mapRect.maxY),
                        MKMapPoint(x: mapRect.minX, y: mapRect.maxY),
                        MKMapPoint(x: mapRect.minX, y: mapRect.minY)
                    ], count: 5))
                }
                
                var totalLatitude: Double = 0
                var totalLongitude: Double = 0
                var annotations = [MKAnnotation]()
                
                print(mapRect)
                print("X: \(mapRect.minX / 1000000) -> \(mapRect.maxX / 1000000)")
                print("Y: \(mapRect.minY / 1000000) -> \(mapRect.maxY / 1000000)")
                print("\(x)-\(y)")
                
                if MKMapRectSpans180thMeridian(mapRect) {
                    print("---->")
                }
               
//                print("annotations")
//                annotations.forEach { print(MKMapPointForCoordinate($0.coordinate)); print(mapRect.contains($0.coordinate)) }
                
                for node in tree.annotations(in: mapRect) {
                    totalLatitude += node.coordinate.latitude
                    totalLongitude += node.coordinate.longitude
                    annotations.append(node)
                }
                
                let count = annotations.count
                if count > 1, Int(zoomLevel) <= self.zoomLevel {
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
//            break
        }
        
        if operation.isCancelled { return (toAdd: [], toRemove: []) }
        
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

public class MKCustomPolyline: MKPolyline {}
