//
//  RCWindow.m
//  Vocabulist
//
//  Created by Oleksandr Tymoshenko on 2013-10-12.
//  Copyright (c) 2013 Bluezbox Software. All rights reserved.
//

#import "RCWindow.h"

@implementation RCWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag];
    
    if ( self )
    {
        [self setStyleMask:NSBorderlessWindowMask];
        [self setOpaque:NO];
        [self setBackgroundColor:[NSColor clearColor]];
        [self setMovableByWindowBackground:TRUE];
        
    }
    
    return self;
}

- (void) setContentView:(NSView *)aView
{
    aView.wantsLayer            = YES;
    aView.layer.frame           = aView.frame;
    aView.layer.cornerRadius    = 10.0;

    
    aView.layer.masksToBounds   = YES;
    
    
    [super setContentView:aView];
}

@end
