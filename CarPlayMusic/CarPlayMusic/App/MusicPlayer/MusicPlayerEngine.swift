//
//  MusicPlayerEngine.swift
//  CarPlayMusic
//
//  Created by Amerigo Mancino on 07/10/22.
//

import Foundation
import MediaPlayer
import AVKit

// MARK: - Structs

public struct SongItem {
    var title: String
    var author: String
    var url: URL
    var image: UIImage
}

// MARK: - Protocols

protocol ReloadDelegate: AnyObject {
    func reloadTable()
    func reloadTable(with: Int)
    func reloadWithLast()
}

// MARK: - Music Player Singleton

class MusicPlayerEngine {
    
    static var shared: MusicPlayerEngine = MusicPlayerEngine()
    
    // MARK: - Class variables
    
    public var player: AVPlayer = AVPlayer()
    
    /// Control center controller
    private var audioInfoControlCenter = [String: Any]()
    
    /// The shared MPRemoteCommandCenter
    private let commandCenter = MPRemoteCommandCenter.shared()
    
    /// Lists of songs
    private let songList: [SongItem] = [
        SongItem(title: "Europe Travel", author: "Cesar", url: Bundle.main.url(forResource: "europe-travel", withExtension: "mp3")!, image: UIImage(named: "author1")!),
        SongItem(title: "Forest Lullaby", author: "Amanda", url: Bundle.main.url(forResource: "forest-lullaby", withExtension: "mp3")!, image: UIImage(named: "author2")!),
        SongItem(title: "Wanderer's life", author: "Jakaya", url: Bundle.main.url(forResource: "wanderer", withExtension: "mp3")!, image: UIImage(named: "author3")!),
        SongItem(title: "Dark world", author: "Renee", url: Bundle.main.url(forResource: "dark-world", withExtension: "mp3")!, image: UIImage(named: "author4")!),
        SongItem(title: "Snowflakes Pattern", author: "Pietro Schellino", url: Bundle.main.url(forResource: "snowflakes-pattern", withExtension: "mp3")!, image: UIImage(named: "author5")!)
    ]
    
    weak var reloadDelegate: ReloadDelegate?
    
    // MARK: - Initialization
    
    private init() {
        // init made private to avoid extenal initialization
        
        self.setupRemoteTransportControls()
    }
    
    // MARK: - Exposed functions
    
    /// Play one of the songs in the song list.
    public func play(id: Int) -> Void {
        guard id <= 4 else { return }
        
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: self.player.currentItem
        )
    
        self.player.replaceCurrentItem(with: AVPlayerItem(url: songList[id].url))
    
        // update general metadata
        
        self.audioInfoControlCenter[MPMediaItemPropertyTitle] = songList[id].title
        self.audioInfoControlCenter[MPMediaItemPropertyArtist] = songList[id].author
        self.audioInfoControlCenter[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: songList[id].image.size, requestHandler: { image in
            return self.songList[id].image
        })
        
        self.audioInfoControlCenter[MPNowPlayingInfoPropertyIsLiveStream] = false
        self.commandCenter.changePlaybackPositionCommand.isEnabled = true
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = self.audioInfoControlCenter
        
        // setup observer for when audio end
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.audioDidEnded),
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: self.player.currentItem
        )
        
        self.player.play()
        
        self.updatePlaybackRateData()
    }
    
    /// Pause the current song.
    public func stop() -> Void {
        self.player.pause()
        self.updatePlaybackRateData()
    }
    
    public func getSongList() -> [SongItem] {
        return self.songList
    }
    
    public func isPlaying() -> Bool {
        return self.player.rate != 0
    }
    
    public func resumePlaying() -> Void {
        self.player.play()
    }
    
    // MARK: - Private functions
    
    /// Setup control center.
    private func setupRemoteTransportControls() -> Void {
        
        // Add handler for play command
        commandCenter.playCommand.addTarget { [unowned self] event in
            self.player.play()
            self.updatePlaybackRateData()
            MusicPlayerEngine.shared.reloadDelegate?.reloadWithLast()
            
            return .success
        }
        
        // Add handler for pause command
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            self.stop()
            self.updatePlaybackRateData()
            MusicPlayerEngine.shared.reloadDelegate?.reloadTable()
            
            return .success
        }
        
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.playCommand.isEnabled = true
    }
    
    /// Update control center.
    private func updatePlaybackRateData() -> Void {
        self.audioInfoControlCenter[MPNowPlayingInfoPropertyPlaybackRate] = self.player.rate
        self.audioInfoControlCenter[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.player.currentItem?.currentTime().seconds
        self.audioInfoControlCenter[MPMediaItemPropertyPlaybackDuration] = self.player.currentItem?.asset.duration.seconds
        
        if self.player.rate == 1 {
            MPNowPlayingInfoCenter.default().playbackState = .playing
        } else {
            MPNowPlayingInfoCenter.default().playbackState = .paused
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = self.audioInfoControlCenter
    }
    
    // MARK: - Protocol functions
    
    func stopSong() -> Void {
        DispatchQueue.main.async {
            self.reloadDelegate?.reloadTable()
        }
    }
    
    // MARK: - Events functions
    
    /// Triggered when an audio reached the end.
    @objc private func audioDidEnded() {
        self.stopSong()
    }
}
