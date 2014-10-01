//
//  VariantFile.h
//  Vocabulist
//
//  Created by Oleksandr Tymoshenko on 2013-05-09.
//  Copyright (c) 2013 Bluezbox Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TranslationEntry.h"

#define kUnknownFile        0
#define kStringsFile        1
#define kXibFile            2
#define kStoryboardFile     3


@interface VariantFile : NSObject {
}

@property (strong) NSString *name;
@property (strong) NSString *baseLocalization;
@property (strong) NSMutableDictionary *localizations;
@property (strong) NSMutableDictionary *translationEntries;
@property (strong) NSMutableArray *keys;
@property (assign) int fileType;
@property (weak) NSString* selectedKey;

- (void)addLocalization:(NSString*)name atPath:(NSString*)path;
- (NSString*)localizationPath:(NSString*)path;
- (void)addTranslationEntry:(TranslationEntry*)entry;
- (TranslationEntry*)translationEntryForKey:(NSString*)key;
- (void)sortKeys;
- (void)initFlags;

@end
