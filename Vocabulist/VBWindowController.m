//
//  VBWindowController.m
//  Vocabulist
//
//  Created by Oleksandr Tymoshenko on 2013-07-02.
//  Copyright (c) 2013 Bluezbox Software. All rights reserved.
//

#import "VBWindowController.h"

@interface VBWindowController ()

@end

@implementation VBWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName
{

    return displayName;
}

@end
