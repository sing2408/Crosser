//
//  Car.swift
//  Crossyroad
//
//  Created by Singgih Tulus Makmud on 20/05/24.
//

import SpriteKit

class Car: SKSpriteNode {
    
    enum Direction {
        case left, right
    }
    
    static func createCar(direction: Direction) -> Car {
        let carImage = direction == .left ? "frame1" : "frame2"
        let car = Car(imageNamed: carImage)
        car.size = CGSize(width: 100, height: 50)
        
        // Set up physics body
        car.physicsBody = SKPhysicsBody(rectangleOf: car.size)
        car.physicsBody?.categoryBitMask = 0x10
        car.physicsBody?.collisionBitMask = 0
        car.physicsBody?.contactTestBitMask = 0x1
        car.physicsBody?.affectedByGravity = false
        
        car.run(car.moveAction(direction: direction))
        return car
    }
    
    func moveAction(direction: Direction) -> SKAction {
        guard let scene = self.scene else {
            return SKAction.removeFromParent() // Fallback action if scene is nil
        }
        
        let moveDistance = direction == .left ? -scene.size.width : scene.size.width
        let moveAction = SKAction.moveBy(x: moveDistance, y: 0, duration: 5.0)
        return SKAction.sequence([moveAction, SKAction.removeFromParent()])
    }

}

