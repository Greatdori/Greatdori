//===---*- Greatdori! -*---------------------------------------------------===//
//
// AssetShims.m
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
#import "GitError.h"
#import "AssetShims.h"

int getCredential(git_credential **out, const char *url, const char *usernameFromURL, unsigned int allowedTypes, void *payload) {
    return git_credential_userpass_plaintext_new(out, "DoriAsset", "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");
}
int getRemoteCallback(git_remote **out, git_repository *repo, const char *name, const char *url, void *payload) {
    return git_remote_create_with_fetchspec(out, repo, name, url, refspecOfBranch((__bridge NSString*)payload));
}

@implementation AssetShims

+(void)startup {
    git_libgit2_init();
}

+(void)shutdown {
    git_libgit2_shutdown();
}

+(bool)downloadResourceInLocale: (NSString*) locale
                         ofType: (NSString*) type
                        payload: (void*) payload
                          error: (NSError**) outError
               onProgressUpdate: (int (*)(const git_indexer_progress *stats, void *payload))progressUpdate {
    git_repository* repository = NULL;
    git_clone_options options = GIT_CLONE_OPTIONS_INIT;
    options.fetch_opts.callbacks.payload = payload;
    options.fetch_opts.callbacks.transfer_progress = progressUpdate;
    options.fetch_opts.callbacks.credentials = getCredential;
    options.checkout_branch = [[[locale stringByAppendingString:@"/"] stringByAppendingString:type] UTF8String];
    options.checkout_opts.checkout_strategy = GIT_CHECKOUT_NONE;
    options.fetch_opts.download_tags = GIT_REMOTE_DOWNLOAD_TAGS_NONE;
    options.fetch_opts.prune = GIT_FETCH_PRUNE;
    options.remote_cb_payload = (__bridge void*) [[locale stringByAppendingString:@"/"] stringByAppendingString:type];
    options.remote_cb = getRemoteCallback;
    
    NSString* destination = [NSHomeDirectory() stringByAppendingString:@"/Documents/OfflineResource.bundle"];
    if (![NSFileManager.defaultManager fileExistsAtPath:destination]) {
        [NSFileManager.defaultManager createDirectoryAtPath:destination withIntermediateDirectories:true attributes:nil error:nil];
    }
    
    int error = git_clone(&repository,
                          "https://github.com/WindowsMEMZ/Greatdori-OfflineResBundle.git",
                          [destination UTF8String],
                          &options);
    if (error < 0) {
        nsErrorForGit(error, outError);
        return false;
    }
    git_repository_free(repository);
    return true;
}

+(int)updateResourceInLocale: (NSString*) locale
                      ofType: (NSString*) type
                     payload: (void*) payload
                       error: (NSError**) outError
            onProgressUpdate: (int (*)(const git_indexer_progress *stats, void *payload))progressUpdate {
    NSString* branch = [[locale stringByAppendingString:@"/"] stringByAppendingString:type];
    const char* refs = refspecOfBranch(branch);
    
    git_repository* repository = NULL;
    int error = git_repository_open(&repository, [[NSHomeDirectory() stringByAppendingString:@"/Documents/OfflineResource.bundle"] UTF8String]);
    if (error != 0) {
        nsErrorForGit(error, outError);
        return -1;
    }
    
    git_remote* remote = NULL;
    error = git_remote_lookup(&remote, repository, "origin");
    if (error != 0) {
        nsErrorForGit(error, outError);
        git_repository_free(repository);
        return -1;
    }
    
    git_fetch_options fetchOptions = GIT_FETCH_OPTIONS_INIT;
    fetchOptions.callbacks.payload = payload;
    fetchOptions.callbacks.transfer_progress = progressUpdate;
    
    git_strarray strarrRefs = { (char**)&refs, strlen(refs) };
    error = git_remote_fetch(remote, &strarrRefs, &fetchOptions, NULL);
    if (error != 0) {
        nsErrorForGit(error, outError);
        git_repository_free(repository);
        return -1;
    }
    
    // Lookup latest commit of remote
    git_reference* remoteLatestRef = NULL;
    error = git_reference_lookup(&remoteLatestRef, repository, [[@"refs/remotes/origin/" stringByAppendingString:branch] UTF8String]);
    if (error != 0) {
        nsErrorForGit(error, outError);
        git_repository_free(repository);
        return -1;
    }
    git_oid remoteLatestOID;
    error = git_reference_name_to_id(&remoteLatestOID, repository, [[@"refs/remotes/origin/" stringByAppendingString:branch] UTF8String]);
    if (error != 0) {
        nsErrorForGit(error, outError);
        git_repository_free(repository);
        return -1;
    }
    git_commit* remoteLatestCommit = NULL;
    error = git_commit_lookup(&remoteLatestCommit, repository, &remoteLatestOID);
    if (error != 0) {
        nsErrorForGit(error, outError);
        git_repository_free(repository);
        return -1;
    }
    
    // Lookup latest commit of local
    git_reference* localLatestRef = NULL;
    error = git_repository_head(&localLatestRef, repository);
    if (error != 0) {
        nsErrorForGit(error, outError);
        git_repository_free(repository);
        return -1;
    }
    const git_oid* localLatestOID = git_reference_target(localLatestRef);
    git_commit* localLatestCommit = NULL;
    error = git_commit_lookup(&localLatestCommit, repository, localLatestOID);
    if (error != 0) {
        nsErrorForGit(error, outError);
        git_repository_free(repository);
        return -1;
    }
    
    // Merge
    git_annotated_commit* remoteAnnotatedLatestCommit = NULL;
    error = git_annotated_commit_from_ref(&remoteAnnotatedLatestCommit, repository, remoteLatestRef);
    if (error != 0) {
        nsErrorForGit(error, outError);
        git_repository_free(repository);
        return -1;
    }
    git_merge_analysis_t analysis;
    git_merge_preference_t preference;
    error = git_merge_analysis(&analysis, &preference, repository, (const git_annotated_commit**)&remoteAnnotatedLatestCommit, 1);
    if (error != 0) {
        nsErrorForGit(error, outError);
        git_repository_free(repository);
        return -1;
    }
    if (analysis & GIT_MERGE_ANALYSIS_UP_TO_DATE) {
        git_repository_free(repository);
        return 0;
    } else {
        git_checkout_options checkoutOptions = GIT_CHECKOUT_OPTIONS_INIT;
        checkoutOptions.checkout_strategy = GIT_CHECKOUT_NONE;
        git_reset(repository, (git_object *)remoteLatestCommit, GIT_RESET_HARD, &checkoutOptions);
        git_repository_free(repository);
        return 0;
    }
}

@end
