//
//  ContentView.swift
//  Minesweeper
//
//  Created by Philipp on 24.05.20.
//  Copyright © 2020 Philipp. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var game: MinesweeperGame

    private var gameState: String {
        switch game.state {
            case .running:
                return "Can you locate the \(game.numberOfMines - game.numberOfFlags)\(game.numberOfFlags > 0 ? " remaining" : "") mines?"
            case .lost:
                return "The game is over. You have lost!"
            case .won:
                return "Well done! You win!"
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            Text("Mine Sweeper")
                .font(.largeTitle)

            Text(gameState)

            ZStack {
                Board()

                GameEnded()
                    .opacity(game.state != .running ? 1 : 0)
                    .animation(.easeIn(duration: 0.3))
            }
            Spacer()
        }
        .padding()
        .environmentObject(game)
    }
}

struct GameEnded: View {
    @EnvironmentObject var game: MinesweeperGame

    var body: some View {
        Button(action: restart) {
            Text(buttonText)
                .font(.headline)
                .frame(minWidth: 40, minHeight: 40)
                .padding()
                .animation(nil)
                .background(RoundedRectangle(cornerRadius: 10)
                    .fill(.red)
                    .shadow(radius: 10)
                )
                .foregroundColor(.white)
                .padding()
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.opacity(0.5))
    }

    private var buttonText: String {
        switch game.state {
        case .lost:
            return "Try again"
        case .won:
            return "Next level"
        default:
            return ""
        }
    }

    private func restart() {
        var numberOfMines = game.numberOfMines
        if game.state == .won {
            numberOfMines += 5
        }
        game.reset(numberOfMines: numberOfMines)
    }
}

struct Board: View {
    @EnvironmentObject var game: MinesweeperGame

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<game.height, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<game.width, id: \.self) { column in
                        fieldView(for: row, column: column)
                    }
                }
            }
        }
    }

    private func fieldView(for row: Int, column: Int) -> some View {
        Field(gameState: game.state, fieldState: game.field[row][column])
            .onTapGesture {
                game.uncover(location: (row, column))
            }
            .onLongPressGesture() {
                game.flagMine(at: (row, column))
            }
    }
}

struct Field: View {
    let gameState:  MinesweeperGame.GameState
    let fieldState: MinesweeperGame.FieldState

    var body: some View {
        let content: String
        switch (gameState, fieldState) {
            case (_, .explodedMine):
                content = "💥"
            case (.lost, .hiddenMine), (.lost, .flaggedMine):
                content = "💣"
            case (_, .uncovered(numberOfNeighbouringMines: 0)):
                content = " "
            case (_, .uncovered(numberOfNeighbouringMines: let number)):
                content = "\(number)"
            case (.won, .hiddenMine), (_, .flagged), (_, .flaggedMine):
                content = "🏴"
            default:
                content = " "
        }
        return Text("xx")
            .hidden()
            .overlay(
                Text(content)
            )
            .background(fieldState.isUncovered ? Color.clear : Color.yellow)
            .overlay(
                Rectangle()
                    .stroke()
            )
            .font(Font.title.bold())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(game: .init())
    }
}
