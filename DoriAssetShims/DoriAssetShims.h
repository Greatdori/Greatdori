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

@interface AssetShims : NSObject

+(void)startup;
+(void)shutdown;

+(bool)downloadResourceInLocale: (NSString*) locale ofType: (NSString*) type onProgressUpdate: (void (^)(double, int, int))progressUpdate;

@end
