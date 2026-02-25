import SceneKit
import SwiftUI

#if canImport(UIKit)
    import UIKit

    struct StateSpace3DView: UIViewRepresentable {
        let apgiScores: APGIProfile

        func makeUIView(context _: Context) -> SCNView {
            let sceneView = SCNView()
            configureScene(on: sceneView)
            return sceneView
        }

        func updateUIView(_: SCNView, context _: Context) {
            // Update if needed
        }
    }

#elseif canImport(AppKit)
    import AppKit

    struct StateSpace3DView: NSViewRepresentable {
        let apgiScores: APGIProfile

        func makeNSView(context _: Context) -> SCNView {
            let sceneView = SCNView()
            configureScene(on: sceneView)
            return sceneView
        }

        func updateNSView(_: SCNView, context _: Context) {
            // Update if needed
        }
    }
#endif

private extension StateSpace3DView {
    func configureScene(on sceneView: SCNView) {
        sceneView.scene = SCNScene()
        sceneView.allowsCameraControl = true
        #if canImport(UIKit)
            sceneView.backgroundColor = UIColor.systemBackground
        #else
            sceneView.backgroundColor = NSColor.windowBackgroundColor
        #endif

        // Add camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 5, y: 5, z: 5)
        sceneView.scene?.rootNode.addChildNode(cameraNode)

        // Add light
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 10, y: 10, z: 10)
        sceneView.scene?.rootNode.addChildNode(lightNode)

        // Add axes
        self.addAxis(from: SCNVector3(0, 0, 0), to: SCNVector3(10, 0, 0), color: self.axisColorRed(), sceneView: sceneView) // x: epsilon
        self.addAxis(from: SCNVector3(0, 0, 0), to: SCNVector3(0, 10, 0), color: self.axisColorGreen(), sceneView: sceneView) // y: precision
        self.addAxis(from: SCNVector3(0, 0, 0), to: SCNVector3(0, 0, 10), color: self.axisColorBlue(), sceneView: sceneView) // z: threshold

        // Add point for profile
        let sphere = SCNSphere(radius: 0.2)
        #if canImport(UIKit)
            sphere.firstMaterial?.diffuse.contents = UIColor.systemOrange
        #else
            sphere.firstMaterial?.diffuse.contents = NSColor.systemOrange
        #endif
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = SCNVector3(Float(self.apgiScores.epsilon) / 10, Float(self.apgiScores.precision) / 10, Float(self.apgiScores.threshold) / 10)
        sceneView.scene?.rootNode.addChildNode(sphereNode)
    }

    func addAxis(from: SCNVector3, to: SCNVector3, color: Any, sceneView: SCNView) {
        let distance = from.distance(to: to)
        let cylinder = SCNCylinder(radius: 0.02, height: CGFloat(distance))
        cylinder.firstMaterial?.diffuse.contents = color
        let node = SCNNode(geometry: cylinder)
        node.position = SCNVector3((from.x + to.x) / 2, (from.y + to.y) / 2, (from.z + to.z) / 2)
        node.look(at: to, up: SCNVector3(0, 1, 0), localFront: SCNVector3(0, 0, 1))
        sceneView.scene?.rootNode.addChildNode(node)
    }

    func axisColorRed() -> Any {
        #if canImport(UIKit)
            return UIColor.systemRed
        #else
            return NSColor.systemRed
        #endif
    }

    func axisColorGreen() -> Any {
        #if canImport(UIKit)
            return UIColor.systemGreen
        #else
            return NSColor.systemGreen
        #endif
    }

    func axisColorBlue() -> Any {
        #if canImport(UIKit)
            return UIColor.systemBlue
        #else
            return NSColor.systemBlue
        #endif
    }
}

extension SCNVector3 {
    func distance(to vector: SCNVector3) -> Float {
        Float(sqrt(pow(Float(x - vector.x), 2) + pow(Float(y - vector.y), 2) + pow(Float(z - vector.z), 2)))
    }
}
