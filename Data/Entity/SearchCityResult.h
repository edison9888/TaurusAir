//
//  SearchCityResult.h
//  TaurusClient
//
//  Created by Simon on 12-12-29.
//  Copyright (c) 2012年 Taurus. All rights reserved.
//

#import <Foundation/Foundation.h>

@class City;

@interface SearchCityResult : NSObject

@property (nonatomic, retain) City *city;
@property (nonatomic, retain) NSString *reason;
- (id)initWithCity:(City*)aCity reason:(NSString*)aReason;

@end
