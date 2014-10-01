//
//  TranslationEntry.h
//  Vocabulist
//
//  Created by Oleksandr Tymoshenko on 2013-05-07.
//  Copyright (c) 2013 Bluezbox Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kTENew          0
#define kTEIgnore       1
#define kTETranslated   2

@interface TranslationEntry : NSObject

@property (strong) NSMutableDictionary *translations;
@property (strong) NSMutableDictionary *flags;
@property (strong) NSString* key;

- (void)setText:(NSString*)text forLocale:(NSString*)locale;
- (void)setFlags:(int)flag forLocale:(NSString*)locale;
- (NSString*)textForLocale:(NSString*)locale;
- (int)flags:(NSString*)locale;

@end
