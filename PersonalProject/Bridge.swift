//
//  Bridge.swift
//  PersonalProject
//
//  Created by Robbe Verhoest on 14/12/2019.
//  Copyright © 2019 Robbe Verhoest. All rights reserved.
//

import Foundation
import RealityKit

class Bridge {
    var width: Double = 0.001
    var heigth: Double = 0.0001
    var depth: Double = 0.05
    var x1: Double = 0.024
    var y1: Double = 0.1
    var material: SimpleMaterial = SimpleMaterial(color: .blue, isMetallic: true)
    var bridge: ModelEntity = ModelEntity()
    
    init(width: Double, heigth: Double, depth: Double, xPos1: Double, yPos1: Double, material: SimpleMaterial) {
        self.width = width
        self.heigth = heigth
        self.depth = depth
        self.x1 = xPos1
        self.y1 = yPos1
        self.material = material
    }
    
    func add() {
        let bridgeMesh = MeshResource.generateBox(width: Float(width), height: Float(heigth), depth: Float(depth))
        let bridgeMaterial = material
        bridge = ModelEntity(mesh: bridgeMesh, materials: [bridgeMaterial])
        bridge.position.x = Float(x1)
        bridge.position.y = Float(y1)
    }
    
    func extrude() {
        var scaleTransform = bridge.transform
        scaleTransform.scale = SIMD3<Float>(x: 1, y: 6000, z: 1)
        bridge.move(to: scaleTransform, relativeTo: bridge.parent, duration: 3, timingFunction: .linear)
    }
    
    func shorten() {
        var scaleTransform = bridge.transform
        scaleTransform.scale = SIMD3<Float>(x: 1, y: 0.0001666666667, z: 1)
        bridge.move(to: scaleTransform, relativeTo: bridge.parent, duration: 1, timingFunction: .linear)
    }
    
    func rotate() {
        var rotationTransform = bridge.transform
        rotationTransform.rotation = simd_quatf(angle: -.pi/2, axis: [0, 0, 1])
        bridge.move(to: rotationTransform, relativeTo: bridge.parent, duration: 1, timingFunction: .easeIn)
    }
    
    func rotateBack() {
        var rotationTransform = bridge.transform
        rotationTransform.rotation = simd_quatf(angle: 0, axis: [0, 0, 1])
        bridge.move(to: rotationTransform, relativeTo: bridge.parent, duration: 1, timingFunction: .easeIn)
    }
    
    func sink() {
        var translationTransform = bridge.transform
        translationTransform.translation = SIMD3<Float>(x: -0.126, y: -0.05, z: 0)
        bridge.move(to: translationTransform, relativeTo: bridge.parent, duration: 2, timingFunction: .easeInOut)
    }
}

