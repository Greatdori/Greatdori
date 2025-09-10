#===---*- Greatdori! -*----------------------------------------------------===#
#
# ci_post_clone.sh
#
# This source file is part of the Greatdori! open source project
#
# Copyright (c) 2025 the Greatdori! project authors
# Licensed under Apache License v2.0
#
# See https://greatdori.memz.top/LICENSE.txt for license information
# See https://greatdori.memz.top/CONTRIBUTORS.txt for the list of Greatdori! project authors
#
#===-----------------------------------------------------------------------===#

# Since the folder name is also Swift Package name for Greatdori,
# it must be renamed to make PreCacheGen can be resolved.
mv /Volumes/workspace/repository /Volumes/workspace/Greatdori
cd /Volumes/workspace/Greatdori
