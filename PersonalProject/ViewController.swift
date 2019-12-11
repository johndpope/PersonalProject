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

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    @IBOutlet weak var overlayView: ARCoachingOverlayView!
    @IBOutlet weak var startGameButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    
    var gameAnchor:Experience.Game!
    
    let coachingOverlay = ARCoachingOverlayView()
    
    var randomDistance:Double = 0
    var randomWidth:Double = 5
    
    var counter = 0.0
    var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gameAnchor = try! Experience.loadGame()
        
        stopButton.isHidden = true
        startButton.isHidden = true
        
        ///timer
        timeLabel.text = String(counter)
        stopButton.isEnabled = false
        ///end timer
                
        gameAnchor.notifications.hideAtStart.post()
    }
    
    @IBAction func startGame(_ sender: UIButton) {
        coachingOverlayViewWillActivate(overlayView)
        setupCoachingOverlay()
        coachingOverlayViewDidDeactivate(overlayView)
        
        startGameButton.isHidden = true
        
        arView.scene.anchors.append(gameAnchor)
        
        gameAnchor.notifications.gameStart.post()
        
        createOcclusionFloor()
        addNewPlatform()
    }
    
    @IBAction func startBridge(_ sender: UIButton) {
        startButton.isHidden = true
        stopButton.isHidden = false
        
        ///timer
        counter = 0.0
        
        startButton.isEnabled = false
        stopButton.isEnabled = true
        
        timer = Timer.scheduledTimer(timeInterval: 0.001, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        ///end timer
        
        gameAnchor.notifications.extrudeBridge.post()
    }
    
    @IBAction func stopBridge(_ sender: UIButton) {
        stopButton.isHidden = true
        
        ///timer
        startButton.isEnabled = true
        stopButton.isEnabled = false
        
        timer.invalidate()
        
        print("counter = \(counter)")
        print("distance = \(randomDistance)")
        print("width = \(randomWidth)")
        print("\(randomDistance - 0.025 - (randomWidth/2)) < \((counter / 10) + 0.002) < \(randomDistance - 0.025 + (randomWidth/2))")
        ///end timer
        
        gameAnchor.bridge?.stopAllAnimations(recursive: true)
        gameAnchor.notifications.pauseAndRotate.post()
        
        checkBridge()
    }
    
    func checkBridge() {
        if (((counter / 10) + 0.002) > (randomDistance - 0.025 - (randomWidth/2))) && (((counter / 10) + 0.002) < randomDistance - 0.025 + (randomWidth/2)) {
            ///next level
            timeLabel.text = "YOU MADE IT"
        } else {
            ///game over
            timeLabel.text = "YOU SUCK"
        }
    }
    
    @objc func updateTimer() {
        counter = counter + 0.001
        timeLabel.text = String(format: "%.001f", counter)
    }
    
    func addNewPlatform() {
        randomDistance = Double.random(in: 0.07...0.25)
        randomWidth = Double.random(in: 0.01...0.05)
        
        let platformMesh = MeshResource.generateBox(width: Float(randomWidth), height: 0.1, depth: 0.05)
        let platformMaterial = SimpleMaterial(color: .red, isMetallic: true)
        let newPlatform = ModelEntity(mesh: platformMesh, materials: [platformMaterial])
        newPlatform.position.x = Float(randomDistance)
        newPlatform.position.y = 0.05
        
        gameAnchor.addChild(newPlatform)
    }
    
    func createOcclusionFloor() {
        let planeMesh = MeshResource.generatePlane(width: 0.5, depth: 0.5)
        let materialForOcclusion = OcclusionMaterial()
        let occlusionPlane = ModelEntity(mesh: planeMesh, materials: [materialForOcclusion])
        occlusionPlane.position.y = -0.001
        
        gameAnchor.addChild(occlusionPlane)
    }
    
}
