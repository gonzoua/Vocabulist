//
//  BaseNode.h
//  Vocabulist
//
//  Created by Oleksandr Tymoshenko on 2013-05-09.
//  Copyright (c) 2013 Bluezbox Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BaseNode : NSObject <NSCoding,NSCopying>

@property (strong) NSString *nodeTitle;
@property (strong) NSImage *nodeIcon;
@property (strong) NSMutableArray *children;

@end
