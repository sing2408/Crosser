//
//  Character.swift
//  Crossyroad
//
//  Created by Singgih Tulus Makmud on 20/05/24.
//

import SpriteKit

class Character: SKSpriteNode {
    
    static func createCharacter() -> Character {
        let character = Character(imageNamed: "frame1")
        character.size = CGSize(width: 50, height: 50)
        
        var textures: [SKTexture] = []
        textures.append(SKTexture(imageNamed: "frame1"))
        textures.append(SKTexture(imageNamed: "frame2"))
        
        let animation = SKAction.animate(with: textures, timePerFrame: 0.1)
        let animationRepeat = SKAction.repeatForever(animation)
        character.run(animationRepeat)
        
        return character
    }

    enum Direction {
        case left, right, up, down
    }

    func move(direction: Direction) {
        let moveAction: SKAction
        switch direction {
        case .left:
            moveAction = SKAction.moveBy(x: -50, y: 0, duration: 0.1)
        case .right:
            moveAction = SKAction.moveBy(x: 50, y: 0, duration: 0.1)
        case .up:
            moveAction = SKAction.moveBy(x: 0, y: 50, duration: 0.1)
        case .down:
            moveAction = SKAction.moveBy(x: 0, y: -50, duration: 0.1)
        }
        self.run(moveAction)
    }
}
