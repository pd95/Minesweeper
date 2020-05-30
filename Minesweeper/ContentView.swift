//
//  ContentView.swift
//  Minesweeper
//
//  Created by Philipp on 24.05.20.
//  Copyright © 2020 Philipp. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var game = MinesweeperGame()

    var gameState: String {
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
                    .animation(Animation.easeIn)
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
                .padding()
                .background(RoundedRectangle(cornerRadius: 10)
                    .fill(Color.red)
                    .shadow(radius: 10)
                )
                .foregroundColor(Color.white)
        }
        .frame(maxWidth: 300, maxHeight: 300)
        .background(Color.white.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    var buttonText: String {
        if game.state == .won {
            return "Next level"
        }
        return "Try again"
    }

    func restart() {
        var numberOfMines = self.game.numberOfMines
        if self.game.state == .won {
            numberOfMines += 5
        }
        self.game.reset(numberOfMines: numberOfMines)
    }
}

struct Board: View {
    @EnvironmentObject var game: MinesweeperGame

    @State private var feedback = UINotificationFeedbackGenerator()

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<game.height, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<self.game.width, id: \.self) { column in
                        self.fieldView(for: row, column: column)
                    }
                }
            }
        }
    }

    func fieldView(for row: Int, column: Int) -> some View {
        return Field(gameState: game.state, fieldState: game.field[row][column])
            .onTapGesture {
                let field = self.game.uncover(location: (row, column))
                if field == .explodedMine {
                    self.feedback.notificationOccurred(.error)
                }
            }
            .onLongPressGesture() {
                if self.game.flagMine(at: (row, column)) {
                    self.feedback.notificationOccurred(.success)
                }
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
        ContentView()
    }
}
