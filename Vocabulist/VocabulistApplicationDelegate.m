//
//  VocabulistApplicationDelegate.m
//  Vocabulist
//
//  Created by Oleksandr Tymoshenko on 2013-06-13.
//  Copyright (c) 2013 Bluezbox Software. All rights reserved.
//

#import "VocabulistApplicationDelegate.h"
#import "Document.h"
#import "LetsMove/PFMoveApplication.h"

#define kVocabulistURL @"http://vocabulistapp.com/?ref=app"
#define kSupportURL @"http://vocabulistapp.com/contact.html?ref=app"
#define kTutorialURL @"http://vocabulistapp.com/tutorial.html?ref=app"


#define kPrefHideStartupWindow @"HideStartupWindow"

@implementation VocabulistApplicationDelegate

- (NSMutableAttributedString*)makeTitle:(NSString*)titleStr subtitle:(NSString*)subtitle {
    NSMutableAttributedString* title = [[NSMutableAttributedString alloc] initWithString:titleStr];
    NSRange boldedRange = NSMakeRange(0, [title length]);
    NSRange normalRange = NSMakeRange([title length], [subtitle length]);
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:subtitle]];
    
    [title beginEditing];
    [title addAttribute:NSFontAttributeName
                  value:[NSFont boldSystemFontOfSize:14]
                  range:boldedRange];
    [title addAttribute:NSFontAttributeName
                  value:[NSFont systemFontOfSize:12]
                  range:normalRange];
    [title endEditing];
    
    return title;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    PFMoveToApplicationsFolderIfNecessary();
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Init layout manager
    NSImage *img = [NSImage imageNamed:@"PBX-project-icon.png"];
    NSImage *webImg = [NSImage imageNamed:@"web.png"];
    NSImage *docImg = [NSImage imageNamed:@"doc.png"];

    [importButton setImage:img];
    [importButton setImagePosition:NSImageLeft];
    [importButton setAttributedTitle:[self makeTitle:@"Import Xcode Project"
                                      subtitle:@"\nStart new translation project"]];
    

    [openButton setImage:docImg];
    [openButton setImagePosition:NSImageLeft];
    [openButton setTitle:@"Open Vocabulist Project\nOpen existing translation project"];
    [openButton setAttributedTitle:[self makeTitle:@"Open Vocabulist Project"
                                         subtitle:@"\nOpen existing translation project"]];
    
    
    [webButton setImage:webImg];
    [webButton setImagePosition:NSImageLeft];
    [webButton setAttributedTitle:[self makeTitle:@"Go to Vocabulist Website"
                                         subtitle:@"\nCheck for news, documentation and tutorials"]];
    
    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *appDefaults = [[NSMutableDictionary alloc] init];
    [appDefaults setObject:[NSNumber numberWithBool:NO] forKey:kPrefHideStartupWindow];
    [defaults registerDefaults:appDefaults];
}

- (void)showStarupWindow {
    BOOL disabled = [[NSUserDefaults standardUserDefaults] boolForKey:kPrefHideStartupWindow];

    if (!disabled)
        [startupWindow makeKeyAndOrderFront:nil];
 
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
    
    [self showStarupWindow];
    return NO;
}

- (IBAction)importXcodeProject:(id)sender
{
    NSError *err;
    NSDocumentController *docController = [NSDocumentController sharedDocumentController];
    Document *doc = [docController makeUntitledDocumentOfType:@"VocabulistProject" error:&err];
    if (doc) {
        [docController addDocument:doc];
        [doc makeWindowControllers];
        [doc showWindows];
        if (![doc importXcodeProject]) {
            [doc close];
        }
    }
    if (err) {
    
    }
}

- (IBAction)cancelStartupWindow:(id)sender
{
    [startupWindow orderOut:nil];
}

- (IBAction)startupImport:(id)sender {
    [startupWindow orderOut:nil];
    [self importXcodeProject:sender];
}

- (IBAction)startupOpen:(id)sender {
    [startupWindow orderOut:nil];
    [[NSDocumentController sharedDocumentController] openDocument:self];
    
}

- (IBAction)startupOpenWeb:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kVocabulistURL]];
}

- (IBAction)contactSupport:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kSupportURL]];
}

- (IBAction)openTutorial:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kTutorialURL]];
}

- (IBAction)preferences:(id)sender {
    [preferencesWindow makeKeyAndOrderFront:nil];
}


@end
