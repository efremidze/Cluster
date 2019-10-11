//
//  Tests.swift
//  Tests
//
//  Created by Lasha Efremidze on 7/11/18.
//  Copyright © 2018 efremidze. All rights reserved.
//

import XCTest
import MapKit

@testable import Cluster

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}

extension Tests {
    
    var mapRect: MKMapRect {
        return MKMapRect(x: 42906844.828649245, y: 103677256.9496724, width: 74565.404444441199, height: 132626.99937182665)
    }
    var center: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: 37.787994, longitude: -122.407437)
    }
    var delta: Double {
        return 0.1
    }
    var zoomScale: Double {
        return 0.01
    }
    
    func testAnnotations() {
        let identifier = "identifier"
        let annotation = ClusterAnnotation()
        let text = "\(annotation.annotations.count)"
        let annotationView = ClusterAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        XCTAssertEqual(annotationView.reuseIdentifier, identifier)
        if let _annotation = annotationView.annotation as? ClusterAnnotation {
            XCTAssertEqual(_annotation, annotation)
            XCTAssertEqual(annotationView.countLabel.text, text)
        } else {
            XCTAssertTrue(false)
        }
    }
    
    func testAddAndRemoveAllAnnotations() {
        let manager = ClusterManager()
        
        manager.addAnnotations(count: 1000, center: center, delta: delta)
        
        let (toAdd, toRemove) = manager.clusteredAnnotations(zoomScale: zoomScale, visibleMapRect: mapRect)
        
        XCTAssertTrue(!toAdd.isEmpty)
        XCTAssertTrue(toRemove.isEmpty)
        
        manager.removeAll()
        
        let (toAdd2, toRemove2) = manager.clusteredAnnotations(zoomScale: zoomScale, visibleMapRect: mapRect)
        
        XCTAssertTrue(toAdd2.isEmpty)
        XCTAssertTrue(!toRemove2.isEmpty)
        
        XCTAssertEqual(toAdd.count, toRemove2.count)
        XCTAssertEqual(toAdd2.count, toRemove.count)
    }
    
    func testAddAndRemoveAnnotations() {
        let manager = ClusterManager()
        
        let annotations = manager.addAnnotations(count: 1000, center: center, delta: delta)
        
        let (toAdd, toRemove) = manager.clusteredAnnotations(zoomScale: zoomScale, visibleMapRect: mapRect)
        
        XCTAssertTrue(!toAdd.isEmpty)
        XCTAssertTrue(toRemove.isEmpty)
        
        manager.remove(annotations)
        
        let (toAdd2, toRemove2) = manager.clusteredAnnotations(zoomScale: zoomScale, visibleMapRect: mapRect)
        
        XCTAssertTrue(toAdd2.isEmpty)
        XCTAssertTrue(!toRemove2.isEmpty)
        
        XCTAssertEqual(toAdd.count, toRemove2.count)
        XCTAssertEqual(toAdd2.count, toRemove.count)
    }
    
    
    func testClusterPositionCenter() {
        let manager = ClusterManager()
        manager.clusterPosition = .center
        
        manager.addAnnotations(count: 1000, center: center, delta: delta)
        
        _ = manager.clusteredAnnotations(zoomScale: zoomScale, visibleMapRect: mapRect)
        
        XCTAssertTrue(manager.visibleNestedAnnotations.count == 1000)
    }
    
    func testClusterPositionNearCenter() {
        let manager = ClusterManager()
        manager.clusterPosition = .nearCenter
        
        manager.addAnnotations(count: 1000, center: center, delta: delta)
        
        _ = manager.clusteredAnnotations(zoomScale: zoomScale, visibleMapRect: mapRect)
        
        XCTAssertTrue(manager.visibleNestedAnnotations.count == 1000)
    }
    
    func testClusterPositionAverage() {
        let manager = ClusterManager()
        manager.clusterPosition = .average
        
        manager.addAnnotations(count: 1000, center: center, delta: delta)
        
        _ = manager.clusteredAnnotations(zoomScale: zoomScale, visibleMapRect: mapRect)
        
        XCTAssertTrue(manager.visibleNestedAnnotations.count == 1000)
    }
    
    func testClusterPositionFirst() {
        let manager = ClusterManager()
        manager.clusterPosition = .first
        
        manager.addAnnotations(count: 1000, center: center, delta: delta)
        
        _ = manager.clusteredAnnotations(zoomScale: zoomScale, visibleMapRect: mapRect)
        
        XCTAssertTrue(manager.visibleNestedAnnotations.count == 1000)
    }
    
    func testSameCoordinate() {
        let manager = ClusterManager()
        manager.shouldDistributeAnnotationsOnSameCoordinate = false
        
        manager.addAnnotations(count: 1000, center: center, delta: delta)
        
        _ = manager.clusteredAnnotations(zoomScale: zoomScale, visibleMapRect: mapRect)
        
        XCTAssertTrue(manager.visibleNestedAnnotations.count == 1000)
    }
    
    func testRemoveInvisibleAnnotations() {
        let manager = ClusterManager()
        manager.shouldRemoveInvisibleAnnotations = false
        
        manager.addAnnotations(count: 1000, center: center, delta: delta)
        
        _ = manager.clusteredAnnotations(zoomScale: zoomScale, visibleMapRect: mapRect)
        
        XCTAssertTrue(manager.visibleNestedAnnotations.count == 1000)
    }
    
    func testMinCountForClustering() {
        let manager = ClusterManager()
        manager.minCountForClustering = 10
        
        manager.addAnnotations(count: 1000, center: center, delta: delta)
        
        _ = manager.clusteredAnnotations(zoomScale: zoomScale, visibleMapRect: mapRect)
        
        XCTAssertTrue(manager.visibleNestedAnnotations.count == 1000)
    }
    
    func testCancelOperation() {
        let manager = ClusterManager()
        manager.addAnnotations(count: 1000, center: center, delta: delta)
        
        let expectation = self.expectation(description: "Clustering")
        
        manager.clusteredAnnotations(zoomScale: zoomScale, visibleMapRect: mapRect) { finished in
            XCTAssertFalse(finished)
        }
        manager.clusteredAnnotations(zoomScale: zoomScale, visibleMapRect: mapRect) { finished in
            XCTAssertTrue(finished)
            expectation.fulfill()
        }
        
        let result = XCTWaiter.wait(for: [expectation], timeout: 10)
        
        XCTAssertTrue(result == .completed)
        XCTAssertTrue(manager.visibleNestedAnnotations.count == 1000)
    }
    
    func testMultipleOperations() {
        let manager = ClusterManager()
        manager.addAnnotations(count: 1000, center: center, delta: delta)
        
        let expectation = self.expectation(description: "Clustering")
        expectation.assertForOverFulfill = true
        
        self.measure {
        for i in 0...100 {
            DispatchQueue.global().async {
                manager.clusteredAnnotations(zoomScale: self.zoomScale, visibleMapRect: self.mapRect) { finished in
                    if i == 100 {
                        expectation.fulfill()
                    }
                }
            }
        }
        }
        
        let result = XCTWaiter.wait(for: [expectation], timeout: 10)
        
        XCTAssertTrue(result == .completed)
        XCTAssertTrue(manager.visibleNestedAnnotations.count == 1000)
    }
    
}

extension ClusterManager {
    @discardableResult
    func addAnnotations(count: Int, center: CLLocationCoordinate2D, delta: Double) -> [MKAnnotation] {
        let annotations: [Annotation] = (0..<count).map { i in
            let annotation = Annotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: center.latitude + drand48() * delta - delta / 2, longitude: center.longitude + drand48() * delta - delta / 2)
            return annotation
        }
        add(annotations)
        return annotations
    }
    
    func clusteredAnnotations(zoomScale: Double, visibleMapRect: MKMapRect, completion: @escaping (Bool) -> Void) {
        operationQueue.cancelAllOperations()
        operationQueue.addBlockOperation { [weak self] operation in
            guard let self = self else { return }
            _ = self.clusteredAnnotations(zoomScale: zoomScale, visibleMapRect: visibleMapRect, operation: operation)
            DispatchQueue.main.async {
                completion(!operation.isCancelled)
            }
        }
    }
}
