//
//  Button.swift
//  NavigationToolbar
//
//  Created by obozhdi on 22/05/2018.
//  Copyright © 2018 ramotion. All rights reserved.
//

import Foundation
import UIKit

public class Button: UIButton {
  
  private var view = ProgressView()
  public private(set) var progress = CGFloat(0.0)
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    self.setup()
  }
  
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.setup()
  }
  
  public override func layoutSubviews() {
    super.layoutSubviews()
    self.view.frame = CGRect(x: bounds.width / 2 - frame.width / 2, y: bounds.height / 2 - view.frame.height / 2, width: 30, height: 22)
    self.view.frame = CGRect(x: bounds.width / 2 - frame.width / 2, y: bounds.height / 2 - view.frame.height / 2, width: 30, height: 22)
  }
  
  public func setProgress(_ aProgress: CGFloat) {
    self.progress = min(max(aProgress, 0.0), 1.0)
    self.view.setProgress(self.progress)
  }
  
  public override func setTitle(_ title: String?, for state: UIControlState) {
    return
  }
  
  public override func setImage(_ image: UIImage?, for state: UIControlState) {
    return
  }
  
  public override func setBackgroundImage(_ image: UIImage?, for state: UIControlState) {
    return
  }
  
  public func animate(progress: CGFloat, duration: TimeInterval) {
    self.view.animate(progress: progress, duration: duration)
  }
  
  private func setup() {
    view.isUserInteractionEnabled = false
    addSubview(view)
  }
}


private class ProgressView: UIView {
  
  public private(set) var progress = CGFloat(0.0)
  private let shapeLayer = CAShapeLayer()
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    
    self.shapeLayer.strokeColor = UIColor.white.cgColor
    self.layer.addSublayer(self.shapeLayer)
    self.setNeedsLayout()
    self.layoutIfNeeded()
  }
  
  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public func setProgress(_ aProgress: CGFloat) {
    self.progress = min(max(aProgress, 0.0), 1.0)
    
    self.setNeedsLayout()
    self.layoutIfNeeded()
  }
  
  public func animate(progress: CGFloat, duration: TimeInterval) {
    UIGraphicsBeginImageContext(self.bounds.size)
    let toPath = self.path(progress: progress).cgPath
    let animation = CABasicAnimation()
    animation.duration = duration
    animation.keyPath = "path"
    animation.fromValue = self.shapeLayer.path
    animation.toValue = toPath
    self.shapeLayer.add(animation, forKey: "shapeAnimation")
    self.shapeLayer.path = toPath
  }
  
  public override func layoutSubviews() {
    super.layoutSubviews()
    
    self.shapeLayer.frame = self.bounds
    self.updateLayer()
  }
  
  private func updateLayer() {
    self.shapeLayer.lineWidth = 3
    self.shapeLayer.path = self.path(progress: self.progress).cgPath
  }
  
  private func path(progress: CGFloat) -> UIBezierPath {
    UIColor.white.setStroke()
    let path = UIBezierPath()
    
    let topXmodifier = progress * 28
    let midXmodifier = progress * 20
    let botXmodifier = progress * 13
    
    let topYmodifier = progress * 10
    let botYmodifier = progress * 10
    
    let startTop  = CGPoint(x: 0, y: 1.5 + topYmodifier)
    let finishTop = CGPoint(x: 28 - topXmodifier * 0.66, y: 1.5)
    
    path.move(to: startTop)
    path.addLine(to: finishTop)
    
    let startMid  = CGPoint(x: 0, y: 11)
    let finishMid = CGPoint(x: 20 + midXmodifier * (20 / 32), y: 11)
    
    path.move(to: startMid)
    path.addLine(to: finishMid)
    
    let startBot  = CGPoint(x: 0, y: 20.5 - botYmodifier)
    let finisBot  = CGPoint(x: 13 - botXmodifier * 0.27, y: 20.5)
    
    path.move(to: startBot)
    path.addLine(to: finisBot)
    
    return path
  }
}

