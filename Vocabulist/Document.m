//
//  Document.m
//  Vocabulist
//
//  Created by Oleksandr Tymoshenko on 2013-04-29.
//  Copyright (c) 2013 Bluezbox Software. All rights reserved.
//

#import "Document.h"
#import "BaseNode.h"
#import "XCodeProject.h"
#import "VariantFile.h"
#import "NSWindow+Fade.h"
#import "VBWindowController.h"
#import "NSString+JSONEscape.h"
#import "NSAlert+SynchronousSheet.h"

#define COLUMNID_NAME			@"NameColumn"	// the single column name in our outline view
#define kExportFile NSLocalizedString(@"Export Current File", nil)
#define kExportFileFormat NSLocalizedString(@"Export %@ “%@”", nil)
#define kExportLocalizationFormat NSLocalizedString(@"Export %@ Localization", nil)
#define kExportLocalization NSLocalizedString(@"Export Current Localization", nil)

#define kExport NSLocalizedString(@"Export", nil)
#define kNoXcrun NSLocalizedString(@"/usr/bin/xcrun not found", nil)
#define kXcodeRequired NSLocalizedString(@"This operation requires xcrun(1) tool. Please download and install Xcode.", nil)

#define kNoIbtool NSLocalizedString(@"ibtool(1) not found", nil)
#define kIbtoolRequired NSLocalizedString(@"Please make sure you have Xcode Command Line Tools installed. Also make sure proper version of Xcode is selected by running \"xcode-select --print-path\" command and if not fix it with \"xcode-select -s /Path/To/Xcode\" command.", nil)

#define kExportUntranslated NSLocalizedString(@"From %@ “%@”...", nil)
#define kNoUntranslated NSLocalizedString(@"No untranslated strings", nil)
#define kExportSucceded NSLocalizedString(@"Export succeeded", nil)
#define kExportFailed NSLocalizedString(@"Export failed", nil)
#define kImportSucceded NSLocalizedString(@"Import succeeded", nil)
#define kImportFailed NSLocalizedString(@"Import failed", nil)
#define kNoBaseLocalization NSLocalizedString(@"Can't import changes: base localization has been removed from Xcode project. Please create new Vocabulist project and re-import Xcode project.", nil)

#define kUntranslated NSLocalizedString(@"Untranslated", nil)
#define kAll NSLocalizedString(@"All", nil)
#define kCantFindFile NSLocalizedString(@"Can't find file %@ in the project", nil)
#define kCantExportBaseLocalization NSLocalizedString(@"Can't export base localization", nil)
#define kFailedParse NSLocalizedString(@"Failed to parse XML file", nil)
#define kInvalidLocalizationEntry NSLocalizedString(@"Invalid localization entry", nil)

#define kDemoVersion NSLocalizedString(@"Unregistered version", nil)
#define kLimitLanguages NSLocalizedString(@"Unregistered version supports only one localization. All other localizations will be disabled", nil)
#define kGenerateLocalizableStrings NSLocalizedString(@"Generate Localizable.strings before importing project?", nil)
#define kYes NSLocalizedString(@"Yes", nil)
#define kNo NSLocalizedString(@"No", nil)

#define kFormatText     0
#define kFormatXML      1

@interface NSXMLNode (oneChildXPath)
-(NSString *) stringForXPath:(NSString*)xpath error:(NSError**)error;
@end

@implementation NSXMLNode (oneChildXPath)

- (NSString *)stringForXPath:(NSString*)xpath error:(NSError**)error
{
    NSArray *nodes = [self nodesForXPath:xpath error:error];
    if ([nodes count])
        return [[nodes objectAtIndex:0] stringValue];
    else
        return nil;
}

@end

@interface NSMenuItem (Font)
- (void)setBold;

@end

@implementation NSMenuItem (Font)

- (void)setBold
{
	NSFont* font = [NSFont boldSystemFontOfSize:13.0] ;
	NSString* title = [self title] ;
	NSDictionary* fontAttribute = [NSDictionary dictionaryWithObjectsAndKeys:
								   font, NSFontAttributeName,
								   nil] ;
	NSMutableAttributedString* newTitle = [[NSMutableAttributedString alloc] initWithString:title
																				 attributes:fontAttribute] ;
    
    
	[self setAttributedTitle:newTitle] ;
}

@end

@implementation Document

- (id)init
{
    self = [super init];
    if (self) {
        self.project = nil;
        self.currentLanguage = nil;
        self.selectedUnit = 0;
    }
    return self;
}

- (void)awakeFromNib
{
    AGScopeBarGroup * group = nil;
    if ([agScopeBar.groups count] == 0) {
        group = [agScopeBar addGroupWithIdentifier:@"0" label:nil items:nil];
        [group addItemWithIdentifier:@"all" title:kAll];
        [group addItemWithIdentifier:@"untranslated" title:kUntranslated];
        group.selectionMode = AGScopeBarGroupSelectOne;
        
        agScopeBar.delegate = self;
        agScopeBar.accessoryView = agAccessoryView;
        searchField.delegate = self;
    }
}

- (void)scopeBar:(AGScopeBar *)theScopeBar item:(AGScopeBarItem *)item wasSelected:(BOOL)selected
{
    if ([item.identifier isEqualToString:@"all"])
        [self showAllStrings:self];
    else
        [self showUntranslatedStrings:self];
}

- (void)showAllStrings:(id)sender
{

    [tuController setUntranslatedFilter:NO];
    
}

- (void)showUntranslatedStrings:(id)sender
{

    [tuController setUntranslatedFilter:YES];
}

// handle search text filters
- (void)controlTextDidChange:(NSNotification *)aNotification
{

    [tuController setTextFilter:[searchField stringValue]];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item {

    if ([item action] == @selector(exportUnit:)) {
        if ([self.project.variantFiles count] > 0) {
            NSLocale *locale = [NSLocale currentLocale];
            
            NSString *langName = [locale displayNameForKey:NSLocaleIdentifier value:self.currentLanguage];
            if (langName == nil)
                langName = self.currentLanguage;
            
            NSInteger idx = self.selectedUnit;
            VariantFile *f = [self.project.variantFiles objectAtIndex:idx];
            item.title = [NSString stringWithFormat:kExportFileFormat, langName, f.name];
            [item setHidden:NO];
        }
        else {
            item.title = kExportFile;
            [item setHidden:NO];
        }
    }
    if ([item action] == @selector(exportLocalization:)) {
        if (self.currentLanguage != nil) {
            NSLocale *locale = [NSLocale currentLocale];

            NSString *langName = [locale displayNameForKey:NSLocaleIdentifier value:self.currentLanguage];
            if (langName == nil)
                langName = self.currentLanguage;
            
            item.title = [NSString stringWithFormat:kExportLocalizationFormat, langName];
            [item setHidden:NO];
        }
        else {
            item.title = kExportLocalization;
            [item setHidden:NO];
        }
    }
    else if ([item action] == @selector(exportUnitUntranslated:)) {
        if ([self.project.variantFiles count] > 0) {
            NSLocale *locale = [NSLocale currentLocale];
            
            NSString *langName = [locale displayNameForKey:NSLocaleIdentifier value:self.currentLanguage];
            if (langName == nil)
                langName = self.currentLanguage;
            
            NSInteger idx = self.selectedUnit;
            VariantFile *f = [self.project.variantFiles objectAtIndex:idx];
            item.title = [NSString stringWithFormat:kExportUntranslated, langName, f.name];
        }
        else
            item.title = kExport;
    }
    return YES;
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"Document";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{

    [super windowControllerDidLoadNib:aController];

    if (self.project) {        
        // sync languages
        [languagesButton removeAllItems];
        NSMenu *menu = [languagesButton menu];
        [menu setAutoenablesItems:NO];

        int tag = 0;
        NSInteger  idx = 0;
        NSInteger baseIdx = 0;
        NSLocale *locale = [NSLocale currentLocale];
        for (NSString *l in self.project.knownRegions) {
            NSMenuItem *item = [[NSMenuItem alloc] init];
            NSString *langName = [locale displayNameForKey:NSLocaleIdentifier value:l];
            if (langName == nil)
                item.title = l;
            else
                item.title = langName;
            if ([self.project.baseLocalization compare:l] == NSOrderedSame) {
                [item setBold];
                baseIdx = idx;
            }

            if ([self.currentLanguage compare:l] == NSOrderedSame)
                idx = tag;
            item.tag = tag++;
            [menu addItem:item];
        }
        
        [languagesButton selectItemAtIndex:idx];

        [projectView reloadData];
        [projectView expandItem:self.project];
        idx = self.selectedUnit;
        VariantFile *f = [self.project.variantFiles objectAtIndex:idx];
        [tuController setUnit:f];
        
        NSIndexSet *set = [[NSIndexSet alloc] initWithIndex:idx+1];
        [projectView selectRowIndexes:set byExtendingSelection:NO];

        [tuController setLocale:self.currentLanguage];
        [tuController syncTranslation];
    }
    [hudPanel setFloatingPanel:YES];
    [hudPanel setWorksWhenModal:YES];


    [documentWindow addChildWindow:hudPanel ordered:NSWindowAbove];
}

+ (BOOL)autosavesInPlace
{
    return NO;
}

- (void)makeWindowControllers
{
    VBWindowController* wc = [[VBWindowController alloc] initWithWindowNibName: [self windowNibName] owner:self];
    [self addWindowController:wc];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    NSMutableData *mData = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:mData];

    if (self.project) {
        [archiver encodeObject:self.project forKey:@"project"];
        [archiver encodeObject:self.currentLanguage forKey:@"currentLanguage"];
        [archiver encodeObject:[NSNumber numberWithInteger:self.selectedUnit] forKey:@"selectedUnit"];
    }
    else {
        [archiver encodeBool:YES forKey:@"emptyProject"];
    }
    [archiver finishEncoding];
    NSData *data = [NSData dataWithData:mData];
    if (!data && outError) {
        *outError = [NSError errorWithDomain:NSCocoaErrorDomain
                                        code:NSFileWriteUnknownError userInfo:nil];
    }
    return data;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{

    
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    BOOL emptyProject = [unarchiver decodeBoolForKey:@"emptyProject"];
    if (!emptyProject) {
        self.project = [unarchiver decodeObjectForKey:@"project"];
        self.currentLanguage = [unarchiver decodeObjectForKey:@"currentLanguage"];
        self.selectedUnit = [[unarchiver decodeObjectForKey:@"selectedUnit"] integerValue];

        if (self.project == nil)
            return NO;
        if (self.currentLanguage == nil) {
            if ([self.project.knownRegions count])
                self.currentLanguage = [self.project.knownRegions objectAtIndex:0];
        }

        [self syncState];
    }
    else {
        self.project = nil;
        self.currentLanguage = @"";
        self.selectedUnit = 0;
    }
    return YES;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    [coder encodeObject:[NSNumber numberWithInteger:self.selectedUnit] forKey:@"selectedUnit"];
    [coder encodeObject:self.currentLanguage forKey:@"currentLanguage"];
    [tuController encodeRestorableStateWithCoder:coder];
}

- (void)syncState {
    NSInteger idx = [self.project.knownRegions indexOfObject:self.currentLanguage];
    if (idx >= 0)
        [languagesButton selectItemAtIndex:idx];
    NSIndexSet *set = [[NSIndexSet alloc] initWithIndex:self.selectedUnit + 1];
    [projectView selectRowIndexes:set byExtendingSelection:NO];
    [tuController setLocale:self.currentLanguage];
}

- (void)restoreStateWithCoder:(NSCoder *)coder {
    [super restoreStateWithCoder:coder];
    
    self.currentLanguage = [coder decodeObjectForKey:@"currentLanguage"];
    self.selectedUnit = [[coder decodeObjectForKey:@"selectedUnit"] integerValue];
    [self syncState];
    
    [tuController restoreStateWithCoder:coder];
}

//
// OutlineView Data Source
//
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    
    if ([item isKindOfClass:[XCodeProject class]])
        return YES;
    else
        return NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (item==nil)
        return (self.project == nil) ? 0 : 1;
    
    if ([item isKindOfClass:[XCodeProject class]]) {
        XCodeProject *proj = (XCodeProject*)item;
        return [proj.variantFiles count];
    }
    
    return (0);
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (item == nil)
        return self.project;

    if ([item isKindOfClass:[XCodeProject class]]) {
        XCodeProject *proj = (XCodeProject*)item;
        return [proj.variantFiles objectAtIndex:index];
    }
    
    return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)theColumn byItem:(id)item
{

    if ([[theColumn identifier] isEqualToString:@"NameColumn"])
    {
        if ([item isKindOfClass:[XCodeProject class]]) {
            XCodeProject *proj = (XCodeProject*)item;
            return proj.name;
        }
        else if ([item isKindOfClass:[VariantFile class]]) {
            VariantFile *vf = (VariantFile*)item;
            return vf.name;
        }
    }

    
    // Never reaches here
    return nil;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView
     viewForTableColumn:(NSTableColumn *)tableColumn
                   item:(id)item {
    
    
    NSTableCellView *result = nil;

    result = [outlineView makeViewWithIdentifier:@"DataCell" owner:self];
    if ([item isKindOfClass:[XCodeProject class]]) {
        XCodeProject *proj = (XCodeProject*)item;
        [[result textField] setStringValue:proj.name];
        [[result imageView] setImage:[NSImage imageNamed:@"PBX-project-icon.png"]];

    }
    else if ([item isKindOfClass:[VariantFile class]]) {
        VariantFile *vf = (VariantFile*)item;
        [[result textField] setStringValue:vf.name];
        if (vf.fileType == kXibFile)
            [[result imageView] setImage:[NSImage imageNamed:@"PBX-xib-Icon.tiff"]];
        else if (vf.fileType == kStoryboardFile)
            [[result imageView] setImage:[NSImage imageNamed:@"PBX-storyboard-Icon.tiff"]];
        else
            [[result imageView] setImage:[NSImage imageNamed:@"PBX-strings-Icon.tiff"]];
    }

 
    return result;
}

/*******************************************************
 *
 * OUTLINE-VIEW DELEGATE
 *
 *******************************************************/

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    if ([item isKindOfClass:[XCodeProject class]])
        return NO;
    else
        return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{

    return NO;
}


//
// optional methods for content editing
//

- (BOOL)    outlineView:(NSOutlineView *)outlineView
  shouldEditTableColumn:(NSTableColumn *)tableColumn
                   item:(id)item {
    

    return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item
{
    
    return YES;
}

- (BOOL)importXcodeProject
{
    
    if (![self checkXcode])
        return FALSE;
    
    // Create the File Open Dialog class.
    NSOpenPanel *openDlg = [NSOpenPanel openPanel];
    
    [openDlg setCanChooseFiles:YES];
    [openDlg setCanChooseDirectories:NO];
    [openDlg setCanCreateDirectories:NO];
    [openDlg setAllowsMultipleSelection:NO];
        
    if ( [openDlg runModal] == NSOKButton )
    {
        NSArray *urls = [openDlg URLs];
        NSURL *url = [urls objectAtIndex:0];
        [progressIndicator startAnimation:self];
        [NSThread detachNewThreadSelector:@selector(backgroundImport:) toTarget:self withObject:url];
        return YES;
    }
    else
        return NO;
}

- (IBAction)importXcodeProjectChanges:(id)sender
{
    
    if (![self checkXcode])
        return;
    NSURL *url = nil;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self.project.bundle path]]) {
        // Create the File Open Dialog class.
        NSOpenPanel *openDlg = [NSOpenPanel openPanel];
        
        [openDlg setCanChooseFiles:YES];
        [openDlg setCanChooseDirectories:NO];
        [openDlg setCanCreateDirectories:NO];
        [openDlg setAllowsMultipleSelection:NO];
        
        if ( [openDlg runModal] == NSOKButton )
        {
            NSArray *urls = [openDlg URLs];
            url = [urls objectAtIndex:0];

        }
    }
    else {
        url = self.project.bundle;
    }
    

    
    [progressIndicator startAnimation:self];
    [NSThread detachNewThreadSelector:@selector(backgroundImportXcodeProjectChanges:) toTarget:self withObject:url];

}

- (void)askForLocalizableStringsUpdate:(id)ctx {
    NSAlert *alert = [[NSAlert alloc] init];
    alert = [[NSAlert alloc] init];
    alert.messageText = kGenerateLocalizableStrings;
    alert.alertStyle = NSInformationalAlertStyle;
    [alert addButtonWithTitle:kYes];
    [alert addButtonWithTitle:kNo];
    NSInteger result = [alert runModalSheetForWindow:documentWindow];
    if (result == 1000)
        self.generateLocalizableStrings = YES;
    else
        self.generateLocalizableStrings = NO;
}

- (void)backgroundImportXcodeProjectChanges:(id)obj
{
    NSURL *url = obj;
    self.xcodeImportAlert = nil;
    XCodeProject *newProject = [[XCodeProject alloc] initWithURL:url];
    if (![newProject.knownRegions containsObject:self.project.baseLocalization]) {
        NSLog(@"No base localization in updated project");
        [self performSelectorOnMainThread:@selector(importXcodeProjectChangesFailed:) withObject:nil waitUntilDone:NO];
        return;

    }
    
    newProject.baseLocalization = self.project.baseLocalization;
    
    NSAlert *alert;
    self.xcodeImportAlert = nil;
    
    if ([newProject hasLocalizableStrings]) {

        self.generateLocalizableStrings = NO;
        [self performSelectorOnMainThread:@selector(askForLocalizableStringsUpdate:) withObject:nil waitUntilDone:YES];
    
        if (self.generateLocalizableStrings) {
            // requires baseLocalization set
            if (![newProject generateLocalizableStrings:&alert]) {
                self.xcodeImportAlert = alert;
                [self performSelectorOnMainThread:@selector(importXcodeProjectChangesFailed:) withObject:nil waitUntilDone:NO];
                return;
            }
        }
    }

    
    if (![newProject loadLocalizedFiles:&alert]) {
        self.xcodeImportAlert = alert;
        [self performSelectorOnMainThread:@selector(importXcodeProjectChangesFailed:) withObject:nil waitUntilDone:NO];
        return;
    }
    [newProject initFlags];


    for (NSString *lang in newProject.knownRegions) {
        for (VariantFile *nf in newProject.variantFiles) {
            NSString *path = [nf localizationPath:lang];
            if (path == nil)
                continue;
            VariantFile *oldf = nil;
            for (VariantFile *f in self.project.variantFiles) {
                NSString *oldPath = [f localizationPath:lang];
                if (oldPath == nil)
                    continue;
                
                if ([oldPath isEqualToString:path]) {
                    oldf = f;
                    break;
                }
            }
            
            if (oldf) {
                for (NSString *k in nf.keys) {
                    TranslationEntry *oldTE = [oldf translationEntryForKey:k];
                    TranslationEntry *newTE = [nf translationEntryForKey:k];
                    
                    if (oldTE == nil)
                        continue;
                    if (newTE == nil)
                        continue;
                    
                    NSString *oldText, *newText;
                    oldText = [oldTE textForLocale:lang];
                    newText = [newTE textForLocale:lang];
                    if ([oldText isEqualToString:newText]) {
                        [newTE setFlags:[oldTE flags:lang] forLocale:lang];
                    }


                }
            }
        }
    }
    
    if (![newProject.knownRegions containsObject:self.currentLanguage])
        self.currentLanguage = newProject.baseLocalization;
    
    self.project = newProject;
    
    [self performSelectorOnMainThread:@selector(importXcodeProjectChangesDone:) withObject:nil waitUntilDone:NO];
}

- (void)importXcodeProjectChangesFailed:(id)obj
{
    [progressIndicator stopAnimation:self];

    [self showMessage:kImportFailed];
    NSAlert *alert;
    if (self.xcodeImportAlert != nil) {
        alert = self.xcodeImportAlert;
        self.xcodeImportAlert = nil;
    }
    else {
        alert = [[NSAlert alloc] init];
        alert.messageText = kImportFailed;
        alert.informativeText = kNoBaseLocalization;
        alert.alertStyle = NSCriticalAlertStyle;
    }
    [alert runModal]; // Ignore return value.
}

- (void)importXcodeProjectChangesDone:(id)obj
{
    [progressIndicator stopAnimation:self];
    [self updateLanguages];
    [projectView reloadData];
    [projectView expandItem:self.project];
    NSIndexSet *set = [[NSIndexSet alloc] initWithIndex:1];
    [self updateChangeCount:NSChangeDone];
    [projectView selectRowIndexes:set byExtendingSelection:NO];
    [self languageChanged:self];
    [self showMessage:kImportSucceded];
}

- (void)backgroundImport:(id)obj
{
    NSURL *url = obj;
    self.project = [[XCodeProject alloc] initWithURL:url];
    [self performSelectorOnMainThread:@selector(baseLanguageStage:) withObject:nil waitUntilDone:NO];
}

- (void)baseLanguageStage:(id)obj
{
    [progressIndicator stopAnimation:self];

    [baseLanguageButton removeAllItems];
    NSMenu *menu = [baseLanguageButton menu];
    
    int tag = 0;
    NSLocale *locale = [NSLocale currentLocale];
    for (NSString *l in self.project.knownRegions) {
        NSMenuItem *item = [[NSMenuItem alloc] init];
        NSString *langName = [locale displayNameForKey:NSLocaleIdentifier value:l];
        if (langName == nil)
            item.title = l;
        else
            item.title = langName;
        item.tag = tag++;
        [menu addItem:item];
    }
    
    [NSApp beginSheet:basePanel modalForWindow:documentWindow
        modalDelegate:self didEndSelector:NULL contextInfo:nil];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    NSInteger row = [projectView selectedRow];
    if (row > 0) {
        VariantFile *f = [self.project.variantFiles objectAtIndex:(row - 1)];
        self.selectedUnit = (row - 1);
        [tuController setUnit:f];
    }
}

- (IBAction)selectBaseLanguage:(id)sender
{
    [NSApp endSheet:basePanel];
    [basePanel orderOut:nil];
    NSString *base = [self.project.knownRegions objectAtIndex:[baseLanguageButton selectedTag]];
    self.project.baseLocalization = base;
    
    [self updateLanguages];
    [progressIndicator startAnimation:self];
    [NSThread detachNewThreadSelector:@selector(loadLocalizedFiles:) toTarget:self withObject:nil];
    return;

    
    if ([self.project.knownRegions count] > 2) {

        [demoLanguageButton removeAllItems];
        NSMenu *menu = [demoLanguageButton menu];
    
        int tag = 0;
        NSLocale *locale = [NSLocale currentLocale];
        for (NSString *l in self.project.knownRegions) {
            if ([base isEqualToString:l]) {
                tag++;
                continue;
            }
            NSMenuItem *item = [[NSMenuItem alloc] init];
            NSString *langName = [locale displayNameForKey:NSLocaleIdentifier value:l];
            if (langName == nil)
                item.title = l;
            else
                item.title = langName;
            item.tag = tag++;
            [menu addItem:item];
        }

        [NSApp beginSheet:demoPanel modalForWindow:documentWindow
            modalDelegate:self didEndSelector:NULL contextInfo:nil];
    }
    else {
        [self updateLanguages];
        
        [progressIndicator startAnimation:self];
        [NSThread detachNewThreadSelector:@selector(loadLocalizedFiles:) toTarget:self withObject:nil];
    }
}

- (IBAction)selectDemoLanguage:(id)sender
{
    [NSApp endSheet:demoPanel];
    [demoPanel orderOut:nil];
    
    NSString *demo = [self.project.knownRegions objectAtIndex:[demoLanguageButton selectedTag]];
    [self.project.knownRegions removeAllObjects];
    [self.project.knownRegions addObject:self.project.baseLocalization];
    [self.project.knownRegions addObject:demo];
    
    [self updateLanguages];
    
    [progressIndicator startAnimation:self];
    [NSThread detachNewThreadSelector:@selector(loadLocalizedFiles:) toTarget:self withObject:nil];
}


- (void)updateLanguages
{
    [languagesButton removeAllItems];
    NSMenu *menu = [languagesButton menu];
    [menu setAutoenablesItems:NO];

    int tag = 0;
    NSLocale *locale = [NSLocale currentLocale];
    
    for (NSString *l in self.project.knownRegions) {
        NSMenuItem *item = [[NSMenuItem alloc] init];
        NSString *langName = [locale displayNameForKey:NSLocaleIdentifier value:l];
        if (langName == nil)
            item.title = l;
        else
            item.title = langName;
        
        item.tag = tag++;
        if ([self.project.baseLocalization compare:l] == NSOrderedSame)
            [item setBold];

        [menu addItem:item];
    }
    

    tuController.currentLocale = [self.project.knownRegions objectAtIndex:0];
}

- (void)loadLocalizedFiles:(id)obj
{
    NSAlert *alert;
    
    if ([self.project hasLocalizableStrings]) {
        
        self.generateLocalizableStrings = NO;
        [self askForLocalizableStringsUpdate:nil];
        
        if (self.generateLocalizableStrings) {
            // requires baseLocalization set
            if (![self.project generateLocalizableStrings:&alert]) {
                self.xcodeImportAlert = alert;
                [self performSelectorOnMainThread:@selector(loadLocalizedFilesFailed:) withObject:nil waitUntilDone:NO];
                return;
            }
        }
    }

    if (![self.project loadLocalizedFiles:&alert]) {
        self.xcodeImportAlert = alert;
        [self performSelectorOnMainThread:@selector(loadLocalizedFilesFailed:) withObject:nil waitUntilDone:NO];
    }
    [self.project initFlags];
    [self performSelectorOnMainThread:@selector(loadLocalizedFilesDone:) withObject:nil waitUntilDone:NO];
}

- (void)loadLocalizedFilesFailed:(id)obj
{
    [progressIndicator stopAnimation:self];
    if (self.xcodeImportAlert != nil)
        [self.xcodeImportAlert runModal];
}

- (void)loadLocalizedFilesDone:(id)obj
{
    [progressIndicator stopAnimation:self];

    [projectView reloadData];
    [projectView expandItem:self.project];
    NSIndexSet *set = [[NSIndexSet alloc] initWithIndex:1];
    [self updateChangeCount:NSChangeDone];
    [projectView selectRowIndexes:set byExtendingSelection:NO];
    [self languageChanged:self];
}

- (IBAction)languageChanged:(id)sender
{
    self.currentLanguage = [self.project.knownRegions objectAtIndex:[languagesButton selectedTag]];
    [tuController setLocale:self.currentLanguage];
    [tuController resetTextSelection:documentWindow];

}

- (IBAction)toggleStringsText:(id)sender
{
    [tuController toggleStringsText];
}


- (IBAction)nextLanguage:(id)sender
{    
    NSInteger idx = languagesButton.selectedTag;
    NSInteger items = [[languagesButton menu] numberOfItems];
    NSInteger origIdx = idx;
    if (items) {
        do {
            if (idx + 1 >= items)
                idx = 0;
            else
                idx++;
            NSMenuItem *item = [languagesButton itemAtIndex:idx];
            if ([item isEnabled]) {
                [languagesButton selectItemWithTag:idx];
                break;
            }
        } while (idx != origIdx);
        [self languageChanged:nil];
    }
}

- (IBAction)prevLanguage:(id)sender
{
    NSInteger idx = languagesButton.selectedTag;
    NSInteger items = [[languagesButton menu] numberOfItems];
    NSInteger origIdx = idx;

    if (items) {
        do {
            if (idx == 0)
                idx = items - 1;
            else
                idx--;
            NSMenuItem *item = [languagesButton itemAtIndex:idx];
            if ([item isEnabled]) {
                [languagesButton selectItemWithTag:idx];
                break;
            }
        } while (idx != origIdx);
        [self languageChanged:nil];
    }
}

- (IBAction)nextString:(id)sender
{
    [tuController resetTextSelection:documentWindow];
    [tuController nextString];
}

- (IBAction)prevString:(id)sender
{
    [tuController resetTextSelection:documentWindow];
    [tuController prevString];
}

- (IBAction)markAsNew:(id)sender
{
    [tuController markAsNew];
}

- (IBAction)markAsTranslated:(id)sender
{
    [tuController markAsTranslated];
}

- (IBAction)markAsIgnored:(id)sender
{
    [tuController markAsIgnored];
}

- (void)saveUntranslatedInFile:(VariantFile*)f toXml:(NSXMLElement*)node
{
    NSXMLElement *localizationNode =
    (NSXMLElement *)[NSXMLNode elementWithName:@"localization"];
    
    NSXMLNode *langAttr = [NSXMLNode attributeWithName:@"lang"
                                           stringValue:self.currentLanguage];
    NSXMLNode *pathAttr = [NSXMLNode attributeWithName:@"path"
                                           stringValue:[f localizationPath:self.currentLanguage]];
    [localizationNode addAttribute:langAttr];
    [localizationNode addAttribute:pathAttr];
    
    
    
    NSMutableArray *untranslated = [[NSMutableArray alloc] init];
    
    
    for (NSString *key in f.keys) {
        TranslationEntry * te = [f translationEntryForKey:key];
        if (te) {
            if ([te flags:self.currentLanguage] == kTENew) {
                [untranslated addObject:[te textForLocale:f.baseLocalization]];
                NSXMLNode *keyAttr = [NSXMLNode attributeWithName:@"key"
                                                      stringValue:[key JSONString]];
                NSXMLElement *stringElement =
                (NSXMLElement *)[NSXMLNode elementWithName:@"string"];
                [stringElement addAttribute:keyAttr];
                
                NSXMLElement *baseElement =
                (NSXMLElement *)[NSXMLNode elementWithName:@"baseText"];
                NSXMLElement *translationElement =
                (NSXMLElement *)[NSXMLNode elementWithName:@"translationText"];
                [baseElement setStringValue:[[te textForLocale:f.baseLocalization] JSONString]];
                NSString *tr;
                tr = [te textForLocale:self.currentLanguage];
                if (tr == nil)
                    tr = [te textForLocale:f.baseLocalization];
                if (tr == nil)
                    tr = @"";
                [translationElement setStringValue:[tr JSONString]];
                [stringElement addChild:baseElement];
                [stringElement addChild:translationElement];
                [localizationNode addChild:stringElement];
            }
        }
    }
    
    [node addChild:localizationNode];
}


- (IBAction)exportAllUntranslated:(id)sender
{
    NSMutableString *name = [NSMutableString stringWithString:self.project.name];
    [name appendFormat:@"-%@-untranslated", self.currentLanguage];
    
    if (exportFormat == kFormatText) {
        [name appendString:@".txt"];
        [exportFormatButton selectItemAtIndex:kFormatText];
    }
    else if (exportFormat == kFormatXML) {
        [name appendString:@".xml"];
        [exportFormatButton selectItemAtIndex:kFormatXML];
    }
    
    savePanel = [NSSavePanel savePanel];
    [savePanel setAccessoryView:saveUntranslatedFormatView];
    savePanel.nameFieldStringValue = name;
    NSInteger choice = [savePanel runModal];
    
    NSString *outFile = [[savePanel URL] path];
    savePanel = nil;
    
    /* if successful, save file under designated name */
    if (choice == NSFileHandlingPanelCancelButton)
        return;

    if (exportFormat == kFormatText) {
        NSMutableArray *untranslated = [[NSMutableArray alloc] init];
        for (VariantFile *f in self.project.variantFiles) {
            for (NSString *key in f.keys) {
                TranslationEntry * te = [f translationEntryForKey:key];
                if (te) {
                    if ([te flags:self.currentLanguage] == kTENew) {
                        [untranslated addObject:[[te textForLocale:f.baseLocalization] JSONString]];
                    }
                }
            }
        }
        
        NSString *text = [untranslated componentsJoinedByString:@"\n\n"];
        NSData *textData = [text dataUsingEncoding:NSUTF8StringEncoding];
        NSError *err;
        if (![textData writeToFile:outFile options:NSDataWritingAtomic error:&err]) {
            NSAlert *alert = [NSAlert alertWithError:err];
            [alert runModal]; // Ignore return value.
        }
    }
    else if (exportFormat == kFormatXML) {
        NSXMLNode *versionAttr = [NSXMLNode attributeWithName:@"version"
                                              stringValue:@"1"];
        NSXMLElement *root =
        (NSXMLElement *)[NSXMLNode elementWithName:@"localizations"];
        [root addAttribute:versionAttr];
        NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithRootElement:root];
        [xmlDoc setVersion:@"1.0"];
        [xmlDoc setCharacterEncoding:@"UTF-8"];
        for (VariantFile *f in self.project.variantFiles) {
            [self saveUntranslatedInFile:f toXml:root];
        }
        
        NSString *xmlString = [xmlDoc XMLStringWithOptions:NSXMLNodePrettyPrint];
        NSData *xmlData = [xmlString dataUsingEncoding:NSUTF8StringEncoding];
        NSError *err;
        if (![xmlData writeToFile:outFile options:NSDataWritingAtomic error:&err]) {
            NSAlert *alert = [NSAlert alertWithError:err];
            [alert runModal]; // Ignore return value.
        }
    }
    
}


- (IBAction)exportUnitUntranslated:(id)sender
{
    if ([self.project.variantFiles count] <= self.selectedUnit) {
        return;
    }
    
    VariantFile *f = [self.project.variantFiles objectAtIndex:self.selectedUnit];

    NSMutableString *name = [NSMutableString stringWithString:f.name];
    [name replaceOccurrencesOfString:@"." withString:@"_" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [name length])];
    [name appendFormat:@"-%@-untranslated", self.currentLanguage];
    
    if (exportFormat == kFormatText) {
        [name appendString:@".txt"];
        [exportFormatButton selectItemAtIndex:kFormatText];
    }
    else if (exportFormat == kFormatXML) {
        [name appendString:@".xml"];
        [exportFormatButton selectItemAtIndex:kFormatXML];
    }
    
    savePanel = [NSSavePanel savePanel];
    [savePanel setAccessoryView:saveUntranslatedFormatView];
    savePanel.nameFieldStringValue = name;
    NSInteger choice = [savePanel runModal];
    
    NSString *outFile = [[savePanel URL] path];
    savePanel = nil;
    
    /* if successful, save file under designated name */
    if (choice == NSFileHandlingPanelCancelButton)
        return;
    

    
    if (exportFormat == kFormatText) {
        NSMutableArray *untranslated = [[NSMutableArray alloc] init];
        
        for (NSString *key in f.keys) {
            TranslationEntry * te = [f translationEntryForKey:key];
            if (te) {
                if ([te flags:self.currentLanguage] == kTENew) {
                    [untranslated addObject:[[te textForLocale:f.baseLocalization] JSONString]];
                }
            }
        }
        
        NSString *text = [untranslated componentsJoinedByString:@"\n\n"];
        NSData *textData = [text dataUsingEncoding:NSUTF8StringEncoding];
        NSError *err;
        if (![textData writeToFile:outFile options:NSDataWritingAtomic error:&err]) {
            NSAlert *alert = [NSAlert alertWithError:err];
            [alert runModal]; // Ignore return value.
        }
    }
    else if (exportFormat == kFormatXML) {
        NSXMLNode *versionAttr = [NSXMLNode attributeWithName:@"version"
                                                  stringValue:@"1"];
        NSXMLElement *root =
        (NSXMLElement *)[NSXMLNode elementWithName:@"localizations"];
        [root addAttribute:versionAttr];
        NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithRootElement:root];
        [xmlDoc setVersion:@"1.0"];
        [xmlDoc setCharacterEncoding:@"UTF-8"];
        
        [self saveUntranslatedInFile:f toXml:root];
        
        NSString *xmlString = [xmlDoc XMLStringWithOptions:NSXMLNodePrettyPrint];
        NSData *xmlData = [xmlString dataUsingEncoding:NSUTF8StringEncoding];
        NSError *err;
        if (![xmlData writeToFile:outFile options:NSDataWritingAtomic error:&err]) {
            NSAlert *alert = [NSAlert alertWithError:err];
            [alert runModal]; // Ignore return value.
        }
    }
}

- (IBAction)importXML:(id)sender
{
    // Create the File Open Dialog class.
    NSOpenPanel *openDlg = [NSOpenPanel openPanel];
    
    [openDlg setCanChooseFiles:YES];
    [openDlg setCanChooseDirectories:NO];
    [openDlg setCanCreateDirectories:NO];
    [openDlg setAllowsMultipleSelection:NO];
    [openDlg setAllowedFileTypes:[NSArray arrayWithObject:@"xml"]];
    
    if ( [openDlg runModal] == NSOKButton )
    {
        NSArray *urls = [openDlg URLs];
        NSURL *url = [urls objectAtIndex:0];
        [progressIndicator startAnimation:self];
        [NSThread detachNewThreadSelector:@selector(backgroundImportXML:) toTarget:self withObject:url];
    }
}

- (void)importXML:(NSXMLElement*)element forLanguage:(NSString*)lang toFile:(VariantFile*)f
{
    NSArray *nodes = [element nodesForXPath:@"./string"
                                     error:nil];
    BOOL modified = NO;
    for (NSXMLElement *el in nodes) {
        NSString *key = [NSString stringFromJSON:[[el attributeForName:@"key"] stringValue]];
        TranslationEntry * te = [f translationEntryForKey:key];
        if (te != nil) {
            // NSString *origBaseText = [te textForLocale:self.project.baseLocalization];
            NSString *origTranslatedText = [te textForLocale:lang];
            if (origTranslatedText == nil)
                origTranslatedText = [te textForLocale:f.baseLocalization];
            NSString *translatedText = [NSString stringFromJSON:[el stringForXPath:@"./translationText" error:nil]];
            if (![origTranslatedText isEqualToString:translatedText]) {
                [te setText:translatedText forLocale:lang];
                [te setFlags:kTETranslated forLocale:lang];
                modified = YES;
            }
        }
    }
    
    if (modified)
        [self updateChangeCount:NSChangeDone];

}

- (void)backgroundImportXML:(id)obj
{
    NSURL *url = obj;
    
    NSXMLDocument *xmlDoc = nil;
    NSError *err = nil;
    
    xmlDoc = [[NSXMLDocument alloc] initWithContentsOfURL:url
                                                   options:(NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA)
                                                     error:&err];
    if (xmlDoc != nil) {
        NSArray *nodes = [xmlDoc nodesForXPath:@"./localizations/localization"
                                          error:nil];
        for(NSXMLNode *localizationNode in nodes) {
            NSXMLElement *localizationElement = (NSXMLElement *)(localizationNode);
            NSString *lang = [[localizationElement attributeForName:@"lang"] stringValue];
            NSString *path = [[localizationElement attributeForName:@"path"] stringValue];
            
            // Find localization file
            BOOL found = NO;
            for (VariantFile *f in self.project.variantFiles) {
                NSString *testPath = [f localizationPath:lang];
                if ([testPath isEqualToString: path]) {
                    found = YES;
                    [self importXML:localizationElement forLanguage:lang toFile:f];
                }
            }
            
            if (!found) {
                NSString *msg = [NSString stringWithFormat:kCantFindFile, path];
                [self performSelectorOnMainThread:@selector(backgroundImportInvalidEntry:) withObject:msg waitUntilDone:YES];
            }
        }
    }
    else {
        
    }
    
    [self performSelectorOnMainThread:@selector(backgroundImportXMLFinished:) withObject:err waitUntilDone:NO];
}

- (void)backgroundImportInvalidEntry:(id)obj
{
    NSString *msg = obj;
    if (msg != nil) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = kInvalidLocalizationEntry;
        alert.informativeText = msg;
        alert.alertStyle = NSCriticalAlertStyle;
        [alert runModal]; // Ignore return value.
    }
}

- (void)backgroundImportXMLFinished:(id)obj
{
    NSError *err = obj;
    [progressIndicator stopAnimation:self];
    [tuController syncAll];
    if (err != nil) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = kFailedParse;
        alert.informativeText = [err localizedDescription];
        alert.alertStyle = NSCriticalAlertStyle;
        [alert runModal]; // Ignore return value.
    }
}

- (IBAction)exportUnit:(id)sender
{
    
    if (![self checkXcode])
        return;

    if ([tuController.currentLocale isEqualToString:tuController.file.baseLocalization]) {
        [self showMessage:kCantExportBaseLocalization];
        return;
    }
    [progressIndicator startAnimation:self];
    [NSThread detachNewThreadSelector:@selector(backgroundExportUnit:) toTarget:self withObject:nil];
}

- (IBAction)exportLocalization:(id)sender
{
    if (![self checkXcode])
        return;
    
    if ([tuController.currentLocale isEqualToString:tuController.file.baseLocalization]) {
        [self showMessage:kCantExportBaseLocalization];
        return;
    }
    
    [progressIndicator startAnimation:self];
    [NSThread detachNewThreadSelector:@selector(backgroundExportLocalization:) toTarget:self withObject:nil];
}

- (IBAction)exportProject:(id)sender
{
    if (![self checkXcode])
        return;
    
    [progressIndicator startAnimation:self];
    [NSThread detachNewThreadSelector:@selector(backgroundExportProject:) toTarget:self withObject:nil];
}

- (void)backgroundExportUnit:(id)obj {
    self.xcodeExportAlert = nil;
    [self exportUnit:tuController.file forLocalization:tuController.currentLocale inBundle:self.project.bundle];
    [self performSelectorOnMainThread:@selector(exportFinished:) withObject:nil waitUntilDone:NO];
}

- (void)backgroundExportLocalization:(id)obj {
    self.xcodeExportAlert = nil;

    for (VariantFile *f in self.project.variantFiles) {
        [self exportUnit:f forLocalization:tuController.currentLocale inBundle:self.project.bundle];
        if (self.xcodeExportAlert != nil)
            break;

    }
    [self performSelectorOnMainThread:@selector(exportFinished:) withObject:nil waitUntilDone:NO];
}

- (void)backgroundExportProject:(id)obj {
    self.xcodeExportAlert = nil;
    
    for (VariantFile *f in self.project.variantFiles) {
        for (NSString *lang in self.project.knownRegions) {
            [self exportUnit:f forLocalization:lang inBundle:self.project.bundle];
            if (self.xcodeExportAlert != nil)
                break;
        }
        
        if (self.xcodeExportAlert != nil)
            break;
    }
    [self performSelectorOnMainThread:@selector(exportFinished:) withObject:nil waitUntilDone:NO];
}

- (void) alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    
}

- (void)exportFinished:(id)obj {
    [progressIndicator stopAnimation:self];
    if (self.xcodeExportAlert != nil) {
        [self showMessage:kExportFailed];
        [self.xcodeExportAlert beginSheetModalForWindow:documentWindow modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
    } else
        [self showMessage:kExportSucceded];
}

- (void)showMessage:(NSString*)msg {
    NSRect windowRect = [documentWindow frame];
    CGFloat centerX = windowRect.origin.x + windowRect.size.width / 2;
    CGFloat centerY = windowRect.origin.y + windowRect.size.height / 2;

    CGFloat xPos = centerX - NSWidth([hudPanel frame])/2;
    CGFloat yPos = centerY - NSHeight([hudPanel frame])/2;
    [hudPanel setFrame:NSMakeRect(xPos, yPos, NSWidth([hudPanel frame]), NSHeight([hudPanel frame])) display:YES];
    [hudPanel setAlphaValue:1.0f];
    msgLabel.stringValue = msg;
    [hudPanel makeKeyAndOrderFront:documentWindow];

    [NSTimer scheduledTimerWithTimeInterval:2.0
                                     target:self
                                   selector:@selector(hideHUD:)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)hideHUD:(id)foo {
    [hudPanel fadeOut:self];
}

- (void) reloadInfo
{
    
    for (NSWindowController *c in [self windowControllers]) {
        [c synchronizeWindowTitleWithDocumentName];
    }
}

- (void)teModified
{

    [self updateChangeCount:NSChangeDone];
}

- (BOOL)checkXcode
{
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:@"/usr/bin/xcrun"]) {
        NSAlert *a = [[NSAlert alloc] init];
        
        [a setAlertStyle:NSCriticalAlertStyle];
        [a setMessageText:kNoXcrun];
        [a setInformativeText:kXcodeRequired];
        [a runModal];
        return NO;
    }
    
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/xcrun"];
    
    NSArray *arguments;
    NSPipe *stdOut = [NSPipe pipe];
    arguments = [NSArray arrayWithObjects: @"-f", @"ibtool", nil];
    [task setArguments:arguments];
    [task setStandardOutput:stdOut];
    [task launch];
    [task waitUntilExit];
    int status = [task terminationStatus];
    
    if (status != 0) {
        NSAlert *a = [[NSAlert alloc] init];
        
        [a setAlertStyle:NSCriticalAlertStyle];
        [a setMessageText:kNoIbtool];
        [a setInformativeText:kIbtoolRequired];
        [a runModal];
        return NO;
    }
    
    return YES;
}

- (IBAction)saveUntranslatedFormatChanged:(id)sender
{
    exportFormat = [exportFormatButton indexOfSelectedItem];
    NSString *filename = savePanel.nameFieldStringValue;
    
    NSString *newFilename = filename;
    if (exportFormat == kFormatText)
        newFilename = [[filename stringByDeletingPathExtension] stringByAppendingPathExtension:@"txt"];
    else if (exportFormat == kFormatXML)
        newFilename = [[filename stringByDeletingPathExtension] stringByAppendingPathExtension:@"xml"];
    savePanel.nameFieldStringValue = newFilename;
}


- (void)exportUnit:(VariantFile*)file forLocalization:(NSString*)locale inBundle:(NSURL*)bundleURL;
{
    if ([file localizationPath:locale] == nil)
        return;
    
    NSURL *fileURL = [NSURL URLWithString:[file localizationPath:locale] relativeToURL:[bundleURL URLByDeletingLastPathComponent]];
    
    NSURL *baseURL = [NSURL URLWithString:[file localizationPath:file.baseLocalization] relativeToURL:[bundleURL URLByDeletingLastPathComponent]];
    
    self.xcodeExportAlert = nil;
    
    NSMutableString *strings = [[NSMutableString alloc] init];
    for (NSString *key in file.keys) {
        TranslationEntry *te = [file translationEntryForKey:key];
        NSString *s = [te textForLocale:locale];
        if (s != nil) {
            [strings appendFormat:@"\"%@\" = \"%@\";\n\n",
             [key stringByEscapingMetacharacters],
             [s stringByEscapingMetacharacters]];
            
        }
    }
    
    int fileType = kStringsFile;
    NSString *ext = [[fileURL path] pathExtension];
    if (ext != nil) {
        if ([ext caseInsensitiveCompare:@"xib"] == NSOrderedSame)
            fileType = kXibFile;
        if ([ext caseInsensitiveCompare:@"strings"] == NSOrderedSame)
            fileType = kStringsFile;
        if ([ext caseInsensitiveCompare:@"storyboard"] == NSOrderedSame)
            fileType = kStoryboardFile;
    }
    
    if (fileType == kStringsFile) {
        NSData *data;
        if ([strings length])
            data = [strings dataUsingEncoding:NSUnicodeStringEncoding];
        else
            data = [NSData data];
        NSError *err;
        if (![data writeToFile:[fileURL path] options:NSDataWritingAtomic error:&err]) {
            self.xcodeExportAlert = [NSAlert alertWithError:err];
        }
    }
    else if ((fileType == kXibFile) || (fileType == kStoryboardFile)){
        NSError *err;
        NSString *tmpPath = [[NSTemporaryDirectory() stringByAppendingPathComponent:[fileURL lastPathComponent]] stringByAppendingPathExtension:@"strings"];
        
        NSData *data = [strings dataUsingEncoding:NSUnicodeStringEncoding];
        [data writeToFile:tmpPath atomically:YES];
        
        
        NSTask *task;
        task = [[NSTask alloc] init];
        [task setLaunchPath:@"/usr/bin/xcrun"];
        
        NSArray *arguments;
        NSPipe *stdOut = [NSPipe pipe];
        arguments = [NSArray arrayWithObjects: @"ibtool", @"--strings-file", tmpPath, @"--write", [fileURL path], [baseURL path], nil];
        [task setArguments:arguments];
        [task setStandardOutput:stdOut];
        [task launch];
        [task waitUntilExit];
        
        [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:&err];
        int status = [task terminationStatus];
        if (status != 0) {
            NSFileHandle * read = [stdOut fileHandleForReading];
            NSData * dataRead = [read readDataToEndOfFile];
            NSString *errorStr;
            NSPropertyListFormat format;
            NSDictionary* plist = [NSPropertyListSerialization propertyListFromData:dataRead mutabilityOption:NSPropertyListImmutable format:&format errorDescription:&errorStr];
            NSArray *errors = [plist objectForKey:@"com.apple.ibtool.errors"];
            for (NSDictionary *error in errors) {
                NSString *description = [error objectForKey:@"description"];
                NSString *suggestion = [error objectForKey:@"recovery-suggestion"];
                self.xcodeExportAlert = [[NSAlert alloc] init];
                [self.xcodeExportAlert setMessageText:description];
                if (suggestion != nil)
                    [self.xcodeExportAlert setInformativeText:suggestion];
                [self.xcodeExportAlert setAlertStyle:NSCriticalAlertStyle];
            }
        }
    }
}


@end
