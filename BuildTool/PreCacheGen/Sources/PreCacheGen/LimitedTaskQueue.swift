//===---*- Greatdori! -*---------------------------------------------------===//
//
// LimitedTaskQueue.swift
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

import Foundation

class LimitedTaskQueue {
    static var shared: LimitedTaskQueue = .init(limit: 15)
    
    private let semaphore: DispatchSemaphore
    private let queue = DispatchQueue(label: "com.memz233.Greatdori.PreCacheGen.limited-task-queue", attributes: .concurrent)
    
    private let lock = NSLock()
    private var runningTasks = 0
    private let allDoneSemaphore = DispatchSemaphore(value: 0)
    
    init(limit: Int) {
        self.semaphore = DispatchSemaphore(value: limit)
    }
    
    func addTask(_ task: @escaping () async -> Void) {
        incrementRunning()
        queue.async {
            self.semaphore.wait()
            Task {
                await task()
                self.semaphore.signal()
                self.decrementRunning()
            }
        }
    }
    
    func waitUntilAllFinished() async {
        await withCheckedContinuation { continuation in
            Task.detached {
                self.lock.lock()
                if self.runningTasks == 0 {
                    self.lock.unlock()
                    continuation.resume()
                    return
                }
                self.lock.unlock()
                
                self.allDoneSemaphore.wait()
                continuation.resume()
            }
        }
    }
    
    private func incrementRunning() {
        lock.lock()
        runningTasks += 1
        lock.unlock()
    }
    
    private func decrementRunning() {
        lock.lock()
        runningTasks -= 1
        if runningTasks == 0 {
            allDoneSemaphore.signal()
        }
        lock.unlock()
    }
}
