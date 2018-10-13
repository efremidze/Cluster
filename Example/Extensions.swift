//
//  Extensions.swift
//  Cluster
//
//  Created by Lasha Efremidze on 7/8/17.
//  Copyright © 2017 efremidze. All rights reserved.
//

import UIKit

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
    
    static let annotation = UIImage(named: "pin")?.filled(with: .annotation)
    static let annotation2 = UIImage(named: "pin2")?.filled(with: .annotation)
    
}

extension UIColor {
    static let annotation = UIColor(red: 255/255, green: 149/255, blue: 0/255, alpha: 1)
}
