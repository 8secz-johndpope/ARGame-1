//
//  GameViewController.swift
//  ARGame
//
//  Created by James Rogers on 16/02/2017.
//  Copyright © 2017 James Rogers. All rights reserved.
//

import GLKit
import OpenGLES

func BUFFER_OFFSET(_ i: Int) -> UnsafeRawPointer? {
    return UnsafeRawPointer(bitPattern: i)
}

@objc class GameViewController: GLKViewController {
    
    var context: EAGLContext? = nil
    var effect: GLKBaseEffect? = nil
    
    var obj: Object? = nil
    
    deinit {
        self.tearDownGL()
        
        if EAGLContext.current() === self.context {
            EAGLContext.setCurrent(nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.context = EAGLContext(api: .openGLES2)
        
        if !(self.context != nil) {
            print("Failed to create ES context")
        }
        
        let view = self.view as! GLKView
        view.context = self.context!
        view.drawableDepthFormat = .format24
        
        self.setupGL()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        if self.isViewLoaded && (self.view.window != nil) {
            self.view = nil
            
            self.tearDownGL()
            
            if EAGLContext.current() === self.context {
                EAGLContext.setCurrent(nil)
            }
            self.context = nil
        }
    }
    
    func setupGL() {
        
        // Set current GL context
        EAGLContext.setCurrent(self.context)
        
        // Set up renderer
        self.effect = GLKBaseEffect()   // Init renderer
        self.effect!.light0.enabled = GLboolean(GL_TRUE)    // Add light
        self.effect!.light0.diffuseColor = GLKVector4Make(1.0, 0.4, 0.4, 1.0)   // Set light colour
        
        // Allow depth testing
        glEnable(GLenum(GL_DEPTH_TEST))
        
        // Set up projection matrix
        let aspect = fabsf(Float(self.view.bounds.size.width / self.view.bounds.size.height))
        let projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0), aspect, 0.1, 100.0)
        self.effect?.transform.projectionMatrix = projectionMatrix
        
        // Create object with monkey model
        self.obj = Object(ModelLoader.loadModelFromFile("robot"))
    }
    
    func tearDownGL() {
        EAGLContext.setCurrent(self.context)
        
        // Delete renderer
        self.effect = nil
        
    }
    
    var rotation: Float = 0.0
    // Update view in here
    func update()
    {
        self.obj?.translate(GLKVector3Make(0.0, 0.0, -5.5))
        self.obj?.rotate(rotation, GLKVector3Make(0.0, 1.0, 0.0))
        //self.obj?.scale(GLKVector3Make(1.5, 0.5, 1.0))
        rotation+=0.01
    }
    
    // Draw OpenGL content here
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        glClearColor(0.65, 0.65, 0.65, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT) | GLbitfield(GL_DEPTH_BUFFER_BIT))
        
        self.obj?.draw(self.effect)
    }
}
