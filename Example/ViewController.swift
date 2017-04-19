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
        
        let annotations: [Annotation] = (0..<1000).map { _ in
            let annotation = Annotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: drand48() * 80 - 40, longitude: drand48() * 80 - 40)
            return annotation
        }
        manager.add(annotations)
        
        mapView.centerCoordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }
    
}

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let color = UIColor(red: 255/255, green: 149/255, blue: 0/255, alpha: 1)
        if annotation is ClusterAnnotation {
            let identifier = "Cluster"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if view == nil {
                view = ClusterAnnotationView(annotation: annotation, reuseIdentifier: identifier, type: .color(color: color, radius: 25))
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
        manager.refresh(mapView)
    }

}
