//
//  Cluster.swift
//  Cluster
//
//  Created by Lasha Efremidze on 4/13/17.
//  Copyright © 2017 efremidze. All rights reserved.
//

import CoreLocation
import MapKit

public enum AnnotationClusterDisplayMode {
    case color(color: UIColor, radius: CGFloat)
    case image(named: String)
}

open class AnnotationClusterView: MKAnnotationView {
    
    open lazy var countLabel: UILabel = { [unowned self] in
        let label = UILabel()
        label.backgroundColor = .clear
        label.textColor = .white
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 2
        label.baselineAdjustment = .alignCenters
        self.addSubview(label)
        return label
    }()
    
    override open var annotation: MKAnnotation? {
        didSet {
            updateAnnotation()
        }
    }
    
    private func updateAnnotation() {
        guard let annotation = annotation as? AnnotationCluster else { return }
        
        let count = annotation.annotations.count
        
        var borderWidth: CGFloat = 3
        var fontSize: CGFloat = 13
        var radius: CGFloat = 15
        
//        switch count {
//        case 0..<10:
//            borderWidth = 3
//            fontSize = 13
//            radius = 15
//        case 10..<20:
//            borderWidth = 4
//            fontSize = 14
//            radius = 20
//        default:
//            borderWidth = 5
//            fontSize = 15
//            radius = 25
//        }
        
        let displayMode: AnnotationClusterDisplayMode = .color(color: .red, radius: radius)
        switch displayMode {
        case let .image(named):
            image = UIImage(named: named)
        case let .color(color, radius):
            backgroundColor	= color
            frame = CGRect(origin: frame.origin, size: CGSize(width: radius * 2, height: radius * 2))
        }
        
        layer.borderWidth = borderWidth
        countLabel.font = .boldSystemFont(ofSize: fontSize)
        countLabel.text = "\(count)"
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = image == nil ? bounds.width / 2 : 0
        layer.masksToBounds = true
    }
}

open class AnnotationCluster: Annotation {
    open var annotations = [MKAnnotation]()
}

open class Annotation: NSObject, MKAnnotation {
    open var coordinate = CLLocationCoordinate2D()
    open var title: String?
    open var subtitle: String?
}
