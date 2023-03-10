//
//  CarPlayMusic.swift
//  CarPlayMusic
//
//  Created by Amerigo Mancino on 07/10/22.
//

import UIKit
import CarPlay

class CarPlayMusic {

    private var interfaceController: CPInterfaceController?
    
    // MARK: - Lifecycle methods
    
    init(interface: CPInterfaceController?) {
        self.interfaceController = interface
    }
    
    // MARK: - Public methods
    
    public func drawList() -> CPListTemplate {
        let songs = MusicPlayerEngine.shared.getSongList()
        
        var items: [CPListItem] = []
        
        for (index, song) in songs.enumerated() {
            let item = CPListItem(
                text: song.title,
                detailText: song.author,
                image: song.image,
                accessoryImage: nil,
                accessoryType: .disclosureIndicator
            )
            
            item.handler = { [self] _ , completion in
                MusicPlayerEngine.shared.reloadDelegate?.reloadTable(with: index)
                MusicPlayerEngine.shared.play(id: index)
                
                guard interfaceController?.topTemplate != CPNowPlayingTemplate.shared else {
                    return
                }
                
                #if targetEnvironment(simulator)
                UIApplication.shared.endReceivingRemoteControlEvents()
                UIApplication.shared.beginReceivingRemoteControlEvents()
                #endif
                
                interfaceController?.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: nil)
                completion()
            }
            
            items.append(item)
        }
        
        let section = CPListSection(items: items, header: "Music", sectionIndexTitle: nil)
        let template = CPListTemplate(title: "Music", sections: [section])
        template.tabImage = UIImage(systemName: "music.note")!
        return template
    }
    
}
