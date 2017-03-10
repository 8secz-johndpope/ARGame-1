//
//  Effect.swift
//  ARGame
//
//  Created by James Rogers on 10/03/2017.
//  Copyright © 2017 James Rogers. All rights reserved.
//

import Foundation

class Effect
{
    private var shader:Shader!
    
    private var projection:GLKMatrix4 = GLKMatrix4Identity
    private var view:GLKMatrix4 = GLKMatrix4Identity
    private var model:GLKMatrix4 = GLKMatrix4Identity
    private var colour: GLKVector4 = GLKVector4Make(0.0, 0.0, 0.0, 0.0)
    private var texture0: GLuint = 0
    private var texture1: GLuint = 0
    
    internal init(_ vertex: String, _ fragment: String, _ vertexAttribs: [(GLint, String)], _ uniformNames:[String])
    {
       
        self.shader = Shader.loadShader(vertex, fragment, vertexAttribs, uniformNames)
        if(shader == nil)
        {
            print("Failed to create shader")
        }
        
    }
    
    public func setProjection(_ projection: GLKMatrix4)
    {
        self.projection = projection
    }
    
    public func setView(_ view:GLKMatrix4)
    {
        self.view = view
    }
    
    public func setModel(_ model: GLKMatrix4)
    {
        self.model = model
    }
    
    public func setColour(_ colour: GLKVector4)
    {
        self.colour = colour
    }
    
    public func setTexture0(_ texture: GLuint)
    {
        self.texture0 = texture
    }
    
    public func setTexture1(_ texture: GLuint)
    {
        self.texture1 = texture
    }
    
    internal func prepareToDraw()
    {
        self.shader.useProgram()
        
        // Compute model view matrix
        let modelViewMatrix = GLKMatrix4Multiply(self.view, self.model)
        var modelViewProjectionMatrix = GLKMatrix4Multiply(self.projection, modelViewMatrix)
        
        // Set up the modelViewProjection matrix in the shader
        withUnsafePointer(to: &modelViewProjectionMatrix, {
            $0.withMemoryRebound(to: Float.self, capacity: 16, {
                glUniformMatrix4fv(self.shader.getUniformLocation("modelViewProjectionMatrix"), 1, 0, $0)
            })
        })
        
        // Set up the colour in the shader
        withUnsafePointer(to: &colour, {
            $0.withMemoryRebound(to: Float.self, capacity: 4, {
                glUniform4fv(self.shader.getUniformLocation("colour"), 1, $0)
            })
        })
        
        // Set up the texture in the shader
        glActiveTexture(GLenum(GL_TEXTURE0))
        glUniform1f(self.shader.getUniformLocation("texture0"), 0)
        glBindTexture(GLenum(GL_TEXTURE_2D), self.texture0)
        
        glActiveTexture(GLenum(GL_TEXTURE1))
        glUniform1f(self.shader.getUniformLocation("texture1"), 0)
        glBindTexture(GLenum(GL_TEXTURE_2D), self.texture1)
    }
}











