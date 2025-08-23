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

/**
 * This structure is used to provide callers information about the
 * progress of indexing a packfile, either directly or part of a
 * fetch or clone that downloads a packfile.
 */
typedef struct _git_indexer_progress {
    /** number of objects in the packfile being indexed */
    unsigned int total_objects;
    
    /** received objects that have been hashed */
    unsigned int indexed_objects;
    
    /** received_objects: objects which have been downloaded */
    unsigned int received_objects;
    
    /**
     * locally-available objects that have been injected in order
     * to fix a thin pack
     */
    unsigned int local_objects;
    
    /** number of deltas in the packfile being indexed */
    unsigned int total_deltas;
    
    /** received deltas that have been indexed */
    unsigned int indexed_deltas;
    
    /** size of the packfile received up to now */
    size_t received_bytes;
} _git_indexer_progress;

@interface AssetShims : NSObject

+(void)startup;
+(void)shutdown;

+(bool)downloadResourceInLocale: (NSString*) locale ofType: (NSString*) type payload: (void*) payload onProgressUpdate: (int (*)(const _git_indexer_progress *stats, void *payload))progressUpdate;

@end
