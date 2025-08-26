//===---*- Greatdori! -*---------------------------------------------------===//
//
// GitUtils.m
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

#import <git2.h>
#import "GitUtils.h"

void nsErrorForGit(int code, NSError** outError) {
    NSError* resultError = [NSError errorWithDomain:GitErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithCString:giterr_last()->message encoding:NSASCIIStringEncoding]}];
    *outError = resultError;
    giterr_clear();
}

const char* refspecOfBranch(NSString* branch) {
    return [[[[@"refs/heads/" stringByAppendingString:branch] stringByAppendingString:@":refs/remotes/origin/"] stringByAppendingString:branch] UTF8String];
}

NSString* branchNameFromLocaleType(NSString* locale, NSString* type) {
    if ([type isEqualToString:@"main"]) {
        return @"main";
    } else {
        return [[locale stringByAppendingString:@"/"] stringByAppendingString:type];
    }
}
