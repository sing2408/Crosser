//
//  StartScene.swift
//  Crosser
//
//  Created by Singgih Tulus Makmud on 21/05/24.
//

import SpriteKit

class StartScene: SKScene {
    
    override func didMove(to view: SKView) {
        let highScoreLabel = self.childNode(withName: "//highScoreLabel") as? SKLabelNode
        
        // Retrieve and display the high score
        let highScore = UserDefaults.standard.integer(forKey: "HighScore")
        highScoreLabel?.text = "Longest Distance: \(highScore)"
        
        
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let scene = GameScene(fileNamed: "GameScene")
        scene!.scaleMode = .aspectFit
        self.view?.presentScene(scene)
    }
    
    
    
    
}
