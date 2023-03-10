//
//  MusicTableView.swift
//  CarPlayMusic
//
//  Created by Amerigo Mancino on 15/11/22.
//

import UIKit

class MusicTableView: UITableView, UITableViewDelegate, UITableViewDataSource, ReloadDelegate {

    private let cellID = "MusicCell"
    
    private var selectedRow = -1
    private var rowInPlay = -1
    private var lastInPlay = -1
    
    private var songs: [SongItem] = [] {
        didSet {
            self.reloadData()
        }
    }
    
    // MARK: - Init

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let nibCell = UINib(nibName: cellID, bundle: nil)
        self.register(nibCell, forCellReuseIdentifier: cellID)
        
        self.dataSource = self
        self.delegate = self
        
        MusicPlayerEngine.shared.reloadDelegate = self
        
        self.songs = MusicPlayerEngine.shared.getSongList()
    }
    
    // MARK: - Table view delegate methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as! MusicCell
        
        cell.authorImage.image = songs[indexPath.row].image
        cell.title.text = songs[indexPath.row].title
        cell.author.text = songs[indexPath.row].author
        
        cell.playButton.tag = indexPath.row
        cell.playButton.addTarget(self, action: #selector(self.playAction(_:)), for: .touchUpInside)
        
        if self.rowInPlay == indexPath.row {
            cell.playButton.setImage(UIImage(systemName: "pause.circle.fill", withConfiguration: UIImage.SymbolConfiguration(scale: .large)), for: .normal)
        } else {
            cell.playButton.setImage(UIImage(systemName: "play.circle.fill", withConfiguration: UIImage.SymbolConfiguration(scale: .large)), for: .normal)
        }
        
        cell.backgroundColor = UIColor.clear
        cell.selectionStyle = .none
        
        return cell
    }
    
    @objc func playAction(_ sender : UIButton) {

        if selectedRow == sender.tag {
            if MusicPlayerEngine.shared.isPlaying() {
                MusicPlayerEngine.shared.stop()
                self.rowInPlay = -1
                self.lastInPlay = sender.tag
            } else {
                MusicPlayerEngine.shared.resumePlaying()
                self.rowInPlay = sender.tag
                self.lastInPlay = sender.tag
            }
        } else {
            MusicPlayerEngine.shared.play(id: sender.tag)
            self.selectedRow = sender.tag
            self.rowInPlay = sender.tag
            self.lastInPlay = sender.tag
        }
        
        self.reloadData()
    }
    
    // MARK: - Reload Delegate protocol
    
    func reloadTable() {
        MusicPlayerEngine.shared.stop()
        self.rowInPlay = -1
        self.selectedRow = -1
        
        self.reloadData()
    }
    
    func reloadTable(with index: Int) {
        self.selectedRow = index
        self.rowInPlay = index
        self.lastInPlay = index
        
        self.reloadData()
    }
    
    func reloadWithLast() {
        self.selectedRow = self.lastInPlay
        self.rowInPlay = self.lastInPlay
        
        self.reloadData()
    }
    
}
