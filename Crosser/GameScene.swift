//
//  GameScene.swift
//  Crossyroad
//
//  Created by Singgih Tulus Makmud on 20/05/24.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let characterCategory: UInt32 = 0x1
    let carCategory: UInt32 = 0x10

    // Character
    private var character: SKSpriteNode?
    private var characterTextures: [SKTexture] = []

    // Background
    let segmentHeight: CGFloat = 250.0
    let moveSpeed: CGFloat = 1.0
    var segmentQueue: [SKSpriteNode] = []
    var roadSegmentHasCar: [Int: Bool] = [:]

    // Gesture swipe
    private var startTouchPosition: CGPoint?
    private var endTouchPosition: CGPoint?

    override func didMove(to view: SKView) {
        self.physicsWorld.contactDelegate = self

        self.character = self.childNode(withName: "//character") as? SKSpriteNode

        characterTextures.append(SKTexture(imageNamed: "frame1"))
        characterTextures.append(SKTexture(imageNamed: "frame2"))

        let animation = SKAction.animate(with: characterTextures, timePerFrame: 0.1)
        let animationRepeat = SKAction.repeatForever(animation)
        character?.run(animationRepeat)

        // Set up physics body for character
        character?.physicsBody = SKPhysicsBody(rectangleOf: character?.size ?? CGSize.zero)
        character?.physicsBody?.categoryBitMask = characterCategory
        character?.physicsBody?.contactTestBitMask = carCategory
        character?.physicsBody?.collisionBitMask = carCategory
        character?.physicsBody?.affectedByGravity = false

        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        createInitialSegments()

        physicsWorld.gravity = CGVector(dx: 0, dy: -0.8)

        spawnCars()
    }

    override func update(_ currentTime: TimeInterval) {
        moveSegments()
    }

    func createInitialSegments() {
        let totalSegments = Int(ceil(self.size.height / segmentHeight)) + 2
        for i in 0..<totalSegments {
            let segment = createSegment(at: i)
            segmentQueue.append(segment)
            self.addChild(segment)
            roadSegmentHasCar[i] = false // Initialize the road segment as empty
        }
    }

    func createSegment(at index: Int) -> SKSpriteNode {
        let segment: SKSpriteNode
        if index % 2 == 0 {
            segment = SKSpriteNode(imageNamed: "road")
            segment.name = "road"
        } else {
            segment = SKSpriteNode(imageNamed: "grass")
            segment.name = "grass"
        }

        segment.size = CGSize(width: self.size.width, height: segmentHeight)
        segment.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        segment.position = CGPoint(x: 0, y: CGFloat(index) * segmentHeight - self.size.height / 2)
        segment.userData = ["index": index] // Store the index in userData
        return segment
    }

    func moveSegments() {
        for node in segmentQueue {
            node.position.y -= moveSpeed
        }

        character?.position.y -= moveSpeed

        // Move cars downwards
        enumerateChildNodes(withName: "car") { (node, _) in
            node.position.y -= self.moveSpeed
        }

        if let topSegment = segmentQueue.first, topSegment.position.y < -segmentHeight / 2 - self.size.height / 2 {
            let newTopPosition = segmentQueue.last!.position.y + segmentHeight
            topSegment.position.y = newTopPosition
            segmentQueue.append(topSegment)
            segmentQueue.removeFirst()
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            startTouchPosition = touch.location(in: self)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            endTouchPosition = touch.location(in: self)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let start = startTouchPosition, let end = endTouchPosition else {
            return
        }

        let dx = end.x - start.x
        let dy = end.y - start.y

        if abs(dx) > abs(dy) {
            if dx > 0 {
                moveCharacter(direction: .right)
            } else {
                moveCharacter(direction: .left)
            }
        } else {
            if dy > 0 {
                moveCharacter(direction: .up)
            } else {
                moveCharacter(direction: .down)
            }
        }

        startTouchPosition = nil
        endTouchPosition = nil
    }

    enum Direction {
        case left, right, up, down
    }

    func moveCharacter(direction: Direction) {
        let moveAction: SKAction
        switch direction {
        case .left:
            moveAction = SKAction.moveBy(x: -100, y: 0, duration: 0.1)
        case .right:
            moveAction = SKAction.moveBy(x: 100, y: 0, duration: 0.1)
        case .up:
            moveAction = SKAction.moveBy(x: 0, y: 100, duration: 0.1)
        case .down:
            moveAction = SKAction.moveBy(x: 0, y: -100, duration: 0.1)
        }
        character?.run(moveAction)
    }

    func spawnCars() {
        run(SKAction.repeatForever(SKAction.sequence([
            SKAction.run(spawnCar),
            SKAction.wait(forDuration: 3, withRange: 0.1)
        ])))
    }

    func spawnCar() {
        let car = SKSpriteNode(imageNamed: "frame1")
        car.name = "car"
        let carSize = CGSize(width: 100, height: 100)
        car.size = carSize

        // Determine side of the road for spawning
        let movesLeftToRight = Bool.random()
        var carX: CGFloat

        if movesLeftToRight {
            carX = -size.width / 2 - car.size.width / 2
        } else {
            carX = size.width / 2 + car.size.width / 2
            car.xScale = -1
        }

        // Check if the car is spawning on the road and ensure no other car is on the same segment
        let roadSegments = segmentQueue.filter { $0.name == "road" }
        if let roadSegment = roadSegments.randomElement(),
           let segmentIndex = roadSegment.userData?["index"] as? Int,
           roadSegmentHasCar[segmentIndex] == false {
            
            // Random Y position within the road segment
//            let randomY = CGFloat.random(in: 0...(segmentHeight - car.size.height))
//            let carY = roadSegment.position.y - segmentHeight / 2 + randomY
            car.position = CGPoint(x: carX, y: roadSegment.position.y)

            car.physicsBody = SKPhysicsBody(rectangleOf: car.size)
            car.physicsBody?.categoryBitMask = carCategory
            car.physicsBody?.contactTestBitMask = characterCategory
            car.physicsBody?.collisionBitMask = characterCategory
            car.physicsBody?.affectedByGravity = false

            addChild(car)

            // Mark the segment as having a car
            roadSegmentHasCar[segmentIndex] = true

            let distance = size.width + car.size.width
            let speed: CGFloat = 100.0
            let duration = distance / speed
            let directionFactor: CGFloat = movesLeftToRight ? 1 : -1
            let moveAction = SKAction.moveBy(x: distance * directionFactor, y: 0, duration: TimeInterval(duration))
            let removeAction = SKAction.run {
                car.removeFromParent()
                self.roadSegmentHasCar[segmentIndex] = false
            }
            car.run(SKAction.sequence([moveAction, removeAction]))
        }
    }

    func didBegin(_ contact: SKPhysicsContact) {
        let collision: UInt32 = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        // Check if collision occurs between character and car
        if collision == (characterCategory | carCategory) {
            print("Collision detected")
            character?.texture = SKTexture(imageNamed: "frame")
            
            // Create and present the GameOver scene
            if let scene = GameOver(fileNamed: "GameOver") {
                scene.win = false
                scene.scaleMode = .aspectFill
                let transition = SKTransition.push(with: .up, duration: 1.0)
                self.view?.presentScene(scene, transition: transition)
            }
        }
    }
}
