//
//  ViewController.swift
//  EyeTrackingTest
//
//  Created by Duncan Lewis on 6/14/18.
//  Copyright © 2018 WillowTree. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

let phoneScreenSize = CGSize(width: 0.0623908297, height: 0.135096943231532)

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.debugOptions = [ ARSCNDebugOptions.showFeaturePoints ]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        configuration.worldAlignment = .camera

        // Run the view's session
        sceneView.session.run(configuration)

        sceneView.scene.rootNode.addChildNode(self.cameraIntersectionPlaneNode)
        self.cameraIntersectionPlaneNode.position.z = Float(Measurement(value: -5.0, unit: UnitLength.inches).converted(to: UnitLength.meters).value)

        sceneView.scene.rootNode.addChildNode(self.faceIntersectionNode)
        self.faceIntersectionNode.isHidden = true

        sceneView.scene.rootNode.addChildNode(self.lookAtIntersectionNode)
        self.lookAtIntersectionNode.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - Nodes and Anchors

    var faceAnchor: ARFaceAnchor? = nil
    var faceNode: FaceNode? = nil

    lazy var cameraIntersectionPlaneNode: SCNNode = {
        let plane = SCNPlane(width: phoneScreenSize.height, height: phoneScreenSize.width)
        plane.materials.first?.diffuse.contents = UIColor.white
        plane.materials.first?.transparency = 0.5
        plane.materials.first?.writesToDepthBuffer = false
        plane.materials.first?.isDoubleSided = true

        let node = SCNNode(geometry: plane)
        return node
    }()

    lazy var faceIntersectionNode: SCNNode = {
        let sphere = SCNSphere(radius: 0.008)
        sphere.materials.first?.diffuse.contents = UIColor.red.withAlphaComponent(0.2)
        sphere.materials.first?.isDoubleSided = true

        let node = SCNNode(geometry: sphere)
        return node
    }()

    lazy var lookAtIntersectionNode: SCNNode = {
        let sphere = SCNSphere(radius: 0.008)
        sphere.materials.first?.diffuse.contents = UIColor.blue.withAlphaComponent(0.2)
        sphere.materials.first?.isDoubleSided = true

        let node = SCNNode(geometry: sphere)
        return node
    }()

    // MARK: - ARSCNViewDelegate

    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {

        if let faceAnchor = anchor as? ARFaceAnchor {
            self.faceAnchor = faceAnchor
            let faceGeometry = ARSCNFaceGeometry(device: self.sceneView.device!)
            self.faceNode = FaceNode(faceGeometry: faceGeometry!)
            return faceNode
        }

        return nil
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {

        if anchor == self.faceAnchor, let faceAnchor = anchor as? ARFaceAnchor {
            guard let faceNode = self.faceNode else { return }
            faceNode.updateFace(with: faceAnchor)

            self.updateFacewiseHitTest(faceAnchor: faceAnchor)
            self.updateLookwiseHitTest(faceAnchor: faceAnchor)
        }

    }

    // Awesome example, thoroughly documented by kevin!
    // LEAVE AS IS, even though we have better methods below. This is edification. 
    func updateFacewiseHitTest(faceAnchor: ARFaceAnchor) {
        // Get the position of the face and the position of a point ahead of the nose.
        // Multiplying with the face anchor transform takes a point in its coordinate space
        // and gives us a point in its parent's coordinate space.
        let faceOrigin = simd_mul(faceAnchor.transform, simd_make_float4(0.0, 0.0, 0.0, 1.0))
        let faceEnd = simd_mul(faceAnchor.transform, simd_make_float4(0.0, 0.0, 0.5, 1.0))

         // Get these two positions represented in the coordinate space of the intersection plane.
         // Multiplying with the inverse of the intersection node transform takes a point in its parent's
         //coordinate space and gives us a point in its coordinate space.
        let intersectionPlaneTransform = self.cameraIntersectionPlaneNode.simdTransform
        let inverseIntersectionPlaneTransform = simd_inverse(intersectionPlaneTransform)
        let faceOriginInPlane = simd_mul(inverseIntersectionPlaneTransform, faceOrigin)
        let faceEndInPlane = simd_mul(inverseIntersectionPlaneTransform, faceEnd)

        let hits = self.cameraIntersectionPlaneNode.hitTestWithSegment(from: SCNVector3FromSIMDFloat4(faceOriginInPlane), to: SCNVector3FromSIMDFloat4(faceEndInPlane), options: [ SCNHitTestOption.ignoreChildNodes.rawValue: NSNumber(booleanLiteral: true) ])

        if let firstHit = hits.first {
            if self.faceIntersectionNode.isHidden == true {
                self.faceIntersectionNode.isHidden = false
            }
            self.faceIntersectionNode.position = firstHit.worldCoordinates
            self.faceIntersectionNode.position.z += 0.00001
        }
    }

    func updateLookwiseHitTest(faceAnchor: ARFaceAnchor) {
        let intersectionLine = LineSegment(start: SCNVector4(0.0, 0.0, 0.0, 1.0), end: SCNVector4(faceAnchor.lookAtPoint, w: 0.0))
        let hits = self.intersect(lineSegement: intersectionLine, toWorld: faceAnchor.transform, with: self.cameraIntersectionPlaneNode)

        if let firstHit = hits.first {
            if self.lookAtIntersectionNode.isHidden == true {
                self.lookAtIntersectionNode.isHidden = false
            }
            self.lookAtIntersectionNode.position = firstHit.worldCoordinates
            self.lookAtIntersectionNode.position.z += 0.00001
        }
    }

    /// Intersect a line segement, specified in the sourceNode's coordinate system, with the targetNode.
    /// - Returns: The result of hit testing the lineSegment against the targetNode.
    func intersect(lineSegement: LineSegment, in sourceNode: SCNNode, with targetNode: SCNNode) -> [SCNHitTestResult] {
        let rayStartInTarget = sourceNode.convertPosition(lineSegement.start.vector3, to: targetNode)
        let rayEndInTarget = sourceNode.convertPosition(lineSegement.end.vector3, to: targetNode)

        return targetNode.hitTestWithSegment(from: rayStartInTarget, to: rayEndInTarget, options: [ SCNHitTestOption.ignoreChildNodes.rawValue: NSNumber(booleanLiteral: true) ])
    }

    /// Given a local-to-world space transform for a line segement, interesct that line segement with the targetNode.
    /// - Returns: The result of hit testing the lineSegment against the targetNode.
    func intersect(lineSegement: LineSegment, toWorld: simd_float4x4, with targetNode: SCNNode) -> [SCNHitTestResult] {
        let lineStartInWorld = simd_mul(toWorld, lineSegement.start.simdVector4)
        let lineEndInWorld = simd_mul(toWorld, lineSegement.end.simdVector4)

        let lineStartInTarget = targetNode.simdConvertPosition(simd_make_float3(lineStartInWorld), from: nil)
        let lineEndInTarget = targetNode.simdConvertPosition(simd_make_float3(lineEndInWorld), from: nil)

        return targetNode.hitTestWithSegment(from: SCNVector3(lineStartInTarget), to: SCNVector3(lineEndInTarget), options: [ SCNHitTestOption.ignoreChildNodes.rawValue: NSNumber(booleanLiteral: true) ])
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }

}

func intersectPlane(p_co: SCNVector3, p_no: SCNVector3, p0: SCNVector3, p1: SCNVector3) -> SCNVector3? {
    let epsilon: Float = 0.00005

    let u = p1 - p0 // line from p0 to p1
    let dot = p_no.dot(vector: u)

    if abs(dot) > epsilon {
        // the factor of the point between p0 -> p1 (0 - 1)
        // if 'fac' is between (0 - 1) the point intersects with the segment.
        // otherwise:
        // < 0.0: behind p0.
        // > 1.0: infront of p1.
        let w = p0 - p_co
        let fac = -p_no.dot(vector: w) / dot
        let newU = u * fac
        return p0 + newU
    } else {
        return nil
    }
}
