//
//  ViewController.swift
//  PersonalProject
//
//  Created by Robbe Verhoest on 11/11/2019.
//  Copyright © 2019 Robbe Verhoest. All rights reserved.
//

import ARKit
import UIKit
import RealityKit
import Combine
import QuartzCore

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    @IBOutlet weak var overlayView: ARCoachingOverlayView!
    
    ///game view
    @IBOutlet weak var startGameButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var scoreLabel: UILabel!
    
    ///game over screen
    @IBOutlet weak var gameOverView: UIView!
    @IBOutlet weak var endScoreLabel: UILabel!
    @IBOutlet weak var endScoreView: UIView!
    @IBOutlet weak var playAgainButton: UIButton!
    
    var gameAnchor = AnchorEntity(plane: .horizontal)
    
    let coachingOverlay = ARCoachingOverlayView()
    
    var counter = 0.00
    var timerCountBridge = Timer()
    var timerAddPlatform = Timer()
    
    var randomDistance:Double = 0
    var randomWidth:Double = 5
    
    var score:Int = 0
    
    var platformArray: [Platform] = []
    var bridgeArray: [Bridge] = []
    
    ///starting platform
    var startPlatform = Platform(width: 0.05, heigth: 0.1, depth: 0.05, xPos1: 0, yPos1: 0.05, xPos2: 0.05, yPos2: 0, material: SimpleMaterial(color: .black, isMetallic: false))
    ///platform
    var newPlatform: Platform = Platform(width: 0.05, heigth: 0.1, depth: 0.05, xPos1: 0, yPos1: 0.05, xPos2: 0, yPos2: 0.05, material: SimpleMaterial(color: .black, isMetallic: false))
    ///bridge
    var bridge: Bridge = Bridge(width: 0.001, heigth: 0.0001, depth: 0.05, xPos1: 0.024, yPos1: 0.1, material: SimpleMaterial(color: .blue, isMetallic: true))
    ///player
    var player: Player = Player(width: 0.02, heigth: 0.02, depth: 0.02, xPos: 0, yPos: 0.11, material: SimpleMaterial(color: .white, isMetallic: true), moveDistance: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ///game buttons
        stopButton.isHidden = true
        startButton.isHidden = true
        ///score label
        scoreLabel.isHidden = true
        scoreLabel.layer.masksToBounds = true
        scoreLabel.layer.cornerRadius = 5
        ///game over view
        endScoreView.layer.masksToBounds = true
        endScoreView.layer.cornerRadius = 5
        gameOverView.isHidden = true
        
        ///timer
        stopButton.isEnabled = false
        ///end timer
    }
    
    @IBAction func startGame(_ sender: UIButton) {
        ///coaching overlay
        coachingOverlayViewWillActivate(overlayView)
        setupCoachingOverlay()
        coachingOverlayViewDidDeactivate(overlayView)
        
        ///game buttons
        startGameButton.isHidden = true
        scoreLabel.isHidden = false
        
        ///score
        score = 0
        scoreLabel.text = String(score)
        
        arView.scene.anchors.append(gameAnchor)
        
        createOcclusionFloor()
        addNullPlatform()
        addStartPlatform()
        addNullBridge()
        addBridge()
        addNewPlatform()
        addPlayer()
        print(platformArray.count)
    }
    
    @IBAction func startBridge(_ sender: UIButton) {
        ///game buttons
        startButton.isHidden = true
        stopButton.isHidden = false
        
        ///timer
        counter = 0.00
        
        startButton.isEnabled = false
        stopButton.isEnabled = true
        
        timerCountBridge = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        
//        gameAnchor.notifications.extrudeBridge.post()
        bridge.extrude()
    }
    
    @objc func updateTimer() {
        counter = counter + 0.1
    }
    
    @IBAction func stopBridge(_ sender: UIButton) {
        stopButton.isHidden = true
        
        ///timer
        startButton.isEnabled = true
        stopButton.isEnabled = false
        
        timerCountBridge.invalidate()
        
        print("\(randomDistance - 0.025 - (randomWidth/2)) < \((counter / 10) + 0.002) < \(randomDistance - 0.025 + (randomWidth/2))")

        bridge.rotate()
        
        ///check if bridge is good or bad
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.checkBridge()
        }
    }
    
    func checkBridge() {
        if (((counter / 10) + 0.002) > (randomDistance - 0.025 - (randomWidth/2))) && (((counter / 10) - 0.002) < randomDistance - 0.025 + (randomWidth/2)) {
            ///next level
            
            bridge.shorten()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                ///reset bridge positions
                ///self.bridge.rotateBack()
                
                ///animation to next platform
                self.platformArray.remove(at: 0)
                self.bridgeArray.remove(at: 0)
                self.addNewPlatform()
                self.platformArray[0].sink()
                self.bridgeArray[0].sink()
                self.platformArray[1].slide()
                self.platformArray[2].arise()
                
                ///game buttons
                self.startButton.isHidden = false
                
                ///score
                self.score = self.score + 1
                self.scoreLabel.text = String(self.score)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.addBridge()
                }
            }
            
        } else {
            ///game over view
            gameOverView.isHidden = false
            endScoreLabel.text = String(score)
        }
    }
    
    func addBridge() {
        bridge = Bridge(width: 0.001, heigth: 0.0001, depth: 0.05, xPos1: platformArray[1].width/2, yPos1: 0.1, material: SimpleMaterial(color: .white, isMetallic: true))
        bridge.add()
        gameAnchor.addChild(bridge.bridge)
        bridgeArray.append(bridge)
    }
    
    func addStartPlatform() {
        startPlatform = Platform(width: 0.05, heigth: 0.1, depth: 0.05, xPos1: 0, yPos1: 0.05, xPos2: 0, yPos2: 0.05, material: SimpleMaterial(color: .black, isMetallic: false))
        startPlatform.add()
        gameAnchor.addChild(startPlatform.platform)
        platformArray.append(startPlatform)
    }
    
    func addNewPlatform() {
        ///generate a random width and distance for new platform
        randomDistance = Double.random(in: 0.07...0.25)
        randomWidth = Double.random(in: 0.01...0.05)
        
        ///make a new platform
        newPlatform = Platform(width: randomWidth, heigth: 0.1, depth: 0.05, xPos1: 0.4, yPos1: -0.1, xPos2: randomDistance, yPos2: 0.05, material: SimpleMaterial(color: .red, isMetallic: false))
        newPlatform.add()
        gameAnchor.addChild(newPlatform.platform)
        newPlatform.arise()
        platformArray.append(newPlatform)
    }
    
    func createOcclusionFloor() {
        ///make a floor that hides stuff below
        let planeMesh = MeshResource.generatePlane(width: 5, depth: 5)
        let materialForOcclusion = OcclusionMaterial()
        let occlusionPlane = ModelEntity(mesh: planeMesh, materials: [materialForOcclusion])
        occlusionPlane.position.y = -0.001
        
        gameAnchor.addChild(occlusionPlane)
    }
    
    func addPlayer() {
        ///make a player
        player = Player(width: 0.02, heigth: 0.02, depth: 0.02, xPos: 0, yPos: 0.11, material: SimpleMaterial(color: .white, isMetallic: true), moveDistance: randomDistance)
    }
    
    @IBAction func playAgain(_ sender: UIButton) {
        ///hide game over view
        gameOverView.isHidden = true
        
        ///reset score
        score = 0
        scoreLabel.text = String(score)
        
        ///remove platforms
        ///reset starting platform or make a new one?
//        gameAnchor.startPlatform?.position.y = 0.05
//        gameAnchor.bridge?.position.x = 0.024
        
        
        ///game action buttons
        startButton.isHidden = false
        stopButton.isHidden = true
    }
    
    func addNullPlatform() {
        let nullPlatform = Platform(width: randomWidth, heigth: 0.1, depth: 0.05, xPos1: -0.15, yPos1: -0.1, xPos2: -0.15, yPos2: -0.1, material: SimpleMaterial(color: .red, isMetallic: false))
        platformArray.append(nullPlatform)
    }
    
    func addNullBridge() {
        let nullBridge = Bridge(width: randomWidth, heigth: 0.1, depth: 0.05, xPos1: -0.15, yPos1: -0.1, material: SimpleMaterial(color: .red, isMetallic: false))
        bridgeArray.append(nullBridge)
    }
    
}
