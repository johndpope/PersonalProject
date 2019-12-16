//
//  ViewController.swift
//  PersonalProject
//
//  Created by Robbe Verhoest on 11/11/2019.
//  Copyright © 2019 Robbe Verhoest. All rights reserved.
//
//  3D Models: Free To Use - credits Poly by Google

import ARKit
import UIKit
import RealityKit
import Combine
import QuartzCore

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    @IBOutlet weak var overlayView: ARCoachingOverlayView!
    
    ///menu view
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var startGameButton: UIButton!
    
    ///game view
    @IBOutlet weak var gameView: UIView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var environmentLabel: UILabel!
    
    ///game over screen
    @IBOutlet weak var gameOverView: UIView!
    @IBOutlet weak var endScoreLabel: UILabel!
    @IBOutlet weak var endScoreView: UIView!
    @IBOutlet weak var playAgainButton: UIButton!
    @IBOutlet weak var highscoreLabel: UILabel!
    @IBOutlet weak var menuButton: UIButton!
    
    var gameAnchor = AnchorEntity(plane: .horizontal, minimumBounds: [0.4, 0.3])
    
    let coachingOverlay = ARCoachingOverlayView()
    
    var counter = 0.00
    var timerCountBridge = Timer()
    
    var randomDistance:Double = 0
    var randomWidth:Double = 5
    
    var score:Int = 0
    var highscore: Int = 0
    
    var platformArray: [Platform] = []
    var bridgeArray: [Bridge] = []
    var environmentArray: [ModelEntity] = []
    
    ///starting platform
    var startPlatform = Platform(width: 0.05, heigth: 0.1, depth: 0.05, xPos1: 0, yPos1: 0.05, xPos2: 0.05, yPos2: 0, material: SimpleMaterial(color: .black, isMetallic: false))
    ///platform
    var newPlatform: Platform = Platform(width: 0.05, heigth: 0.1, depth: 0.05, xPos1: 0, yPos1: 0.05, xPos2: 0, yPos2: 0.05, material: SimpleMaterial(color: .black, isMetallic: false))
    ///bridge
    var bridge: Bridge = Bridge(width: 0.001, heigth: 0.0001, depth: 0.05, xPos: 0.024, yPos: 0.1, xSink: -0.126, material: SimpleMaterial(color: .blue, isMetallic: true))
    ///player
    var player: Player = Player(xPos: 0, yPos: 0.11, material: SimpleMaterial(color: .white, isMetallic: true), moveDistance: 0)
    ///texture
    var texture: SimpleMaterial = SimpleMaterial()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ///game views
        menuView.isHidden = false
        gameView.isHidden = true
        gameOverView.isHidden = true
        
        ///score label
        scoreLabel.layer.masksToBounds = true
        scoreLabel.layer.cornerRadius = 5
        ///game over view
        endScoreView.layer.masksToBounds = true
        endScoreView.layer.cornerRadius = 5
        
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
            //sound walk
            let audio = try! AudioFileResource.load(named: "wheel.mp3", in: nil, inputMode: .spatial, loadingStrategy: .preload, shouldLoop: false)
            self.player.player.prepareAudio(audio).play()
            
            //scene
            if (score == 4) {
                removePreviousEnvironment()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.createAntarctica()
                    self.ariseEnvironment()
                    self.texture.baseColor = try! MaterialColorParameter.texture(TextureResource.load(named: "ice"))
                    self.environmentLabel.text = "You reached Antarctica!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.environmentLabel.text = ""
                    }
                }
            } else if (score == 9) {
                removePreviousEnvironment()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.createSpace()
                    self.ariseEnvironment()
                    self.texture.baseColor = try! MaterialColorParameter.texture(TextureResource.load(named: "moonpowder"))
                    self.environmentLabel.text = "You reached Space!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.environmentLabel.text = ""
                    }
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.bridge.shorten()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.gameAnchor.removeChild(self.player.player)
                        self.addPlayer()
                        self.addBridge()
                        
                        ///game buttons
                        self.startButton.isHidden = false
                        self.startButton.isEnabled = true
                    }
                    
                    ///score
                    self.score = self.score + 1
                    self.scoreLabel.text = String(self.score)
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
        bridge = Bridge(width: 0.001, heigth: 0.0001, depth: 0.05, xPos: platformArray[1].width/2, yPos: 0.1, xSink: -0.151 + platformArray[0].width/2, material: texture)
        bridge.add()
        gameAnchor.addChild(bridge.bridge)
        bridgeArray.append(bridge)
    }
    
    func addStartPlatform() {
        startPlatform = Platform(width: 0.05, heigth: 0.1, depth: 0.05, xPos1: 0, yPos1: 0.05, xPos2: 0, yPos2: 0.05, material: texture)
        startPlatform.add()
        gameAnchor.addChild(startPlatform.platform)
        platformArray.append(startPlatform)
    }
    
    func addNewPlatform() {
        ///generate a random width and distance for new platform
        if (score < 5) {
            randomDistance = Double.random(in: 0.07...0.15)
            randomWidth = Double.random(in: 0.03...0.05)
        } else if (score < 10) {
            randomDistance = Double.random(in: 0.07...0.20)
            randomWidth = Double.random(in: 0.03...0.05)
        } else if (score < 15) {
            randomDistance = Double.random(in: 0.07...0.25)
            randomWidth = Double.random(in: 0.02...0.05)
        } else {
            randomDistance = Double.random(in: 0.13...0.25)
            randomWidth = Double.random(in: 0.01...0.05)
        }
        
        newPlatform = Platform(width: randomWidth, heigth: 0.1, depth: 0.05, xPos1: 0.4, yPos1: -0.1, xPos2: randomDistance, yPos2: 0.05, material: texture)
        newPlatform.add()
        gameAnchor.addChild(newPlatform.platform)
        newPlatform.arise()
        platformArray.append(newPlatform)
    }
    
    func addPlayer() {
        ///make a player
        player = Player(xPos: 0, yPos: 0.1, material: SimpleMaterial(color: .white, isMetallic: true), moveDistance: randomDistance)
        player.add()
        gameAnchor.addChild(player.player)
    }
    
    func createOcclusionFloor() {
        ///make a floor that hides stuff below
        let planeMesh = MeshResource.generatePlane(width: 5, depth: 5)
        let materialForOcclusion = OcclusionMaterial()
        let occlusionPlane = ModelEntity(mesh: planeMesh, materials: [materialForOcclusion])
        occlusionPlane.position.y = -0.005
        
        gameAnchor.addChild(occlusionPlane)
    }
    
    @IBAction func playAgain(_ sender: UIButton) {
        ///hide game over view
        gameOverView.isHidden = true
        gameView.isHidden = false
        startButton.isEnabled = true
        
        removePreviousScene()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.createStartScene()
        }
    }
    
    func addNullPlatform() {
        let nullPlatform = Platform(width: randomWidth, heigth: 0.1, depth: 0.05, xPos1: -0.15, yPos1: -0.1, xPos2: -0.15, yPos2: -0.1, material: SimpleMaterial(color: .red, isMetallic: false))
        platformArray.append(nullPlatform)
    }
    
    func addNullBridge() {
        let nullBridge = Bridge(width: randomWidth, heigth: 0.1, depth: 0.05, xPos: -0.15, yPos: -0.1, xSink: -0.126, material: SimpleMaterial(color: .red, isMetallic: false))
        bridgeArray.append(nullBridge)
    }
    
    func removePreviousScene() {
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
    }
    
    func removePreviousEnvironment() {
        for element in environmentArray {
            //sink
            var translationTransform = element.transform
            translationTransform.translation = SIMD3<Float>(x: element.position.x, y: element.position.y - 0.3, z: element.position.z)
            element.move(to: translationTransform, relativeTo: element.parent, duration: 1, timingFunction: .easeInOut)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.gameAnchor.removeChild(element)
                print(self.environmentArray.count)
            }
            self.environmentArray.removeAll()
        }
    }
    
    func ariseEnvironment() {
        for element in environmentArray {
            //arise
            var translationTransform = element.transform
            translationTransform.translation = SIMD3<Float>(x: element.position.x, y: element.position.y + 0.3, z: element.position.z)
            element.move(to: translationTransform, relativeTo: element.parent, duration: 1, timingFunction: .easeInOut)
        }
    }
    
    func createStartScene() {
        menuView.isHidden = true
        gameView.isHidden = false
        
        ///score
        score = 0
        scoreLabel.text = String(score)
        
        environmentLabel.text = ""
        removePreviousEnvironment()
        createFarm()
        texture.baseColor = try! MaterialColorParameter.texture(TextureResource.load(named: "grass"))
        
        createOcclusionFloor()
        addNullPlatform()
        addStartPlatform()
        addNullBridge()
        addBridge()
        addNewPlatform()
        addPlayer()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            ///game action buttons
            self.startButton.isHidden = false
            self.stopButton.isHidden = true
        }
    }
    
    @IBAction func goToMenu(_ sender: UIButton) {
        gameOverView.isHidden = true
        menuView.isHidden = false
        startGameButton.isHidden = false
    }
    
    func createAntarctica() {
        addClouds()
        //iglos
        load3DModelAsync(named: "igloo", position: SIMD3(x: 0.22, y: -0.001, z: 0.08), scale: SIMD3(x: 2, y: 2, z: 2), rotation: simd_quatf(angle: GLKMathDegreesToRadians(-45), axis: [0, 1, 0]))
        load3DModelAsync(named: "igloo", position: SIMD3(x: 0.02, y: -0.001, z: -0.13), scale: SIMD3(x: 2, y: 2, z: 2), rotation: simd_quatf(angle: GLKMathDegreesToRadians(30), axis: [0, 1, 0]))
        //penguins
        load3DModelAsync(named: "penguin", position: SIMD3(x: 0.02, y: 0, z: 0.08), scale: SIMD3(x: 0.2, y: 0.2, z: 0.2), rotation: simd_quatf(angle: GLKMathDegreesToRadians(30), axis: [0, 1, 0]))
        load3DModelAsync(named: "penguin", position: SIMD3(x: 0.17, y: 0, z: 0.1), scale: SIMD3(x: 0.2, y: 0.2, z: 0.2), rotation: simd_quatf(angle: GLKMathDegreesToRadians(-45), axis: [0, 1, 0]))
        load3DModelAsync(named: "penguin", position: SIMD3(x: 0.2, y: 0, z: -0.1), scale: SIMD3(x: 0.2, y: 0.2, z: 0.2), rotation: simd_quatf(angle: GLKMathDegreesToRadians(-20), axis: [0, 1, 0]))
        load3DModelAsync(named: "penguin", position: SIMD3(x: 0.21, y: 0, z: -0.1), scale: SIMD3(x: 0.15, y: 0.15, z: 0.15), rotation: simd_quatf(angle: GLKMathDegreesToRadians(-30), axis: [0, 1, 0]))
        //icebergs
        load3DModelAsync(named: "iceberg", position: SIMD3(x: -0.04, y: 0, z: 0.12), scale: SIMD3(x: 0.3, y: 0.3, z: 0.3), rotation: simd_quatf(angle: GLKMathDegreesToRadians(90), axis: [0, 1, 0]))
        load3DModelAsync(named: "iceberg", position: SIMD3(x: 0.08, y: 0, z: 0.08), scale: SIMD3(x: 0.3, y: 0.3, z: 0.3), rotation: simd_quatf(angle: GLKMathDegreesToRadians(90), axis: [0, 1, 0]))
        load3DModelAsync(named: "iceberg", position: SIMD3(x: 0.1, y: 0, z: 0.13), scale: SIMD3(x: 0.5, y: 0.5, z: 0.5), rotation: simd_quatf(angle: GLKMathDegreesToRadians(90), axis: [0, 1, 0]))
        load3DModelAsync(named: "iceberg", position: SIMD3(x: 0.1, y: 0, z: -0.12), scale: SIMD3(x: 0.3, y: 0.3, z: 0.3), rotation: simd_quatf(angle: GLKMathDegreesToRadians(90), axis: [0, 1, 0]))
        load3DModelAsync(named: "iceberg", position: SIMD3(x: 0.17, y: 0, z: -0.13), scale: SIMD3(x: 0.3, y: 0.3, z: 0.3), rotation: simd_quatf(angle: GLKMathDegreesToRadians(90), axis: [0, 1, 0]))
    }
    
    func createSpace() {
        //asteroids
        load3DModelAsync(named: "asteroids", position: SIMD3(x: -0.03, y: 0.15, z: 0.03), scale: SIMD3(x: 2, y: 2, z: 2), rotation: simd_quatf(angle: GLKMathDegreesToRadians(0), axis: [0, 1, 0]))
        load3DModelAsync(named: "asteroids", position: SIMD3(x: 0.07, y: 0.12, z: -0.07), scale: SIMD3(x: 2, y: 2, z: 2), rotation: simd_quatf(angle: GLKMathDegreesToRadians(60), axis: [0, 1, 0]))
        load3DModelAsync(named: "asteroids", position: SIMD3(x: 0.21, y: 0.08, z: 0.09), scale: SIMD3(x: 2, y: 2, z: 2), rotation: simd_quatf(angle: GLKMathDegreesToRadians(140), axis: [0, 1, 0]))
        //rocket
        load3DModelAsync(named: "rocketship", position: SIMD3(x: 0.18, y: 0, z: 0.1), scale: SIMD3(x: 1, y: 1, z: 1), rotation: simd_quatf(angle: GLKMathDegreesToRadians(90), axis: [0, 1, 0]))
        //base
        load3DModelAsync(named: "spacebase", position: SIMD3(x: 0.12, y: 0, z: -0.12), scale: SIMD3(x: 2, y: 2, z: 2), rotation: simd_quatf(angle: GLKMathDegreesToRadians(-90), axis: [0, 1, 0]))
        //ufo
        load3DModelAsync(named: "ufo", position: SIMD3(x: -0.04, y: 0, z: 0.13), scale: SIMD3(x: 0.3, y: 0.3, z: 0.3), rotation: simd_quatf(angle: GLKMathDegreesToRadians(0), axis: [0, 1, 0]))
        //satellites
        load3DModelAsync(named: "satellite1", position: SIMD3(x: 0.12, y: 0.17, z: -0.1), scale: SIMD3(x: 0.3, y: 0.3, z: 0.3), rotation: simd_quatf(angle: GLKMathDegreesToRadians(-90), axis: [0, 1, 0]))
        load3DModelAsync(named: "satellite2", position: SIMD3(x: 0.02, y: 0.2, z: 0.12), scale: SIMD3(x: 0.5, y: 0.5, z: 0.5), rotation: simd_quatf(angle: GLKMathDegreesToRadians(0), axis: [0, 1, 0]))
    }
    
    func createFarm() {
        addClouds()
        //oilpump
        load3DModelAsync(named: "oilpump", position: SIMD3(x: 0.03, y: 0, z: 0.12), scale: SIMD3(x: 0.0002, y: 0.0002, z: 0.0002), rotation: simd_quatf(angle: GLKMathDegreesToRadians(150), axis: [0, 1, 0]))
        //silos
        load3DModelAsync(named: "silo", position: SIMD3(x: -0.07, y: 0, z: -0.1), scale: SIMD3(x: 0.6, y: 0.6, z: 0.6), rotation: simd_quatf(angle: GLKMathDegreesToRadians(-60), axis: [0, 1, 0]))
        load3DModelAsync(named: "silo", position: SIMD3(x: -0.12, y: 0, z: -0.07), scale: SIMD3(x: 0.6, y: 0.6, z: 0.6), rotation: simd_quatf(angle: GLKMathDegreesToRadians(0), axis: [0, 1, 0]))
        //tractor
        load3DModelAsync(named: "tractor", position: SIMD3(x: 0.04, y: 0, z: 0.1), scale: SIMD3(x: 0.3, y: 0.3, z: 0.3), rotation: simd_quatf(angle: GLKMathDegreesToRadians(120), axis: [0, 1, 0]))
        //treestump
        load3DModelAsync(named: "treestump", position: SIMD3(x: 0.11, y: 0, z: 0.08), scale: SIMD3(x: 0.5, y: 0.5, z: 0.5), rotation: simd_quatf(angle: GLKMathDegreesToRadians(0), axis: [0, 1, 0]))
        //windturbine
        load3DModelAsync(named: "windturbine", position: SIMD3(x: 0.06, y: 0, z: -0.12), scale: SIMD3(x: 0.4, y: 0.4, z: 0.4), rotation: simd_quatf(angle: GLKMathDegreesToRadians(0), axis: [0, 1, 0]))
        //stone
        load3DModelAsync(named: "stone", position: SIMD3(x: 0.14, y: 0, z: -0.09), scale: SIMD3(x: 0.5, y: 0.5, z: 0.5), rotation: simd_quatf(angle: GLKMathDegreesToRadians(0), axis: [0, 1, 0]))
        load3DModelAsync(named: "stone", position: SIMD3(x: 0.06, y: 0, z: -0.11), scale: SIMD3(x: 0.5, y: 0.5, z: 0.5), rotation: simd_quatf(angle: GLKMathDegreesToRadians(0), axis: [0, 1, 0]))
        load3DModelAsync(named: "stone", position: SIMD3(x: 0.2, y: 0, z: 0.14), scale: SIMD3(x: 0.5, y: 0.5, z: 0.5), rotation: simd_quatf(angle: GLKMathDegreesToRadians(0), axis: [0, 1, 0]))
        //tree
        load3DModelAsync(named: "greentree", position: SIMD3(x: 0.01, y: 0, z: 0.07), scale: SIMD3(x: 0.12, y: 0.12, z: 0.12), rotation: simd_quatf(angle: GLKMathDegreesToRadians(0), axis: [0, 1, 0]))
        load3DModelAsync(named: "greentree", position: SIMD3(x: -0.1, y: 0, z: -0.04), scale: SIMD3(x: 0.1, y: 0.1, z: 0.1), rotation: simd_quatf(angle: GLKMathDegreesToRadians(0), axis: [0, 1, 0]))
    }
    
    func addClouds() {
        load3DModelAsync(named: "cloud", position: SIMD3(x: -0.05, y: 0.15, z: -0.15), scale: SIMD3(x: 0.1, y: 0.1, z: 0.1), rotation: simd_quatf(angle: GLKMathDegreesToRadians(0), axis: [0, 1, 0]))
        load3DModelAsync(named: "cloud", position: SIMD3(x: 0.07, y: 0.12, z: 0.12), scale: SIMD3(x: 0.1, y: 0.1, z: 0.1), rotation: simd_quatf(angle: GLKMathDegreesToRadians(0), axis: [0, 1, 0]))
        load3DModelAsync(named: "cloud", position: SIMD3(x: 0.2, y: 0.17, z: -0.1), scale: SIMD3(x: 0.15, y: 0.15, z: 0.15), rotation: simd_quatf(angle: GLKMathDegreesToRadians(0), axis: [0, 1, 0]))
    }
    
//    func load3DModel(named entityName: String, position: SIMD3<Float>, scale: SIMD3<Float>) {
//        let entity = try! ModelEntity.loadModel(named: entityName)
//        entity.position = position
//        entity.scale = scale
//        gameAnchor.addChild(entity)
//    }
    
    func load3DModelAsync(named entityName: String, position: SIMD3<Float>, scale: SIMD3<Float>, rotation: simd_quatf) {
        var cancellable: AnyCancellable? = nil
        cancellable = ModelEntity.loadModelAsync(named: entityName)
            .sink(receiveCompletion: { error in
                print("--- unexpected error: \(error) ---")
                cancellable?.cancel()
            }, receiveValue: { (entity) in
                entity.position = position
                entity.scale = scale
                entity.transform.rotation = rotation
                self.gameAnchor.addChild(entity)
                self.environmentArray.append(entity)
                cancellable?.cancel()
                print("--- loaded \(entityName) and added to the scene")
            })
    }
}
