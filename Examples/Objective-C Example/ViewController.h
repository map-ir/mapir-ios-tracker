//
//  ViewController.h
//  Objective-C Example
//
//  Created by Alireza Asadi on 4/8/1398 AP.
//  Copyright © 1398 AP Map. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapirLiveTracker/MapirLiveTracker.h>

@interface ObjcViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate, MLTPublisherDelegate, MLTSubscriberDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *clearBarButton;

@property (nonatomic, strong) NSMutableArray<CLLocation *> *sentLocations;
@property (nonatomic, strong) NSMutableArray<CLLocation *> *receivedLocations;

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) NSDateFormatter *dateFormatter;

@property (nonatomic, strong) MLTPublisher *publisher;
@property (nonatomic, strong) MLTSubscriber *subscriber;


@end
