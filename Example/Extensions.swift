//
//  Extensions.swift
//  Cluster
//
//  Created by Lasha Efremidze on 7/8/17.
//  Copyright © 2017 efremidze. All rights reserved.
//

import UIKit
import MapKit

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
    
    static let pin = UIImage(named: "pin")?.filled(with: .green)
    static let pin2 = UIImage(named: "pin2")?.filled(with: .green)
    static let me = UIImage(named: "me")?.filled(with: .blue)
    
}

extension UIColor {
    class var green: UIColor { return UIColor(red: 76 / 255, green: 217 / 255, blue: 100 / 255, alpha: 1) }
    class var blue: UIColor { return UIColor(red: 0, green: 122 / 255, blue: 1, alpha: 1) }
}

extension MKMapView {
    func annotationView<T: MKAnnotationView>(of type: T.Type, annotation: MKAnnotation?, reuseIdentifier: String) -> T {
        guard let annotationView = dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) as? T else {
            return type.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        }
        annotationView.annotation = annotation
        return annotationView
    }
}
