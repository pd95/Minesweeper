//
//  ContentView.swift
//  Minesweeper
//
//  Created by Philipp on 24.05.20.
//  Copyright © 2020 Philipp. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State private var feedback = UINotificationFeedbackGenerator()

    @ObservedObject var game = MinesweeperGame()

    var gameState: String {
        switch game.state {
            case .running:
                return "Can you locate the \(game.numberOfMines) mines?"
            case .lost:
                return "The game is over. You have lost!"
            case .won:
                return "Well done! You win!"
        }
    }

    var buttonText: String {
        if game.state == .won {
            return "Next level"
        }
        return "Restart"
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Mine Sweeper")
                .font(.largeTitle)

            Text(gameState)

            ZStack {
                VStack(spacing: 0) {
                    ForEach(0..<game.height, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<self.game.width, id: \.self) { column in
                                self.cellView(for: row, column: column)
                            }
                        }
                    }
                }

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
                .opacity(game.state != .running ? 1 : 0)
                .animation(Animation.easeIn)
            }
            Spacer()
        }
        .padding()
    }

    func restart() {
        var numberOfMines = self.game.numberOfMines
        if self.game.state == .won {
            numberOfMines += 5
        }
        self.game.reset(numberOfMines: numberOfMines)
    }

    func cellView(for row: Int, column: Int) -> some View {
        let state = game.field[row][column]
        let content: String
        switch state {
            case .outOfBounds:
                content = "?"
            case .covered:
                content = " "
            case .explodedMine:
                content = "💥"
            case .hiddenMine:
                content = game.state == .lost ? "💣" : " "
            case .uncovered(numberOfNeighbouringMines: let numberOfNeighbouringMines):
                content = numberOfNeighbouringMines > 0 ? "\(numberOfNeighbouringMines)" : " "
            case .flagged:
                content = "🏴"
            case .flaggedMine:
                content = game.state == .lost ? "💣" : "🏴"
        }
        return Text("xx")
            .hidden()
            .overlay(
                Text(content)
            )
            .background(state.isUncovered ? Color.clear : Color.yellow)
            .overlay(
                Rectangle()
                    .stroke()
            )
            .font(Font.title.bold())
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
