//
//  GameViewController.swift
//  ARGame
//
//  Created by James Rogers on 16/02/2017.
//  Copyright © 2017 James Rogers. All rights reserved.
//

import GLKit
import OpenGLES

func BUFFER_OFFSET(_ i: Int) -> UnsafeRawPointer?
{
    return UnsafeRawPointer(bitPattern: i)
}

class FightGameController: GLKViewController
{
    
    var context: EAGLContext? = nil
    
    // Indicates if context was create
    var sharingShareGroup: Bool = false
    
    let scene: FightGameScene = FightGameScene()
    
    var arHandler: ARHandler = ARHandler()
    
    deinit
    {
        self.tearDownGL()
        
        if EAGLContext.current() === self.context
        {
            EAGLContext.setCurrent(nil)
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        if self.context == nil
        {
            self.context = EAGLContext(api: .openGLES3)
        }
        
        if !(self.context != nil)
        {
            print("Failed to create ES context")
        }
        
        let view = self.view as! GLKView
        view.context = self.context!
        view.drawableDepthFormat = .format24
        
        self.setupGL()
        
        glFlush()

        //self.scene.initaliseScene()
        //self.scene.initalise(xml: "character-selection")
        
        self.scene.setupGame()
        
        // Initalise the AR handler
        self.arHandler.onViewLoad()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        // Start the AR handler
        self.arHandler.start()
        
        //glViewport(-105, 0, 851, 1136);
        glViewport(0,0, self.arHandler.camWidth, self.arHandler.camHeight)
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        // Stop the AR handler
        self.arHandler.stop()
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        
        /*if self.isViewLoaded && (self.view.window != nil)
        {
            self.view = nil
            
            self.tearDownGL()
            
            if EAGLContext.current() === self.context
            {
                EAGLContext.setCurrent(nil)
            }
            self.context = nil
            
        }*/
    }
    
    func setupGL()
    {
        // Set current GL context
        EAGLContext.setCurrent(self.context)
        
        // Allow depth testing
        glEnable(GLenum(GL_DEPTH_TEST))
        
        if sharingShareGroup
        {
            // Update the VAOs of the objects as VAOs are not shared between contexts
            for (_, entity) in self.scene.entitesStatic
            {
                entity.glModel.updateModelVAO()
            }
        
            for (_, entity) in self.scene.entitesAnimated
            {
                entity.glModel.updateModelVAO()
            }
        }
    }
    
    func tearDownGL()
    {
        EAGLContext.setCurrent(self.context)
        
        self.scene.destroyScene()
    }
    
    // Update view in here
    func update()
    {
        
        if self.arHandler.running
        {
            
            // Update the projection matrix and camera view
            if self.scene.effectMaterial != nil
            {
                self.scene.effectMaterial?.setProjection(self.arHandler.camProjection)
                self.scene.effectMaterial?.setView(self.arHandler.camPose)
            }
            
            if self.scene.effectMaterialAnimated != nil
            {
                self.scene.effectMaterialAnimated?.setProjection(self.arHandler.camProjection)
                self.scene.effectMaterialAnimated?.setView(self.arHandler.camPose)
            }
            
            self.scene.updateScene(delta: self.timeSinceLastUpdate)
            self.scene.updateAnimations()
            
            // Start the animation
            if let entity = self.scene.getEntityAnimated("vangaurd")
            {
                if !entity.glModel.animationController.isPlaying
                {
                    if let animation = self.scene.getAnimation("vangaurd_breathing_idle")
                    {
                        entity.glModel.animationController.play(("vangaurd_breathing_idle", animation), loop: true)
                    }
                }
            }
        }
    }
    
    // Draw OpenGL content here
    override func glkView(_ view: GLKView, drawIn rect: CGRect)
    {
        glClearColor(0.65, 0.65, 0.65, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT) | GLbitfield(GL_DEPTH_BUFFER_BIT))
        
        if self.arHandler.running
        {
            self.arHandler.setViewport()
        
            // Draw the camera view
            self.arHandler.draw()
        
            // Draw the object
            self.scene.render()
        }
    }
    
    
    @IBAction func moveLeftButtonDown(_ sender: UIButton)
    {
        self.scene.player.activateMoveLeft()
    }
    
    @IBAction func moveLeftButtonUp(_ sender: UIButton)
    {
        self.scene.player.deactivateMoveLeft()
    }
    
    @IBAction func moveRightButtonDown(_ sender: UIButton)
    {
        self.scene.player.activateMoveRight()
    }
    
    @IBAction func moveRightButtonUp(_ sender: UIButton)
    {
        self.scene.player.deactivateMoveRight()
    }

    @IBAction func punchButton(_ sender: UIButton)
    {
        self.scene.player.punchButton()
    }
    
    @IBAction func kickButton(_ sender: UIButton)
    {
        self.scene.player.kickButton()
    }
    
    @IBAction func blockButton(_ sender: UIButton)
    {
        self.scene.player.blockButton()
    }
    
    @IBAction func moveLeftButtonDoubleTap(_ sender: UIButton, _ event: UIEvent)
    {
        let t: UITouch = event.allTouches!.first!
        if t.tapCount == 2
        {
            self.scene.player.activateDashLeft()
        }
    }
    
    @IBAction func moveRightButtonDoubleTap(_ sender: UIButton, _ event: UIEvent)
    {
        let t: UITouch = event.allTouches!.first!
        if t.tapCount == 2
        {
            self.scene.player.activateDashRight()
        }
    }
}
