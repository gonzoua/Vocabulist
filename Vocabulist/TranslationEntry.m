//
//  TranslationEntry.m
//  Vocabulist
//
//  Created by Oleksandr Tymoshenko on 2013-05-07.
//  Copyright (c) 2013 Bluezbox Software. All rights reserved.
//

#import "TranslationEntry.h"

@implementation TranslationEntry

- (id)init
{
    self = [super init];
    if (self) {
        self.translations = [[NSMutableDictionary alloc] init];
        self.flags = [[NSMutableDictionary alloc] init];

    }
    
    return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
    [coder encodeObject:self.translations forKey:@"translations"];
    [coder encodeObject:self.flags forKey:@"flags"];
    [coder encodeObject:self.key forKey:@"key"];
}

- (id) initWithCoder: (NSCoder *)coder
{
    if (self = [super init])
    {
        self.translations = [coder decodeObjectForKey:@"translations"];
        self.flags = [coder decodeObjectForKey:@"flags"];
        self.key = [coder decodeObjectForKey:@"key"];

    }
    return self;
}

- (void)setText:(NSString*)text forLocale:(NSString*)locale
{
    [self.translations setObject:text forKey:locale];
}

- (NSString*)textForLocale:(NSString*)locale
{
    return  ([self.translations objectForKey:locale]);
}

- (void)setFlags:(int)flags forLocale:(NSString*)locale
{
    NSNumber *n = [NSNumber numberWithInt:flags];
    [self.flags setObject:n forKey:locale];
}

- (int)flags:(NSString*)locale
{
    NSNumber *n = [self.flags objectForKey:locale];
    
    if (n == nil)
        return kTENew;
    
    return [n intValue];
}

@end
