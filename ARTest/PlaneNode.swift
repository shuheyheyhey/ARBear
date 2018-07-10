//
//  PlaneNode.swift
//  ARTest
//
//  Created by Shuhei Yukawa on 2018/03/25.
//  Copyright © 2018年 Shuhei Yukawa. All rights reserved.
//

import Foundation
import UIKit
import SceneKit
import ARKit

class PlaneNode: SCNNode {

    fileprivate override init() {
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(anchor: ARPlaneAnchor) {
        super.init()
        // 平面の検出時に呼ばれて検出された平面の大きさで SCNPlane を作成
        geometry = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        // アンカー中心位置の移動
        transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
        // 物理特性の設定
        physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: geometry!, options: nil))
        setPhysicsBody()
        display()
    }

    func update(anchor: ARPlaneAnchor) {
        // ARKit が新しい平面を検出した際に呼ばれる
        // 検出した平面に拡張
        (geometry as! SCNPlane).width = CGFloat(anchor.extent.x)
        (geometry as! SCNPlane).height = CGFloat(anchor.extent.z)

        position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: geometry!, options: nil))
        setPhysicsBody()
        display()
    }

    private func setPhysicsBody() {
        physicsBody?.categoryBitMask = 2
        // 衝突
        physicsBody?.collisionBitMask = 1
        physicsBody?.contactTestBitMask = 1
        // 摩擦
        physicsBody?.friction = 1
        // 弾性
        physicsBody?.restitution = 0
    }

    private func display() {
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = UIColor(red: 0.0, green: 0.1, blue: 0.0, alpha: 0.3)
        geometry?.materials = [planeMaterial]
    }

}
