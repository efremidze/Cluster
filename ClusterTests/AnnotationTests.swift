//
//  AnnotationTests.swift
//  ClusterTests
//
//  Created by Nikita Belosludtcev on 23/05/2018.
//  Copyright © 2018 efremidze. All rights reserved.
//

import XCTest
import Cluster
import MapKit

class AnnotationTests: XCTestCase {
    
    class MockAnnotation: NSObject, MKAnnotation {
        var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0, 0)
        var title: String? = nil
        var subtitle: String? = nil
    }
    
    let identifier = "identifier"
    let styleColor = UIColor.red
    let styleRadius: CGFloat = 20.0
    let testImage = UIImage()
    let annotation = ClusterAnnotation()
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testAnnotationInit() {
        
        var style = ClusterAnnotationStyle.color(styleColor, radius: styleRadius)
        var annotationView = ClusterAnnotationView(annotation: annotation,
                                                   reuseIdentifier: identifier,
                                                   style: style)
        
        XCTAssertEqual(annotationView.reuseIdentifier, identifier)
        if case ClusterAnnotationStyle.color(let color, let radius) = annotationView.style {
            XCTAssertEqual(color, styleColor)
            XCTAssertEqual(radius, styleRadius)
        } else {
            XCTAssertTrue(false, "Style is not .color")
        }
        
        style = ClusterAnnotationStyle.image(testImage)
        annotationView = ClusterAnnotationView(annotation: nil,
                                                   reuseIdentifier: identifier,
                                                   style: style)
        
        XCTAssertEqual(annotationView.reuseIdentifier, identifier)
        if case ClusterAnnotationStyle.image(let image) = annotationView.style {
            XCTAssertEqual(image, testImage)
        } else {
            XCTAssertTrue(false, "Style is not .image")
        }
    }
}
