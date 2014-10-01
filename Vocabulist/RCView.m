//
//  RCView.m
//  Vocabulist
//
//  Created by Oleksandr Tymoshenko on 2013-10-12.
//  Copyright (c) 2013 Bluezbox Software. All rights reserved.
//

#import "RCView.h"

@implementation RCView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor colorWithCalibratedWhite:0 alpha:0.6] set];
    NSRectFill(dirtyRect);
}

@end
