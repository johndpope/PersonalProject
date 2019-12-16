//
//  Player.swift
//  PersonalProject
//
//  Created by Robbe Verhoest on 14/12/2019.
//  Copyright © 2019 Robbe Verhoest. All rights reserved.
//

import Foundation
import RealityKit

class Player {
    var width: Double = 0.02
    var heigth: Double = 0.02
    var depth: Double = 0.02
    var x: Double = 0
    var y: Double = 0.1
    var material: SimpleMaterial = SimpleMaterial(color: .white, isMetallic: true)
    var moveDistance: Double = 0
    var player: ModelEntity = ModelEntity()
    
    init(width: Double, heigth: Double, depth: Double, xPos: Double, yPos: Double, material: SimpleMaterial, moveDistance: Double) {
        self.width = width
        self.heigth = heigth
        self.depth = depth
        self.x = xPos
        self.y = yPos
        self.material = material
        self.moveDistance = moveDistance
    }
    
    func add() {
        player = try! ModelEntity.loadModel(named: "player")
        player.position.x = Float(x)
        player.position.y = Float(y)
        player.scale = SIMD3<Float>(x: 0.05, y: 0.05, z: 0.05)
    }
    
    func walk() {
        var translationTransform = player.transform
        translationTransform.translation = SIMD3<Float>(x: Float(moveDistance), y: 0.1, z: 0)
        player.move(to: translationTransform, relativeTo: player.parent, duration: 2, timingFunction: .easeInOut)
    }
    
    func walkToEnd(xPos: Double) {
        var translationTransform = player.transform
        translationTransform.translation = SIMD3<Float>(x: Float(xPos), y: 0.1, z: 0)
        player.move(to: translationTransform, relativeTo: player.parent, duration: 1, timingFunction: .easeInOut)
    }
    
    func fall(xPos: Double) {
        var translationTransform = player.transform
        translationTransform.translation = SIMD3<Float>(x: Float(xPos), y: -0.05, z: 0)
        player.move(to: translationTransform, relativeTo: player.parent, duration: 0.7, timingFunction: .easeInOut)
    }
    
    func slide() {
        var translationTransform = player.transform
        translationTransform.translation = SIMD3<Float>(x: 0, y: 0.1, z: 0)
        player.move(to: translationTransform, relativeTo: player.parent, duration: 2, timingFunction: .easeInOut)
    }
}

