//===---*- Greatdori! -*---------------------------------------------------===//
//
// AssetShims.h
//
// This source file is part of the Greatdori! open source project
//
// Copyright (c) 2025 the Greatdori! project authors
// Licensed under Apache License v2.0
//
// See https://greatdori.memz.top/LICENSE.txt for license information
// See https://greatdori.memz.top/CONTRIBUTORS.txt for the list of Greatdori! project authors
//
//===----------------------------------------------------------------------===//

#import <Foundation/Foundation.h>
#import "ExportedGitTypes.h"

NS_ASSUME_NONNULL_BEGIN

typedef struct AssetUpdateCheckerResult {
    bool isUpdateAvailable;
    const char* localSHA;
    const char* remoteSHA;
} AssetUpdateCheckerResult;

@interface AssetShims : NSObject

+(void)startup;
+(void)shutdown;

+(bool)downloadResourceInLocale: (NSString*) locale
                         ofType: (NSString*) type
                        payload: (void* _Nullable) payload
                          error: (NSError**) outError
               onProgressUpdate: (int (*)(const _git_indexer_progress *stats,  void * _Nullable payload))progressUpdate;

+(int)updateResourceInLocale: (NSString*) locale
                      ofType: (NSString*) type
                     payload: (void* _Nullable) payload
                       error: (NSError**) outError
            onProgressUpdate: (int (*)(const _git_indexer_progress *stats, void * _Nullable payload))progressUpdate;

+(AssetUpdateCheckerResult* _Nullable)checkForUpdateInLocale: (NSString*) locale
                                                      ofType: (NSString*) type
                                                       error: (NSError**) outError;

@end

NS_ASSUME_NONNULL_END
