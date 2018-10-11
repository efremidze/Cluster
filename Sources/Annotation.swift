//
//  Annotation.swift
//  Cluster
//
//  Created by Lasha Efremidze on 4/15/17.
//  Copyright © 2017 efremidze. All rights reserved.
//

import MapKit

public typealias Annotation = MKPointAnnotation

open class ClusterAnnotation: Annotation {
    open var annotations = [MKAnnotation]()
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? ClusterAnnotation else { return false }
        
        if self === object {
            return true
        }
        
        if coordinate != object.coordinate {
            return false
        }
        
        if annotations.count != object.annotations.count {
            return false
        }
        
        return annotations.map { $0.coordinate } == object.annotations.map { $0.coordinate }
    }
}

open class ClusterAnnotationView: MKAnnotationView {
    
    open lazy var countLabel: UILabel = {
        let label = UILabel()
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        label.backgroundColor = .clear
        label.font = .boldSystemFont(ofSize: 13)
        label.textColor = .white
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 2
        label.baselineAdjustment = .alignCenters
        self.addSubview(label)
        return label
    }()
    
    open override var annotation: MKAnnotation? {
        didSet {
            configure()
        }
    }
    
    open func configure() {
        guard let annotation = annotation as? ClusterAnnotation else { return }
        let count = annotation.annotations.count
        countLabel.text = "\(count)"
    }
    
}
