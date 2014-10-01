//
//  VocabulistApplicationDelegate.h
//  Vocabulist
//
//  Created by Oleksandr Tymoshenko on 2013-06-13.
//  Copyright (c) 2013 Bluezbox Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Sparkle/SUUpdater.h"


@interface VocabulistApplicationDelegate : NSObject<NSApplicationDelegate> {
    IBOutlet SUUpdater *updater;
    IBOutlet NSWindow *startupWindow;
    IBOutlet NSWindow *preferencesWindow;
    IBOutlet NSButton *importButton;
    IBOutlet NSButton *openButton;
    IBOutlet NSButton *webButton;
}


- (IBAction)importXcodeProject:(id)sender;
- (IBAction)preferences:(id)sender;

- (IBAction)cancelStartupWindow:(id)sender;

- (IBAction)startupImport:(id)sender;
- (IBAction)startupOpen:(id)sender;
- (IBAction)startupOpenWeb:(id)sender;

- (IBAction)contactSupport:(id)sender;
- (IBAction)openTutorial:(id)sender;


@end
