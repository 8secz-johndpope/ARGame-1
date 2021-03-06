//
//  MaterialData.swift
//  ARGame
//
//  Created by James Rogers on 23/03/2017.
//  Copyright © 2017 James Rogers. All rights reserved.
//

import Foundation

struct Material
{
    /**
     The diffuse texture.
     */
    var diffuseTexture: (Bool, String) = (false, "")
    
    /**
     The specular texture.
     */
    var specularTexture: (Bool, String) = (false, "")
    
    /**
     The diffuse colour.
     */
    var diffuseColour: GLKVector4 = GLKVector4()
    
    /**
     The specular colour.
     */
    var specularColour: GLKVector4 = GLKVector4()
    
    /**
     The shininess factor.
     */
    var shininess: Float = 0.0
    
    init()
    {}
    
    init(_ diffuseTexture: (Bool, String), _ specularTexture: (Bool, String), _ diffuseColour: GLKVector4, _ specularColour: GLKVector4, _ shininess: Float)
    {
        self.diffuseTexture = diffuseTexture
        self.specularTexture = specularTexture
        self.diffuseColour = diffuseColour
        self.specularColour = specularColour
        self.shininess = shininess
    }
}
