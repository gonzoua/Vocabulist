//
//  XCodeProject.m
//  Vocabulist
//
//  Created by Oleksandr Tymoshenko on 2013-05-09.
//  Copyright (c) 2013 Bluezbox Software. All rights reserved.
//

#import "XCodeProject.h"
#import "VariantFile.h"
#include <sys/sysctl.h>

#define kImportFailed NSLocalizedString(@"Import failed", nil)
#define kGenstringsFailed NSLocalizedString(@"Running genstrings(1) failed", nil)


@implementation XCodeProject

- (id)initWithURL:(NSURL *)url
{
    self = [super init];
    if (self) {
        self.variantFiles = [[NSMutableArray alloc] init];
        self.name = [[url lastPathComponent] stringByDeletingPathExtension];
        self.bundle = url;
        
        NSURL *pbxURL = [url URLByAppendingPathComponent:@"project.pbxproj"];
        projDict = [[NSDictionary alloc] initWithContentsOfURL:pbxURL];
        if (projDict) {
            objects = [projDict objectForKey:@"objects"];
            NSString *rootObjId = [projDict objectForKey:@"rootObject"];
            rootObj = [self objectForId:rootObjId];
            self.knownRegions = [[NSMutableArray alloc] init];
            [self loadKnownRegions];
        }
    }
    
    return self;
}

- (id) initWithCoder: (NSCoder *)coder
{
    if (self = [super init])
    {
        self.name = [coder decodeObjectForKey:@"name"];
        self.baseLocalization = [coder decodeObjectForKey:@"baseLocalization"];
        self.bundle = [coder decodeObjectForKey:@"bundleURL"];
        self.knownRegions = [coder decodeObjectForKey:@"regions"];
        self.variantFiles = [coder decodeObjectForKey:@"variantFiles"];
    }
    return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.baseLocalization forKey:@"baseLocalization"];
    [coder encodeObject:self.bundle forKey:@"bundleURL"];
    [coder encodeObject:self.knownRegions forKey:@"regions"];
    [coder encodeObject:self.variantFiles forKey:@"variantFiles"];
}

- (NSString*)localeForObject:(NSDictionary*)obj
{
    NSString *path = [obj objectForKey:@"path"];
    NSArray *components = [path pathComponents];
    for (NSString *c in components) {
        if ([c hasSuffix:@".lproj"]) {
            return [c stringByDeletingPathExtension];
        }
    }
    return nil;
}

- (BOOL)generateLocalizableStrings:(NSAlert**)importAlert
{
    if (importAlert)
        *importAlert = nil;
    
    
    // find path to base Localizable.strings
    NSArray *localizedObjects = [self localizedObjectIds];
    for (NSString *objId in localizedObjects) {
        NSDictionary *obj = [self objectForId:objId];
        
        NSString *ext = [[obj objectForKey:@"name"] pathExtension];
        if (ext == nil)
            continue;
        if ([ext caseInsensitiveCompare:@"strings"] != NSOrderedSame)
            continue;
        
        NSString *name = [[obj objectForKey:@"name"] stringByDeletingPathExtension];
        if ([name caseInsensitiveCompare:@"localizable"] != NSOrderedSame)
            continue;
        
        NSArray *children = [obj objectForKey:@"children"];
        for (NSString *idString in children) {
            NSDictionary *kid = [self objectForId:idString];
            if (kid) {
                NSString *locale = [self normalizeLocale:[self localeForObject:kid]];
                if (![locale isEqualToString:self.baseLocalization])
                    continue;
                NSString *path = [self pathToObject:idString];
                NSString *bundlePath = [[self.bundle URLByDeletingLastPathComponent] path];
                
                NSArray *exts = [NSArray arrayWithObjects:@"c", @"cc", @"cpp", @"C", @"m", @"mm", nil];
                NSMutableArray *codeFiles = [NSMutableArray array];
                // get source files
                for (NSString *objId in [objects allKeys]) {
                    NSString *srcPath = [self pathToObject:objId];
                    if (srcPath == nil)
                        continue;
                    NSString *srcExt = [srcPath pathExtension];
                    if (![exts containsObject:srcExt])
                        continue;
                    [codeFiles addObject:srcPath];

                }

                
                int mib[4], maxarg = 0;
                size_t size = 0;
                
                mib[0] = CTL_KERN;
                mib[1] = KERN_ARGMAX;
                
                size = sizeof(maxarg);
                if ( sysctl(mib, 2, &maxarg, &size, NULL, 0) == -1 ) {
                    maxarg = 0;
                }
                
                if (maxarg == 0)
                    maxarg = 128*1024;
                
                maxarg -= 128;
                maxarg = 128;

                int left = maxarg;
                NSMutableArray *chunks = [NSMutableArray array];
                NSMutableArray *currentFiles = [NSMutableArray array];

                for (NSString *p in codeFiles) {
                    if (left < [p length] + 1) {
                        [chunks addObject:currentFiles];
                        currentFiles = [NSMutableArray array];
                        left = maxarg;
                    }
                    
                    [currentFiles addObject:p];
                    left -= [p length] + 1;
                }
                
                if ([currentFiles count])
                    [chunks addObject:currentFiles];
                
                BOOL firstRun = YES;
                for (NSMutableArray *files in chunks) {
                    NSTask *task;
                    task = [[NSTask alloc] init];
                    [task setLaunchPath:@"/usr/bin/xcrun"];
                    
                    NSMutableArray *arguments;
                    NSPipe *stdOut = [NSPipe pipe];
                    [task setStandardOutput:stdOut];
                    [task setStandardError:stdOut];
                    [task setCurrentDirectoryPath:bundlePath];
                    arguments = [NSMutableArray arrayWithObjects: @"genstrings", @"-o", [path stringByDeletingLastPathComponent], nil];
                    if (!firstRun)
                        [arguments addObject:@"-a"];
                    [arguments addObjectsFromArray:files];
                    [task setArguments: arguments];
                    [task launch];
                    [task waitUntilExit];
                    int status = [task terminationStatus];
                    if (status != 0) {
                        if (importAlert) {
                            NSFileHandle * read = [stdOut fileHandleForReading];
                            NSData * dataRead = [read readDataToEndOfFile];
                            NSString *errorStr =  [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
                            *importAlert = [[NSAlert alloc] init];

                            [*importAlert setMessageText:kGenstringsFailed];
                            [*importAlert setInformativeText:errorStr];
                            [*importAlert setAlertStyle:NSCriticalAlertStyle];
                        }
                        
                        return NO;
                    }
                    else {
                        // redirect output to log for further analysis if required
                        NSFileHandle * read = [stdOut fileHandleForReading];
                        NSData * dataRead = [read readDataToEndOfFile];
                        NSString *output =  [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
                        if ([output length])
                            for (NSString *s in [output componentsSeparatedByString:@"\n"])
                                NSLog(@"[genstrings] %@", s);

                    }

                    firstRun = NO;
                }
                
                return YES;
            }
        }
    }
    
    return NO;
}


- (BOOL)loadLocalizedFiles:(NSAlert**)importAlert
{
    // now import stuff from project
    if (importAlert)
        *importAlert = nil;
    NSArray *localizedObjects = [self localizedObjectIds];
    for (NSString *objId in localizedObjects) {
        NSDictionary *obj = [self objectForId:objId];
        VariantFile *f = [[VariantFile alloc] init];
        
        NSString *ext = [[obj objectForKey:@"name"] pathExtension];
        if (ext != nil) {
            if ([ext caseInsensitiveCompare:@"xib"] == NSOrderedSame)
                f.fileType = kXibFile;
            if ([ext caseInsensitiveCompare:@"strings"] == NSOrderedSame)
                f.fileType = kStringsFile;
            if ([ext caseInsensitiveCompare:@"storyboard"] == NSOrderedSame)
                f.fileType = kStoryboardFile;
        }
        
        
        if (f.fileType == kUnknownFile)
            continue;
        
        f.name = [obj objectForKey:@"name"];
        f.baseLocalization = self.baseLocalization;
        NSArray *children = [obj objectForKey:@"children"];
        NSMutableDictionary *translations = [[NSMutableDictionary alloc] init];
        NSDictionary *baseDictionary = nil;
        for (NSString *idString in children) {
            
            NSDictionary *obj = [self objectForId:idString];
            if (obj) {
                NSString *path = [self pathToObject:idString];
                
                NSString *ext = [path pathExtension];
                int fileType = kUnknownFile;
                if (ext != nil) {
                    if ([ext caseInsensitiveCompare:@"xib"] == NSOrderedSame)
                        fileType = kXibFile;
                    if ([ext caseInsensitiveCompare:@"strings"] == NSOrderedSame)
                        fileType = kStringsFile;
                    if ([ext caseInsensitiveCompare:@"storyboard"] == NSOrderedSame)
                        fileType = kStoryboardFile;
                }
                
                if (fileType == kUnknownFile)
                    continue;
                
                NSString *fullPath = [[[self.bundle URLByDeletingLastPathComponent] path] stringByAppendingPathComponent:path];
                NSString *locale = [self normalizeLocale:[self localeForObject:obj]];
                
                [f addLocalization:locale atPath:path];
                
                NSDictionary *dict;
                if (fileType == kStringsFile)
                    dict = [NSDictionary dictionaryWithContentsOfFile:fullPath];
                else {
                    NSString *tmpDir = NSTemporaryDirectory();
                    tmpDir = nil;
                    if (tmpDir == nil) {
                        NSArray *paths = NSSearchPathForDirectoriesInDomains(
                                                                             NSCachesDirectory, NSUserDomainMask, YES);
                        if ([paths count])
                        {
                            NSString *bundleName =
                            [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
                            tmpDir = [[paths objectAtIndex:0] stringByAppendingPathComponent:bundleName];
                        }
                    }
                    
                    if (![[NSFileManager defaultManager] fileExistsAtPath:tmpDir]) {
                        NSError *err;
                        [[NSFileManager defaultManager] createDirectoryAtPath:tmpDir withIntermediateDirectories:YES attributes:nil error:&err];
                    }
                    
                    NSString *tmpPath = [[tmpDir stringByAppendingPathComponent:[fullPath lastPathComponent]] stringByAppendingPathExtension:@"strings"];;
                    NSTask *task;
                    task = [[NSTask alloc] init];
                    [task setLaunchPath:@"/usr/bin/xcrun"];
                    
                    NSArray *arguments;
                    NSPipe *stdOut = [NSPipe pipe];
                    [task setStandardOutput:stdOut];
                    arguments = [NSArray arrayWithObjects: @"ibtool", @"--generate-strings-file", tmpPath, fullPath, nil];
                    [task setArguments: arguments];
                    [task launch];
                    [task waitUntilExit];
                    
                    int status = [task terminationStatus];
                    if (status != 0) {
                        if (importAlert) {
                            NSFileHandle * read = [stdOut fileHandleForReading];
                            NSData * dataRead = [read readDataToEndOfFile];
                            NSString *errorStr;
                            NSPropertyListFormat format;
                            NSDictionary* plist = [NSPropertyListSerialization propertyListFromData:dataRead mutabilityOption:NSPropertyListImmutable format:&format errorDescription:&errorStr];
                            *importAlert = [[NSAlert alloc] init];
                            NSMutableString *msg = [NSMutableString stringWithString:@""];

                            NSArray *errors = [plist objectForKey:@"com.apple.ibtool.errors"];
                            for (NSDictionary *error in errors) {
                                NSString *description = [error objectForKey:@"description"];
                                NSString *suggestion = [error objectForKey:@"recovery-suggestion"];
                                if ([msg length] > 0)
                                    [msg appendString:@"\n\n"];
                                if (description != nil)
                                    [msg appendString:description];
                                if (suggestion != nil) {
                                    [msg appendString:@"\n\n"];
                                    [msg appendString:suggestion];
                                }
                            }
                            
                            [*importAlert setMessageText:kImportFailed];
                            [*importAlert setInformativeText:[NSString stringWithString:msg]];
                            [*importAlert setAlertStyle:NSCriticalAlertStyle];
                        }
                        return NO;
                    }
                                        
                    dict = [NSDictionary dictionaryWithContentsOfFile:tmpPath];
                    [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
                    
                }
                
                if (dict != nil) {
                    if ([locale compare:f.baseLocalization] == NSOrderedSame)
                        baseDictionary = [NSDictionary dictionaryWithDictionary:dict];
                    else
                        [translations setObject:dict forKey:locale];
                }
            }
            
        }
        
        // now merge all the translations and convert them to translation
        if (baseDictionary == nil)
            NSLog(@"No base translation for %@", f.name);
        else {
            for (NSString *key in [baseDictionary allKeys]) {
                TranslationEntry *te = [[TranslationEntry alloc] init];
                te.key = key;
                [te setText:[baseDictionary objectForKey:key] forLocale:f.baseLocalization];
                for (NSString *locale in [translations allKeys]) {
                    NSDictionary *dict = [translations objectForKey:locale];
                    NSString *translated = [dict objectForKey:key];
                    if (translated != nil)
                        [te setText:translated forLocale:locale];
                }
                [f addTranslationEntry:te];
            }
        }
        [f sortKeys];
        
        [self.variantFiles addObject:f];
    }
    
    return YES;
}



- (void)loadKnownRegions
{
    // now import stuff from project
    NSArray *localizedObjects = [self localizedObjectIds];
    for (NSString *objId in localizedObjects) {
        NSDictionary *obj = [self objectForId:objId];
        
        NSArray *children = [obj objectForKey:@"children"];
        for (NSString *kidId in children) {
            NSDictionary *obj = [self objectForId:kidId];
            if (obj == nil)
                continue;
            NSString *name = [self normalizeLocale:[self localeForObject:obj]];
            if (name == nil)
                continue;
            
            BOOL found = NO;
            
            for (NSString *region in self.knownRegions) {
                if ([name caseInsensitiveCompare:region] == NSOrderedSame) {
                    found = TRUE;
                    break;
                }
            }
            
            if (!found) {
                [self.knownRegions addObject:name];
            }
        }
    }
}


- (NSDictionary*)objectForId:(NSString*)objId
{
    return [objects objectForKey:objId];
}

- (BOOL)pathToObject:(NSString *)objId inObject:(NSString*)folderId save:(NSMutableArray*)result
{
    if ([folderId caseInsensitiveCompare:objId] == NSOrderedSame) {
        [result insertObject:folderId atIndex:0];
        return YES;
    }
    
    NSDictionary *obj = [self objectForId:objId];
    if (obj == nil)
        return NO;
 
    NSDictionary *folderObj = [self objectForId:folderId];
    if (folderObj == nil)
        return NO;
    
    NSArray *children = [folderObj objectForKey:@"children"];
    for (NSString *idString in children) {
        if ([self pathToObject:objId inObject:idString save:result]) {
            [result insertObject:folderId atIndex:0];
            return YES;
        }
    }
    
    return NO;
}

- (NSString*)pathToObject:(NSString *)objId
{
    NSMutableArray *pathElements = [[NSMutableArray alloc] init];
    NSString *mainGroupId = [rootObj objectForKey:@"mainGroup"];
    NSString *path = @"";
    if ([self pathToObject:objId inObject:mainGroupId save:pathElements]) {
        for (NSString *elementId in pathElements) {
            NSDictionary *obj = [self objectForId:elementId];
            NSString *pathElement = [obj objectForKey:@"path"];
            if (pathElement != nil)
                path = [path stringByAppendingPathComponent:pathElement];
        }
    }
    
    return path;
}


- (NSArray*)localizedObjectIds {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    for (NSString *objId in [objects allKeys]) {
        NSDictionary *dict = [objects objectForKey:objId];
        if ([[dict objectForKey:@"isa"] caseInsensitiveCompare:@"PBXVariantGroup"] == NSOrderedSame)
            [result addObject:objId];
    }
    
    return result;
}


- (NSString*)normalizeLocale:(NSString*)locale
{
    if ([locale caseInsensitiveCompare:@"English"] == NSOrderedSame)
        return @"en";
    
    return locale;
}

- (void)initFlags {
    for (VariantFile *f in self.variantFiles) {
        [f initFlags];
    }
}

- (BOOL)hasLocalizableStrings
{

    for (NSString *objId in [objects allKeys]) {
        NSDictionary *obj = [objects objectForKey:objId];

        if ([[obj objectForKey:@"isa"] caseInsensitiveCompare:@"PBXVariantGroup"] == NSOrderedSame) {
            NSString *ext = [[obj objectForKey:@"name"] pathExtension];
            if (ext != nil) {
                if ([ext caseInsensitiveCompare:@"strings"] != NSOrderedSame)
                    continue;

                NSArray *children = [obj objectForKey:@"children"];
                for (NSString *idString in children) {
                    NSDictionary *child = [self objectForId:idString];
                    if (child) {
                        NSString *path = [self pathToObject:idString];
                        if ([path hasSuffix:@"Localizable.strings"])
                            return YES;
                    }
                }
            }
        }
        
    }
    
    return NO;
}



@end
