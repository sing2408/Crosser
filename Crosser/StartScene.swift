//
//  StartScene.swift
//  Crosser
//
//  Created by Singgih Tulus Makmud on 21/05/24.
//

import SpriteKit
import AVFoundation

class StartScene: SKScene {
    
    var backgroundMusicPlayer: AVAudioPlayer?
    
    override func didMove(to view: SKView) {
        let highScoreLabel = self.childNode(withName: "//highScoreLabel") as? SKLabelNode
        
        // Retrieve and display the high score
        let highScore = UserDefaults.standard.integer(forKey: "HighScore")
        highScoreLabel?.text = "Longest Distance: \(highScore)"
        
        // Play background music
        playBackgroundMusic()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let scene = GameScene(fileNamed: "GameScene")
        scene!.scaleMode = .aspectFit
        self.view?.presentScene(scene)
    }
    
    func playBackgroundMusic() {
        // Get the URL of the background music file
        guard let url = Bundle.main.url(forResource: "bgmusic", withExtension: "mp3") else {
            print("Background music file not found")
            return
        }
        
        // Initialize the audio player with the background music file
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundMusicPlayer?.numberOfLoops = -1 // Loop indefinitely
            backgroundMusicPlayer?.play() // Start playing the background music
        } catch {
            print("Error playing background music: \(error)")
        }
    }
    
    override func willMove(from view: SKView) {
        // Stop playing background music when leaving the scene
        backgroundMusicPlayer?.stop()
    }
    
}
