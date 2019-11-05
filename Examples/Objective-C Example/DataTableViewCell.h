//
//  DataTableViewCell.h
//  Objective-C Example
//
//  Created by Alireza Asadi on 4/8/1398 AP.
//  Copyright © 1398 AP Map. All rights reserved.
//

#import <UIKit/UIKit.h>

#define DataTableViewCellReuseIdentifier @"data-cell"

NS_ASSUME_NONNULL_BEGIN

@interface DataTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *coordinatesLabel;
@property (weak, nonatomic) IBOutlet UILabel *directionLabel;
@property (weak, nonatomic) IBOutlet UILabel *speedLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@end

NS_ASSUME_NONNULL_END
