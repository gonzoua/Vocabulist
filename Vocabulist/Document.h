//
//  Document.h
//  Vocabulist
//
//  Created by Oleksandr Tymoshenko on 2013-04-29.
//  Copyright (c) 2013 Bluezbox Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XCodeProject.h"
#import "TUCDelegate.h"
#import "TranslationUnitController.h"
#import "AGScopeBar.h"

@interface Document : NSDocument<NSOutlineViewDataSource,NSOutlineViewDelegate,NSToolbarDelegate,TUCDelegate,NSTextFieldDelegate,AGScopeBarDelegate> {
    IBOutlet NSWindow *documentWindow;
    IBOutlet NSOutlineView *projectView;
    IBOutlet TranslationUnitController *tuController;
    IBOutlet NSPopUpButton *languagesButton;
    
    // base language part
    IBOutlet NSPanel *basePanel;
    IBOutlet NSPopUpButton *baseLanguageButton;
    IBOutlet NSPanel *demoPanel;
    IBOutlet NSPopUpButton *demoLanguageButton;
    IBOutlet NSProgressIndicator *progressIndicator;
    IBOutlet NSPanel *hudPanel;
    IBOutlet NSTextField *msgLabel;
    IBOutlet NSView *saveUntranslatedFormatView;
    IBOutlet NSPopUpButton *exportFormatButton;
    IBOutlet AGScopeBar *agScopeBar;
    IBOutlet NSView *agAccessoryView;
    IBOutlet NSSearchField *searchField;
    NSSavePanel *savePanel;
    NSInteger exportFormat;

}

@property (strong) XCodeProject *project;
@property (assign) NSInteger selectedUnit;
@property (strong) NSString *currentLanguage;

@property (strong) NSAlert *xcodeExportAlert;
@property (strong) NSAlert *xcodeImportAlert;
@property (assign) BOOL generateLocalizableStrings;


- (BOOL)importXcodeProject;
- (void)backgroundImport:(id)obj;
- (IBAction)importXcodeProjectChanges:(id)sender;
- (void)backgroundImportXcodeProjectChanges:(id)obj;

- (void)backgroundExportUnit:(id)obj;
- (void)backgroundExportLocalization:(id)obj;
- (void)backgroundExportProject:(id)obj;

- (void)exportFinished:(id)obj;

- (IBAction)selectBaseLanguage:(id)sender;
- (IBAction)selectDemoLanguage:(id)sender;
- (IBAction)languageChanged:(id)sender;

- (IBAction)toggleStringsText:(id)sender;

- (IBAction)nextLanguage:(id)sender;
- (IBAction)prevLanguage:(id)sender;

- (IBAction)nextString:(id)sender;
- (IBAction)prevString:(id)sender;


- (IBAction)markAsNew:(id)sender;
- (IBAction)markAsTranslated:(id)sender;
- (IBAction)markAsIgnored:(id)sender;

- (IBAction)exportUnit:(id)sender;
- (IBAction)exportLocalization:(id)sender;
- (IBAction)exportProject:(id)sender;

- (void)exportUnit:(VariantFile*)file forLocalization:(NSString*)locale inBundle:(NSURL*)bundleURL;

- (IBAction)saveUntranslatedFormatChanged:(id)sender;

- (void)showMessage:(NSString*)msg;

- (void) reloadInfo;

- (void)showAllStrings:(id)sender;
- (void)showUntranslatedStrings:(id)sender;

- (IBAction)importXML:(id)sender;
- (void)importXML:(NSXMLElement*)element forLanguage:(NSString*)lang toFile:(VariantFile*)f;

- (void)scopeBar:(AGScopeBar *)theScopeBar item:(AGScopeBarItem *)item wasSelected:(BOOL)selected;

@end