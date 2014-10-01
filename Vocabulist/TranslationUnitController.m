//
//  TranslationUnitController.m
//  Vocabulist
//
//  Created by Oleksandr Tymoshenko on 2013-05-16.
//  Copyright (c) 2013 Bluezbox Software. All rights reserved.
//

#import "TranslationUnitController.h"
#import "TECellView.h"

#import <Foundation/Foundation.h>


@implementation TranslationUnitController


- (id)init {
    self = [super init];
    if (self) {
        self.arrangedObjects = [NSMutableArray array];
        self.showBaseStrings = YES;
    }
    
    return self;
}


- (void)awakeFromNib
{
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (self.file == nil)
        return 0;
    
    
    return [self.arrangedObjects count];
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
    
    // Retrieve to get the @"MyView" from the pool
    // If no version is available in the pool, load the Interface Builder version
    NSTableCellView *result = [tableView makeViewWithIdentifier:@"StringCell" owner:self];
    TECellView *cell = (TECellView*)result;

    // or as a new cell, so set the stringValue of the cell to the
    // nameArray value at row
    NSString *key = [self.arrangedObjects objectAtIndex:row];
//    cell.keyText.stringValue = [key stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    TranslationEntry *te = [self.file translationEntryForKey:key];
    if (te != nil) {
        if (self.showBaseStrings) {
            cell.baseText.stringValue = [[te textForLocale:self.file.baseLocalization] stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        }
        else {
            NSString *text = [te textForLocale:self.currentLocale];
            
            if (text == nil)
                text = [te textForLocale:self.file.baseLocalization];
            if (text == nil)
                text = @"";
            cell.baseText.stringValue = [text stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        }
    }
    else
        cell.baseText.stringValue = @"";
    
    [self updateCell:cell flags:[te flags:self.currentLocale]];

    // return the result.
    return result;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    if (self.file != nil) {
        NSInteger idx = [translationsView selectedRow];
        if (idx != -1) {
            self.file.selectedKey = [self.arrangedObjects objectAtIndex:idx];
        }
        else
            self.file.selectedKey = nil;
        [self syncTranslation];
    }
}

- (void)setUnit:(VariantFile*)f
{
    self.file = f;

    if (f != nil) {
        [self applyFilter];
        [translationsView reloadData];
        if ([f.translationEntries count]) {
            NSInteger idx = [self.arrangedObjects indexOfObject:f.selectedKey];

            if (idx != NSNotFound) {
                NSIndexSet *set = [[NSIndexSet alloc] initWithIndex:idx];
                [translationsView selectRowIndexes:set byExtendingSelection:NO];
            }
            else {
                [translationsView deselectAll:self];
            }
        }
    }
}

- (void)setLocale:(NSString*)lang
{
    self.currentLocale = lang;

    if (self.file != nil) {
        [self applyFilter];
        [translationsView reloadData];
        if ([self.file.translationEntries count]) {
            NSInteger idx = [self.arrangedObjects indexOfObject:self.file.selectedKey];
            if (idx != NSNotFound) {
                NSIndexSet *set = [[NSIndexSet alloc] initWithIndex:idx];
                [translationsView selectRowIndexes:set byExtendingSelection:NO];
            }
            else {
                [translationsView deselectAll:self];
            }
        }
        if ([lang isEqualToString:self.file.baseLocalization]) {
            [translationTextField setEnabled:NO];
        }
        else
            [translationTextField setEnabled:YES];
    }
}


- (void)syncTranslation
{
    if (self.file != nil) {
        [flagsControl setSelected:NO forSegment:0];
        [flagsControl setSelected:NO forSegment:1];
        
        NSInteger idx = [self.arrangedObjects indexOfObject:self.file.selectedKey];
        
        if (idx == NSNotFound)
        {
            [keyTextField setStringValue:@""];
            [baseTextField setStringValue:@""];
            [translationTextField setStringValue:@""];
            
            [baseTextField setEnabled:NO];
            [translationTextField setEnabled:NO];
            [flagsControl setEnabled:NO];
            return;
        }
        
        [baseTextField setEnabled:YES];
        [translationTextField setEnabled:YES];
        [flagsControl setEnabled:YES];

        
        NSString *key = self.file.selectedKey;
        TranslationEntry *te = [self.file translationEntryForKey:key];
        if (te != nil) {
            [keyTextField setStringValue:key];
            
            NSString *baseText = [te textForLocale:self.file.baseLocalization];
            [baseTextField setStringValue:baseText];
            NSString *translation = [te textForLocale:self.currentLocale];
            if (translation != nil)
                [translationTextField setStringValue:translation];
            else
                [translationTextField setStringValue:baseText];
            
            int flags = [te flags:self.currentLocale];

            if (flags == kTETranslated)
                [flagsControl setSelected:YES forSegment:1];
            else if (flags == kTEIgnore)
                [flagsControl setSelected:YES forSegment:0];

        }
        
        NSIndexSet *rows = [[NSIndexSet alloc] initWithIndex:idx];
        NSIndexSet *cols = [[NSIndexSet alloc] initWithIndex:0];
        
        [translationsView reloadDataForRowIndexes:rows columnIndexes:cols];
    }
}

- (void)setCurrentTranslationText:(NSString*)text {
    if (self.file != nil) {
        NSInteger idx = [self.file.keys indexOfObject:self.file.selectedKey];
        
        if (idx == NSNotFound) {
            NSLog(@"Key not found: %@", self.file.selectedKey);
            return;
        }
        
        if (idx >= [self.file.keys count]) {
            NSLog(@"Index out of bounds: %ld (max %ld)", idx, [self.file.keys count] - 1);
            return;
        }
        
        if (self.currentLocale) {
            NSString *key = self.file.selectedKey;
            TranslationEntry *te = [self.file translationEntryForKey:key];
            NSString *currentText = [te textForLocale:self.currentLocale];
            if (te != nil) {
                if (![currentText isEqualToString:text]) {
                    [te setText:text forLocale:self.currentLocale];
                    if ([te flags:self.currentLocale] == kTENew)
                        [te setFlags:kTETranslated forLocale:self.currentLocale];
                    [delegate teModified];
                    idx = [self.arrangedObjects indexOfObject:self.file.selectedKey];
                    NSIndexSet *rows = [[NSIndexSet alloc] initWithIndex:idx];
                    NSIndexSet *cols = [[NSIndexSet alloc] initWithIndex:0];
                    
                    [translationsView reloadDataForRowIndexes:rows columnIndexes:cols];
                }
            }
        }
        else
            NSLog(@"Current locale is nil");
    }
}

- (IBAction)chnageFlags:(id)sender
{
    NSInteger selectedSegment = [flagsControl selectedSegment];
    NSInteger idx = [self.arrangedObjects indexOfObject:self.file.selectedKey];
    
    if (idx == NSNotFound)
    {
        NSLog(@"changeFlags: invalid state");
        return;
    }

    NSString *key = self.file.selectedKey;
    TranslationEntry *te = [self.file translationEntryForKey:key];
    
    if (te != nil) {
        int flags = [te flags:self.currentLocale];

        if (selectedSegment == 0) {
            if (flags == kTEIgnore) {
                [flagsControl setSelected:NO forSegment:0];
                [flagsControl setSelected:NO forSegment:1];
                [te setFlags:kTENew forLocale:self.currentLocale];
            } else
                [te setFlags:kTEIgnore forLocale:self.currentLocale];

        }
        else if (selectedSegment == 1) {
            if (flags == kTETranslated) {
                [flagsControl setSelected:NO forSegment:0];
                [flagsControl setSelected:NO forSegment:1];
                [te setFlags:kTENew forLocale:self.currentLocale];
            } else
                [te setFlags:kTETranslated forLocale:self.currentLocale];
        }
        
        [delegate teModified];
        
        NSIndexSet *rows = [[NSIndexSet alloc] initWithIndex:idx];
        NSIndexSet *cols = [[NSIndexSet alloc] initWithIndex:0];

        [translationsView reloadDataForRowIndexes:rows columnIndexes:cols];
    }    
}

- (void)nextString
{
    if (self.file != nil) {
        NSInteger idx = [translationsView selectedRow];
        NSInteger total = [self.arrangedObjects count];
        if (total) {
            if (idx + 1 >= total)
                idx = 0;
            else
                idx++;
            NSIndexSet *set = [[NSIndexSet alloc] initWithIndex:idx];
            [translationsView selectRowIndexes:set byExtendingSelection:NO];
            [translationsView scrollRowToVisible:idx];
        }
    }
}

- (void)prevString
{
    if (self.file != nil) {
        NSInteger idx = [translationsView selectedRow];
        NSInteger total = [self.arrangedObjects count];
        if (total) {
            if (idx == 0)
                idx = total - 1;
            else
                idx--;
            NSIndexSet *set = [[NSIndexSet alloc] initWithIndex:idx];
            [translationsView selectRowIndexes:set byExtendingSelection:NO];
            [translationsView scrollRowToVisible:idx];
        }
    }
}

- (void)markAsNew
{
    NSString *key = self.file.selectedKey;
    TranslationEntry *te = [self.file translationEntryForKey:key];
    if (te != nil)
        [te setFlags:kTENew forLocale:self.currentLocale];
    [self syncTranslation];
}

- (void)markAsTranslated
{
    NSString *key = self.file.selectedKey;
    TranslationEntry *te = [self.file translationEntryForKey:key];
    if (te != nil)
        [te setFlags:kTETranslated forLocale:self.currentLocale];
    [self syncTranslation];

}

- (void)markAsIgnored
{
    NSString *key = self.file.selectedKey;
    TranslationEntry *te = [self.file translationEntryForKey:key];
    if (te != nil)
        [te setFlags:kTEIgnore forLocale:self.currentLocale];
    [self syncTranslation];
}


- (void)controlTextDidEndEditing:(NSNotification *)notification {
    NSTextField *textField = [notification object];
    [self setCurrentTranslationText:[textField stringValue]];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{

    [coder encodeInteger:[translationsView selectedRow] forKey:@"selectedTE"];
}

- (void)restoreStateWithCoder:(NSCoder *)coder
{
    NSInteger idx = [coder decodeIntegerForKey:@"selectedTE"];
    if ((self.file != nil) && (idx >= 0)) {
        NSIndexSet *set = [[NSIndexSet alloc] initWithIndex:idx];
        [translationsView selectRowIndexes:set byExtendingSelection:NO];
    }
}

- (void)resetTextSelection:(NSWindow*)window
{
    NSText* fieldEditor = [window fieldEditor:YES forObject:translationTextField];
    NSRange noSelection;
    noSelection.location = 0;
    noSelection.length = 0;
    [fieldEditor setSelectedRange:noSelection];
}


- (void)updateCell:(id)c flags:(NSInteger)flags
{
    TECellView *cell = (TECellView*)c;
    
    if (flags == kTEIgnore) {
        [cell.baseText setTextColor:[NSColor textColor]];
        
        NSMutableAttributedString *as = [cell.baseText.attributedStringValue mutableCopy];
        
        [as addAttribute:NSStrikethroughStyleAttributeName value:(NSNumber *)kCFBooleanTrue range:NSMakeRange(0, [as length])];
        cell.baseText.attributedStringValue = as;
        
    }
    else if (flags == kTENew) {
        [cell.baseText setTextColor:[NSColor redColor]];
    }
    else
    {
        [cell.baseText setTextColor:[NSColor textColor]];
    }
}

- (void)setTextFilter:(NSString*)string
{
    if ([string length] == 0)
        self.filter = nil;
    else
        self.filter = [string lowercaseString];
    [self applyFilter];
}

- (void)applyFilter
{
    [self.arrangedObjects removeAllObjects];

    if (self.file) {
        if (!self.showOnlyUntranslated && (self.filter == nil)) {
            [self.arrangedObjects addObjectsFromArray:self.file.keys];
        }
        else {
        
            for (NSString *k in self.file.keys) {
                TranslationEntry *te = [self.file translationEntryForKey:k];
                if (te) {
                    NSInteger flags = [te flags:self.currentLocale];
                    if (self.showOnlyUntranslated && (flags != kTENew))
                        continue;
                    
                    if (self.filter != nil) {
                        NSString *baseText = [[te textForLocale:self.file.baseLocalization] lowercaseString];
                        NSRange range = [baseText rangeOfString:self.filter];
                        if (range.location == NSNotFound) {
                            NSString *localizedText = [[te textForLocale:self.currentLocale] lowercaseString];
                            if (localizedText != nil)
                                range = [localizedText rangeOfString:self.filter];
                        }
                        if (range.location == NSNotFound)
                            continue;
                    }
                    
                    [self.arrangedObjects addObject:k];
                }
            }
        }
    }
    
    [translationsView reloadData];
    
    if ([self.arrangedObjects count] > 0) {

        NSInteger idx = [self.arrangedObjects indexOfObject:self.file.selectedKey];
        if (idx != NSNotFound) {
            NSIndexSet *set = [[NSIndexSet alloc] initWithIndex:idx];
            [translationsView selectRowIndexes:set byExtendingSelection:NO];
        }
        else {
            [translationsView deselectAll:self];
        }
    }
    
    [self syncTranslation];
}

- (void)setUntranslatedFilter:(BOOL)b
{
    if (self.showOnlyUntranslated != b) {
        self.showOnlyUntranslated = b;
        [self applyFilter];
    }
}

- (void)toggleStringsText
{
    self.showBaseStrings = !self.showBaseStrings;
    [translationsView reloadData];
}


- (void)syncAll
{
    [translationsView reloadData];
    [self syncTranslation];
}

@end
