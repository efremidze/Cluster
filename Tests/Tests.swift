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
    
    func testAnnotation() {
        let identifier = "identifier"
        let color: UIColor = .red
        let radius: CGFloat = 20
        let image = UIImage()
        let annotation = ClusterAnnotation()
        
        var style = ClusterAnnotationStyle.color(color, radius: radius)
        var annotationView = ClusterAnnotationView(annotation: annotation, reuseIdentifier: identifier, style: style)
        
        XCTAssertEqual(annotationView.reuseIdentifier, identifier)
        if case ClusterAnnotationStyle.color(let _color, let _radius) = annotationView.style {
            XCTAssertEqual(_color, color)
            XCTAssertEqual(_radius, radius)
        } else {
            XCTAssertTrue(false)
        }
        
        style = ClusterAnnotationStyle.image(image)
        annotationView = ClusterAnnotationView(annotation: annotation, reuseIdentifier: identifier, style: style)
        
        XCTAssertEqual(annotationView.reuseIdentifier, identifier)
        if case ClusterAnnotationStyle.image(let _image) = annotationView.style {
            XCTAssertEqual(_image, image)
        } else {
            XCTAssertTrue(false)
        }
    }
    
    func testAddRemoveAnnotation() {
        let manager = ClusterManager()
        
        let annotations: [Annotation] = (0..<1000).map { i in
            let annotation = Annotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: center.latitude + drand48() * delta - delta / 2, longitude: center.longitude + drand48() * delta - delta / 2)
            return annotation
        }
        manager.add(annotations)
        
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
    
}
