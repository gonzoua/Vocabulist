//
//  NSString+JSONEscape.h
//  Vocabulist
//
//  Created by Oleksandr Tymoshenko on 2013-09-25.
//  Copyright (c) 2013 Bluezbox Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (JSONEscape)
- (NSString *)JSONString;
+ (NSString *)stringFromJSON:(NSString*)jsonString;
- (NSString *)stringByEscapingMetacharacters;

@end
