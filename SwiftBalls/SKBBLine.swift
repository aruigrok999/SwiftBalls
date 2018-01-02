//
//  SKBBLine.swift
//  SwiftBalls
//
//  Created by Adrian Ruigrok on 2014-07-05.
//  Copyright (c) 2014 Cobey and Adrian not-Inc. All rights reserved.
//

import SpriteKit

class SKBBLine: SKSpriteNode {
    var endPoints: [SKBBEndpoint] = []
    var letterNode: SKLabelNode?
    var letter: String?
    var index = 0
}
