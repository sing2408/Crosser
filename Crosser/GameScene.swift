import SpriteKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let characterCategory: UInt32 = 0x1
    let carCategory: UInt32 = 0x10
    
    // Bird spawn frequency
    var birdSpawnInterval: TimeInterval = 5.0 // Initial bird spawn interval
    let baseBirdSpawnInterval: TimeInterval = 5.0 // Base bird spawn interval
    var birdSpeed: CGFloat = 300.0 // Adjust the bird falling speed as needed
    
    // Score
    private var scoreLabel: SKLabelNode?
    private var score: Int = 0
    
    // Character
    private var character: SKSpriteNode?
    private var characterTextures: [SKTexture] = []
    
    // Background
    let segmentHeight: CGFloat = 250.0
    var moveSpeed: CGFloat = 1.0
    let baseMoveSpeed: CGFloat = 1.0
    let speedIncrement: CGFloat = 0.5
    var segmentQueue: [SKSpriteNode] = []
    var roadSegmentHasCar: [Int: Bool] = [:]
    
    // Car spawn frequency
    var carSpawnInterval: TimeInterval = 3.0
    let baseCarSpawnInterval: TimeInterval = 3.0
    let spawnIntervalDecrement: TimeInterval = 0.5
    
    // Gesture swipe
    private var startTouchPosition: CGPoint?
    private var endTouchPosition: CGPoint?
    
    override func didMove(to view: SKView) {
        self.physicsWorld.contactDelegate = self
        
        self.scoreLabel = self.childNode(withName: "//scorelabel") as? SKLabelNode
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
        
        // Set the listener for positional audio
        self.scene?.listener = character
        
        spawnCars()
    }
    
    func spawnBird() {
        // Play sound cue indicating the bird's upcoming appearance
        playBirdSoundCue()
        
        // Delay the actual spawning of the bird after the sound cue
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [self] in
            let bird = SKSpriteNode(imageNamed: "bird1")
            bird.name = "bird"
            let birdSize = CGSize(width: 200, height: 200)
            bird.size = birdSize
            // Set the position of the bird
            let randomX = CGFloat.random(in: -self.size.width/2...self.size.width/2)
            let initialY = self.size.height / 2 // Set the initial Y position to the top of the screen
            bird.position = CGPoint(x: randomX, y: initialY)
            
            // Set the zPosition of the bird to be the highest
            bird.zPosition = 1000
            
            // Add physics body for collision detection if needed
            bird.physicsBody = SKPhysicsBody(rectangleOf: bird.size)
            bird.physicsBody?.categoryBitMask = carCategory
            bird.physicsBody?.contactTestBitMask = characterCategory
            bird.physicsBody?.collisionBitMask = characterCategory
            bird.physicsBody?.affectedByGravity = false
            
            // Add flap sound to the bird
            let flapSound = SKAudioNode(fileNamed: "flapsound.mp3")
            flapSound.autoplayLooped = true
            flapSound.isPositional = true // Enable positional audio
            flapSound.position = CGPoint(x: 0, y: 0) // Ensure the sound is centered on the car
            flapSound.name = "flapSound"
            bird.addChild(flapSound)
            
            // Add the bird node to the scene
            self.addChild(bird)
            
            // Calculate the duration for the bird's movement
            let distance = self.size.height // Distance the bird will travel
            let duration = distance / self.birdSpeed // Duration based on birdSpeed
            
            // Set up actions for the bird's movement and removal
            let moveAction = SKAction.moveBy(x: 0, y: -distance, duration: TimeInterval(duration))
            let removeAction = SKAction.removeFromParent()
            let sequence = SKAction.sequence([moveAction, removeAction])
            bird.run(sequence)
        }
    }
    
    
    
    func playBirdSoundCue() {
        // Create an audio node for the bird sound
        let birdSound = SKAudioNode(fileNamed: "birdsound.mp3")
        birdSound.autoplayLooped = false
        birdSound.isPositional = true // Enable positional audio
        birdSound.position = CGPoint(x: 0, y: 0) // Set position relative to the listener
        
        // Add the sound node to the scene
        addChild(birdSound)
        
        // Run the sound action
        birdSound.run(SKAction.play())
    }


    
    
    
    override func update(_ currentTime: TimeInterval) {
        updateSpeed() // Call updateSpeed() at the beginning of each frame update
        moveSegments()
        updateSounds()
        scoreLabel?.text = "Distance: \(score)"
        updateSpawnFrequency()
        
        
        // Check if the character goes out of bounds
        if let character = character {
            let halfWidth = character.size.width / 2
            let halfHeight = character.size.height / 2
            let maxX = size.width / 2 - halfWidth
            let minX = -size.width / 2 + halfWidth
            let maxY = size.height / 2 - halfHeight
            let minY = -size.height / 2 + halfHeight
            
            if character.position.x > maxX {
                character.position.x = maxX
            } else if character.position.x < minX {
                character.position.x = minX
            }
            
            if character.position.y > maxY {
                character.position.y = maxY
            } else if character.position.y < minY {
                endGame()
            }
        }
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
            moveAction = SKAction.moveBy(x: -125, y: 0, duration: 0.1)
        case .right:
            moveAction = SKAction.moveBy(x: 125, y: 0, duration: 0.1)
        case .up:
            moveAction = SKAction.moveBy(x: 0, y: 125, duration: 0.1)
            score += 1
        case .down:
            moveAction = SKAction.moveBy(x: 0, y: -125, duration: 0.1)
            score -= 1
        }
        scoreLabel?.text = "Distance: \(score)"
        character?.run(moveAction)
    }
    
    
    func spawnCars() {
        let spawnDelay: TimeInterval = 0.5 // Adjust this value to control the delay between car spawns
        let numberOfCarsToSpawn = 3 // Adjust the number of cars to spawn
        
        // Spawn cars with a delay
        for i in 0..<numberOfCarsToSpawn {
            let spawnAction = SKAction.sequence([
                SKAction.wait(forDuration: TimeInterval(i) * spawnDelay),
                SKAction.run {
                    self.spawnCar()
                }
            ])
            run(spawnAction)
        }
    }
    
    
    func spawnCar() {
        // Calculate the base speed of the car based on the score
        let baseCarSpeed = CGFloat(100.0 + 10.0 * Double(score))
        
        // Introduce a random factor to the car speed
        let randomFactor = CGFloat.random(in: 0.5...1.5) // Adjust the range of the random factor as desired
        
        // Calculate the final speed of the car
        let carSpeed = baseCarSpeed * randomFactor
        
        // Create the car node and set its properties
        let car = SKSpriteNode(imageNamed: "car1")
        car.name = "car"
        let carSize = CGSize(width: 250, height: 150)
        car.size = carSize
        
        // Randomly select a road segment for car spawn
        let availableSegments = segmentQueue.filter { $0.name == "road" && !roadSegmentHasCar[$0.userData?["index"] as! Int, default: false] }
        guard let roadSegment = availableSegments.randomElement(),
              let segmentIndex = roadSegment.userData?["index"] as? Int else {
            // No available road segment for spawning, retry in the next frame
            DispatchQueue.main.async { [weak self] in
                self?.spawnCar()
            }
            return
        }
        
        // Determine the side of the road for spawning
        let movesLeftToRight = Bool.random()
        var carX: CGFloat
        
        if movesLeftToRight {
            carX = -size.width / 2 - car.size.width / 2
            car.xScale = -1
        } else {
            carX = size.width / 2 + car.size.width / 2
        }
        
        // Set the position of the car
        car.position = CGPoint(x: carX, y: roadSegment.position.y)
        
        // Set up physics body for the car
        car.physicsBody = SKPhysicsBody(rectangleOf: car.size)
        car.physicsBody?.categoryBitMask = carCategory
        car.physicsBody?.contactTestBitMask = characterCategory
        car.physicsBody?.collisionBitMask = characterCategory
        car.physicsBody?.affectedByGravity = false
        
        // Add stereo panning sound
        let carSound = SKAudioNode(fileNamed: "carsound.mp3")
        carSound.autoplayLooped = true
        carSound.isPositional = true // Enable positional audio
        carSound.position = CGPoint(x: 0, y: 0) // Ensure the sound is centered on the car
        carSound.name = "carSound"
        car.addChild(carSound)
        
        // Set the initial volume of the car sound to a lower value
        carSound.run(SKAction.changeVolume(to: 0.1, duration: 0)) // Set the volume to 30% of the original volume
        
        // Add the car node to the scene
        addChild(car)
        
        // Mark the segment as having a car
        roadSegmentHasCar[segmentIndex] = true
        
        // Calculate the distance and duration for the car's movement
        let distance = size.width + car.size.width
        let duration = distance / carSpeed
        let directionFactor: CGFloat = movesLeftToRight ? 1 : -1
        
        // Set up actions for the car's movement and removal
        let moveAction = SKAction.moveBy(x: distance * directionFactor, y: 0, duration: TimeInterval(duration))
        let removeAction = SKAction.run {
            car.removeFromParent()
            self.roadSegmentHasCar[segmentIndex] = false
        }
        car.run(SKAction.sequence([moveAction, removeAction]))
    }
    
    func updateSounds() {
        guard let character = character else { return }
        
        enumerateChildNodes(withName: "car") { car, _ in
            if let carSound = car.childNode(withName: "carSound") as? SKAudioNode {
                let distance = hypot(car.position.x - character.position.x, car.position.y - character.position.y)
                let maxDistance: CGFloat = 300.0 // Maximum distance for the sound to be heard
                let volume = max(1.0 - (distance / maxDistance), 0.0)
                carSound.run(SKAction.changeVolume(to: Float(volume), duration: 0.1))
            }
        }
        
        enumerateChildNodes(withName: "bird") { bird, _ in
                if let flapSound = bird.childNode(withName: "flapSound") as? SKAudioNode {
                    let distance = hypot(bird.position.x - character.position.x, bird.position.y - character.position.y)
                    let maxDistance: CGFloat = 600.0 // Maximum distance for the sound to be heard
                    let volume = max(1.0 - (distance / maxDistance), 0.0)
                    flapSound.run(SKAction.changeVolume(to: Float(volume), duration: 0.1))
                }
            }
    }
    
    func updateSpeed() {
        if score >= 10 {
            moveSpeed = baseMoveSpeed + speedIncrement * CGFloat(score / 10)
        } else {
            moveSpeed = baseMoveSpeed
        }
        print("Current moveSpeed: \(moveSpeed)") // Print out the moveSpeed value
    }
    
    
    func updateSpawnFrequency() {
        if score >= 10 {
            carSpawnInterval = max(baseCarSpawnInterval - spawnIntervalDecrement * TimeInterval(score / 10), 0.5)
        } else {
            carSpawnInterval = baseCarSpawnInterval
        }
        
        // Update the duration of the existing car spawning action
        if let spawnCarsAction = action(forKey: "spawnCarsAction") {
            spawnCarsAction.duration = carSpawnInterval
        } else {
            // If the action doesn't exist, create it
            let spawnAction = SKAction.sequence([
                SKAction.run(spawnCar),
                SKAction.wait(forDuration: carSpawnInterval, withRange: 0.1)
            ])
            run(SKAction.repeatForever(spawnAction), withKey: "spawnCarsAction")
        }
        
        // Update the duration of the existing bird spawning action
        if let spawnBirdsAction = action(forKey: "spawnBirdsAction") {
            spawnBirdsAction.duration = birdSpawnInterval
        } else {
            // If the action doesn't exist, create it
            let spawnAction = SKAction.sequence([
                SKAction.run(spawnBird),
                SKAction.wait(forDuration: birdSpawnInterval, withRange: 0.1)
            ])
            run(SKAction.repeatForever(spawnAction), withKey: "spawnBirdsAction")
        }
    }
    
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        let collision: UInt32 = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        // Check if collision occurs between character and car
        if collision == (characterCategory | carCategory) {
            print("Collision detected")
            character?.texture = SKTexture(imageNamed: "frame")
            
            // Update high score
            updateHighScore()
            
            // Create and present the GameOver scene
            if let scene = GameOver(fileNamed: "GameOver") {
                scene.finalScore = score
                scene.win = false
                scene.scaleMode = .aspectFill
                let transition = SKTransition.push(with: .up, duration: 1.0)
                self.view?.presentScene(scene, transition: transition)
            }
        }
    }
    
    func endGame() {
        // Update high score
        updateHighScore()
        
        // Create and present the GameOver scene
        if let scene = GameOver(fileNamed: "GameOver") {
            scene.finalScore = score
            scene.win = false
            scene.scaleMode = .aspectFill
            let transition = SKTransition.push(with: .down, duration: 1.0)
            self.view?.presentScene(scene, transition: transition)
        }
    }
    
    func updateHighScore() {
        let highScore = UserDefaults.standard.integer(forKey: "HighScore")
        if score > highScore {
            UserDefaults.standard.set(score, forKey: "HighScore")
        }
    }
    
    
    
}

