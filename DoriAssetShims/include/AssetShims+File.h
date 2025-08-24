//===---*- Greatdori! -*---------------------------------------------------===//
//
// AssetShims+File.h
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

#import "AssetShims.h"

NS_ASSUME_NONNULL_BEGIN

@interface AssetShims (File)

+(bool)fileExists: (NSString*) path
         inLocale: (NSString*) locale
           ofType: (NSString*) type;

+(NSArray<NSString*>* _Nullable)contentsOfDirectoryAtPath: (NSString*) path
                                                 inLocale: (NSString*) locale
                                                   ofType: (NSString*) type
                                                    error: (NSError**) outError;

@end

NS_ASSUME_NONNULL_END
