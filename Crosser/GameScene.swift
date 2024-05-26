//
//  GameScene.swift
//  Crosser
//
//  Created by Singgih Tulus Makmud on 21/05/24.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var audioPlayer: AVAudioPlayer?
    var backgroundMusicPlayer: AVAudioPlayer?
    
    let characterCategory: UInt32 = 0x1
    let obstacleCategory: UInt32 = 0x10
    
    var birdSpawnInterval: TimeInterval = 5.0
    let baseBirdSpawnInterval: TimeInterval = 5.0
    var birdSpeed: CGFloat = 300.0
    let minBirdSpawnInterval: TimeInterval = 0.5
    
    private var scoreLabel: SKLabelNode?
    private var score: Int = 0
    
    private var character: SKSpriteNode?
    private var characterTextures: [SKTexture] = []
    
    let segmentHeight: CGFloat = 250.0
    var moveSpeed: CGFloat = 1.0
    let baseMoveSpeed: CGFloat = 1.0
    let speedIncrement: CGFloat = 0.2
    var segmentQueue: [SKSpriteNode] = []
    var roadSegmentHasCar: [Int: Bool] = [:]
    
    var carSpawnInterval: TimeInterval = 3.0
    let baseCarSpawnInterval: TimeInterval = 3.0
    let spawnIntervalDecrement: TimeInterval = 0.2
    
    private var startTouchPosition: CGPoint?
    private var endTouchPosition: CGPoint?
    
    override func didMove(to view: SKView) {
        self.physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: -0.8)
        self.scene?.listener = character
        
        self.scoreLabel = self.childNode(withName: "//scorelabel") as? SKLabelNode
        self.character = self.childNode(withName: "//character") as? SKSpriteNode
        
        characterTextures.append(SKTexture(imageNamed: "frame1"))
        characterTextures.append(SKTexture(imageNamed: "frame2"))
        let animation = SKAction.animate(with: characterTextures, timePerFrame: 0.1)
        let animationRepeat = SKAction.repeatForever(animation)
        character?.run(animationRepeat)
        
        character?.physicsBody = SKPhysicsBody(rectangleOf: character?.size ?? CGSize.zero)
        character?.physicsBody?.categoryBitMask = characterCategory
        character?.physicsBody?.contactTestBitMask = obstacleCategory
        character?.physicsBody?.collisionBitMask = obstacleCategory
        character?.physicsBody?.affectedByGravity = false
        
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        createInitialSegments()
        spawnCars()
        playBackgroundMusic()
    }
    
    override func update(_ currentTime: TimeInterval) {
        updateSpeed()
        moveSegments()
        updateSounds()
        updateSpawnFrequency()
        checkCharacterPosition()
        
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
    
    func didBegin(_ contact: SKPhysicsContact) {
        let collision: UInt32 = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        if collision == (characterCategory | obstacleCategory) {
            print("Collision detected")
            
            playCollisionSound()
            character?.texture = SKTexture(imageNamed: "frame")
            endGame()
            
        }
    }
    
    override func willMove(from view: SKView) {
        backgroundMusicPlayer?.stop()
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
    
    func createInitialSegments() {
        let totalSegments = Int(ceil(self.size.height / segmentHeight)) + 2
        for i in 0..<totalSegments {
            let segment = createSegment(at: i)
            segmentQueue.append(segment)
            self.addChild(segment)
            roadSegmentHasCar[i] = false
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
        segment.userData = ["index": index]
        return segment
    }
    
    func moveSegments() {
        for node in segmentQueue {
            node.position.y -= moveSpeed
        }
        character?.position.y -= moveSpeed
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
    
    func spawnCars() {
        let spawnDelay: TimeInterval = 0.3
        let numberOfCarsToSpawn = 3
        
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
        let baseCarSpeed = CGFloat(100.0 + 5.0 * Double(score))
        let randomFactor = CGFloat.random(in: 0.5...1.5)
        let carSpeed = baseCarSpeed * randomFactor
        
        let car = SKSpriteNode(imageNamed: "car1")
        car.name = "car"
        let carSize = CGSize(width: 250, height: 150)
        car.size = carSize
        
        let hitboxSize = CGSize(width: carSize.width * 0.8, height: carSize.height * 0.8)
        
        let availableSegments = segmentQueue.filter { $0.name == "road" && !roadSegmentHasCar[$0.userData?["index"] as! Int, default: false] }
        guard let roadSegment = availableSegments.randomElement(),
              let segmentIndex = roadSegment.userData?["index"] as? Int else {
            DispatchQueue.main.async { [weak self] in
                self?.spawnCar()
            }
            return
        }
        
        let movesLeftToRight = Bool.random()
        var carX: CGFloat
        
        if movesLeftToRight {
            carX = -size.width / 2 - car.size.width / 2
            car.xScale = -1
        } else {
            carX = size.width / 2 + car.size.width / 2
        }
        
        car.position = CGPoint(x: carX, y: roadSegment.position.y)
        car.physicsBody = SKPhysicsBody(rectangleOf: hitboxSize)
        car.physicsBody?.categoryBitMask = obstacleCategory
        car.physicsBody?.contactTestBitMask = characterCategory
        car.physicsBody?.collisionBitMask = characterCategory
        car.physicsBody?.affectedByGravity = false
        
        let carSound = SKAudioNode(fileNamed: "carsound.mp3")
        carSound.autoplayLooped = true
        carSound.isPositional = true
        carSound.position = CGPoint(x: 0, y: 0)
        carSound.name = "carSound"
        car.addChild(carSound)
        
        carSound.run(SKAction.changeVolume(to: 0.1, duration: 0))
        addChild(car)
        
        roadSegmentHasCar[segmentIndex] = true
        
        let distance = size.width + car.size.width
        let duration = distance / carSpeed
        let directionFactor: CGFloat = movesLeftToRight ? 1 : -1
        
        let moveAction = SKAction.moveBy(x: distance * directionFactor, y: 0, duration: TimeInterval(duration))
        let removeAction = SKAction.run {
            car.removeFromParent()
            self.roadSegmentHasCar[segmentIndex] = false
        }
        car.run(SKAction.sequence([moveAction, removeAction]))
    }
    
    func spawnBird() {
        let isLeftSide = Bool.random()
        let randomX: CGFloat
        if isLeftSide {
            randomX = CGFloat.random(in: -self.size.width/2...(-self.size.width/4))
        } else {
            randomX = CGFloat.random(in: self.size.width/4...self.size.width/2)
        }
        
        playBirdSoundCue(at: randomX)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [self] in
            let bird = SKSpriteNode(imageNamed: "bird1")
            bird.name = "bird"
            let birdSize = CGSize(width: 200, height: 200)
            bird.size = birdSize
            
            let initialY = self.size.height / 2
            bird.position = CGPoint(x: randomX, y: initialY)
            bird.zPosition = 1000
            
            bird.physicsBody = SKPhysicsBody(rectangleOf: bird.size)
            bird.physicsBody?.categoryBitMask = obstacleCategory
            bird.physicsBody?.contactTestBitMask = characterCategory
            bird.physicsBody?.collisionBitMask = characterCategory
            bird.physicsBody?.affectedByGravity = false
            
            let flapSound = SKAudioNode(fileNamed: "flapsound.mp3")
            flapSound.autoplayLooped = true
            flapSound.isPositional = true
            flapSound.position = CGPoint(x: 0, y: 0)
            flapSound.name = "flapSound"
            bird.addChild(flapSound)
            self.addChild(bird)
            
            let distance = self.size.height
            let duration = distance / self.birdSpeed
            let moveAction = SKAction.moveBy(x: 0, y: -distance, duration: TimeInterval(duration))
            let removeAction = SKAction.removeFromParent()
            let sequence = SKAction.sequence([moveAction, removeAction])
            bird.run(sequence)
        }
    }
    
    func updateSounds() {
        guard let character = character else { return }
        
        enumerateChildNodes(withName: "car") { car, _ in
            if let carSound = car.childNode(withName: "carSound") as? SKAudioNode {
                let distance = hypot(car.position.x - character.position.x, car.position.y - character.position.y)
                let maxDistance: CGFloat = 500.0
                let volume = max(1.0 - (distance / maxDistance), 0.0)
                carSound.run(SKAction.changeVolume(to: Float(volume), duration: 0.1))
            }
        }
        
        enumerateChildNodes(withName: "bird") { bird, _ in
            if let flapSound = bird.childNode(withName: "flapSound") as? SKAudioNode {
                let distance = hypot(bird.position.x - character.position.x, bird.position.y - character.position.y)
                let maxDistance: CGFloat = 600.0
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
    }
    
    func updateSpawnFrequency() {
        if score >= 10 {
            carSpawnInterval = max(baseCarSpawnInterval - spawnIntervalDecrement * TimeInterval(score / 10), 0.5)
        } else {
            carSpawnInterval = baseCarSpawnInterval
        }
        
        if let spawnCarsAction = action(forKey: "spawnCarsAction") {
            spawnCarsAction.duration = carSpawnInterval
        } else {
            let spawnAction = SKAction.sequence([
                SKAction.run(spawnCar),
                SKAction.wait(forDuration: carSpawnInterval, withRange: 0.1)
            ])
            run(SKAction.repeatForever(spawnAction), withKey: "spawnCarsAction")
        }
        
        birdSpawnInterval = baseBirdSpawnInterval/2
        
        if score >= 20{
            
            if let spawnBirdsAction = action(forKey: "spawnBirdsAction") {
                spawnBirdsAction.duration = birdSpawnInterval
            } else {
                let spawnAction = SKAction.sequence([
                    SKAction.run(spawnBird),
                    SKAction.wait(forDuration: birdSpawnInterval, withRange: 0.1)
                ])
                run(SKAction.repeatForever(spawnAction), withKey: "spawnBirdsAction")
            }
        }
    }
    
    func updateHighScore() {
        let highScore = UserDefaults.standard.integer(forKey: "HighScore")
        if score > highScore {
            UserDefaults.standard.set(score, forKey: "HighScore")
        }
    }
    
    func playCollisionSound() {
        guard let url = Bundle.main.url(forResource: "hitsound", withExtension: "mp3") else {
            print("Sound file not found")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            print("Collision sound played")
        } catch {
            print("Error playing sound: \(error)")
        }
    }
    
    func playBackgroundMusic() {
        guard let url = Bundle.main.url(forResource: "bgmusic", withExtension: "mp3") else {
            print("Background music file not found")
            return
        }
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundMusicPlayer?.numberOfLoops = -1
            backgroundMusicPlayer?.volume = 0.1
            backgroundMusicPlayer?.play()
        } catch {
            print("Error playing background music: \(error)")
        }
    }
    
    func playBirdSoundCue(at xPosition: CGFloat) {
        let birdSound = SKAudioNode(fileNamed: "birdsound.mp3")
        birdSound.autoplayLooped = false
        birdSound.isPositional = true
        birdSound.position = CGPoint(x: xPosition, y: 0)
        addChild(birdSound)
        birdSound.run(SKAction.play())
    }
    
    func checkCharacterPosition() {
        guard let character = character else { return }
        
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
    
    func endGame() {
        updateHighScore()
        
        if let scene = GameOver(fileNamed: "GameOver") {
            scene.finalScore = score
            scene.win = false
            scene.scaleMode = .aspectFill
            let transition = SKTransition.push(with: .down, duration: 3.0)
            self.view?.presentScene(scene, transition: transition)
        }
    }
    
}
