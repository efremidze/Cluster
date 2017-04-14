//
//  Cluster.swift
//  Cluster
//
//  Created by Lasha Efremidze on 4/13/17.
//  Copyright © 2017 efremidze. All rights reserved.
//

import CoreLocation
import MapKit

open class ClusterManager {
    
    var tree = Tree()
    
    public init() {}
    
    open func add(annotations: [MKAnnotation]) {
        for annotation in annotations {
            tree.insert(annotation: annotation)
        }
    }
    
    func removeAll() {
        tree = Tree()
    }
    
    func annotations() -> [MKAnnotation] {
        var annotations = [MKAnnotation]()
        tree.enumerateAnnotationsUsingBlock {
            annotations.append($0)
        }
        return annotations
    }
    
    func clusteredAnnotations(withinMapRect rect:MKMapRect, zoomScale: Double) -> [MKAnnotation] {
        guard !zoomScale.isInfinite else { return [] }
        
        let cellSize = ZoomLevel(MKZoomScale(zoomScale)).cellSize()
        
        let scaleFactor = zoomScale / Double(cellSize)
        
        let minX = Int(floor(MKMapRectGetMinX(rect) * scaleFactor))
        let maxX = Int(floor(MKMapRectGetMaxX(rect) * scaleFactor))
        let minY = Int(floor(MKMapRectGetMinY(rect) * scaleFactor))
        let maxY = Int(floor(MKMapRectGetMaxY(rect) * scaleFactor))
        
        var clusteredAnnotations = [MKAnnotation]()
        
        for i in minX...maxX {
            for j in minY...maxY {
                
                let mapPoint = MKMapPoint(x: Double(i) / scaleFactor, y: Double(j) / scaleFactor)
                let mapSize = MKMapSize(width: 1.0 / scaleFactor, height: 1.0 / scaleFactor)
                let mapRect = MKMapRect(origin: mapPoint, size: mapSize)
                
                var totalLatitude: Double = 0
                var totalLongitude: Double = 0
                
                var annotations = [MKAnnotation]()
                
                tree.enumerateAnnotations(inRect: mapRect) { obj in
                    totalLatitude += obj.coordinate.latitude
                    totalLongitude += obj.coordinate.longitude
                    annotations.append(obj)
                }
                
                let count = annotations.count
                
                switch count {
                case 0: break
                case 1:
                    clusteredAnnotations += annotations
                default:
                    let coordinate = CLLocationCoordinate2D(
                        latitude: CLLocationDegrees(totalLatitude)/CLLocationDegrees(count),
                        longitude: CLLocationDegrees(totalLongitude)/CLLocationDegrees(count)
                    )
                    let cluster = ClusterAnnotation()
                    cluster.coordinate = coordinate
                    cluster.annotations = annotations
                    clusteredAnnotations.append(cluster)
                }
            }
        }
        
        return clusteredAnnotations
    }
    
//    func display(annotations: [MKAnnotation], onMapView mapView: MKMapView) {
//        let before = NSMutableSet(mapView.annotations)
//        before.remove(mapView.userLocation)
//        
//        let after = NSSet(array: annotations)
//        
//        let toKeep = NSMutableSet(set: before)
//        toKeep.intersect(after as Set<NSObject>)
//        
//        let toAdd = NSMutableSet(set: after)
//        toAdd.minus(toKeep as Set<NSObject>)
//        
//        let toRemove = NSMutableSet(set: before)
//        toRemove.minus(after as Set<NSObject>)
//        
//        _ = toAdd.allObjects.flatMap { $0 as? MKAnnotation }.map { mapView.addAnnotations($0) }
//        _ = toRemove.allObjects.flatMap { $0 as? MKAnnotation }.map { mapView.removeAnnotations($0) }
//    }
    
}

typealias ZoomLevel = Int
extension ZoomLevel {
    
    init(scale: MKZoomScale) {
        let totalTilesAtMaxZoom = MKMapSizeWorld.width / 256.0
        let zoomLevelAtMaxZoom = Int(log2(totalTilesAtMaxZoom))
        let floorLog2ScaleFloat = floor(log2f(Float(scale))) + 0.5
        
        if !floorLog2ScaleFloat.isInfinite {
            let sum = zoomLevelAtMaxZoom + Int(floorLog2ScaleFloat)
            let zoomLevel = altmax(0, sum)
            self = zoomLevel
        } else {
            self = floorLog2ScaleFloat.sign == .plus ? 0 : 19
        }
    }
    
    func cellSize() -> CGFloat {
        switch (self) {
        case 13...15:
            return 64
        case 16...18:
            return 32
        case 18 ..< Int.max:
            return 16
        default:
            return 88 // Less than 13
        }
    }
}

// Required due to conflict with Int static variable 'max'
public func altmax<T : Comparable>(_ x: T, _ y: T) -> T {
    return max(x, y)
}

public enum ClusterAnnotationDisplayMode {
    case color(color: UIColor, radius: CGFloat)
    case image(named: String)
}

open class ClusterAnnotationView: MKAnnotationView {
    
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
        guard let annotation = annotation as? ClusterAnnotation else { return }
        
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
        
        let displayMode: ClusterAnnotationDisplayMode = .color(color: .red, radius: radius)
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

open class ClusterAnnotation: Annotation {
    open var annotations = [MKAnnotation]()
}

open class Annotation: NSObject, MKAnnotation {
    open var coordinate = CLLocationCoordinate2D()
    open var title: String?
    open var subtitle: String?
}

//extension MKAnnotation: Hashable {
//    var hashValue: Int {
//        return coordinate.latitude.hashValue ^ coordinate.longitude.hashValue
//    }
//}
//
//extension MKAnnotation: Equatable {}
//
//func ==(lhs: MKAnnotation, rhs: MKAnnotation) -> Bool {
//    return lhs.coordinate == rhs.coordinate
//}
