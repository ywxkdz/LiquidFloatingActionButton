//
//  CustomDrawingActionButton.swift
//  LiquidFloatingActionButton-iOS8.0
//
//  Created by Liumao on 2019/7/17.
//

import UIKit


class CustomDrawingActionButton: LiquidFloatingActionButton {


    override public func createPlusLayer(_ frame: CGRect) -> CAShapeLayer {
        
        let plusLayer = CAShapeLayer()
        plusLayer.lineCap = CAShapeLayerLineCap.round
        plusLayer.strokeColor = UIColor.white.cgColor
        plusLayer.lineWidth = 3.0
        
        let w = frame.width
        let h = frame.height
        
        let points = [
            (CGPoint(x: w * 0.25, y: h * 0.35), CGPoint(x: w * 0.75, y: h * 0.35)),
            (CGPoint(x: w * 0.25, y: h * 0.5), CGPoint(x: w * 0.75, y: h * 0.5)),
            (CGPoint(x: w * 0.25, y: h * 0.65), CGPoint(x: w * 0.75, y: h * 0.65))
        ]
        
        let path = UIBezierPath()
        for (start, end) in points {
            path.move(to: start)
            path.addLine(to: end)
        }
        
        plusLayer.path = path.cgPath
        
        return plusLayer
    }

}
