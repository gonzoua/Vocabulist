//
//  VariantFile.m
//  Vocabulist
//
//  Created by Oleksandr Tymoshenko on 2013-05-09.
//  Copyright (c) 2013 Bluezbox Software. All rights reserved.
//

#import "VariantFile.h"

@implementation VariantFile


- (id)init
{
    self = [super init];
    if (self)
    {
        self.localizations = [[NSMutableDictionary alloc] init];
        self.translationEntries = [[NSMutableDictionary alloc] init];
        self.keys = [[NSMutableArray alloc] init];
        self.fileType = kUnknownFile;
        self.selectedKey = nil;

    }
    
    return self;
}

- (id) initWithCoder: (NSCoder *)coder
{
    if (self = [super init])
    {
        self.name = [coder decodeObjectForKey:@"name"];
        self.baseLocalization = [coder decodeObjectForKey:@"baseLocalization"];
        self.localizations = [coder decodeObjectForKey:@"localizations"];
        self.translationEntries = [coder decodeObjectForKey:@"translationEntries"];
        self.keys = [coder decodeObjectForKey:@"keys"];
        self.fileType = [[coder decodeObjectForKey:@"fileType"] intValue];
        self.selectedKey = [coder decodeObjectForKey:@"selectedKey"];
    }
    return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.baseLocalization forKey:@"baseLocalization"];
    [coder encodeObject:self.localizations forKey:@"localizations"];
    [coder encodeObject:self.translationEntries forKey:@"translationEntries"];
    [coder encodeObject:self.keys forKey:@"keys"];
    [coder encodeObject:[NSNumber numberWithInt:self.fileType] forKey:@"fileType"];
    [coder encodeObject:self.selectedKey forKey:@"selectedKey"];

}

- (void)addLocalization:(NSString*)name atPath:(NSString*)path;
{
    [self.localizations setObject:path forKey:name];
}

- (NSString*)localizationPath:(NSString*)path
{
    return [self.localizations objectForKey:path];
}


- (void)addTranslationEntry:(TranslationEntry*)entry
{
    [self.translationEntries setObject:entry forKey:entry.key];
    [self.keys addObject:entry.key];
}

- (TranslationEntry*)translationEntryForKey:(NSString*)key
{
    return [self.translationEntries objectForKey:key];
}


- (void)sortKeys {
    NSArray *sorted = [self.keys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    self.keys = [NSMutableArray arrayWithArray:sorted];
}

- (void)initFlags {
    for (NSString *key in self.keys) {
        TranslationEntry *e = [self.translationEntries objectForKey:key];
        NSString *base = [e textForLocale:self.baseLocalization];
        for (NSString *l in self.localizations) {
            if ([l isEqualToString:self.baseLocalization])
                [e setFlags:kTETranslated forLocale:l];
            else {
                NSString *translation = [e textForLocale:l];
                if ((translation != nil) && (![base isEqualToString:translation]))
                    [e setFlags:kTETranslated forLocale:l];
            }
        }
    }
}

@end
