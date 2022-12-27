//
//  MinesweeperGame.swift
//  Minesweeper
//
//  Created by Philipp on 24.05.20.
//  Copyright © 2020 Philipp. All rights reserved.
//

import Foundation
import UIKit

class MinesweeperGame: ObservableObject {

    enum FieldState: Hashable, Equatable, CustomStringConvertible {
        case outOfBounds, covered, hiddenMine, uncovered(numberOfNeighbouringMines: Int), flagged, flaggedMine, explodedMine

        var isUncovered: Bool {
            return self != .covered && self != .hiddenMine
        }

        var hasMine: Bool {
            return self == .flaggedMine || self == .hiddenMine || self == .explodedMine
        }

        var hasFlag: Bool {
            return self == .flaggedMine || self == .flagged
        }

        var description: String {
            switch self {
                case .outOfBounds:
                    return "?"
                case .covered:
                    return "_"
                case .explodedMine:
                    return "💥"
                case .hiddenMine:
                    return "💣"
                case .uncovered(numberOfNeighbouringMines: let numberOfNeighbouringMines):
                    return numberOfNeighbouringMines > 0 ? "\(numberOfNeighbouringMines)" : " "
                case .flagged:
                    return "🏴"
                case .flaggedMine:
                    return "🏴‍☠️"
            }
        }
    }

    enum GameState: String {
        case running, won, lost
    }

    @Published private(set) var field: [[FieldState]] = []
    @Published private(set) var state: GameState = .running
    let width: Int
    let height: Int
    @Published private(set) var numberOfMines: Int
    @Published private(set) var numberOfFlags = 0

    // Interaction with audio feedback
    private var audioFeedback = AudioFeedback()
    @Published var isMute = false {
        didSet {
            audioFeedback.isMute = isMute
        }
    }

    // Haptic feedback
    private var hapticFeedback = UINotificationFeedbackGenerator()

    init(width: Int = 10, height: Int = 15, numberOfMines: Int = 5) {
        self.width = width
        self.height = height
        self.numberOfMines = numberOfMines
        reset()
    }

    func reset(numberOfMines: Int? = nil) {
        let numberOfMines = numberOfMines ?? self.numberOfMines
        guard numberOfMines > 0 && numberOfMines < self.width * self.height / 4 else {
            self.state = .lost
            return
        }
        self.numberOfMines = numberOfMines

        var field = [[FieldState]]()
        (0..<height).forEach { _ in
            field.append(Array(repeating: FieldState.covered, count: width))
        }
        self.field = field

        var minesPlaced = 0
        while minesPlaced < numberOfMines {
            let randomLocation = (row: Int.random(in: (0..<height)), column: Int.random(in: (0..<width)))

            if !fieldState(at: randomLocation).hasMine {
                self.field[randomLocation.row][randomLocation.column] = .hiddenMine
                minesPlaced += 1
            }
        }
        numberOfFlags = 0
        self.state = .running

        audioFeedback.stopAll()
        audioFeedback.prepare(.explosion)
    }

    func fieldState(at location: (row: Int, column: Int)) -> FieldState {
        guard (0..<height).contains(location.row) && (0..<width).contains(location.column) else {
            return .outOfBounds
        }

        return field[location.row][location.column]
    }

    func uncover(location: (row: Int, column: Int), initial: Bool = true) {
        guard state == .running,
            (0..<height).contains(location.row),
            (0..<width).contains(location.column) else {
            return
        }
        let oldState = fieldState(at: location)
        let state: FieldState
        if oldState.hasFlag {
            state = oldState
            hapticFeedback.notificationOccurred(.warning)
        }
        else if oldState.hasMine {
            state = .explodedMine
            self.state = .lost
            audioFeedback.play(.explosion)
            hapticFeedback.notificationOccurred(.error)
        }
        else {
            var mineCount = 0
            for dy in -1...1 {
                for dx in -1...1 {
                    mineCount += fieldState(at: (location.row + dy, location.column + dx)).hasMine ? 1 : 0
                }
            }
            state = .uncovered(numberOfNeighbouringMines: mineCount)
        }
        field[location.row][location.column] = state

        // Make sure flag counter is decremented if a flag is uncovered
        if oldState == .flagged && oldState != state {
            numberOfFlags -= 1
        }

        if state == .uncovered(numberOfNeighbouringMines: 0) {
            uncoverNeighbors(location: location)
        }
        if initial {
            updateGameState()
        }
    }

    private func updateGameState() {
        if state == .running {
            var hiddenMines = 0
            for row in field {
                for field in row {
                    if field == .hiddenMine {
                        hiddenMines += 1
                    }
                    else if field == .covered {
                        return
                    }
                }
            }
            if numberOfFlags == numberOfMines || hiddenMines + numberOfFlags == numberOfMines  {
                state = .won
            }
        }
    }

    private func uncoverNeighbors(location: (row: Int, column: Int)) {
        for dy in -1...1 {
            for dx in -1...1 {
                let newLocation = (location.row + dy, location.column + dx)
                if fieldState(at: newLocation) == .covered {
                    _ = uncover(location: newLocation, initial: false)
                }
            }
        }
    }

    func flagMine(at location: (row: Int, column: Int)) {
        guard state == .running,
            (0..<height).contains(location.row),
            (0..<width).contains(location.column) else {
            return
        }
        let oldNumberOfFlags = numberOfFlags
        let state = field[location.row][location.column]
        if state == .covered && numberOfFlags < numberOfMines {
            field[location.row][location.column] = .flagged
            numberOfFlags += 1
        }
        else if state == .hiddenMine && numberOfFlags < numberOfMines {
            field[location.row][location.column] = .flaggedMine
            numberOfFlags += 1
        }
        else if state == .flagged {
            field[location.row][location.column] = .covered
            numberOfFlags -= 1
        }
        else if state == .flaggedMine {
            field[location.row][location.column] = .hiddenMine
            numberOfFlags -= 1
        }

        updateGameState()

        if oldNumberOfFlags < numberOfFlags {
            hapticFeedback.notificationOccurred(.success)
        }
    }
}
