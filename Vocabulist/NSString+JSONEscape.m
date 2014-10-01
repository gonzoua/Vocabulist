//
//  NSString+JSONEscape.m
//  Vocabulist
//
//  Created by Oleksandr Tymoshenko on 2013-09-25.
//  Copyright (c) 2013 Bluezbox Software. All rights reserved.
//

#import "NSString+JSONEscape.h"
#import <vis.h>

@implementation NSString (JSONEscape)

+ (NSString *)stringFromJSON:(NSString*)jsonString
{
    NSUInteger len = [jsonString length];

    
    NSMutableString *result = [[NSMutableString alloc] initWithCapacity:len];
    NSUInteger limit = len;
    for (NSUInteger i = 0; i < limit; ++i) {
        unichar character = [jsonString characterAtIndex:i];
        
        if (character == '\\') {
            
            // Escape sequence
            
            if (i == limit - 1) {
                NSLog(@"%s: JSON string cannot end with single backslash", __PRETTY_FUNCTION__);
                return nil;
            }
            
            ++i;
            unichar nextCharacter = [jsonString characterAtIndex:i];
            switch (nextCharacter) {
                case 'b':
                    [result appendString:@"\b"];
                    break;
                    
                case 'f':
                    [result appendString:@"\f"];
                    break;
                    
                case 'n':
                    [result appendString:@"\n"];
                    break;
                    
                case 'r':
                    [result appendString:@"\r"];
                    break;
                    
                case 't':
                    [result appendString:@"\t"];
                    break;
                    
                case 'u':
                    if ((i + 4) >= limit) {
                        NSLog(@"%s: insufficient characters remaining after \\u in JSON string", __PRETTY_FUNCTION__);
                        return nil;
                    }
                {
                    NSString *hexdigits = [jsonString substringWithRange:NSMakeRange(i + 1, 4)];
                    i += 4;
                    NSScanner *scanner = [NSScanner scannerWithString:hexdigits];
                    unsigned int hexValue = 0;
                    if (![scanner scanHexInt:&hexValue]) {
                        NSLog(@"%s: invalid hex digits following \\u", __PRETTY_FUNCTION__);
                    }
                    [result appendFormat:@"%C", (unichar)hexValue];
                }
                    break;
                    
                default:
                    [result appendFormat:@"%C", nextCharacter];
                    break;
            }
        }
        else {
            // No escape
            [result appendFormat:@"%C", character];
        }
    }
    
    // Return an immutable copy
    return [NSString stringWithString:result];
}


- (NSString *)JSONString {
    NSMutableString *s = [NSMutableString stringWithString:self];
    [s replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
    [s replaceOccurrencesOfString:@"/" withString:@"\\/" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
    [s replaceOccurrencesOfString:@"\n" withString:@"\\n" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
    [s replaceOccurrencesOfString:@"\b" withString:@"\\b" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
    [s replaceOccurrencesOfString:@"\f" withString:@"\\f" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
    [s replaceOccurrencesOfString:@"\r" withString:@"\\r" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
    [s replaceOccurrencesOfString:@"\t" withString:@"\\t" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
    return [NSString stringWithString:s];
}

- (NSString *)stringByEscapingMetacharacters
{
    const char *UTF8Input = [self UTF8String];
    char *UTF8Output = [[NSMutableData dataWithLength:strlen(UTF8Input) * 4 + 1 /* Worst case */] mutableBytes];
    char ch, *och = UTF8Output;
    
    while ((ch = *UTF8Input++))
        if (ch == '\\' || ch == '"')
        {
            *och++ = '\\';
            *och++ = ch;
        }
        else if (isascii(ch))
            och = vis(och, ch, VIS_NL | VIS_TAB | VIS_CSTYLE, *UTF8Input);
        else
            *och++ = ch;
    
    return [NSString stringWithUTF8String:UTF8Output];
}


@end
