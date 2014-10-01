//
//  BaseNode.m
//  Vocabulist
//
//  Created by Oleksandr Tymoshenko on 2013-05-09.
//  Copyright (c) 2013 Bluezbox Software. All rights reserved.
//

#import "BaseNode.h"

@implementation BaseNode

- (id)init
{
	self = [super init];
    if (self)
	{
        self.nodeTitle = @"BaseNode Untitled";
        
		[self setChildren:[NSArray array]];
	}
	return self;
}

// -------------------------------------------------------------------------------
//	mutableKeys:
//
//	Override this method to maintain support for archiving and copying.
// -------------------------------------------------------------------------------
- (NSArray *)mutableKeys
{
	return [NSArray arrayWithObjects:
            @"nodeTitle",
            @"isLeaf",		// isLeaf MUST come before children for initWithDictionary: to work
            @"children",
            @"nodeIcon",
            @"urlString",
            nil];
}

// -------------------------------------------------------------------------------
//	initWithDictionary:dictionary
// -------------------------------------------------------------------------------
- (id)initWithDictionary:(NSDictionary *)dictionary
{
	self = [self init];
    if (self)
    {
        NSString *key;
        for (key in [self mutableKeys])
        {
            if ([key isEqualToString:@"children"])
            {
                if ([[dictionary objectForKey:@"isLeaf"] boolValue])
                    [self setChildren:[NSArray arrayWithObject:self]];
                else
                {
                    NSArray *dictChildren = [dictionary objectForKey:key];
                    NSMutableArray *newChildren = [NSMutableArray array];
                    
                    for (id node in dictChildren)
                    {
                        id newNode = [[[self class] alloc] initWithDictionary:node];
                        [newChildren addObject:newNode];
                    }
                    [self setChildren:newChildren];
                }
            }
            else
            {
                [self setValue:[dictionary objectForKey:key] forKey:key];
            }
        }
    }
	return self;
}

// -------------------------------------------------------------------------------
//	dictionaryRepresentation
// -------------------------------------------------------------------------------
- (NSDictionary *)dictionaryRepresentation
{
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
	for (NSString *key in [self mutableKeys])
    {
		// convert all children to dictionaries
		if ([key isEqualToString:@"children"])
		{
            NSMutableArray *dictChildren = [NSMutableArray array];
            for (id node in self.children)
            {
                [dictChildren addObject:[node dictionaryRepresentation]];
            }
				
            [dictionary setObject:dictChildren forKey:key];
		}
		else if ([self valueForKey:key])
		{
			[dictionary setObject:[self valueForKey:key] forKey:key];
		}
	}
	return dictionary;
}



// -------------------------------------------------------------------------------
//	initWithCoder:coder
// -------------------------------------------------------------------------------
- (id)initWithCoder:(NSCoder *)coder
{
	self = [self init];
	if (self)
    {
        for (NSString *key in [self mutableKeys])
            [self setValue:[coder decodeObjectForKey:key] forKey:key];
	}
	return self;
}

// -------------------------------------------------------------------------------
//	encodeWithCoder:coder
// -------------------------------------------------------------------------------
- (void)encodeWithCoder:(NSCoder *)coder
{
    for (NSString *key in [self mutableKeys])
    {
		[coder encodeObject:[self valueForKey:key] forKey:key];
    }
}

// -------------------------------------------------------------------------------
//	copyWithZone:zone
// -------------------------------------------------------------------------------
- (id)copyWithZone:(NSZone *)zone
{
	id newNode = [[[self class] allocWithZone:zone] init];
	
	for (NSString *key in [self mutableKeys])
		[newNode setValue:[self valueForKey:key] forKey:key];
	
	return newNode;
}

@end
