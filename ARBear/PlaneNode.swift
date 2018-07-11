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
        self.geometry = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        // アンカー中心位置の移動
        self.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
        // 物理特性の設定
        self.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: self.geometry!, options: nil))
        self.setPhysicsBody()
        self.display()
    }

    func update(anchor: ARPlaneAnchor) {
        // ARKit が新しい平面を検出した際に呼ばれる
        // 検出した平面に拡張
        (self.geometry as! SCNPlane).width = CGFloat(anchor.extent.x)
        (self.geometry as! SCNPlane).height = CGFloat(anchor.extent.z)

        self.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        self.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: self.geometry!, options: nil))
        self.setPhysicsBody()
        self.display()
    }

    private func setPhysicsBody() {
        self.physicsBody?.categoryBitMask = 2
        // 衝突
        self.physicsBody?.collisionBitMask = 1
        self.physicsBody?.contactTestBitMask = 1
        // 摩擦
        self.physicsBody?.friction = 1
        // 弾性
        self.physicsBody?.restitution = 0
    }

    private func display() {
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = UIColor(red: 0.0, green: 0.1, blue: 0.0, alpha: 0.3)
        self.geometry?.materials = [planeMaterial]
    }

}
