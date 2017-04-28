//
//  ViewController.m
//  ObjcExample
//
//  Created by Aaron Brethorst on 4/24/17.
//  Copyright © 2017 efremidze. All rights reserved.
//

#import "ViewController.h"
@import Cluster;
@import MapKit;

@interface ViewController ()<MKMapViewDelegate>
@property(nonatomic,strong) MKMapView *mapView;
@property(nonatomic,strong) ClusterManager *clusterManager;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.delegate = self;
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.mapView];

    self.clusterManager = [[ClusterManager alloc] init];

    NSMutableArray *annotations = [[NSMutableArray alloc] init];
    for (NSUInteger i=0; i<1000; i++) {
        Annotation *a = [[Annotation alloc] init];
        a.coordinate = CLLocationCoordinate2DMake(drand48() * 80 - 40, drand48() * 80 - 40);
        [annotations addObject:a];
    }
    [self.clusterManager add:annotations];

    self.mapView.centerCoordinate = CLLocationCoordinate2DMake(0,0);
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView*)mapView:(MKMapView*)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[ClusterAnnotation class]]) {
        NSString *identifier = @"Cluster";
        MKAnnotationView *view = [mapView dequeueReusableAnnotationViewWithIdentifier:identifier];

        if (view) {
            view.annotation = annotation;
        }
        else {
            ClusterAnnotationConfig *config = [[ClusterAnnotationConfig alloc] init];
            config.color = [UIColor greenColor];
            view = [[ClusterAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier type:config];
        }
        return view;
    }

    NSString *identifier = @"Pin";
    MKAnnotationView *view = [mapView dequeueReusableAnnotationViewWithIdentifier:identifier];

    if (view) {
        view.annotation = annotation;
    }
    else {
        view = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
        view.tintColor = [UIColor colorWithRed:1.f green:(149.f/255.f) blue:0.f alpha:1.f];
    }

    return view;
}

- (void)mapView:(MKMapView*)mapView regionDidChangeAnimated:(BOOL)animated {
    [self.clusterManager reload:mapView];
}


@end
