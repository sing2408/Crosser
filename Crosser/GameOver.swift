//
//  GameOver.swift
//  Crosser
//
//  Created by Singgih Tulus Makmud on 21/05/24.
//

import SpriteKit

class GameOver: SKScene {
    
    public var win = true
    public var finalScore: Int = 0
    
    override func didMove(to view: SKView) {
        let label = self.childNode(withName: "//label") as? SKLabelNode
        let scoreLabel = self.childNode(withName: "//scoreLabel") as? SKLabelNode
        let highScoreLabel = self.childNode(withName: "//highScoreLabel") as? SKLabelNode
        
        if win == false {
            label?.text = "Better Luck Next Time"
        }
        
        scoreLabel?.text = "Distance: \(finalScore)"
        let highScore = UserDefaults.standard.integer(forKey: "HighScore")
        highScoreLabel?.text = "Longest Distance: \(highScore)"
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let scene = GameScene(fileNamed: "GameScene")
        scene!.scaleMode = .aspectFit
        self.view?.presentScene(scene)
    }
}
