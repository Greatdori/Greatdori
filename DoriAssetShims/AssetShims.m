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
    return git_credential_ssh_key_memory_new(out, "DoriAsset", "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDhdiKmNkMgowBqvT+bde80lfwv7bRSbTkVdiyd9uy/lNkbbBgjflwG/jaZgT5NytHSJ1WDVfIOxxRcGvwSWa7ZNospRAQcn1/K86LI9BLZivT9z0EUs2gPUYGQ9d9rksfHfIiQ3SFEyu7g46b7IAyWWQ35sApbgzQ2kI8J3Rfh2PERuCItep6cZBc1B2ov1MFDbvep/Eq/nw7CUFEroEX63ixLZRZXgtJggIVgS/vf+wUUcYRuvk6R2bnBj5pE6iW1y5P8DH7l5CkwC9ZXsGIaNRYCkwmfQaHLhKrEaeQGaYmX4+QCnECzYB//VRzRe2hVNT0h+oLRgxxAhayzugqKYkY4qiGQ0i6+MQYmGCwMf635uVrACTJqUXHVacTXol5fZOtySw0R8cpHwPR7CuPn8FvsZ4sFjQtqeDhfeUhem9UE4aNci/CB9Gfm3Bd6cisfvOc44GFQ1Bv4hbW4+2w9t+OzRx3XAHnbK7vb5SuqSamNhoPv6psYacTDAUrPZUs=", R"(
         -----BEGIN OPENSSH PRIVATE KEY-----
         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
         ndLEguo15D5gRI+NPSc8B37aOZc=
         -----END OPENSSH PRIVATE KEY-----
         )", "aka(Togawa Sakiko).cn.dropFirst()");
}

@implementation AssetShims

+(void)startup {
    git_libgit2_init();
}

+(void)shutdown {
    git_libgit2_shutdown();
}

+(bool)downloadResourceInLocale: (NSString*) locale ofType: (NSString*) type onProgressUpdate: (void (^)(double, int, int))progressUpdate {
    git_repository* repository = NULL;
    git_clone_options options = GIT_CLONE_OPTIONS_INIT;
    options.fetch_opts.callbacks.transfer_progress = (__bridge void*) ^ int (const git_indexer_progress* progress, void* payload) {
        double percentage = progress->received_objects / progress->total_objects;
        progressUpdate(percentage, progress->received_objects, progress->total_objects);
        return 0;
    };
    options.fetch_opts.callbacks.credentials = getCredential;
    
    NSString* destination = [NSHomeDirectory() stringByAppendingString:@"/Documents/OfflineResource.bundle"];
    if (![NSFileManager.defaultManager fileExistsAtPath:destination]) {
        [NSFileManager.defaultManager createDirectoryAtPath:destination withIntermediateDirectories:true attributes:nil error:nil];
    }
    
    int error = git_clone(&repository,
                          "https://github.com/WindowsMEMZ/Greatdori-OfflineResBundle.git",
                          [destination UTF8String],
                          &options);
    if (error < 0) {
        printf("%s", giterr_last()->message);
        return false;
    }
    git_repository_free(repository);
    return true;
}

@end
