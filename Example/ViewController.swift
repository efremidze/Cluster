//
//  ViewController.swift
//  Example
//
//  Created by Lasha Efremidze on 4/13/17.
//  Copyright © 2017 efremidze. All rights reserved.
//

import UIKit
import MapKit
import Cluster

class ViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    let manager = ClusterManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // When zoom level is quite close to the pins, disable clustering in order to show individual pins and allow the user to interact with them via callouts.
        manager.cellSize = nil
        manager.maxZoomLevel = 17
        manager.minCountForClustering = 3
        manager.clusterPosition = .nearCenter
        
        let center = CLLocationCoordinate2D(latitude: 37.787994, longitude: -122.407437) // region center
        let delta = 0.1 // region span
        
        // Add annotations to the manager.
        let annotations: [Annotation] = (0..<100000).map { i in
            let annotation = Annotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: center.latitude + drand48() * delta - delta / 2, longitude: center.longitude + drand48() * delta - delta / 2)
            let color = UIColor(red: 255/255, green: 149/255, blue: 0/255, alpha: 1)
            annotation.style = .color(color, radius: 25)
            // or
            // annotation.style = .image(UIImage(named: "pin")?.filled(with: color)) // custom image
            return annotation
        }
        manager.add(annotations)
        
        mapView.region = .init(center: center, span: .init(latitudeDelta: delta, longitudeDelta: delta))
    }
    
}

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? ClusterAnnotation {
            guard let style = annotation.style else { return nil }
            let identifier = "Cluster"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if let view = view as? BorderedClusterAnnotationView {
                view.annotation = annotation
                view.style = style
                view.configure()
            } else {
                view = BorderedClusterAnnotationView(annotation: annotation, reuseIdentifier: identifier, style: style, borderColor: .white)
            }
            return view
        } else {
            guard let annotation = annotation as? Annotation, let style = annotation.style else { return nil }
            let identifier = "Pin"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
            if let view = view {
                view.annotation = annotation
            } else {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }
            if #available(iOS 9.0, *), case let .color(color, _) = style {
                view?.pinTintColor =  color
            } else {
                view?.pinColor = .green
            }
            return view
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        manager.reload(mapView: mapView) { finished in
            print(finished)
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else { return }
        
        if let cluster = annotation as? ClusterAnnotation {
            var zoomRect = MKMapRectNull
            for annotation in cluster.annotations {
                let annotationPoint = MKMapPointForCoordinate(annotation.coordinate)
                let pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0, 0)
                if MKMapRectIsNull(zoomRect) {
                    zoomRect = pointRect
                } else {
                    zoomRect = MKMapRectUnion(zoomRect, pointRect)
                }
            }
            mapView.setVisibleMapRect(zoomRect, animated: true)
        }
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        views.forEach { $0.alpha = 0 }
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: { 
            views.forEach { $0.alpha = 1 }
        }, completion: nil)
    }
    
//    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
//        let view = MKPolylineRenderer(overlay: overlay)
//        if overlay is MKBasePolyline {
//            view.strokeColor = .blue
//        } else {
//            view.strokeColor = .red
//        }
//        return view
//    }

}

class BorderedClusterAnnotationView: ClusterAnnotationView {
    let borderColor: UIColor
    
    init(annotation: MKAnnotation?, reuseIdentifier: String?, style: ClusterAnnotationStyle, borderColor: UIColor) {
        self.borderColor = borderColor
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier, style: style)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func configure() {
        super.configure()
        
        switch style {
        case .image:
            layer.borderWidth = 0
        case .color:
            layer.borderColor = borderColor.cgColor
            layer.borderWidth = 2
        }
    }
}
