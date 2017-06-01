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
        manager.zoomLevel = 17
        
        for location in testLocations {
            let annotation = Annotation()
            annotation.coordinate = location.coordinate
            manager.add(annotation)
        }
        
//        // Add annotations to the manager.
//        let annotations: [Annotation] = (0..<10).map { i in
//            let annotation = Annotation()
//            annotation.coordinate = CLLocationCoordinate2D(latitude: drand48() * 80 - 40, longitude: drand48() * 80 - 40)
//            let color = UIColor(red: 255/255, green: 149/255, blue: 0/255, alpha: 1)
//            if i % 2 == 0 {
//                annotation.type = .color(color, radius: 25)
//            } else {
//                annotation.type = .image(UIImage(named: "pin")?.filled(with: color))
//            }
//            return annotation
//        }
//        manager.add(annotations)
        
//        print("Expected \(testLocations.count)")
//        print("Actual \(manager.annotations.count)")
        
        mapView.centerCoordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }
    
}

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let color = UIColor(red: 255/255, green: 149/255, blue: 0/255, alpha: 1)
        if let annotation = annotation as? ClusterAnnotation {
            let identifier = "Cluster"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if view == nil {
                if let annotation = annotation.annotations.first as? Annotation, let type = annotation.type {
                    view = ClusterAnnotationView(annotation: annotation, reuseIdentifier: identifier, type: type)
                } else {
                    view = ClusterAnnotationView(annotation: annotation, reuseIdentifier: identifier, type: .color(color, radius: 25))
                }
            } else {
                view?.annotation = annotation
            }
            return view
        } else {
            let identifier = "Pin"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
            if view == nil {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view?.pinTintColor = color
            } else {
                view?.annotation = annotation
            }
            return view
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        manager.reload(mapView, visibleMapRect: mapView.visibleMapRect)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else { return }
        
        if let cluster = annotation as? ClusterAnnotation {
            mapView.removeAnnotations(mapView.annotations)
            
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
            manager.reload(mapView, visibleMapRect: zoomRect)
            mapView.setVisibleMapRect(zoomRect, animated: true)
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let view = MKPolylineRenderer(overlay: overlay)
        if overlay is MKCustomPolyline {
            view.strokeColor = .blue
        } else {
            view.strokeColor = UIColor(red: 255/255, green: 149/255, blue: 0/255, alpha: 1)
        }
        return view
    }
    
}

extension UIImage {
    
    func filled(with color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        color.setFill()
        guard let context = UIGraphicsGetCurrentContext() else { return self }
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0);
        context.setBlendMode(CGBlendMode.normal)
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        guard let mask = self.cgImage else { return self }
        context.clip(to: rect, mask: mask)
        context.fill(rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
}

let testLocations: [CLLocation] = [
    CLLocation(latitude: 20.99019666666667, longitude: -156.66481166666671),
    CLLocation(latitude: 37.787358900000001, longitude: -122.408227),
    CLLocation(latitude: 40.747549999999997, longitude: -73.991950000000003),
    CLLocation(latitude: 35.702069100000003, longitude: 139.77532690000001),
    CLLocation(latitude: -33.863399999999999, longitude: 151.21100000000001)
]
