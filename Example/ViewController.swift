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
            mapView.region = .init(center: region.center, span: .init(latitudeDelta: region.delta, longitudeDelta: region.delta))
        }
    }
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    lazy var manager: ClusterManager = {
        let manager = ClusterManager()
        manager.delegate = self
        manager.maxZoomLevel = 17
        manager.minCountForClustering = 3
        manager.clusterPosition = .nearCenter
        return manager
    }()
    
    let region = (center: CLLocationCoordinate2D(latitude: 37.787994, longitude: -122.407437), delta: 0.1)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        manager.add(MeAnnotation(coordinate: region.center))
        addAnnotations()
    }
    
    @IBAction func addAnnotations(_ sender: UIButton? = nil) {
        // Add annotations to the manager.
        let annotations: [Annotation] = (0..<100000).map { i in
            let annotation = Annotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: region.center.latitude + drand48() * region.delta - region.delta / 2, longitude: region.center.longitude + drand48() * region.delta - region.delta / 2)
            return annotation
        }
        manager.add(annotations)
        manager.reload(mapView: mapView)
    }
    
    @IBAction func removeAnnotations(_ sender: UIButton? = nil) {
        manager.removeAll()
        manager.reload(mapView: mapView)
    }
    
    @IBAction func valueChanged(_ sender: UISegmentedControl) {
        removeAnnotations()
        addAnnotations()
    }
    
}

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? ClusterAnnotation {
            let index = segmentedControl.selectedSegmentIndex
            let identifier = "Cluster\(index)"
            let selection = Selection(rawValue: index)!
            return mapView.annotationView(selection: selection, annotation: annotation, reuseIdentifier: identifier)
        } else if let annotation = annotation as? MeAnnotation {
            let identifier = "Me"
            let annotationView = mapView.annotationView(of: MKAnnotationView.self, annotation: annotation, reuseIdentifier: identifier)
            annotationView.image = .me
            return annotationView
        } else {
            let identifier = "Pin"
            let annotationView = mapView.annotationView(of: MKPinAnnotationView.self, annotation: annotation, reuseIdentifier: identifier)
            annotationView.pinTintColor = .green
            return annotationView
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
            var zoomRect = MKMapRect.null
            for annotation in cluster.annotations {
                let annotationPoint = MKMapPoint(annotation.coordinate)
                let pointRect = MKMapRect(x: annotationPoint.x, y: annotationPoint.y, width: 0, height: 0)
                if zoomRect.isNull {
                    zoomRect = pointRect
                } else {
                    zoomRect = zoomRect.union(pointRect)
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
    
}

extension ViewController: ClusterManagerDelegate {
    
    func cellSize(for zoomLevel: Double) -> Double? {
        return nil // default
    }
    
    func shouldClusterAnnotation(_ annotation: MKAnnotation) -> Bool {
        return !(annotation is MeAnnotation)
    }
    
}

extension ViewController {
    enum Selection: Int {
        case count, imageCount, image
    }
}

extension MKMapView {
    func annotationView(selection: ViewController.Selection, annotation: MKAnnotation?, reuseIdentifier: String) -> MKAnnotationView {
        switch selection {
        case .count:
            let annotationView = self.annotationView(of: CountClusterAnnotationView.self, annotation: annotation, reuseIdentifier: reuseIdentifier)
            annotationView.countLabel.backgroundColor = .green
            return annotationView
        case .imageCount:
            let annotationView = self.annotationView(of: ImageCountClusterAnnotationView.self, annotation: annotation, reuseIdentifier: reuseIdentifier)
            annotationView.countLabel.textColor = .green
            annotationView.image = .pin2
            return annotationView
        case .image:
            let annotationView = self.annotationView(of: MKAnnotationView.self, annotation: annotation, reuseIdentifier: reuseIdentifier)
            annotationView.image = .pin
            return annotationView
        }
    }
}

class MeAnnotation: Annotation {}
