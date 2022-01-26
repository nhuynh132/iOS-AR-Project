//
//  ViewController.swift
//  TestAR
//
//  Created by Apple on 1/19/22.
//

import Combine
import UIKit
import RealityKit

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*
        // Load the "Box" scene from the "Experience" Reality File
        let boxAnchor = try! Experience.loadBox()
        
        // Add the box anchor to the scene
        arView.scene.anchors.append(boxAnchor)
        */
        
        let anchor = AnchorEntity(plane: .horizontal, minimumBounds: [0.2, 0.2])
        
        arView.scene.addAnchor(anchor)
        
        var cards: [Entity] = []
        for _ in 1...16 {
            let box = MeshResource.generateBox(width: 0.04, height: 0.002, depth: 0.04)
            let material = SimpleMaterial(color: .darkGray, isMetallic: true)
            let model = ModelEntity(mesh: box, materials: [material])
            
            model.generateCollisionShapes(recursive: true)
            
            cards.append(model)
        }
        
        // This is to show the cards
        for (index, card) in cards.enumerated() {
            let x = Float(index % 4) - 1.5
            // no y
            let z = Float(index / 4) - 1.5
            
            card.position = [x * 0.1, 0, z * 0.1]
            anchor.addChild(card)
        }
        
        // Hide the object, won't be able to what's under
        let boxSize: Float = 0.7
        let occlusionBoxMesh = MeshResource.generateBox(size: boxSize)
        let occlusionBox = ModelEntity(mesh: occlusionBoxMesh, materials: [OcclusionMaterial()])
        
        occlusionBox.position.y = -boxSize / 2
        
        anchor.addChild(occlusionBox)
    
        // Begin to load models
        var cancellable: AnyCancellable? = nil
        
        cancellable = ModelEntity.loadModelAsync(named: "AirForce")
            .append(ModelEntity.loadModelAsync(named: "CupSaucerSet"))
            .append(ModelEntity.loadModelAsync(named: "PegasusTrail"))
            .append(ModelEntity.loadModelAsync(named: "ToyBiplane"))
            .append(ModelEntity.loadModelAsync(named: "ToyCar"))
            .append(ModelEntity.loadModelAsync(named: "ToyDrummer"))
            .append(ModelEntity.loadModelAsync(named: "ToyRobot"))
            .append(ModelEntity.loadModelAsync(named: "Tulip"))
        .collect()
        .sink(receiveCompletion: {
            error in print("Error: \(error)")
            cancellable?.cancel()
        }, receiveValue: {
            entities in var objects: [ModelEntity] = []
            for entity in entities {
                entity.setScale(SIMD3<Float>(0.002, 0.002, 0.002), relativeTo: anchor)
                entity.generateCollisionShapes(recursive: true)
                
                for _ in 1...2 {
                    objects.append(entity.clone(recursive: true))
                }
            }
            objects.shuffle()
            
            for (index, object) in objects.enumerated() {
                cards[index].addChild(object)
                cards[index].transform.rotation = simd_quatf(angle: .pi, axis: [1, 0, 0])
            }
            
            cancellable?.cancel()
        })
    }
    
    @IBAction func whenTap(_ sender: UITapGestureRecognizer) {
        let tapLocation = sender.location(in: arView)
        
        if let card = arView.entity(at: tapLocation) {
            if card.transform.rotation.angle == .pi {
                var flipDownTransform = card.transform
                
                flipDownTransform.rotation = simd_quatf(angle: 0, axis: [1, 0, 0])
                card.move(to: flipDownTransform, relativeTo: card.parent, duration: 0.5, timingFunction: .easeInOut)
            } else {
                var flipUpTransform = card.transform
                    
                flipUpTransform.rotation = simd_quatf(angle: .pi, axis: [1, 0, 0])
                card.move(to: flipUpTransform, relativeTo: card.parent, duration: 0.5, timingFunction: .easeInOut)
            }
        }
    }
}
