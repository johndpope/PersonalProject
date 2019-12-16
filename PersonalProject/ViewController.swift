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
    @IBOutlet weak var gameView: UIView!
    @IBOutlet weak var startGameButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var scoreLabel: UILabel!
    
    ///game over screen
    @IBOutlet weak var gameOverView: UIView!
    @IBOutlet weak var endScoreLabel: UILabel!
    @IBOutlet weak var endScoreView: UIView!
    @IBOutlet weak var playAgainButton: UIButton!
    @IBOutlet weak var highscoreLabel: UILabel!
    
    var gameAnchor = AnchorEntity(plane: .horizontal)
    
    let coachingOverlay = ARCoachingOverlayView()
    
    var counter = 0.00
    var timerCountBridge = Timer()
    
    var randomDistance:Double = 0
    var randomWidth:Double = 5
    
    var score:Int = 0
    var highscore: Int = 0
    
    var platformArray: [Platform] = []
    var bridgeArray: [Bridge] = []
    
    ///starting platform
    var startPlatform = Platform(width: 0.05, heigth: 0.1, depth: 0.05, xPos1: 0, yPos1: 0.05, xPos2: 0.05, yPos2: 0, material: SimpleMaterial(color: .black, isMetallic: false))
    ///platform
    var newPlatform: Platform = Platform(width: 0.05, heigth: 0.1, depth: 0.05, xPos1: 0, yPos1: 0.05, xPos2: 0, yPos2: 0.05, material: SimpleMaterial(color: .black, isMetallic: false))
    ///bridge
    var bridge: Bridge = Bridge(width: 0.001, heigth: 0.0001, depth: 0.05, xPos: 0.024, yPos: 0.1, xSink: -0.126, material: SimpleMaterial(color: .blue, isMetallic: true))
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
        
        //sound
        let audio = try! AudioFileResource.load(named: "algemeen.mp3", in: nil, inputMode: .spatial, loadingStrategy: .stream, shouldLoop: true)
        gameAnchor.prepareAudio(audio).play()
    }
    
    @IBAction func startGame(_ sender: UIButton) {
        ///coaching overlay
        coachingOverlayViewWillActivate(overlayView)
        setupCoachingOverlay()
        coachingOverlayViewDidDeactivate(overlayView)
        
        arView.scene.anchors.append(gameAnchor)
        
        createStartScene()
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

        bridge.rotate()
        
        ///check if bridge is good or bad
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.checkBridge()
        }
    }
    
    func checkBridge() {
        if (((counter / 10) + 0.008) > (platformArray[2].x2 - platformArray[2].width/2 - platformArray[1].width/2) && (((counter / 10) - 0.008) < (platformArray[2].x2 + platformArray[2].width/2 - platformArray[1].width/2))) {
            ///next level
            player.walk()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.bridge.shorten()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    ///delete previous and add new platform + bridge
                    self.gameAnchor.removeChild(self.platformArray[0].platform)
                    self.platformArray.remove(at: 0)
                    self.gameAnchor.removeChild(self.bridgeArray[0].bridge)
                    self.bridgeArray.remove(at: 0)
                    self.addNewPlatform()
                    ///animation to next platform
                    self.platformArray[0].sink()
                    self.bridgeArray[0].sink()
                    self.platformArray[1].slide()
                    self.platformArray[2].arise()
                    self.player.slide()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.gameAnchor.removeChild(self.player.player)
                        self.addPlayer()
                    }
                    
                    ///game buttons
                    self.startButton.isHidden = false
                    
                    ///score
                    self.score = self.score + 1
                    self.scoreLabel.text = String(self.score)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.addBridge()
                    }
                }
            }
        } else {
            player.walkToEnd(xPos: counter/10 + 0.005)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                self.bridgeArray[1].fall()
                self.player.fall(xPos: self.counter/10 + 0.005)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    let audio = try! AudioFileResource.load(named: "crash.mp3", in: nil, inputMode: .spatial, loadingStrategy: .preload, shouldLoop: false)
                    self.player.player.prepareAudio(audio).play()
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                ///game over view
                self.gameView.isHidden = true
                self.gameOverView.isHidden = false
                self.endScoreLabel.text = String(self.score)
                
                if (self.score > self.highscore) {
                    self.highscore = self.score
                }
                self.highscoreLabel.text = String(self.highscore)
            }
        }
    }
    
    func addBridge() {
        var texture = SimpleMaterial()
        texture.baseColor = try! MaterialColorParameter.texture(TextureResource.load(named: "04"))
        
        bridge = Bridge(width: 0.001, heigth: 0.0001, depth: 0.05, xPos: platformArray[1].width/2, yPos: 0.1, xSink: -0.151 + platformArray[0].width/2, material: texture)
        bridge.add()
        gameAnchor.addChild(bridge.bridge)
        bridgeArray.append(bridge)
    }
    
    func addStartPlatform() {
        var texture = SimpleMaterial()
        texture.baseColor = try! MaterialColorParameter.texture(TextureResource.load(named: "metaal"))
            
        startPlatform = Platform(width: 0.05, heigth: 0.1, depth: 0.05, xPos1: 0, yPos1: 0.05, xPos2: 0, yPos2: 0.05, material: texture)
        startPlatform.add()
        gameAnchor.addChild(startPlatform.platform)
        platformArray.append(startPlatform)
    }
    
    func addNewPlatform() {
        ///generate a random width and distance for new platform
        randomDistance = Double.random(in: 0.07...0.25)
        randomWidth = Double.random(in: 0.01...0.05)
        
        ///make a new platform
        var texture = SimpleMaterial()
        texture.baseColor = try! MaterialColorParameter.texture(TextureResource.load(named: "metaal"))
        
        newPlatform = Platform(width: randomWidth, heigth: 0.1, depth: 0.05, xPos1: 0.4, yPos1: -0.1, xPos2: randomDistance, yPos2: 0.05, material: texture)
        newPlatform.add()
        gameAnchor.addChild(newPlatform.platform)
        newPlatform.arise()
        platformArray.append(newPlatform)
    }
    
    func addPlayer() {
        ///make a player
        player = Player(width: 0.02, heigth: 0.02, depth: 0.02, xPos: 0, yPos: 0.1, material: SimpleMaterial(color: .white, isMetallic: true), moveDistance: randomDistance)
        player.add()
        gameAnchor.addChild(player.player)
    }
    
    func createOcclusionFloor() {
        ///make a floor that hides stuff below
        let planeMesh = MeshResource.generatePlane(width: 5, depth: 5)
        let materialForOcclusion = OcclusionMaterial()
        let occlusionPlane = ModelEntity(mesh: planeMesh, materials: [materialForOcclusion])
        occlusionPlane.position.y = -0.001
        
        gameAnchor.addChild(occlusionPlane)
    }
    
    @IBAction func playAgain(_ sender: UIButton) {
        ///hide game over view
        gameOverView.isHidden = true
        gameView.isHidden = false
        
        ///remove objects from previous game
        for element in platformArray {
            gameAnchor.removeChild(element.platform)
        }
        platformArray.removeAll()
        for element in bridgeArray {
            gameAnchor.removeChild(element.bridge)
        }
        bridgeArray.removeAll()
        gameAnchor.removeChild(player.player)
        
        createStartScene()
    }
    
    func addNullPlatform() {
        let nullPlatform = Platform(width: randomWidth, heigth: 0.1, depth: 0.05, xPos1: -0.15, yPos1: -0.1, xPos2: -0.15, yPos2: -0.1, material: SimpleMaterial(color: .red, isMetallic: false))
        platformArray.append(nullPlatform)
    }
    
    func addNullBridge() {
        let nullBridge = Bridge(width: randomWidth, heigth: 0.1, depth: 0.05, xPos: -0.15, yPos: -0.1, xSink: -0.126, material: SimpleMaterial(color: .red, isMetallic: false))
        bridgeArray.append(nullBridge)
    }
    
    func addEnvironment() {
        //cloud
        placeObject(named: "cloud", x: -0.05, y: 0.15, z: -0.15, scale: SIMD3(x: 0.1, y: 0.1, z: 0.1))
        placeObject(named: "cloud", x: 0.07, y: 0.12, z: 0.12, scale: SIMD3(x: 0.1, y: 0.1, z: 0.1))
        placeObject(named: "cloud", x: 0.2, y: 0.17, z: -0.1, scale: SIMD3(x: 0.15, y: 0.15, z: 0.15))
        //drone
        placeObject(named: "drone", x: 0.04, y: 0.15, z: -0.03, scale: SIMD3(x: 0.4, y: 0.4, z: 0.4))
        //cactus
        placeObject(named: "cactus", x: 0.1, y: 0, z: 0.08, scale: SIMD3(x: 0.5, y: 0.5, z: 0.5))
        //tree
        placeObject(named: "tree", x: 0.15, y: 0, z: -0.1, scale: SIMD3(x: 0.3, y: 0.3, z: 0.3))
    }
    
    func createStartScene() {
        ///score
        score = 0
        scoreLabel.text = String(score)
        
        createOcclusionFloor()
        addNullPlatform()
        addStartPlatform()
        addNullBridge()
        addBridge()
        addNewPlatform()
        addPlayer()
        addEnvironment()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            ///game action buttons
            self.startButton.isHidden = false
            self.stopButton.isHidden = true
        }
    }
    
    func placeObject(named entityName: String, x: Double, y: Double, z: Double, scale: SIMD3<Float>) {
        let entity = try! ModelEntity.loadModel(named: entityName)
        entity.position.x = Float(x)
        entity.position.y = Float(y)
        entity.position.z = Float(z)
        entity.scale = scale
        gameAnchor.addChild(entity)
    }
}
