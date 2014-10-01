//
//  XCodeProject.h
//  Vocabulist
//
//  Created by Oleksandr Tymoshenko on 2013-05-09.
//  Copyright (c) 2013 Bluezbox Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XCodeProject : NSObject {
    // these are valid only for conversion 
    NSDictionary *projDict;
    NSDictionary *objects;
    NSDictionary *rootObj;
}

@property (strong) NSString *name;
@property (strong) NSString *baseLocalization;
@property (strong) NSURL *bundle;
@property (strong) NSMutableArray *variantFiles;
@property (strong) NSMutableArray *knownRegions;


- (id)initWithURL:(NSURL*)url;
- (BOOL)loadLocalizedFiles:(NSAlert**)importAlert;
- (NSDictionary*)objectForId:(NSString*)objId;
- (NSArray*)localizedObjectIds;
- (NSString*)pathToObject:(NSString*)objId;
- (NSString*)normalizeLocale:(NSString*)locale;
- (void)initFlags;

- (BOOL)hasLocalizableStrings;
- (BOOL)generateLocalizableStrings:(NSAlert**)importAlert;


@end
