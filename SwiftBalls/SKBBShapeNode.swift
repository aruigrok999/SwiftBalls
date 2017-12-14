//
//  SKBBShapeNode.swift
//  SwiftBalls
//
//  Created by Adrian Ruigrok on 2017-12-14.
//  Copyright © 2017 Adrian Ruigrok. All rights reserved.
//

import SpriteKit

class SKBBShapeNode: SKShapeNode {
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            updateForTouch(touch)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            updateForTouch(touch)
        }
    }

    func updateForTouch(_ touch: UITouch) {
        
        let location = touch.location(in: self)
        let previousLocation = touch.previousLocation(in: self)
        self.position = CGPoint(x: self.position.x + location.x - previousLocation.x,
                                y: self.position.y + location.y - previousLocation.y)
    }
}
