//===---*- Greatdori! -*---------------------------------------------------===//
//
// FileDistibution.swift
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

import DoriKit


func prepareUpdateFolder(forLocale locale: DoriLocale, from: String, to: String) async {
    let branches: [String] = ["basic", "movie", "sound", "unsupported"]
    print("[$][Prepare][\(locale.rawValue)] Preparation starts.")
    //    Task {
    for branchName in branches {
        await prepareUpdateFolderForBranch(forLocale: locale, branchName: branchName, from: from, to: to)
    }
    //    }
    print("[$][Prepare][\(locale.rawValue)] Preparation completed.")
    
    func prepareUpdateFolderForBranch(forLocale locale: DoriLocale, branchName: String, from: String, to: String) async {
        do {
            // Compose branch/path like "$1/$2" => "<locale>/<target>"
            let branchPath = "\(locale.rawValue)/\(branchName)"
            
            let script = #"""
set -euo pipefail

git config --global --add safe.directory "\(from)"
cd "\(from)"

git checkout "\(branchPath)"

# Retry git pull --rebase up to 10 times
for i in {1..10}; do
  if git pull --rebase; then
    break
  fi
  sleep 1
done

cp -Rf "./\(locale.rawValue)/" "\(to)/\(locale.rawValue)"
"""#
            
            let (status, output) = try await runTool(
                arguments: ["bash", "-lc", script]
            )
            
            print("[✓][Prepare][\(locale.rawValue)/\(branchName)] Succeed. Status \(status).")
        } catch {
            print("[×][Prepare][\(locale.rawValue)/\(branchName)] Failed. Error: \(error).")
        }
    }
}

