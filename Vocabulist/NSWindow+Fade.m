//
//  NSWindow+Fade.m
//  Vocabulist
//
//  Created by Oleksandr Tymoshenko on 2013-06-22.
//  Copyright (c) 2013 Bluezbox Software. All rights reserved.
//

#import "NSWindow+Fade.h"

#define kWindowAnimationDuration 0.3f

@implementation NSWindow (Fade)
- (IBAction)fadeIn:(id)sender
{
    [self setAlphaValue:0.f];
    [self makeKeyAndOrderFront:nil];
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:kWindowAnimationDuration];
    [[self animator] setAlphaValue:1.f];
    [NSAnimationContext endGrouping];
}

- (IBAction)fadeOut:(id)sender
{
    [NSAnimationContext beginGrouping];
    __block __unsafe_unretained NSWindow *bself = self;
    [[NSAnimationContext currentContext] setDuration:kWindowAnimationDuration];
    [[NSAnimationContext currentContext] setCompletionHandler:^{
        [bself orderOut:nil];
        [bself setAlphaValue:1.f];
    }];
    [[self animator] setAlphaValue:0.f];
    [NSAnimationContext endGrouping];
}
@end
