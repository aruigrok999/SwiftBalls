//
//  GameScene.swift
//  SwiftBalls
//
//  Created by Adrian Ruigrok on 2017-12-13.
//  Copyright © 2017 Adrian Ruigrok. All rights reserved.
//

import SpriteKit
import GameplayKit
import AudioToolbox

func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
    func sqrt(a: CGFloat) -> CGFloat {
        return CGFloat(sqrtf(Float(a)))
    }
#endif

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    private var newStartPoint : SKBBEndpoint?
    private var newEndPoint : SKBBEndpoint?
    private var soundIDs: [SystemSoundID]
    
    private let numberOfNotes = 17
    private var source: SKShapeNode
    private var hitNode: SKNode?
    
    required init?(coder aDecoder: NSCoder)
    {
        soundIDs = Array<SystemSoundID>(repeating: 0, count: numberOfNotes)
        
        let w = 24
        self.source = SKBBShapeNode.init(ellipseOf: CGSize(width: w, height: w))
        source.position = CGPoint(x: 0, y: 0)
        source.lineWidth = 2.5
        source.strokeColor = .green
        source.isUserInteractionEnabled = true
        
        super.init(coder: aDecoder)

        var oldGravity: CGVector = self.physicsWorld.gravity
        oldGravity.dy = -1
        self.physicsWorld.gravity = oldGravity
        self.physicsWorld.contactDelegate = self

        self.backgroundColor = SKColor(red: 125/255, green: 110/255, blue: 1, alpha: 1)

        for i in 0..<numberOfNotes
        {
            let soundURL = Bundle.main.url(forResource: "Note" + String(i+1), withExtension: "caf")
            if let safeSoundURL = soundURL
            {
                var systemSoundID: SystemSoundID = 0;
                AudioServicesCreateSystemSoundID(safeSoundURL as CFURL, &systemSoundID)
                self.soundIDs[i] = systemSoundID
            }
        }
    }

    override func didMove(to view: SKView) {
  
        self.addChild(source)

        let dropBall = SKAction.run({
            self.dropBallAt(location: self.source.position)
            
        })
        let actions = [dropBall, SKAction.wait(forDuration: 1.5)]
        let sequence = SKAction.sequence(actions)
        self.run(SKAction.repeatForever(sequence))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            hitNode = self.atPoint(touch.location(in: self))
            
            if hitNode as? SKShapeNode == nil && hitNode as? SKBBBall == nil {

                    let startPoint = createEndpoint(location:touch.location(in: self))
                    newStartPoint = startPoint
                    let endPoint = createEndpoint(location:touch.location(in: self))
                    newEndPoint = endPoint
                    let newLine = SKBBLine()
                    startPoint.line = newLine
                    endPoint.line = newLine
                    newLine.endPoints = [startPoint, endPoint]
                    addChild(newLine)
                    hitNode = newEndPoint
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            newEndPoint?.updateForTouch(touch)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            newEndPoint?.updateForTouch(touch)
            newEndPoint = nil;
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            newEndPoint?.updateForTouch(touch)
        }
        newEndPoint = nil;
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    func dropBallAt(location: CGPoint)
    {
        let sprite = SKBBBall(imageNamed: "SmallMarble")
        
        sprite.position = location
        sprite.xScale = 0.1
        sprite.yScale = 0.1
        sprite.isUserInteractionEnabled = false
        
        let body = SKPhysicsBody(circleOfRadius: 1.1)
        sprite.physicsBody = body
        body.mass = 10
        body.restitution = 0
        body.friction = 0.6
        body.contactTestBitMask = 1
        let angularVelocityMaxMin = CGFloat(3.14*2)
        body.angularVelocity = randomFloat(minimum: angularVelocityMaxMin, maximum: angularVelocityMaxMin)
        body.categoryBitMask = 1

        let action = SKAction.scale(by: 10, duration: 0.3)
        
        sprite.run(action)
        self.addChild(sprite)
    }

    func randomFloat(minimum: CGFloat, maximum:CGFloat) -> CGFloat
    {
        //        var result = CGFloat(UInt(arc4random() % RAND_MAX)))
        //        result = result / CGFloat(RAND_MAX)
        //        result = result * maximum-minimum + minimum
        
        return CGFloat(Float(arc4random()) / Float(UINT32_MAX))
    }
    
    func createEndpoint(location: CGPoint) -> SKBBEndpoint {
        let w = 10
        let endPoint = SKBBEndpoint.init(ellipseOf: CGSize(width: w*2, height: w*2))
        endPoint.position = location
        endPoint.strokeColor = .clear
        endPoint.isUserInteractionEnabled = true

        let dot = SKShapeNode.init(ellipseOf:CGSize(width: w, height: w))
        dot.lineWidth = 2.5
        dot.strokeColor = .red
        dot.fillColor = .blue
        dot.isUserInteractionEnabled = false
        endPoint.addChild(dot)
        self.addChild(endPoint)
        
        return endPoint
    }
    
    func didBegin(_ contact: SKPhysicsContact)
    {
        var line = contact.bodyA.node as? SKBBLine
        if (line == nil)
        {
            line = contact.bodyB.node as? SKBBLine
        }
        if let safeLine = line {
            let width = safeLine.size.width
            var index = 16 - Int(width) / 30    // Notes are 0-16, with 0 being the lowest note for lines over 500
            if index < 0 { index = 0 }
            
            AudioServicesPlaySystemSound(soundIDs[index]);
        }
    }

    
}
