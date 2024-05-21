//
//  GameOver.swift
//  Crossyroad
//
//  Created by Singgih Tulus Makmud on 20/05/24.
//

import SpriteKit
import GameplayKit

class GameOver: SKScene {
    
    public var win = true
    
    override func didMove(to view: SKView) {
        
    
        let label = self.childNode(withName: "//label") as? SKLabelNode
        if win == false {
            label?.text = "Better Luck next time"
        }
        }
        
       
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let scene = GameScene(fileNamed: "GameScene")
        scene!.scaleMode = .aspectFit
        self.view?.presentScene(scene)
    }
    
}
