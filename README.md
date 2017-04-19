# Cluster

[![Language](https://img.shields.io/badge/Swift-3.1-orange.svg?style=flat)](https://swift.org)
[![Version](https://img.shields.io/cocoapods/v/Cluster.svg?style=flat)](http://cocoapods.org/pods/Cluster)
[![License](https://img.shields.io/cocoapods/l/Cluster.svg?style=flat)](http://cocoapods.org/pods/Cluster)
[![Platform](https://img.shields.io/cocoapods/p/Cluster.svg?style=flat)](http://cocoapods.org/pods/Cluster)

**Cluster** is an easy map annotation clustering library.

<img src="https://raw.githubusercontent.com/efremidze/Cluster/master/Images/demo.gif" width="320">

```
$ pod try Cluster
```

## Requirements

- iOS 8.0+
- Xcode 8.0+
- Swift 3.0+

## Usage

Follow the instructions below:

### Step 1: Initialize a `ClusterManager` object

```swift
let clusterManager = ClusterManager()
```

### Step 2: Add annotations

```swift
let annotation = Annotation()
annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
clusterManager.add(annotation)
```

### Step 3: Return the pins and clusters

```swift
func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
    if view == nil {
        view = ClusterAnnotationView(annotation: annotation, reuseIdentifier: identifier, type: .color(color: color, radius: radius))
    } else {
        view?.annotation = annotation
    }
    return view
}
```

### Step 4: Reload the annotations

```swift
func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    clusterManager.reload(mapView)
}
```

## Installation

### CocoaPods
To install with [CocoaPods](http://cocoapods.org/), simply add this in your `Podfile`:
```ruby
use_frameworks!
pod "Cluster"
```

### Carthage
To install with [Carthage](https://github.com/Carthage/Carthage), simply add this in your `Cartfile`:
```ruby
github "efremidze/Cluster"
```

## Communication

- If you **found a bug**, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request.

## Credits

https://github.com/ribl/FBAnnotationClusteringSwift

## License

Cluster is available under the MIT license. See the LICENSE file for more info.
