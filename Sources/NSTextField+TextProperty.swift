//
//  NSTextField+TextProperty.swift
//  Cluster-Mac
//
//  Created by Vincent Neo on 27/1/23.
//  Copyright © 2023 efremidze. All rights reserved.
//

#if os(macOS)
import Cocoa

extension NSTextField {
    public var text: String {
        get {
            return self.stringValue
        }
        set {
            self.stringValue = newValue
        }
    }
}
#endif
