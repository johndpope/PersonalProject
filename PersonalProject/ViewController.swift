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
    @IBOutlet weak var startGameButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    
    ///game over screen
    @IBOutlet weak var gameOverView: UIView!
    @IBOutlet weak var endScoreLabel: UILabel!
    @IBOutlet weak var endScoreView: UIView!
    @IBOutlet weak var playAgainButton: UIButton!
    
    var gameAnchor:Experience.Game!
    
    let coachingOverlay = ARCoachingOverlayView()
    
    var counter = 0.00
    var timerCountBridge = Timer()
    var timerAddPlatform = Timer()
    
    var randomDistance:Double = 0
    var randomWidth:Double = 5
    
    var score:Int = 0
    
    ///platform
    var platformMesh: MeshResource?
    var platformMaterial: SimpleMaterial?
    var newPlatform: ModelEntity?
    ///player
    var playerMesh: MeshResource?
    var playerMaterial: SimpleMaterial?
    var player: ModelEntity?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gameAnchor = try! Experience.loadGame()
        
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
        timeLabel.text = String(counter)
        stopButton.isEnabled = false
        ///end timer
                
        gameAnchor.notifications.hideAtStart.post()
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
        
        gameAnchor.notifications.gameStart.post()
        
        createOcclusionFloor()
        addNewPlatform()
        addPlayer()
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
        
        gameAnchor.notifications.extrudeBridge.post()
    }
    
    @objc func updateTimer() {
        counter = counter + 0.1
        timeLabel.text = String(format: "%.1f", counter)
    }
    
    @IBAction func stopBridge(_ sender: UIButton) {
        stopButton.isHidden = true
        
        ///timer
        startButton.isEnabled = true
        stopButton.isEnabled = false
        
        timerCountBridge.invalidate()
        
        print("\(randomDistance - 0.025 - (randomWidth/2)) < \((counter / 10) + 0.002) < \(randomDistance - 0.025 + (randomWidth/2))")

        ///stop building bridge
        gameAnchor.bridge?.stopAllAnimations(recursive: true)
        gameAnchor.notifications.pauseAndRotate.post()
        
        ///check if bridge is good or bad
        timerAddPlatform = Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(self.checkBridge), userInfo: nil, repeats: false)
    }
    
    @objc func checkBridge() {
        if (((counter / 10) + 0.008) > (randomDistance - 0.025 - (randomWidth/2))) && (((counter / 10) - 0.008) < randomDistance - 0.025 + (randomWidth/2)) {
            ///next level
            timeLabel.text = "YOU MADE IT"
            
            resetBridge()
            
            ///delete starting platform
            gameAnchor.startPlatform?.position.y = -10
            
            ///move next platform to start position
            newPlatform?.position.x = 0
            
            ///add a new platform
            addNewPlatform()
            
            ///score
            score = score + 1
            scoreLabel.text = String(score)
            
            ///game buttons
            startButton.isHidden = false
            
        } else {
            ///game over
            timeLabel.text = "GAME OVER"
            
            ///game over view
            gameOverView.isHidden = false
            endScoreLabel.text = String(score)
        }
    }
    
    func resetBridge() {
        ///reset bridge positions
        gameAnchor.bridge?.position.x = Float(randomWidth / 2)
        gameAnchor.bridge?.transform.rotation = simd_quatf(angle: GLKMathDegreesToRadians(90), axis: SIMD3(x: 0, y: 0, z: 1))
        gameAnchor.bridge?.position.y = 0.1
    }
    
    @objc func addNewPlatform() {
        ///generate a random width and distance for new platform
        randomDistance = Double.random(in: 0.07...0.25)
        randomWidth = Double.random(in: 0.01...0.05)
        
        ///make a new platform
        platformMesh = MeshResource.generateBox(width: Float(randomWidth), height: 0.1, depth: 0.05)
        platformMaterial = SimpleMaterial(color: .red, isMetallic: false)
        newPlatform = ModelEntity(mesh: platformMesh!, materials: [platformMaterial!])
        newPlatform!.position.x = Float(randomDistance)
        newPlatform!.position.y = 0.05
        
        gameAnchor.addChild(newPlatform!)
    }
    
    func createOcclusionFloor() {
        ///make a floor that hides stuff below
        let planeMesh = MeshResource.generatePlane(width: 0.5, depth: 0.5)
        let materialForOcclusion = OcclusionMaterial()
        let occlusionPlane = ModelEntity(mesh: planeMesh, materials: [materialForOcclusion])
        occlusionPlane.position.y = -0.001
        
        gameAnchor.addChild(occlusionPlane)
    }
    
    func addPlayer() {
        ///make a player
        playerMesh = MeshResource.generateBox(width: 0.02, height: 0.02, depth: 0.02)
        playerMaterial = SimpleMaterial(color: .blue, isMetallic: true)
        player = ModelEntity(mesh: playerMesh!, materials: [playerMaterial!])
        player?.position.y = 0.11
        player?.position.x = 0
        player?.position.z = 0
        
        gameAnchor.addChild(player!)
    }
    
    @IBAction func playAgain(_ sender: UIButton) {
        ///hide game over view
        gameOverView.isHidden = true
        
        ///reset score
        score = 0
        scoreLabel.text = String(score)
        
        ///remove platforms
        gameAnchor.removeChild(newPlatform!)
//        for child in self.children {
//            if child.nibName == "newPlatform" {
//                child.removeFromParent()
//            }
//        }
        
        ///reset starting platform or make a new one?
        gameAnchor.startPlatform?.position.y = 0.05
        ///reset bridge
        resetBridge()
        gameAnchor.bridge?.position.x = 0.024
        
        
        ///game action buttons
        startButton.isHidden = false
        stopButton.isHidden = true
        
        addNewPlatform()
    }
    
}
