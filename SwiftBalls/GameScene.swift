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
import CoreMotion

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
    private var automaticallyDroppingBalls = false
    
    let motionManager = CMMotionManager()
    var timer: Timer!
    var dragStartLocation = CGPoint(x:0, y:0)
    
    required init?(coder aDecoder: NSCoder)
    {
        soundIDs = Array<SystemSoundID>(repeating: 0, count: numberOfNotes)
        
        let w = 24
        source = SKBBShapeNode.init(ellipseOf: CGSize(width: w, height: w))
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
        
        motionManager.startAccelerometerUpdates()
    }

    override func didMove(to view: SKView) {
  
        self.addChild(source)
        
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(tap))
        tapGR.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapGR)

        let doubleTapGR = UITapGestureRecognizer(target: self, action: #selector(doubleTap))
        doubleTapGR.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGR)

//        let panGR = UIPanGestureRecognizer(target: self, action: #selector(pan))
//        view.addGestureRecognizer(panGR)

        automaticallyDropBalls()
    }
    
    func automaticallyDropBalls() {
        let dropBall = SKAction.run({
            self.dropBallAt(location: self.source.position)
            
        })
        let actions = [dropBall, SKAction.wait(forDuration: 1.5)]
        let sequence = SKAction.sequence(actions)
        self.run(SKAction.repeatForever(sequence))
        automaticallyDroppingBalls = true
    }
    
    @objc func tap(sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            var touchLocation: CGPoint = sender.location(in: sender.view)
            touchLocation = self.convertPoint(fromView: touchLocation)
            let hitNodes = self.nodes(at: touchLocation)
            for hitNode in hitNodes {
                if hitNode == source {
                    self.dropBallAt(location: self.source.position)
                }
            }
        }
    }
    
    @objc func pan(sender: UIPanGestureRecognizer) {
            var touchLocation: CGPoint = sender.location(in: sender.view)
            touchLocation = self.convertPoint(fromView: touchLocation)
            let hitNodes = self.nodes(at: touchLocation)
            for hitNode in hitNodes {
                print(hitNode)
            }
    }
    
    @objc func doubleTap(sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            
            var touchLocation: CGPoint = sender.location(in: sender.view)
            touchLocation = self.convertPoint(fromView: touchLocation)
            let hitNodes = self.nodes(at: touchLocation)
            print(hitNodes)
            if hitNodes.count == 0 {
                if automaticallyDroppingBalls {
                    self.removeAllActions()
                    automaticallyDroppingBalls = false;
                } else {
                    automaticallyDropBalls()
                }
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            dragStartLocation = touch.location(in: self)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            let run = dragStartLocation.x - location.x
            let rise = dragStartLocation.y - location.y
            let lineLength = CGFloat(sqrtf(Float(run*run+rise*rise)))

            if (newEndPoint == nil && lineLength > 30) {
                let hitNodes = self.nodes(at: touch.location(in: self))
                if hitNodes.count == 0 {
                    let startPoint = createEndpoint(location:dragStartLocation)
                    newStartPoint = startPoint
                    let endPoint = createEndpoint(location:location)
                    newEndPoint = endPoint
                    let newLine = SKBBLine()
                    startPoint.line = newLine
                    endPoint.line = newLine
                    newLine.endPoints = [startPoint, endPoint]
                    addChild(newLine)
                    addChild(startPoint)
                    addChild(endPoint)
                }
            }
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
        let orientation = UIDevice.current.orientation
        
        if let accelerometerData = motionManager.accelerometerData {
            var acceleration = accelerometerData.acceleration
            switch orientation {
            case .landscapeLeft:
                acceleration.x = -accelerometerData.acceleration.y
                acceleration.y = accelerometerData.acceleration.x
                acceleration.z = 0
            case .landscapeRight:
                acceleration.x = accelerometerData.acceleration.y
                acceleration.y = -accelerometerData.acceleration.x
                acceleration.z = 0
            default:
                acceleration = accelerometerData.acceleration
            }
            if acceleration.y < 0.01 && acceleration.x < 0.01 { // make sure we have some acceleration
                acceleration.y = -0.1
            }
            
            physicsWorld.gravity = CGVector(dx: acceleration.x * 9.8, dy: acceleration.y * 9.8)
        }
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
        let w = 12
        let endPoint = SKBBEndpoint.init(ellipseOf: CGSize(width: w*2, height: w*2))
        endPoint.position = location
        endPoint.strokeColor = .clear
        endPoint.isUserInteractionEnabled = true

        let dotWidth = 3
        let dot = SKShapeNode.init(ellipseOf:CGSize(width: dotWidth, height: dotWidth))
        dot.lineWidth = 2
        dot.strokeColor = .red
        dot.fillColor = .blue
        dot.isUserInteractionEnabled = false
        endPoint.addChild(dot)
        
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
