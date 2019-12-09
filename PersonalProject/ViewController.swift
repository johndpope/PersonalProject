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
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    
    var gameAnchor:Experience.Game!
    
    let coachingOverlay = ARCoachingOverlayView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        coachingOverlayViewWillActivate(overlayView)
        setupCoachingOverlay()
        coachingOverlayViewDidDeactivate(overlayView)
        
        gameAnchor = try! Experience.loadGame()
                
        gameAnchor.notifications.hideAtStart.post()
    }
    
    @IBAction func startGame(_ sender: UIButton) {
        startGameButton.isHidden = true
        playButton.isHidden = false
        pauseButton.isHidden = false
        
        arView.scene.anchors.append(gameAnchor)
        
        gameAnchor.notifications.gameStart.post()
    }
    
    @IBAction func makeBridge(_ sender: UIButton) {
        gameAnchor.notifications.extrudeBridge.post()
    }
    
    @IBAction func pauseAnimation(_ sender: UIButton) {
        gameAnchor.bridge?.stopAllAnimations(recursive: true)
        gameAnchor.notifications.pauseAndRotate.post()
    }
    
}
