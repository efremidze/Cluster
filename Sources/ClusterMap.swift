//
//  ClusterMap.swift
//  Cluster
//
//  Created by Lasha Efremidze on 7/30/18.
//  Copyright © 2018 efremidze. All rights reserved.
//

import MapKit

public struct Animation {
    let annotations: [ClusterAnnotation]
    var from: CLLocationCoordinate2D
    var to: CLLocationCoordinate2D
}

public protocol ClusterMap {
    var manager: ClusterManager { get }
    var visibleMapRect: MKMapRect { get }
    var zoom: Double { get }
    func selectCluster(annotation: MKAnnotation, animated: Bool)
    func deselectCluster(annotation: MKAnnotation, animated: Bool)
    func addClusters(annotations: [MKAnnotation])
    func removeClusters(annotations: [MKAnnotation])
    func performAnimations(_ animations: [Animation], completion: (Bool) -> Void)
}

//extension MKMapView: ClusterMap {
//    public var zoom: Double {
//    }
//}
