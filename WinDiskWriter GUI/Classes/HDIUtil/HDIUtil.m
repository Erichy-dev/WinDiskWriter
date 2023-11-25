//
//  HDIUtil.m
//  windiskwriter
//
//  Created by Macintosh on 26.01.2023.
//  Copyright © 2023 TechUnRestricted. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CommandLine.h"
#import "Constants.h"
#import "HDIUtil.h"
#import "NSString+Common.h"

@implementation HDIUtil {
    NSString *mountPoint;
    NSString *BSDEntry;
    NSString *volumeKind;
}

- (BOOL)attachImageWithArguments: (NSArray * _Nullable)arguments
                           error: (NSError *_Nullable *_Nullable)error {
    NSMutableArray *localArgumentsArray = [NSMutableArray arrayWithArray: @[
        @"attach",
        self.imagePath,
        @"-plist"]
    ];
    
    if (arguments != NULL) {
        /* Adding custom arguments to the HDIUtil attach command */
        [localArgumentsArray addObjectsFromArray:arguments];
    }
    
    CommandLineData *commandLineData = [CommandLine execute: self.hdiutilPath
                                                  arguments: localArgumentsArray];
        
    if (commandLineData.terminationStatus != EXIT_SUCCESS) {
        NSString *errorString = [[NSString alloc] initWithData: commandLineData.errorData
                                                      encoding: NSUTF8StringEncoding].strip;
        
        NSString *finalErrorDescription = [NSString stringWithFormat:@"The exit status of hdiutil was not EXIT_SUCCESS.\n[%@]", errorString];
      
        if (error) {
            *error = [NSError errorWithDomain: PACKAGE_NAME
                                         code: -1
                                     userInfo: @{NSLocalizedDescriptionKey:
                                                     finalErrorDescription}];
        }
        
        return NO;
    }
    
    NSString *plistLoadErrorDescription;
    NSDictionary *plist = [NSPropertyListSerialization
                           propertyListFromData: commandLineData.standardData
                           mutabilityOption: NSPropertyListImmutable
                           format: NULL
                           errorDescription: &plistLoadErrorDescription];
    
    if (plist == NULL) {
        if (error) {
            *error = [NSError errorWithDomain: PACKAGE_NAME
                                         code: -1
                                     userInfo: @{NSLocalizedDescriptionKey:
                                                     @"An error occurred while reading output from hdiutil."}];
        }
        
        return NO;
    }
    
    /* Output from hdiutil was successfully parsed into NSDictionary */
    
    NSArray *systemEntities = [plist objectForKey:@"system-entities"];
    if (systemEntities == NULL) {
        if (error) {
            *error = [NSError errorWithDomain: PACKAGE_NAME
                                         code: -1
                                     userInfo: @{NSLocalizedDescriptionKey:
                                                     @"Can't load \"system-entities\" from parsed plist."}];
        }
        return NO;
    }
    
    if ([systemEntities count] == 0) {
        if (error) {
            *error = [NSError errorWithDomain: PACKAGE_NAME
                                         code: -1
                                     userInfo: @{NSLocalizedDescriptionKey:
                                                     @"This image does not contain any System Entity."}];
        }
        return NO;
    }
    
    if ([systemEntities count] > 1) {
        if (error) {
            *error = [NSError errorWithDomain: PACKAGE_NAME
                                         code: -1
                                     userInfo: @{NSLocalizedDescriptionKey:
                                                     @"The number of System Entities in this image is >1. The required Entity could not be determined. Try to specify the path to an already mounted image."}];
        }
        return NO;
    }
    
    NSDictionary *firstSystemEntity = [systemEntities firstObject];
    
    BSDEntry = [firstSystemEntity objectForKey:@"dev-entry"];
    mountPoint = [firstSystemEntity objectForKey:@"mount-point"];
    volumeKind = [firstSystemEntity objectForKey:@"volume-kind"];
    
    return YES;
}

- (BOOL)attachImageWithError: (NSError *_Nullable *_Nullable)attachImageError {
    NSError *attachWithArgumentsError = NULL;
    
    [self attachImageWithArguments:NULL
                             error: &attachWithArgumentsError];
    
    if (attachImageError != NULL) {
        *attachImageError = attachWithArgumentsError;
    }
    
    return YES;
}

- (void)initDefaultProperties {
    _hdiutilPath = @"/usr/bin/hdiutil";
}

- (instancetype)initWithImagePath: (NSString *)imagePath {
    self = [super init];
    
    [self initDefaultProperties];
    
    _imagePath = imagePath;
    
    return self;
}

- (NSString *)BSDEntry {
    return BSDEntry;
}

- (NSString *)mountPoint {
    return mountPoint;
}

- (NSString *)volumeKind {
    return volumeKind;
}

@end

