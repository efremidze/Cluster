//
//  Tests.swift
//  Tests
//
//  Created by Lasha Efremidze on 7/11/18.
//  Copyright © 2018 efremidze. All rights reserved.
//

import XCTest
import Cluster

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
    
}
