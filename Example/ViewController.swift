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
    
    let center = CLLocationCoordinate2D(latitude: 37.787994, longitude: -122.407437) // region center
    let delta = 0.1 // region span
    let color = UIColor(red: 255/255, green: 149/255, blue: 0/255, alpha: 1)
    lazy var image = UIImage(named: "pin")?.filled(with: color)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // When zoom level is quite close to the pins, disable clustering in order to show individual pins and allow the user to interact with them via callouts.
        mapView.region = .init(center: center, span: .init(latitudeDelta: delta, longitudeDelta: delta))
        manager.cellSize = nil
        manager.maxZoomLevel = 17
        manager.minCountForClustering = 3
        manager.clusterPosition = .nearCenter
        addAnnotations()
    }
    
    @IBAction func addAnnotations(_ sender: UIButton? = nil) {
        // Add annotations to the manager.
        let annotations: [Annotation] = (0..<100000).map { i in
            let annotation = Annotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: center.latitude + drand48() * delta - delta / 2, longitude: center.longitude + drand48() * delta - delta / 2)
            return annotation
        }
        manager.add(annotations)
        manager.reload(mapView: mapView)
    }
    
    @IBAction func removeAnnotations(_ sender: UIButton? = nil) {
        manager.removeAll()
        manager.reload(mapView: mapView)
    }
    
}

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? ClusterAnnotation {
            let identifier = "Cluster"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? ClusterAnnotationView
            if let view = view {
                view.annotation = annotation
            } else {
                view = ClusterAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }
            view?.countLabel.backgroundColor = color
            view?.countLabel.layer.borderColor = UIColor.white.cgColor
            view?.countLabel.layer.borderWidth = 1.5
            view?.radii = [(5, 12), (10, 16), (15, 20)]
            return view
        } else {
            let identifier = "Pin"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
            if let view = view {
                view.annotation = annotation
            } else {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }
            view?.pinTintColor = color
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
