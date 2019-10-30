//
//  DataTableViewCell.m
//  Objective-C Example
//
//  Created by Alireza Asadi on 4/8/1398 AP.
//  Copyright © 1398 AP Map. All rights reserved.
//

#import "DataTableViewCell.h"

@implementation DataTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [self.coordinatesLabel setText:@""];
    [self.directionLabel setText:@""];
    [self.speedLabel setText:@""];
    [self.timeLabel setText:@""];
}

@end
