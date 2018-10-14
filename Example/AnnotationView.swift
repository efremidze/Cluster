//
//  AnnotationView.swift
//  Example
//
//  Created by Lasha Efremidze on 10/9/18.
//  Copyright © 2018 efremidze. All rights reserved.
//

import UIKit
import MapKit
import Cluster

class CountClusterAnnotationView: ClusterAnnotationView {
    override func configure() {
        super.configure()
        
        guard let annotation = annotation as? ClusterAnnotation else { return }
        let count = annotation.annotations.count
        let diameter = radius(for: count) * 2
        countLabel.frame.size = CGSize(width: diameter, height: diameter)
        countLabel.layer.cornerRadius = countLabel.frame.width / 2
        countLabel.layer.masksToBounds = true
        countLabel.layer.borderColor = UIColor.white.cgColor
        countLabel.layer.borderWidth = 1.5
    }
    
    func radius(for count: Int) -> CGFloat {
        if count < 5 {
            return 12
        } else if count < 10 {
            return 16
        } else {
            return 20
        }
    }
}

class ImageCountClusterAnnotationView: ClusterAnnotationView {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        countLabel.frame.size.width -= 6
        countLabel.frame.origin.x += 3
        countLabel.frame.origin.y -= 6
    }
}
