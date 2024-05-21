//
//  Segment.swift
//  Crossyroad
//
//  Created by Singgih Tulus Makmud on 20/05/24.
//

import SpriteKit

class Segment: SKSpriteNode {

    static func createSegment(at index: Int, sceneSize: CGSize) -> SKSpriteNode {
        let segment: SKSpriteNode
        if index % 2 == 0 {
            segment = SKSpriteNode(imageNamed: "road")
            segment.name = "road"
        } else {
            segment = SKSpriteNode(imageNamed: "grass")
            segment.name = "grass"
        }

        let segmentHeight: CGFloat = 250.0
        segment.size = CGSize(width: sceneSize.width, height: segmentHeight)
        segment.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        segment.position = CGPoint(x: 0, y: CGFloat(index) * segmentHeight - sceneSize.height / 2)
        return segment
    }
}


