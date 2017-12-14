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
        
        super.init(coder: aDecoder)

        var oldGravity: CGVector = self.physicsWorld.gravity
        oldGravity.dy = -1
        self.physicsWorld.gravity = oldGravity
        self.physicsWorld.contactDelegate = self

        self.backgroundColor = SKColor(red: 125/255, green: 110/255, blue: 1, alpha: 1)
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
            
            let hitShapeNode = hitNode as? SKShapeNode
            if hitShapeNode == nil {

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
            updateForTouch(touch)
        }
    }
    
    func updateForTouch(_ touch: UITouch) {
        
        if let nodeActuallyHit = hitNode {
            let location = touch.location(in: self)
            let previousLocation = touch.previousLocation(in: self)
            nodeActuallyHit.position = CGPoint(x: nodeActuallyHit.position.x + location.x - previousLocation.x,
                                               y: nodeActuallyHit.position.y + location.y - previousLocation.y)
        }
        
        if let endPoint = hitNode as? SKBBEndpoint, let startPoint = newStartPoint {
            let run = startPoint.position.x - endPoint.position.x
            let rise = startPoint.position.y - endPoint.position.y
            let lineLength = CGFloat(sqrtf(Float(run*run+rise*rise)))
            let size = CGSize(width:lineLength, height:2)
            if let line = startPoint.line {
                line.size = size
                line.position = CGPoint(x:(startPoint.position.x + endPoint.position.x) / 2 , y:(startPoint.position.y + endPoint.position.y) / 2 )
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
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            updateForTouch(touch)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            updateForTouch(touch)
        }
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
    
}
