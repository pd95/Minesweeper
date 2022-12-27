//
//  AudioFeedback.swift
//  Minesweeper
//
//  Created by Philipp on 30.05.20.
//  Copyright © 2020 Philipp. All rights reserved.
//

import Foundation
import AVKit

class AudioFeedback {

    enum AudioAsset: String {
        case explosion
    }

    private var playerCache = [String:AVAudioPlayer]()

    var isMute = false {
        didSet {
            if isMute {
                stopAll()
            }
        }
    }

    func prepare(_ asset: AudioAsset) {
        let assetName = asset.rawValue
        guard let dataAsset = NSDataAsset(name: assetName) else {
            print("Asset \(assetName) missing")
            return
        }
        guard let player = try? AVAudioPlayer(data: dataAsset.data) else {
            print("Unable to initialize AVAudioPlayer with asset \(assetName)")
            return
        }
        #if !targetEnvironment(simulator)
        player.prepareToPlay()
        #endif
        playerCache[assetName] = player
    }

    func play(_ asset: AudioAsset) {
        guard !isMute else {
            return
        }
        guard let player = playerCache[asset.rawValue] else {
            print("Asset \(asset.rawValue) has no associated player. Did you call prepare(.\(asset.rawValue)?")
            return
        }
        #if targetEnvironment(simulator)
        print(asset)
        #else
        player.play()
        #endif
    }

    func stop(_ asset: AudioAsset) {
        guard let player = playerCache[asset.rawValue] else {
            print("Asset \(asset.rawValue) has no associated player. Did you call prepare(.\(asset.rawValue)?")
            return
        }
        #if !targetEnvironment(simulator)
        player.stop()
        #endif
    }

    func stopAll() {
        for player in playerCache {
            player.value.stop()
        }
    }
}
