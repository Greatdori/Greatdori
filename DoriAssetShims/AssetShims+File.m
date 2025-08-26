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
#import "GitUtils.h"
#import "AssetShims+File.h"

@implementation AssetShims (File)

+(bool)fileExists: (NSString*) path
         inLocale: (NSString*) locale
           ofType: (NSString*) type {
    NSString* branch = branchNameFromLocaleType(locale, type);
    
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

+(NSArray<NSString*>* _Nullable)contentsOfDirectoryAtPath: (NSString*) path
                                                 inLocale: (NSString*) locale
                                                   ofType: (NSString*) type
                                                    error: (NSError**) outError {
    NSString* branch = branchNameFromLocaleType(locale, type);
    
    git_repository* repository = NULL;
    int error = git_repository_open(&repository, [[NSHomeDirectory() stringByAppendingString:@"/Documents/OfflineResource.bundle"] UTF8String]);
    if (error != 0) {
        nsErrorForGit(error, outError);
        return nil;
    }
    
    git_reference* ref = NULL;
    error = git_reference_lookup(&ref, repository, [[@"refs/heads/" stringByAppendingString:branch] UTF8String]);
    if (error != 0) {
        nsErrorForGit(error, outError);
        git_repository_free(repository);
        return nil;
    }
    
    const git_oid* oid = git_reference_target(ref);
    git_commit* commit = NULL;
    error = git_commit_lookup(&commit, repository, oid);
    if (error != 0) {
        nsErrorForGit(error, outError);
        git_repository_free(repository);
        return nil;
    }
    
    git_tree* rootTree = NULL;
    error = git_commit_tree(&rootTree, commit);
    if (error != 0) {
        nsErrorForGit(error, outError);
        git_repository_free(repository);
        return nil;
    }
    
    git_tree* tree = NULL;
    if ([path length] > 0) {
        git_tree_entry* entry = NULL;
        error = git_tree_entry_bypath(&entry, rootTree, [path UTF8String]);
        if (error != 0) {
            nsErrorForGit(error, outError);
            git_repository_free(repository);
            return nil;
        }
        
        if (git_tree_entry_type(entry) != GIT_OBJ_TREE) {
            *outError = [NSError errorWithDomain:NSPOSIXErrorDomain code:100020 userInfo:nil];
            //                                                   ENOTDIR ~~~~~~
            git_repository_free(repository);
            return nil;
        }
        
        error = git_tree_lookup(&tree, repository, git_tree_entry_id(entry));
        if (error != 0) {
            nsErrorForGit(error, outError);
            git_repository_free(repository);
            return nil;
        }
    } else {
        tree = rootTree;
    }
    
    size_t count = git_tree_entrycount(tree);
    NSMutableArray<NSString*>* result = [NSMutableArray arrayWithCapacity:count];
    for (size_t i = 0; i < count; i++) {
        const git_tree_entry* entry = git_tree_entry_byindex(tree, i);
        const char* name = git_tree_entry_name(entry);
        [result addObject:[NSString stringWithCString:name encoding:NSUTF8StringEncoding]];
    }
    git_repository_free(repository);
    return result;
}

+(NSData* _Nullable)fileDataForPath: (NSString*) path
                           inLocale: (NSString*) locale
                             ofType: (NSString*) type
                              error: (NSError**) outError {
    NSString* branch = branchNameFromLocaleType(locale, type);
    
    git_repository* repository = NULL;
    int error = git_repository_open(&repository, [[NSHomeDirectory() stringByAppendingString:@"/Documents/OfflineResource.bundle"] UTF8String]);
    if (error != 0) goto cleanup;
    
    git_reference* ref = NULL;
    error = git_reference_lookup(&ref, repository, [[@"refs/heads/" stringByAppendingString:branch] UTF8String]);
    if (error != 0) goto cleanup;
    
    const git_oid* oid = git_reference_target(ref);
    git_commit* commit = NULL;
    error = git_commit_lookup(&commit, repository, oid);
    if (error != 0) goto cleanup;
    
    git_tree* tree = NULL;
    error = git_commit_tree(&tree, commit);
    if (error != 0) goto cleanup;
    
    git_tree_entry* entry = NULL;
    error = git_tree_entry_bypath(&entry, tree, [path UTF8String]);
    if (error != 0) goto cleanup;
    
    if (git_tree_entry_type(entry) != GIT_OBJ_BLOB) {
        *outError = [NSError errorWithDomain:NSPOSIXErrorDomain code:100021 userInfo:nil];
        //                                                    EISDIR ~~~~~~
        git_repository_free(repository);
        return nil;
    }
    
    git_blob* blob = NULL;
    error = git_blob_lookup(&blob, repository, git_tree_entry_id(entry));
    if (error != 0) goto cleanup;
    
    const void* content = git_blob_rawcontent(blob);
    size_t size = git_blob_rawsize(blob);
    return [NSData dataWithBytes:content length:size];
    
cleanup:
    nsErrorForGit(error, outError);
    if (repository) git_repository_free(repository);
    return nil;
}

+(NSString* _Nullable)fileHashForPath: (NSString*) path
                             inLocale: (NSString*) locale
                               ofType: (NSString*) type
                                error: (NSError**) outError {
    NSString* branch = branchNameFromLocaleType(locale, type);
    
    git_repository* repository = NULL;
    int error = git_repository_open(&repository, [[NSHomeDirectory() stringByAppendingString:@"/Documents/OfflineResource.bundle"] UTF8String]);
    if (error != 0) goto cleanup;
    
    git_reference* ref = NULL;
    error = git_reference_lookup(&ref, repository, [[@"refs/heads/" stringByAppendingString:branch] UTF8String]);
    if (error != 0) goto cleanup;
    
    const git_oid* oid = git_reference_target(ref);
    git_commit* commit = NULL;
    error = git_commit_lookup(&commit, repository, oid);
    if (error != 0) goto cleanup;
    
    git_tree* tree = NULL;
    error = git_commit_tree(&tree, commit);
    if (error != 0) goto cleanup;
    
    git_tree_entry* entry = NULL;
    error = git_tree_entry_bypath(&entry, tree, [path UTF8String]);
    if (error != 0) goto cleanup;
    
    if (git_tree_entry_type(entry) != GIT_OBJ_BLOB) {
        *outError = [NSError errorWithDomain:NSPOSIXErrorDomain code:100021 userInfo:nil];
        //                                                    EISDIR ~~~~~~
        git_repository_free(repository);
        return nil;
    }
    
    const git_oid* entryOID = git_tree_entry_id(entry);
    char hash[GIT_OID_HEXSZ + 1];
    git_oid_tostr(hash, sizeof(hash), entryOID);
    return [NSString stringWithCString:hash encoding:NSASCIIStringEncoding];
    
cleanup:
    nsErrorForGit(error, outError);
    if (repository) git_repository_free(repository);
    return nil;
}

@end
