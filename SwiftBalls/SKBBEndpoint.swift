//
//  SKBBEndpoint.swift
//  SwiftBalls
//
//  Created by Adrian Ruigrok on 2014-07-06.
//  Copyright (c) 2014 Cobey and Adrian not-Inc. All rights reserved.
//

import SpriteKit

class SKBBEndpoint: SKBBShapeNode {

    var line: SKBBLine?
    
    override func updateForTouch(_ touch: UITouch) {
        
        super.updateForTouch(touch)
        
        var newEndPoint: SKBBEndpoint?
        if let line = self.line {
            for otherEndpoint in line.endPoints {
                if (otherEndpoint != self) {
                    newEndPoint = otherEndpoint;
                }
            }
        }
        
        if let startPoint = newEndPoint {
            let run = startPoint.position.x - self.position.x
            let rise = startPoint.position.y - self.position.y
            let lineLength = CGFloat(sqrtf(Float(run*run+rise*rise)))
            let size = CGSize(width:lineLength, height:2)
            if let line = startPoint.line {
                line.size = size
                line.position = CGPoint(x:(startPoint.position.x + self.position.x) / 2 , y:(startPoint.position.y + self.position.y) / 2 )
                line.zRotation = CGFloat(atanf(Float(rise/run)))
                line.color = .blue
                if lineLength < 10 {
                    line.physicsBody = nil
                    return
                }
                let block = SKPhysicsBody(rectangleOf:size)
                line.physicsBody = block
                block.isDynamic = false
                block.affectedByGravity = false
                block.restitution = 1.2
                block.friction = 0.6
                block.contactTestBitMask = 1
                block.categoryBitMask = 2
            }
        }
    }

}
