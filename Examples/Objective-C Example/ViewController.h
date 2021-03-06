//
//  ViewController.h
//  Objective-C Example
//
//  Created by Alireza Asadi on 4/8/1398 AP.
//  Copyright © 1398 AP Map. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapirLiveTracker/MapirLiveTracker.h>

#define ACCESS_TOKEN @"eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImp0aSI6Ijc4MDMzN2YyYjFlOTZkZjExZjdhY2FhZGI1MzVhNDBjMjA4N2E2MmVkMDFjMmE5MzI4Y2M1ZDE2MDJjODlkMDIzOTEwZDdkY2YxNjQwNTA1In0.eyJhdWQiOiI3MTU3IiwianRpIjoiNzgwMzM3ZjJiMWU5NmRmMTFmN2FjYWFkYjUzNWE0MGMyMDg3YTYyZWQwMWMyYTkzMjhjYzVkMTYwMmM4OWQwMjM5MTBkN2RjZjE2NDA1MDUiLCJpYXQiOjE1NjQyOTI3MzksIm5iZiI6MTU2NDI5MjczOSwiZXhwIjoxNTY2OTcxMTM4LCJzdWIiOiIiLCJzY29wZXMiOlsiYmFzaWMiXX0.Ef9kZ-_jmy8Dcp_Pu1fGlu5RbMZLORUgFFpcSD_dRBfXb232TJldXRFu66pIoiQcLqtFTWFPwx31HXDfruWh0Nt3QsoG9zvxqAi0ILCdioW4aiJVM5jro1euPSQ3ezlDgqzcraAToVjVrvy-5C7CQ9aFVy8PNq-oB9-PIeHsBfqGOYo4xjfsaCEB1_eqst_jWICUs-1fTLzCUyrRv2RsKHfJdhaFbc-3Mim1oQjYah4C8Qa4BFcGDcfYLR_LMu68zUdQSQL1yBZZsfpINVcGpFggP1zbtNbXPEk0Ouf5wlVz0AA2nL8Heu9Owjoc9_gVuPOeMF7qXpBE0d5WXRJjHw"

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
