//
//  Platform.swift
//  PersonalProject
//
//  Created by Robbe Verhoest on 14/12/2019.
//  Copyright © 2019 Robbe Verhoest. All rights reserved.
//

import Foundation
import RealityKit

class Platform {
    var width: Double = 0.05
    var heigth: Double = 0.1
    var depth: Double = 0.05
    var x1: Double = 0.1
    var y1: Double = 0.05
    var x2: Double = 0.1
    var y2: Double = 0.05
    var material: SimpleMaterial = SimpleMaterial(color: .red, isMetallic: false)
    var platform: ModelEntity = ModelEntity()
    
    init(width: Double, heigth: Double, depth: Double, xPos1: Double, yPos1: Double, xPos2: Double, yPos2: Double, material: SimpleMaterial) {
        self.width = width
        self.heigth = heigth
        self.depth = depth
        self.x1 = xPos1
        self.y1 = yPos1
        self.x2 = xPos2
        self.y2 = yPos2
        self.material = material
    }
    
    func add() {
        let platformMesh = MeshResource.generateBox(width: Float(width), height: Float(heigth), depth: Float(depth))
        let platformMaterial = material
        platform = ModelEntity(mesh: platformMesh, materials: [platformMaterial])
        platform.position.x = Float(x1)
        platform.position.y = Float(y1)
    }
    
    func slide() {
        var translationTransform = platform.transform
        translationTransform.translation = SIMD3<Float>(x: 0, y: 0.05, z: 0)
        platform.move(to: translationTransform, relativeTo: platform.parent, duration: 1, timingFunction: .easeInOut)
    }
    
    func sink() {
        var translationTransform = platform.transform
        translationTransform.translation = SIMD3<Float>(x: -0.15, y: -0.1, z: 0)
        platform.move(to: translationTransform, relativeTo: platform.parent, duration: 1, timingFunction: .easeInOut)
    }
    
    func arise() {
        var translationTransform = platform.transform
        translationTransform.translation = SIMD3<Float>(x: Float(x2), y: Float(y2), z: 0)
        platform.move(to: translationTransform, relativeTo: platform.parent, duration: 1, timingFunction: .easeInOut)
    }
}
