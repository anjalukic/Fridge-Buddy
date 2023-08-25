//
//  Semaphore.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 22.8.23..
//

import Foundation

actor Semaphore {
    enum State {
        case green
        case red(waiters: [CheckedContinuation<Void, Never>])
    }

    private var state: State

    init() {
        self.state = .green
    }

    private func enter() async {
        switch self.state {
        case .green:
            self.state = .red(waiters: [])
            return
        case .red(waiters: var waiters):
            await withCheckedContinuation {
                waiters.append($0)
                self.state = .red(waiters: waiters)
            }
        }
    }

    private func exit() {
        guard case .red(waiters: var waiters) = self.state else {
            fatalError("Exiting in invalid state")
        }

        if waiters.isEmpty {
            self.state = .green
            return
        }

        let nextWaiter = waiters.removeFirst()
        self.state = .red(waiters: waiters)
        nextWaiter.resume()
    }

    func withSemaphoreLock<ReturnValue>(_ body: () async -> ReturnValue) async -> ReturnValue {
        await self.enter()
        defer {
            self.exit()
        }
        return await body()
    }
}
