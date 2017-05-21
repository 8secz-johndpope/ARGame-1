//
//  STATELoose.swift
//  ARGame
//
//  Created by James Rogers on 13/05/2017.
//  Copyright © 2017 James Rogers. All rights reserved.
//

import Foundation

class STATELose : STATE<FighterAI>
{
    
    override public func run(parent: FighterAI) -> Int
    {
        parent.lose()
        
        return FighterStates.S_END.rawValue
    }
}
