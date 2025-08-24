//===---*- Greatdori! -*---------------------------------------------------===//
//
// AssetShims+File.m
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
#import "AssetShims+File.h"

@implementation AssetShims (File)

+(bool)fileExists: (NSString*) path
         inLocale: (NSString*) locale
           ofType: (NSString*) type {
    NSString* branch = [[locale stringByAppendingString:@"/"] stringByAppendingString:type];
    
    git_repository* repository = NULL;
    int error = git_repository_open(&repository, [[NSHomeDirectory() stringByAppendingString:@"/Documents/OfflineResource.bundle"] UTF8String]);
    if (error != 0) {
        return false;
    }
    
    git_reference* ref = NULL;
    error = git_reference_lookup(&ref, repository, [[@"refs/heads/" stringByAppendingString:branch] UTF8String]);
    if (error != 0) {
        git_repository_free(repository);
        return false;
    }
    
    const git_oid* oid = git_reference_target(ref);
    git_commit* commit = NULL;
    error = git_commit_lookup(&commit, repository, oid);
    if (error != 0) {
        git_repository_free(repository);
        return false;
    }
    
    git_tree* tree = NULL;
    error = git_commit_tree(&tree, commit);
    if (error != 0) {
        git_repository_free(repository);
        return false;
    }
    
    git_tree_entry* entry = NULL;
    if (git_tree_entry_bypath(&entry, tree, [path UTF8String]) == 0) {
        git_repository_free(repository);
        return true;
    }
    
    git_repository_free(repository);
    return false;
}

@end
