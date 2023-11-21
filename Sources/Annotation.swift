//
//  Annotation.swift
//  Cluster
//
//  Created by Lasha Efremidze on 4/15/17.
//  Copyright © 2017 efremidze. All rights reserved.
//

import MapKit
#if os(macOS)
import Cocoa
public typealias CommonColor = NSColor
public typealias CommonImage = NSImage
#elseif os(iOS)
public typealias CommonColor = UIColor
public typealias CommonImage = UIImage
#endif

open class Annotation: MKPointAnnotation {
    // @available(swift, obsoleted: 6.0, message: "Please migrate to StyledClusterAnnotationView.")
    open var style: ClusterAnnotationStyle?
    
    public convenience init(coordinate: CLLocationCoordinate2D) {
        self.init()
        self.coordinate = coordinate
    }
}

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

/**
 The view associated with your cluster annotations.
 */
open class ClusterAnnotationView: MKAnnotationView {
    #if os(iOS)
    open lazy var countLabel: UILabel = {
        let label = UILabel()
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        label.backgroundColor = .clear
        label.font = .boldSystemFont(ofSize: 13)
        label.textColor = .white
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.baselineAdjustment = .alignCenters
        self.addSubview(label)
        return label
    }()
    #endif
    
    #if os(macOS)
    open lazy var countLabel: NSTextField = {
        let label = NSTextField()
        label.font = .boldSystemFont(ofSize: 13)
        label.textColor = .white
        label.drawsBackground = false
        label.isSelectable = false
        label.isEditable = false
        label.isBezeled = false
        label.alignment = .center
        label.maximumNumberOfLines = 1
        label.preferredMaxLayoutWidth = self.frame.width
        label.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(label)
        NSLayoutConstraint(item: label, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: label, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: -1).isActive = true
        return label
    }()
    #endif
    
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

/**
 The style of the cluster annotation view.
 */
public enum ClusterAnnotationStyle {
    /**
     Displays the annotations as a circle.
     
     - `color`: The color of the annotation circle
     - `radius`: The radius of the annotation circle
     */
    case color(CommonColor, radius: CGFloat)
    
    /**
     Displays the annotation as an image.
     */
    case image(CommonImage?)
}

/**
 A cluster annotation view that supports styles.
 */
open class StyledClusterAnnotationView: ClusterAnnotationView {
    
    /**
     The style of the cluster annotation view.
     */
    public var style: ClusterAnnotationStyle
    
    /**
     Initializes and returns a new cluster annotation view.
     
     - Parameters:
     - annotation: The annotation object to associate with the new view.
     - reuseIdentifier: If you plan to reuse the annotation view for similar types of annotations, pass a string to identify it. Although you can pass nil if you do not intend to reuse the view, reusing annotation views is generally recommended.
     - style: The cluster annotation style to associate with the new view.
     
     - Returns: The initialized cluster annotation view.
     */
    public init(annotation: MKAnnotation?, reuseIdentifier: String?, style: ClusterAnnotationStyle) {
        self.style = style
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        configure()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func configure() {
        guard let annotation = annotation as? ClusterAnnotation else { return }
        
        switch style {
        case let .image(image):
            backgroundColor = .clear
            self.image = image
        case let .color(color, radius):
            let count = annotation.annotations.count
            backgroundColor = color
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
    
    // macOS's layer is optional, unlike iOS.
    private func getLayer() -> CALayer? {
        return layer
    }
    
    private func layoutView() {
        if case .color = style {
            getLayer()?.masksToBounds = true
            getLayer()?.cornerRadius = image == nil ? bounds.width / 2 : 0
            #if os(iOS)
            countLabel.frame = bounds
            #endif
        }
    }
    
    #if os(iOS)
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        self.layoutView()
    }
    #endif
    
    #if os(macOS)
    open override func layout() {
        super.layout()
        
        self.layoutView()
    }
    
    var _backgroundColor = NSColor.clear
    var backgroundColor: NSColor {
        get {
            return _backgroundColor
        }
        set {
            getLayer()?.backgroundColor = newValue.cgColor
            _backgroundColor = newValue
        }
    }
    #endif
}
