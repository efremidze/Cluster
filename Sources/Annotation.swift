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
}

open class ClusterAnnotation: Annotation {
    open var annotations = [MKAnnotation]()
}

public enum ClusterAnnotationType {
    case color(color: UIColor, radius: CGFloat)
    case image(named: String)
}

open class ClusterAnnotationView: MKAnnotationView {
    
    open lazy var countLabel: UILabel = { [unowned self] in
        let label = UILabel()
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        label.backgroundColor = .clear
        label.textColor = .white
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 2
        label.baselineAdjustment = .alignCenters
        self.addSubview(label)
        return label
    }()
    
    public var type: ClusterAnnotationType = .color(color: .black, radius: 15)
    
    override open var annotation: MKAnnotation? {
        didSet {
            updateAnnotation()
        }
    }
    
    override public init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        updateAnnotation()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        updateAnnotation()
    }
    
    public convenience init(annotation: MKAnnotation?, reuseIdentifier: String?, type: ClusterAnnotationType) {
        self.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.type = type
    }
    
    open func updateAnnotation() {
        guard let annotation = annotation as? ClusterAnnotation else { return }
        
        let count = annotation.annotations.count
        
        switch type {
        case let .image(named):
            backgroundColor = .clear
            image = UIImage(named: named)
        case let .color(color, radius):
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
        }
        
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 2
        countLabel.font = .boldSystemFont(ofSize: 13)
        countLabel.text = "\(count)"
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        layer.masksToBounds = true
        layer.cornerRadius = image == nil ? bounds.width / 2 : 0
        countLabel.frame = bounds
    }
    
}
