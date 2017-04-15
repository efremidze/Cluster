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
    
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.centerCoordinate = CLLocationCoordinate2DMake(0, 0)
        }
    }
    
    let manager = ClusterManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let annotations: [Annotation] = (0..<1000).map { _ in
            let annotation = Annotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: drand48() * 40 - 20, longitude: drand48() * 80 - 40)
            return annotation
        }
        manager.add(annotations: annotations)
    }
    
}

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is ClusterAnnotation {
            let identifier = "Cluster"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if view == nil {
                view = ClusterAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            } else {
                view?.annotation = annotation
            }
            return view
        } else {
            let identifier = "Pin"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
            if view == nil {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view?.pinTintColor = .green
            } else {
                view?.annotation = annotation
            }
            return view
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let strongSelf = self else { return }
            
            let mapBoundsWidth = Double(strongSelf.mapView.bounds.width)
            let mapRectWidth = strongSelf.mapView.visibleMapRect.size.width
            let scale = mapBoundsWidth / mapRectWidth
            
            let annotationArray = strongSelf.manager.clusteredAnnotations(withinMapRect: strongSelf.mapView.visibleMapRect, zoomScale: scale)
            
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                
                strongSelf.manager.display(annotations: annotationArray, onMapView: strongSelf.mapView)
            }
        }
    }

}
