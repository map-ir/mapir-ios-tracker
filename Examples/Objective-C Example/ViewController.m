//
//  ViewController.m
//  Objective-C Example
//
//  Created by Alireza Asadi on 4/8/1398 AP.
//  Copyright © 1398 AP Map. All rights reserved.
//

#import "ViewController.h"
#import "DataTableViewCell.h"

#define API_KEY @"<#Map.ir API Key#>"

@interface ObjcViewController ()

@end

@implementation ObjcViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    [self setupDateFormatter];
    [self setupLocationManager];
    [self setupPublisherAndSubscriber];
    [self setupDelegates];

    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
}

- (void)setupLocationManager
{
    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager setDelegate:self];

    int auth = [CLLocationManager authorizationStatus];
    if (!(auth == kCLAuthorizationStatusAuthorizedWhenInUse || auth == kCLAuthorizationStatusAuthorizedAlways))
    {
        [self.locationManager requestAlwaysAuthorization];
    }
}

- (void)setupDateFormatter
{
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat:@"dd/MM HH:mm:ss.SSS"];
    [self.dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
}

- (void)setupPublisherAndSubscriber
{
    self.publisher = [[MLTPublisher alloc] initWithAPIKey:API_KEY distanceFilter:30.0];
    self.subscriber = [[MLTSubscriber alloc] initWithAPIKey:API_KEY];

    self.sentLocations = [[NSMutableArray alloc] init];
    self.receivedLocations = [[NSMutableArray alloc] init];
}

- (void)setupDelegates
{
    [self.publisher setDelegate:self];
    [self.subscriber setDelegate:self];

    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
}

- (IBAction)segmentChanged:(UISegmentedControl *)sender
{
    [self.tableView reloadData];
}

- (IBAction)clearButtonTapped:(id)sender
{
    if (self.segmentedControl.selectedSegmentIndex == 0)
    {
        self.receivedLocations = [@[] mutableCopy];
    }
    else
    {
        self.sentLocations = [@[] mutableCopy];
    }
}

- (IBAction)receivingSwitched:(UISwitch *)sender
{
    if ([sender isOn])
    {
        [self.subscriber startWithTrackingIdentifier:@"sample-unique-identifier-test"];
        NSLog(@"Subscriber Started.");
    }
    else
    {
        [self.subscriber stop];
    }
}

- (IBAction)publishingSwitched:(UISwitch *)sender
{
    if ([sender isOn])
    {
        [self.publisher startWithTrackingIdentifier:@"sample-unique-identifier-test"];
        NSLog(@"Publisher Started.");
    }
    else
    {
        [self.publisher stop];
    }
}

#pragma mark MLTSubscriberDelegate

- (void)subscriber:(MLTSubscriber *)subscriber locationReceived:(CLLocation *)location
{
    [self.receivedLocations insertObject:location atIndex:0];
    if (![self selectedSegmentIndex])
    {
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
    }
}

- (void)subscriber:(MLTSubscriber *)subscriber stoppedWithError:(NSError *)error
{
    NSLog(@"Subscriber Stopped.\nError: %@", error);
}

#pragma mark MLTPublisherDelegate

- (void)publisher:(MLTPublisher *)publisher stoppedWithError:(NSError *)error
{
    NSLog(@"Publisher Stopped.\nError: %@", error);
}

-(void)publisher:(MLTPublisher *)publisher publishedLocation:(CLLocation *)location
{
    [self.sentLocations insertObject:location atIndex:0];
    if ([self selectedSegmentIndex])
    {
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
    }
}

#pragma mark Location Delegate Methods

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSLog(@"Invalid location authorization.\nStatus: %d", status);
}

#pragma mark UI Drawing Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (![self selectedSegmentIndex])
    {
        return self.receivedLocations.count;
    }
    else
    {
        return self.sentLocations.count;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (![self selectedSegmentIndex])
    {
        return @"Received Locations";
    }
    else
    {
        return @"Sent Locations";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DataTableViewCell *cell = (DataTableViewCell *)[tableView dequeueReusableCellWithIdentifier:DataTableViewCellReuseIdentifier];
    if (!cell)
    {
        cell = [[DataTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DataTableViewCellReuseIdentifier];
    }

    CLLocation *data;
    if (![self selectedSegmentIndex])
    {
        data = self.receivedLocations[indexPath.row];
    }
    else
    {
        data = self.sentLocations[indexPath.row];
    }

    NSString *coordinateText = [[NSString alloc] initWithFormat:@"%f, %f", data.coordinate.latitude, data.coordinate.longitude];
    NSString *directionText = [[NSString alloc] initWithFormat:@"%f", data.course];
    NSString *speedText = [[NSString alloc] initWithFormat:@"%f", data.speed];
    NSString *timeText = [self.dateFormatter stringFromDate:data.timestamp];

    [cell.coordinatesLabel setText:coordinateText];
    [cell.directionLabel setText:directionText];
    [cell.speedLabel setText:speedText];
    [cell.timeLabel setText:timeText];

    return cell;
}

#pragma mark Utility methods

- (NSInteger)selectedSegmentIndex
{
    return self.segmentedControl.selectedSegmentIndex;
}

@end
