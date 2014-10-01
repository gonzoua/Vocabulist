//
//  TranslationUnitController.h
//  Vocabulist
//
//  Created by Oleksandr Tymoshenko on 2013-05-16.
//  Copyright (c) 2013 Bluezbox Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VariantFile.h"
#import "TUCDelegate.h"

@interface TranslationUnitController : NSObject<NSTableViewDataSource, NSTextFieldDelegate> {
    IBOutlet NSSegmentedControl *flagsControl;
    IBOutlet NSTableView *translationsView;
    IBOutlet NSTextField *baseTextField;
    IBOutlet NSTextField *translationTextField;
    IBOutlet NSTextField *keyTextField;

    IBOutlet NSObject<TUCDelegate> *delegate;
    
}

@property (strong) VariantFile *file;

@property (strong) NSString *currentLocale;
@property (strong) NSMutableArray *arrangedObjects;


@property (assign) BOOL showOnlyUntranslated;
@property (assign) BOOL showBaseStrings;

@property (strong) NSString *filter;

- (void)setUnit:(VariantFile*)f;
- (void)setLocale:(NSString*)lang;
- (void)syncTranslation;
- (IBAction)chnageFlags:(id)sender;

- (void)nextString;
- (void)prevString;


- (void)markAsNew;
- (void)markAsTranslated;
- (void)markAsIgnored;

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder;
- (void)restoreStateWithCoder:(NSCoder *)coder;

- (void)resetTextSelection:(NSWindow*)window;
- (void)updateCell:(id)cell flags:(NSInteger)flags;

- (void)setTextFilter:(NSString*)string;
- (void)setUntranslatedFilter:(BOOL)b;

- (void)applyFilter;
- (void)toggleStringsText;
- (void)syncAll;


@end
