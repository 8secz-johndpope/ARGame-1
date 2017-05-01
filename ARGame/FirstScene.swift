//
//  FirstScene.swift
//  ARGame
//
//  Created by James Rogers on 07/04/2017.
//  Copyright © 2017 James Rogers. All rights reserved.
//

import Foundation

class FirstScene : Scene
{
    public func initaliseScene()
    {
        super.effectMaterial = EffectMaterial()
        super.effectMaterialAnimated = EffectMatAnim()
        
        let entityLoader = EntityLoader()
        entityLoader.loadEntityFromFile("ganfaul", self);
        entityLoader.loadEntityFromFile("beta", self);
        
        
        let animation1 = ("beta_breathing_idle", AnimationLoader.loadAnimationFromFile("beta_breathing_idle", "fbx")!)
        if !super.addAnimation(animation1)
        {
            print("Could not add Animation: \(animation1.0) to scene")
        }
        
        self.entitesAnimated["beta"]?.glModel.animationController.loop(animation1)
        
        
        /*let animation2 = ("maria_breathing_idle", AnimationLoader.loadAnimationFromFile("maria_breathing_idle2", "fbx")!)
        if !super.addAnimation(animation2)
        {
            print("Could not add Animation: \(animation2.0) to scene")
        }
        
        self.entitesAnimated["maria"]?.glModel.animationController.loop(animation2)*/
        
    }
}
