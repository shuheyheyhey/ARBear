//
//  ViewController.swift
//  ARTest
//
//  Created by Shuhei Yukawa on 2018/03/24.
//  Copyright © 2018年 Shuhei Yukawa. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {

    @IBOutlet var sceneView: ARSCNView!

    private var planeNodes: [PlaneNode] = []
    private var characterNode: CharacterNode?
    private let configuration = ARWorldTrackingConfiguration()
    //private var position: SCNVector3?
    
    private let micInput = MicInput()
    
    private var stopCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        self.sceneView.delegate = self
        self.sceneView.scene = SCNScene()

        self.sceneView.scene.physicsWorld.contactDelegate = self
        
        self.sceneView.autoenablesDefaultLighting = true

        self.registerGestureRecognizer()
        // Set the scene to the view
        //sceneView.scene = scene
        self.setUpMic()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 平面検出の有効化
        self.configuration.planeDetection = .horizontal
        self.sceneView.session.run(self.configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        self.sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    private func registerGestureRecognizer() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.tapped))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func tapped(sender: UITapGestureRecognizer) {
        // すでに追加済みであれば無視
        if self.characterNode != nil {
            return
        }
        // タップされた位置を取得する
        let tapLocation = sender.location(in: self.sceneView)
        // タップされた位置のARアンカーを探す
        let hitTest = self.sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        if !hitTest.isEmpty {
            // タップした箇所が取得できていればitemを追加
            self.addItem(hitTestResult: hitTest.first!)
        }
    }
    
    private func addItem(hitTestResult: ARHitTestResult) {
        self.characterNode = CharacterNode(hitTestResult: hitTestResult)
        self.sceneView.scene.rootNode.addChildNode(self.characterNode!)
    }
    
    private func setUpMic() {
        self.micInput.setUpAudio()
        Timer.scheduledTimer(timeInterval: 1,
                             target: self,
                             selector: #selector(ViewController.timerUpdate),
                             userInfo: nil,
                             repeats: true)
    }
    
    @objc func timerUpdate() {
        guard let char  = self.characterNode else {
            return
        }
        
        // マイクの入力が一定以上ならストップに
        if self.micInput.level > 0.01 && char.collision {
            char.stop()
            self.stopCount = 0
        }
        
        // ストップの場合は常にカメラに向ける
        if char.status == Status.stop && char.collision {
            self.stopCount += 1
            // カメラに向ける
            char.headForCamera(sceneView: self.sceneView)
        }
        
        if self.stopCount > 5 {
            char.dance()
        }
    }

    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("didAdd")
        if let planeAnchor = anchor as? ARPlaneAnchor {
            // 平面を表現するノードを追加する
            let panelNode = PlaneNode(anchor: planeAnchor)

            node.addChildNode(panelNode)
            self.planeNodes.append(panelNode)
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        print("didUpdate")
        if let planeAnchor = anchor as? ARPlaneAnchor, let planeNode = node.childNodes[0] as? PlaneNode {
            // ノードの位置及び形状を修正する
            planeNode.update(anchor: planeAnchor)
        }
    }
    
    // MARK: - SCNPhysicsContactDelegate
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        guard let char = self.characterNode else {
            return
        }
        if char.collision {
            // すでに初回衝突済み
            return
        }
        char.dance()
        char.collision = true
        
        //        var planeNode: PlaneNode?
        //        if contact.nodeA is PlaneNode {
        //            planeNode = contact.nodeA as? PlaneNode
        //        }
        //
        //        if contact.nodeB is PlaneNode {
        //            planeNode = contact.nodeB as? PlaneNode
        //        }
        //
        //        if planeNode != nil {
        //            let plane = planeNode!.geometry as! SCNPlane
        //            char.walk(planePosition: (planeNode?.position)!, width: plane.width, height: plane.height)
        //        }
    }
}
