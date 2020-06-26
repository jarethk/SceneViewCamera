//
//  SceneViewCamera.swift
//  TavernPlayground
//
//  Created by David Fuller on 6/24/20.
//  Copyright © 2020 David Fuller. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
import SpriteKit

/**
 Convenience class to consolidate camera handling for a SKScene.
 Constrains the camera to the view based on the background, supporting pinch/zoom, pan,
 and double-tap to refocus gestures
 */
class SceneViewCamera {
    var scene : SKScene
    var view : SKView
    var camera : SKCameraNode
    var background : SKNode
    
    var previousCameraPoint = CGPoint.zero
    var previousCameraScale = CGFloat.zero
    var maxScale = CGFloat.zero
    var minScale = CGFloat(0.5)

    init(scene: SKScene, view: SKView, camera : SKCameraNode, background: SKNode) {
        self.scene = scene
        self.view = view
        self.camera = camera
        self.background = background
    }
    
    func addGestureRecognizers() {
        // add pinch/zoom gesture
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        view.addGestureRecognizer(pinchGesture)

        // add swipe/pan gesture
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(panGesture)
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGesture)
        
        // max scale is the ratio of the background to the scene dimensions
        let maxScaleX = background.frame.width / scene.frame.width
        let maxScaleY = background.frame.height / scene.frame.height
        maxScale = CGFloat.minimum(maxScaleX, maxScaleY)
        
        updateCameraConstraints()
    }
    
    private func updateCameraConstraints() {
        // frame.width/height is the size of the scene frame, multiply by the camera scale to
        // know how much is shown, then divide by 2 to figure out relative distance between
        // the edge of the camera view and the camera center.  combined with the background
        // frame minx/miny/maxx/maxy gets us the camera x/y position constraints
        let halfScaledWidth = scene.frame.width * camera.xScale/2
        let xRange = SKRange(lowerLimit: background.frame.minX + halfScaledWidth,
                             upperLimit: background.frame.maxX - halfScaledWidth)

        let halfScaledHeight = scene.frame.height * camera.yScale/2
        let yRange = SKRange(lowerLimit: background.frame.minY + halfScaledHeight,
                             upperLimit: background.frame.maxY - halfScaledHeight)
        let edgeConstraint = SKConstraint.positionX(xRange, y: yRange)
        camera.constraints = [edgeConstraint]
    }
    
    @IBAction func handlePinch(_ sender: UIPinchGestureRecognizer) {
        if sender.state == .began {
            previousCameraScale = camera.xScale
        }
        // recognizer scale is relative to the recognizer itself based on when the gesture started,
        // so have to evaluate relative to previous camera scale to determine new scale
        let newScale = CGFloat.maximum(minScale, CGFloat.minimum(maxScale, (previousCameraScale * 1 / sender.scale)))
        camera.setScale(newScale)
        updateCameraConstraints()
    }
    
    @IBAction func handlePan(_ sender: UIPanGestureRecognizer) {
        if sender.state == .began {
            previousCameraPoint = camera.position
        }
        let translation = sender.translation(in: self.view)
        // scale the translation to handle scaled view
        // we do *2 here to compensate for the camera scale, we want to move twice as much as the camera is scaled
        let xTranslation = translation.x * camera.xScale * 2
        let yTranslation = translation.y * camera.yScale * 2
        let newPosition = CGPoint(x: previousCameraPoint.x - xTranslation,
                                  y: previousCameraPoint.y + yTranslation)
        camera.position = newPosition
    }
    
    @IBAction func handleDoubleTap(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            var location = sender.location(in: sender.view)
            // convert the senders location to the scene's location
            location = scene.convertPoint(fromView: location)
            camera.position = location
            camera.setScale(1.0)
            updateCameraConstraints()
        }
    }
    
}
#endif
