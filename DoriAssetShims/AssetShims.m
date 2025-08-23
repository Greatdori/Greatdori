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
#import "DoriAssetShims.h"

int getCredential(git_credential **out, const char *url, const char *usernameFromURL, unsigned int allowedTypes, void *payload) {
    return git_credential_userpass_plaintext_new(out, "DoriAsset", "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");
}

@implementation AssetShims

+(void)startup {
    git_libgit2_init();
}

+(void)shutdown {
    git_libgit2_shutdown();
}

+(bool)downloadResourceInLocale: (NSString*) locale ofType: (NSString*) type payload: (void*) payload onProgressUpdate: (int (*)(const git_indexer_progress *stats, void *payload))progressUpdate {
    git_repository* repository = NULL;
    git_clone_options options = GIT_CLONE_OPTIONS_INIT;
    options.fetch_opts.callbacks.payload = payload;
    options.fetch_opts.callbacks.transfer_progress = progressUpdate;
    options.fetch_opts.callbacks.credentials = getCredential;
    options.checkout_branch = [[[locale stringByAppendingString:@"/"] stringByAppendingString:type] UTF8String];
    options.fetch_opts.download_tags = GIT_REMOTE_DOWNLOAD_TAGS_NONE;
    options.fetch_opts.prune = GIT_FETCH_PRUNE;
    
    NSString* destination = [NSHomeDirectory() stringByAppendingString:@"/Documents/OfflineResource.bundle"];
    if (![NSFileManager.defaultManager fileExistsAtPath:destination]) {
        [NSFileManager.defaultManager createDirectoryAtPath:destination withIntermediateDirectories:true attributes:nil error:nil];
    }
    
    int error = git_clone(&repository,
                          "https://github.com/WindowsMEMZ/Greatdori-OfflineResBundle.git",
                          [destination UTF8String],
                          &options);
    if (error < 0) {
        printf("%s\n", giterr_last()->message);
        return false;
    }
    git_repository_free(repository);
    return true;
}

@end
