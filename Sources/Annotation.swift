//
//  Annotation.swift
//  Cluster
//
//  Created by Lasha Efremidze on 4/15/17.
//  Copyright © 2017 efremidze. All rights reserved.
//

import MapKit

open class Annotation: NSObject, MKAnnotation {
    open var coordinate = CLLocationCoordinate2D()
    open var title: String?
    open var subtitle: String?
    open var type: ClusterAnnotationType?
}

open class ClusterAnnotation: Annotation {
    open var annotations = [MKAnnotation]()
}

public enum ClusterAnnotationType {
    case color(UIColor, radius: CGFloat)
    case image(UIImage?)
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
    
    override open var annotation: MKAnnotation? {
        didSet {
            configure()
        }
    }
    
    open let type: ClusterAnnotationType
    
    /**
     Initializes and returns a new cluster annotation view.
     
     - Parameters:
        - annotation: The annotation object to associate with the new view.
        - reuseIdentifier: If you plan to reuse the annotation view for similar types of annotations, pass a string to identify it. Although you can pass nil if you do not intend to reuse the view, reusing annotation views is generally recommended.
        - type: The cluster annotation type to associate with the new view.
     
     - Returns: The initialized cluster annotation view.
     */
    public init(annotation: MKAnnotation?, reuseIdentifier: String?, type: ClusterAnnotationType) {
        self.type = type
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        configure()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func configure() {
        guard let annotation = annotation as? ClusterAnnotation else { return }
        
        switch type {
        case let .image(image):
            backgroundColor = .clear
            self.image = image
        case let .color(color, radius):
            let count = annotation.annotations.count
            backgroundColor	= color
            var diameter = radius * 2
            switch count {
            case _ where count < 8:
                diameter *= 0.6
            case _ where count < 16:
                diameter *= 0.8
            default: break
            }
            frame = CGRect(origin: frame.origin, size: CGSize(width: diameter, height: diameter))
            countLabel.text = "\(count)"
        }
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        if case .color = type {
            layer.masksToBounds = true
            layer.cornerRadius = image == nil ? bounds.width / 2 : 0
            countLabel.frame = bounds
        }
    }
    
}
