//
//  TopView.swift
//  NavigationToolbar
//
//  Created by obozhdi on 22/05/2018.
//  Copyright © 2018 ramotion. All rights reserved.
//

import UIKit

protocol TopViewDelegate {
  func topDidScroll(offset: CGFloat)
}

class TopView: UIView {
  
  private var collectionViewTop         : UICollectionView!
  private var collectionViewMiddleImage : UICollectionView!
  private var collectionViewMiddleText  : UICollectionView!
  private var sizingView                : SizingView = SizingView()
  
  private var images : [UIImage] = []
  private var titles : [String]  = []
  
  private var direction    : UICollectionViewScrollDirection = .horizontal
  
  var delegate: TopViewDelegate?
  
  var currentIndex : Int = 0 {
    didSet {
      updateSizingView(index: currentIndex)
    }
  }
  
  var currentOffset: CGFloat = 0.0 {
    didSet {
      collectionViewTop.contentOffset.x         = currentOffset
      collectionViewMiddleImage.contentOffset.x = currentOffset
      collectionViewMiddleText.contentOffset.x  = currentOffset
      updateIndex()
    }
  }
  
  var size: CGFloat = Settings.Sizes.navbarSize {
    didSet {
      setNeedsLayout()
      layoutIfNeeded()
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }
  
  private func setup() {
    hideSizingView()
    setupCollections()
    setCollectionsLayout()
    
    addSubview(collectionViewTop)
    addSubview(collectionViewMiddleImage)
    addSubview(collectionViewMiddleText)
    addSubview(sizingView)
  }
  
  private func setupCollections() {
    collectionViewTop                                 = UICollectionView(frame : .zero, collectionViewLayout : AnimatedCollectionViewLayout())
    collectionViewTop.delegate                        = self
    collectionViewTop.dataSource                      = self
    collectionViewTop.backgroundView?.backgroundColor = .clear
    collectionViewTop.backgroundColor                 = .clear
    collectionViewTop.isHidden                       = false
    collectionViewTop.showsHorizontalScrollIndicator = false
    collectionViewTop.showsVerticalScrollIndicator   = false
    collectionViewTop.register(TopViewCellOne.self, forCellWithReuseIdentifier: "TopViewCellOne")
    
    collectionViewMiddleImage                                 = UICollectionView(frame : .zero, collectionViewLayout : AnimatedCollectionViewLayout())
    collectionViewMiddleImage.delegate                        = self
    collectionViewMiddleImage.dataSource                      = self
    collectionViewMiddleImage.backgroundView?.backgroundColor = .clear
    collectionViewMiddleImage.backgroundColor                 = .clear
    collectionViewMiddleImage.isHidden = true
    collectionViewMiddleImage.showsHorizontalScrollIndicator = false
    collectionViewMiddleImage.showsVerticalScrollIndicator = false
    collectionViewMiddleImage.register(TopViewCellTwo.self, forCellWithReuseIdentifier: "TopViewCellTwo")
    
    collectionViewMiddleText                                 = UICollectionView(frame : .zero, collectionViewLayout : AnimatedCollectionViewLayout())
    collectionViewMiddleText.delegate                        = self
    collectionViewMiddleText.dataSource                      = self
    collectionViewMiddleText.backgroundView?.backgroundColor = .clear
    collectionViewMiddleText.backgroundColor                 = .clear
    collectionViewMiddleText.isHidden = true
    collectionViewMiddleText.showsHorizontalScrollIndicator = false
    collectionViewMiddleText.showsVerticalScrollIndicator = false
    collectionViewMiddleText.register(TopViewCellThree.self, forCellWithReuseIdentifier: "TopViewCellThree")
  }
  
  private func setCollectionsLayout() {
    if let layout = collectionViewTop?.collectionViewLayout as? AnimatedCollectionViewLayout {
      layout.scrollDirection = direction
      layout.animator = FadeAnimator()
      collectionViewTop?.isPagingEnabled = true
    }
    
    if let layout = collectionViewMiddleImage?.collectionViewLayout as? AnimatedCollectionViewLayout {
      layout.scrollDirection = direction
      layout.animator = FadeAnimator()
      collectionViewMiddleImage?.isPagingEnabled = true
    }
    
    if let layout = collectionViewMiddleText?.collectionViewLayout as? AnimatedCollectionViewLayout {
      layout.scrollDirection = direction
      layout.animator = MovementAnimator()
      collectionViewMiddleText?.isPagingEnabled = true
    }
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    sizingView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: size)
    
    collectionViewTop.frame = CGRect(x: 0, y: 0, width: bounds.width, height: Settings.Sizes.navbarSize)
    collectionViewMiddleImage.frame = CGRect(x: 0, y: 0, width: bounds.width, height: Settings.Sizes.middleSize)
    collectionViewMiddleText.frame = CGRect(x: 0, y: 0, width: bounds.width, height: Settings.Sizes.middleSize)
  }

}

extension TopView {
  
  func setSizingViewHeight(height: CGFloat) {
    size = height
  }
  
  func hideSizingView() {
    sizingView.isHidden = true
  }
  
  func showSizingView() {
    sizingView.isHidden = false
  }
  
  func collapseSizingView() {
    sizingView.animateCollapse()
  }
  
  func toggleTopStateViews() {
    collectionViewTop.isHidden         = false
    collectionViewMiddleImage.isHidden = true
    collectionViewMiddleText.isHidden  = true
  }
  
  func toggleMiddleStateViews() {
    collectionViewTop.isHidden         = true
    collectionViewMiddleImage.isHidden = false
    collectionViewMiddleText.isHidden  = false
  }
  
  func toggleBottomStateViews() {
    collectionViewTop.isHidden         = true
    collectionViewMiddleImage.isHidden = true
    collectionViewMiddleText.isHidden  = true
  }
  
  func setSizingViewProgress(progress: CGFloat) {
    sizingView.progress = progress
  }
  
}

extension TopView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return images.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    switch collectionView {
    case collectionViewTop:
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TopViewCellOne", for: indexPath) as! TopViewCellOne
      cell.backgroundColor = .clear
      cell.setData(title: titles[indexPath.row], image: images[indexPath.row])
      return cell
    case collectionViewMiddleImage:
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TopViewCellTwo", for: indexPath) as! TopViewCellTwo
      cell.backgroundColor = .clear
      cell.setImage(image: images[indexPath.row])
      return cell
    case collectionViewMiddleText:
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TopViewCellThree", for: indexPath) as! TopViewCellThree
      cell.backgroundColor = .clear
      cell.setTitle(title: titles[indexPath.row])
      return cell
    default:
      break
    }
    
    
    return UICollectionViewCell()
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(width: self.bounds.width, height: collectionView.frame.height)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return .zero
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 0
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
    return 0
  }
  
}

extension TopView: UIScrollViewDelegate {
  
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    updateIndex()
  }
  
  func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    updateIndex()
  }
  
  private func updateIndex() {
    currentIndex = Int(collectionViewMiddleImage.contentOffset.x / UIScreen.main.bounds.width)
    (superview as! NavigationView).currentIndex = currentIndex
  }
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if collectionViewMiddleText.isTracking {
      collectionViewTop.contentOffset.x         = collectionViewMiddleText.contentOffset.x
      collectionViewMiddleImage.contentOffset.x = collectionViewMiddleText.contentOffset.x
      delegate?.topDidScroll(offset: collectionViewMiddleText.contentOffset.x)
    }
    if collectionViewMiddleText.isDragging {
      collectionViewTop.contentOffset.x         = collectionViewMiddleText.contentOffset.x
      collectionViewMiddleImage.contentOffset.x = collectionViewMiddleText.contentOffset.x
      delegate?.topDidScroll(offset: collectionViewMiddleText.contentOffset.x)
    }
    if collectionViewMiddleText.isDecelerating {
      collectionViewTop.contentOffset.x         = collectionViewMiddleText.contentOffset.x
      collectionViewMiddleImage.contentOffset.x = collectionViewMiddleText.contentOffset.x
      delegate?.topDidScroll(offset: collectionViewMiddleText.contentOffset.x)
    }
    
    if collectionViewTop.isTracking {
      collectionViewMiddleText.contentOffset.x  = collectionViewTop.contentOffset.x
      collectionViewMiddleImage.contentOffset.x = collectionViewTop.contentOffset.x
      delegate?.topDidScroll(offset: collectionViewTop.contentOffset.x)
    }
    if collectionViewTop.isDragging {
      collectionViewMiddleText.contentOffset.x  = collectionViewTop.contentOffset.x
      collectionViewMiddleImage.contentOffset.x = collectionViewTop.contentOffset.x
      delegate?.topDidScroll(offset: collectionViewTop.contentOffset.x)
    }
    if collectionViewTop.isDecelerating {
      collectionViewMiddleText.contentOffset.x  = collectionViewTop.contentOffset.x
      collectionViewMiddleImage.contentOffset.x = collectionViewTop.contentOffset.x
      delegate?.topDidScroll(offset: collectionViewTop.contentOffset.x)
    }
  }
  
}

extension TopView {
  
  func setData(titles: [String], images: [UIImage]) {
    self.titles = titles
    self.images = images
    
    collectionViewTop.reloadData()
    collectionViewMiddleImage.reloadData()
    collectionViewMiddleText.reloadData()
    updateIndex()
  }
  
  private func updateSizingView(index: Int) {
    var previousTitle : String = ""
    var nextTitle     : String = ""
    
    if index - 1 >= 0 {
      previousTitle = titles[index - 1]
    }
    if index + 1 <= titles.count - 1 {
      nextTitle = titles[index + 1]
    }
    
    sizingView.setData(title: titles[index], image: images[index], previousTitle: previousTitle, nextTitle: nextTitle)
  }
  
  func updateOffsets() {
    let collectionContentOffset: CGPoint = CGPoint(x: CGFloat(currentIndex) * UIScreen.main.bounds.width, y: 0)
    
    collectionViewTop.setContentOffset(collectionContentOffset, animated: false)
    collectionViewMiddleImage.setContentOffset(collectionContentOffset, animated: false)
    collectionViewMiddleText.setContentOffset(collectionContentOffset, animated: false)
  }
  
}
