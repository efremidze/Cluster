![Cluster](https://raw.githubusercontent.com/efremidze/Cluster/master/Images/logo.png)

[![Build Status](https://travis-ci.org/efremidze/Cluster.svg?branch=master)](https://travis-ci.org/efremidze/Cluster)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Language](https://img.shields.io/badge/Swift-5-orange.svg?style=flat)](https://swift.org)
[![Version](https://img.shields.io/cocoapods/v/Cluster.svg?style=flat)](http://cocoapods.org/pods/Cluster)
[![License](https://img.shields.io/cocoapods/l/Cluster.svg?style=flat)](http://cocoapods.org/pods/Cluster)
[![Platform](https://img.shields.io/cocoapods/p/Cluster.svg?style=flat)](http://cocoapods.org/pods/Cluster)

Cluster is an easy map annotation clustering library. This repository uses an efficient method (QuadTree) to aggregate pins into a cluster.

![Demo Screenshots](https://raw.githubusercontent.com/efremidze/Cluster/master/Images/demo.png)

- [Features](#features)
- [Requirements](#requirements)
- [Demo](#demo)
- [Installation](#installation)
- [Usage](#usage)
- [Communication](#communication)
- [Mentions](#mentions)
- [Credits](#credits)
- [License](#license)

## Features

- [x] Adding/Removing Annotations
- [x] Clustering Annotations
- [x] Multiple Managers
- [x] Dynamic Cluster Disabling
- [x] Custom Cell Size
- [x] Custom Annotation Views
- [x] Animation Support
- [x] [Documentation](https://efremidze.github.io/Cluster)

## Requirements

- iOS 8.0+
- Xcode 9.0+
- Swift 5 (Cluster 3.x), Swift 4 (Cluster 2.x), Swift 3 (Cluster 1.x)

## Demo

The [Example](Example) is a great place to get started. It demonstrates how to:

- integrate the library
- add/remove annotations
- reload annotations
- configure the annotation view
- configure the manager

![Demo GIF](https://thumbs.gfycat.com/BoringUnhealthyAngelwingmussel-size_restricted.gif)

[Demo Video](https://gfycat.com/BoringUnhealthyAngelwingmussel)

```
$ pod try Cluster
```

## Installation

Cluster is available via CocoaPods and Carthage.

### CocoaPods

To install Cluster with [CocoaPods](http://cocoapods.org/), add this to your `Podfile`:

```
pod "Cluster"
```

### Carthage

To install Cluster with [Carthage](https://github.com/Carthage/Carthage), add this to your `Cartfile`:

```
github "efremidze/Cluster"
```

## Usage

### The Basics
The `ClusterManager` class generates, manages and displays annotation clusters.

```swift
let clusterManager = ClusterManager()
```

### Adding an Annotation

Create an object that conforms to the `MKAnnotation` protocol, or extend an existing one. Next, add the annotation object to an instance of `ClusterManager` with `add(annotation:)`.

```swift
let annotation = Annotation(coordinate: CLLocationCoordinate2D(latitude: 21.283921, longitude: -157.831661))
manager.add(annotation)
```

### Configuring the Annotation View

Implement the map view’s `mapView(_:viewFor:)` delegate method to configure the annotation view. Return an instance of `MKAnnotationView` to display as a visual representation of the annotations.

To display clusters, return an instance of `ClusterAnnotationView`.

```swift
extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? ClusterAnnotation {
            return CountClusterAnnotationView(annotation: annotation, reuseIdentifier: "cluster")
        } else {
            return MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        }
    }
}
```

For performance reasons, you should generally reuse `MKAnnotationView` objects in your map views. See the [Example](Example) to learn more.

#### Customizing the Appearance

The `ClusterAnnotationView` class exposes a `countLabel` property. You can subclass `ClusterAnnotationView` to provide custom behavior as needed. Here's an example of subclassing the  `ClusterAnnotationView` and customizing the layer `borderColor`.

```swift
class CountClusterAnnotationView: ClusterAnnotationView {
    override func configure() {
        super.configure()

        self.layer.cornerRadius = self.frame.width / 2
        self.layer.masksToBounds = true
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 1.5
    }
}
```

See the [AnnotationView](Example/AnnotationView.swift) to learn more.

#### Annotation Styling

You can customize the appearance of the `StyledClusterAnnotationView` by setting the `style` property of the annotation.

```swift
let annotation = Annotation(coordinate: CLLocationCoordinate2D(latitude: 21.283921, longitude: -157.831661))
annotation.style = .color(color, radius: 25)
manager.add(annotation)
```

Several styles are available in the `ClusterAnnotationStyle` enum:
- `color(UIColor, radius: CGFloat)` - Displays the annotations as a circle. 
- `image(UIImage?)` - Displays the annotation as an image.

Once you have added the annotation, you need to return an instance of the `StyledClusterAnnotationView` to display the styled annotation.

```swift
func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    if let annotation = annotation as? ClusterAnnotation {
        return StyledClusterAnnotationView(annotation: annotation, reuseIdentifier: identifier, style: style)
    }
}
```

### Removing Annotations

To remove annotations, you can call `remove(annotation:)`. However the annotations will still display until you call `reload()`.

```swift
manager.remove(annotation)
```

In the case that `shouldRemoveInvisibleAnnotations` is set to `false`, annotations that have been removed may still appear on map until calling `reload()` on visible region.

### Reloading Annotations

Implement the map view’s `mapView(_:regionDidChangeAnimated:)` delegate method to reload the `ClusterManager` when the region changes.

```swift
func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    clusterManager.reload(mapView: mapView) { finished in
        // handle completion
    }
}
```

You should call `reload()` anytime you add or remove annotations.

### Configuring the Manager

The `ClusterManager` class exposes several properties to configure clustering:

```swift
var zoomLevel: Double // The current zoom level of the visible map region.
var maxZoomLevel: Double // The maximum zoom level before disabling clustering.
var minCountForClustering: Int // The minimum number of annotations for a cluster. The default is `2`.
var shouldRemoveInvisibleAnnotations: Bool // Whether to remove invisible annotations. The default is `true`.
var shouldDistributeAnnotationsOnSameCoordinate: Bool // Whether to arrange annotations in a circle if they have the same coordinate. The default is `true`.
var distanceFromContestedLocation: Double // The distance in meters from contested location when the annotations have the same coordinate. The default is `3`.
var clusterPosition: ClusterPosition // The position of the cluster annotation. The default is `.nearCenter`.
```

### ClusterManagerDelegate

The  `ClusterManagerDelegate` protocol provides a number of functions to manage clustering and configure cells.

```swift
// The size of each cell on the grid at a given zoom level.
func cellSize(for zoomLevel: Double) -> Double? { ... }

// Whether to cluster the given annotation.
func shouldClusterAnnotation(_ annotation: MKAnnotation) -> Bool { ... }
```

## Communication

- If you **found a bug**, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request.

## Mentions

- [Natasha The Robot's Newsleter 128](https://swiftnews.curated.co/issues/128#start)
- [Top 5 iOS Libraries May 2017](https://medium.cobeisfresh.com/top-5-ios-libraries-may-2017-6e3ac5077473)

## Credits

* https://github.com/ribl/FBAnnotationClusteringSwift
* https://github.com/choefele/CCHMapClusterController
* https://github.com/googlemaps/google-maps-ios-utils
* https://github.com/hulab/ClusterKit

## License

Cluster is available under the MIT license. See the LICENSE file for more info.
