//
//  CharcterNode.swift
//  ARTest
//
//  Created by Shuhei Yukawa on 2018/03/25.
//  Copyright © 2018年 Shuhei Yukawa. All rights reserved.
//

import Foundation

import Foundation
import UIKit
import SceneKit
import ARKit

enum Status: Int {
    case Walk = 1
    case Stop = 2
    case Dancing = 3
}

let WALK_NODE = "art.scnassets/walk.dae";
let STOP_NODE = "art.scnassets/Talking.dae";
let DANCE_NODE = "art.scnassets/Dancing.dae";

class CharacterNode: SCNNode {

    var status: Status
    var collision: Bool = false;

    fileprivate override init() {
        // 初期化時のステータスは Stop
        status = .Stop

        super.init()
        self.name = "Character"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(hitTestResult: ARHitTestResult) {
        // 初期化時のステータスは Stop
        status = .Stop

        super.init()

        // アセットより、シーンを作成
        setNode(fileName: STOP_NODE);

        // サイズ調整
        scale = SCNVector3(0.0005, 0.0005, 0.0005);

        // 位置決定
        position = SCNVector3(hitTestResult.worldTransform.columns.3.x,
                              hitTestResult.worldTransform.columns.3.y + 0.3,
                              hitTestResult.worldTransform.columns.3.z)

        // 物理特性追加
        addPhysics()
    }
    
    func headForCamera(sceneView: SCNView) {
        // カメラ方向に向けるアニメーション
        if let camera = sceneView.pointOfView {
            // Y 軸のみ回す
            let action = SCNAction.rotateTo(x: 0, y: CGFloat(camera.eulerAngles.y), z: 0, duration: 1)
            runAction(action)
        }
    }

    func stop() {
        print("stop")
        if (status == .Walk || status == .Dancing) {
            status = .Stop
            // node は全消し
            for node in childNodes {
                node.removeFromParentNode();
            }
            self.position = self.presentation.worldPosition
            // Stop 状態の node に差し替え
            setNode(fileName: STOP_NODE);
        }
    }
    
    func dance() {
        print("dance")
        if (status == .Stop || status == .Walk) {
            status = .Dancing
            // node は全消し
            for node in childNodes {
                node.removeFromParentNode();
            }
            // Dance 状態の node に差し替え
            setNode(fileName: DANCE_NODE);
        }
    }

    private func addPhysics() {
        // 物理特性追加(node で追加するとうまく平面で止まってくれず・・・ひとまずキューブで対応)
        let cube = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: cube, options: nil))
        physicsBody?.categoryBitMask = 0
        physicsBody?.restitution = 0
        // 空気抵抗(ゆっくり落としたいので 1)
        physicsBody?.damping = 1
        physicsBody?.angularDamping = 1
        physicsBody?.friction = 1
        
    }

    private func setNode(fileName: String) {
        // アセットより、シーンを作成
        let scene = SCNScene(named: fileName)!
        for childNode in scene.rootNode.childNodes {
            addChildNode(childNode)
        }
    }
    
    /*
    func walk(planePosition: SCNVector3, width: CGFloat, height: CGFloat) {
        if (status == .Stop || status == .Attack) {
            status = .Walk
            // Stop の node は全消し
            for node in childNodes {
                node.removeFromParentNode();
            }
            // Stop 状態の node に差し替え
            setNode(fileName: WALK_NODE);
            // アニメーション
            walkAnimation(planePosition: planePosition, width: width, height: height)
        }
    }
    
    private func walkAnimation(planePosition: SCNVector3, width: CGFloat, height: CGFloat) {
        let position = self.presentation.worldPosition;
        print(planePosition)
        print("width: ", width)
        print("height: ",height)
        if (position.x > planePosition.x + Float(width/2) || position.z > planePosition.z + Float(height/2) ||
            position.x < planePosition.x - Float(width/2) || position.z < planePosition.z - Float(height/2)) {
            // Y 軸で回転
            let rotateAction = SCNAction.rotateTo(x: 0, y: sin(10), z: 0, duration: 1)
            runAction(rotateAction, forKey: "rotate", completionHandler: {
                self.walkAnimation(planePosition: planePosition, width: width, height: height)
            })
            return
        }
        
        let vec = SCNVector4Make(0, 0, 0.1, 0)
        let mat = SCNMatrix4MakeRotation(rotation.w, 0, 1, 0)
        let newVec = (mat * vec).to3()
        
        // 回転させたベクトル分人体モデルを動かす
        let toPosition = SCNVector3(x: newVec.x, y: self.presentation.worldPosition.y, z: newVec.z);
        let move = SCNAction.move(to: toPosition, duration: 2)
        
        // Actionが完了したら再帰的にmove()を呼び出す
        runAction(move, forKey: "move", completionHandler: {
            self.walkAnimation(planePosition: planePosition, width: width, height: height)
        })
    }*/
}

/*
extension SCNMatrix4 {
    static public func *(left: SCNMatrix4, right: SCNVector4) -> SCNVector4 {
        let x = left.m11*right.x + left.m21*right.y + left.m31*right.z + left.m41*right.w
        let y = left.m12*right.x + left.m22*right.y + left.m32*right.z + left.m42*right.w
        let z = left.m13*right.x + left.m23*right.y + left.m33*right.z + left.m43*right.w
        let w = left.m14*right.x + left.m24*right.y + left.m43*right.z + left.m44*right.w

        return SCNVector4(x: x, y: y, z: z, w: w)
    }
}
extension SCNVector4 {
    public func to3() -> SCNVector3 {
        return SCNVector3(self.x , self.y, self.z)
    }
}*/
