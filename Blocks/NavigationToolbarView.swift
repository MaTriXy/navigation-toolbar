//
//  Copyright © 2018 Ramotion. All rights reserved.
//

import UIKit
import Foundation

enum State {
  case horizontal
  case vertical
}

class NavigationToolbarView: UIView {
  private var screens               : [ScreenObject] = []
  private var cellViews             : [CellView]     = []
  
  private var backgroundImageView : UIImageView             = UIImageView()
  private var transitionImageView : AnimationTransitionView = AnimationTransitionView()
  
  private var middleView           : AnimationMiddleView = AnimationMiddleView()
  private var middleViewFrameIsSet : Bool                = true
  private var bottomView           : AnimationBottomView = AnimationBottomView()
  
  private var mainScrollview: UIScrollView = UIScrollView()
  
  private var panRecognizer: UIPanGestureRecognizer!
  
  private var bottomScrollContentSize: CGSize {
    get {
      let w = self.bounds.width * CGFloat(screens.count)
      let h = CGFloat(screens.count) * (Layout.TopView.bottomStateSize + Layout.TopView.bottomStateInterval)
   
      return CGSize(width: w, height: h)
    }
  }
  
  private var duration: Double = 0.75
  
  private var currentIndex: Int = 0
  
  private var needMakeHorizontalFrames : Bool = true
  private var shouldShowSCALV          : Bool = true
  private var menuIsOpen               : Bool = false
  
  private var prevState: State = .horizontal
  private var state: State = .horizontal {
    didSet {
      mainScrollview.isScrollEnabled = false
      
      self.prevState = oldValue
      
      switch state {
      case .horizontal:
        mainScrollview.isPagingEnabled = true
//        mainScrollview.contentInset = UIEdgeInsets(top: 0, left: -((cellViews.first?.frame.minX)!), bottom: -((cellViews.last?.frame.maxY)!), right: -1 * (self.mainScrollview.contentSize.width - ((cellViews.last?.frame.maxX)!)))
        
      case .vertical:
        mainScrollview.isPagingEnabled = false
//        mainScrollview.contentInset = UIEdgeInsets(top: 0, left: -(cellViews[currentIndex].frame.minX), bottom: 0, right: -1 * (self.mainScrollview.contentSize.width - ((cellViews.last?.frame.maxX)!)))
      }
      
      setViewsState(progress: getNormalizedProgress(), state: state)
      
      self.mainScrollview.isScrollEnabled = true
    }
  }
  
  private var menuButton: AnimationProgressButton = AnimationProgressButton()
  
  init(screens: [ScreenObject]) {
    super.init(frame:.zero)
    
    self.screens = screens
    
    setup()
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }
  
  var scrollBg = UIView()
  
  private func setup() {
    self.backgroundColor = .gray
    
    backgroundImageView.image         = UIImage(named :"collection_bg")
    backgroundImageView.contentMode   = .scaleAspectFill
    backgroundImageView.clipsToBounds = true
    
    self.panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(processPan))
  
    bottomView.setScreens(screens: self.screens)
    bottomView.scrollView.delegate                     = self
    
    mainScrollview.delegate                 = self
    mainScrollview.clipsToBounds            = false
    mainScrollview.backgroundColor          = UIColor.clear
    mainScrollview.isPagingEnabled          = true
    mainScrollview.bounces                  = false
    mainScrollview.isDirectionalLockEnabled = true
    mainScrollview.decelerationRate         = 1.0
    
    if #available(iOS 11.0, *) {
      mainScrollview.contentInsetAdjustmentBehavior = .never
    }
    
    scrollBg.backgroundColor = UIColor.darkGray
    
    menuButton.setTitle("M", for: .normal)
    menuButton.addTarget(self, action: #selector(tapMenuButton), for: .touchUpInside)
    
    transitionImageView.delegate = self
    
    self.addSubview(backgroundImageView)
    self.addSubview(transitionImageView)
    self.makeCells()
    self.addSubview(mainScrollview)
    self.addSubview(middleView)
    self.addSubview(bottomView)
    self.addSubview(menuButton)
    
    self.middleView.addGestureRecognizer(panRecognizer!)
    
    mainScrollview.contentInset = UIEdgeInsets(top: 0, left: -((cellViews.first?.frame.minX)!), bottom: -((cellViews.last?.frame.maxY)!), right: -1 * (self.mainScrollview.contentSize.width - ((cellViews.last?.frame.maxX)!)))
    
    print("-----------------------")
    print("JUST STARTED: top state")
    print("-----------------------")
    showTOPCOL()
    hideSCALV()
    hideMIDCOLTXT()
    hideCELLV()
    printStates()
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    backgroundImageView.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)

    mainScrollview.contentSize = bottomScrollContentSize
    let w = self.bounds.width
    
    mainScrollview.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)
 
    if middleViewFrameIsSet {
      middleView.frame = CGRect(x: 0, y: Layout.TopView.topStateSize, width: self.bounds.width, height: Layout.MidView.height)
      middleViewFrameIsSet = false
    }
    transitionImageView.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: middleView.frame.minY)
    transitionImageView.currentHeight = middleView.frame.minY
    
    bottomView.frame = CGRect(x: 0, y: middleView.frame.maxY, width: CGFloat(w), height: self.bounds.height - middleView.frame.maxY)
    
    for i in 0..<cellViews.count {
      cellViews[i].frame = makeFrames()[i]
    }
    if state == .vertical {
      setScrollOffset()
    }
    
    menuButton.frame = CGRect(x: 8, y: 22, width: 32, height: 32)
  }
  
  @objc private func tapMenuButton() {
    self.hideTOPCOL()
    self.hideMIDCOLTXT()
    self.hideSCALV()
    self.showCELLV()
    if !menuIsOpen {
      UIView.animate(withDuration: duration, animations: {
        self.middleView.frame.origin.y = self.bounds.height
        self.setNeedsLayout()
        self.layoutIfNeeded()
        self.state = .vertical
      }) { (completed) in
        if completed {
          self.menuIsOpen = true
        }
      }
    } else {
      UIView.animate(withDuration: duration, animations: {
        self.middleView.frame.origin.y = Layout.TopView.topStateSize
        self.setNeedsLayout()
        self.layoutIfNeeded()
      }) { (completed) in
        if completed {
          self.menuIsOpen = false
          self.state = .horizontal
        }
      }
    }
  }
  
}

extension NavigationToolbarView: UIScrollViewDelegate, AnimationTransitionViewDelegate {
  
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    updateIndex()
  }
  
  func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    updateIndex()
  }
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    
    
    if self.mainScrollview.isTracking {
      bottomView.scrollView.contentOffset.x = self.mainScrollview.contentOffset.x
      syncOffsets()
    }
    if bottomView.scrollView.isTracking {
      self.mainScrollview.contentOffset.x = bottomView.scrollView.contentOffset.x
      syncOffsets()
    }
    
    if self.mainScrollview.isDragging {
      bottomView.scrollView.contentOffset.x = self.mainScrollview.contentOffset.x
      syncOffsets()
    }
    if bottomView.scrollView.isDragging {
      self.mainScrollview.contentOffset.x = bottomView.scrollView.contentOffset.x
      syncOffsets()
    }
    
    if self.mainScrollview.isDecelerating {
      bottomView.scrollView.contentOffset.x = self.mainScrollview.contentOffset.x
      syncOffsets()
    }
    if bottomView.scrollView.isDecelerating {
      self.mainScrollview.contentOffset.x = bottomView.scrollView.contentOffset.x
      syncOffsets()
    }
  }
  
  func setScrollOffset(offset: CGFloat) {
    self.mainScrollview.contentOffset.x = offset
    bottomView.scrollView.contentOffset.x = self.mainScrollview.contentOffset.x
  }
  
  private func syncOffsets() {
    transitionImageView.collectionViewNavbar?.contentOffset.x   = self.mainScrollview.contentOffset.x
    transitionImageView.collectionViewMidText?.contentOffset.x  = self.mainScrollview.contentOffset.x
    transitionImageView.collectionViewMidImage?.contentOffset.x = self.mainScrollview.contentOffset.x
  }
  
  private func updateIndex() {
    if state != .vertical {
      currentIndex = Int(CGFloat(Int(mainScrollview.contentOffset.x / self.bounds.width)))
      transitionImageView.index = currentIndex
      
      let image = screens[currentIndex].image
        
      let gradient    : UIImage = UIImage.imageWithGradient(from    : UIColor.red, to    : UIColor.blue)
      let mergedImage : UIImage = UIImage.mergeImages(bottom : gradient, top : image)
      
      var left = ""
      var right = ""
      
      if currentIndex == 0 {
        left = ""
        right = screens[currentIndex + 1].title
      } else if currentIndex == 1 {
        left = screens[currentIndex - 1].title
        right = screens[currentIndex + 1].title
      } else if currentIndex == screens.count - 1 {
        left = screens[currentIndex - 1].title
        right = ""
      } else if currentIndex == screens.count - 2 {
        left = screens[currentIndex - 1].title
        right = screens[currentIndex + 1].title
      } else {
        left = screens[currentIndex - 1].title
        right = screens[currentIndex + 1].title
      }
      
      transitionImageView.scalingView.setData(title: screens[currentIndex].title, image: mergedImage, left: left, right: right)
    }
  }
  
}

extension NavigationToolbarView {
  
  @objc private func processPan() {
    let location = panRecognizer.location(in: self)
    
    switch panRecognizer.state {
    case .changed:
      UIView.animate(withDuration: duration, animations: {
        self.middleView.frame = CGRect(x: 0, y: location.y - Layout.MidView.height / 2, width: self.bounds.width, height: Layout.MidView.height)
        self.setNeedsLayout()
        self.layoutIfNeeded()
      }) { (completed) in
        switch self.middleView.frame.origin.y {
        case ..<0, 0..<64:
          self.state = .horizontal
          self.shouldShowSCALV = true
          print("------------")
          defer {
            print("CHANGED-COMPLETED: pre top state")
            print("STATE: \(self.state)")
            self.printStates()
            print("------------")
          }
          break
        case 64:
          self.state = .horizontal
          self.shouldShowSCALV = true
          self.showTOPCOL()
          print("------------")
          defer {
            print("CHANGED-COMPLETED: top state")
            print("STATE: \(self.state)")
            self.printStates()
            print("------------")
          }
          break
        case 65..<Layout.TopView.middleStateSize:
          self.shouldShowSCALV = true
          self.state = .horizontal
          self.showSCALV()
          self.hideTOPCOL()
          self.hideMIDCOLTXT()
          self.hideCELLV()
          self.printStates()
          print("------------")
          defer {
            print("CHANGED-COMPLETED: pre mid state")
            print("STATE: \(self.state)")
            
            print("------------")
          }
          break
        case Layout.TopView.middleStateSize:
          self.state = .horizontal
          self.shouldShowSCALV = false
          print("------------")
          defer {
            print("CHANGED-COMPLETED: mid state")
            print("STATE: \(self.state)")
            self.printStates()
            print("------------")
          }
          break
        case Layout.TopView.middleStateSize + 1..<Layout.TopView.middleStateSize + Layout.TopView.middleStateSize / 2:
          self.state = .vertical
          self.shouldShowSCALV = false
          self.hideMIDCOLTXT()
          self.hideTOPCOL()
          self.hideSCALV()
          self.showCELLV()
          self.printStates()
          print("------------")
          defer {
            print("CHANGED-COMPLETED: post mid state")
            print("STATE: \(self.state)")
            
            print("------------")
          }
          break
        case Layout.TopView.middleStateSize + 1 + Layout.TopView.middleStateSize / 2...self.bounds.height:
          self.state = .vertical
          self.shouldShowSCALV = false
          self.hideMIDCOLTXT()
          self.hideTOPCOL()
          self.hideSCALV()
          print("------------")
          defer {
            print("CHANGED-COMPLETED: bottom state")
            print("STATE: \(self.state)")
            self.printStates()
            
            print("------------")
          }
          break
        default:
          break
        }
      }
      break
    case .possible, .ended, .cancelled, .failed:
      UIView.animate(withDuration: duration, animations: {
        switch self.middleView.frame.origin.y {
        case ..<0, 0..<64:
          self.middleView.frame = CGRect(x: 0, y: Layout.TopView.topStateSize, width: self.bounds.width, height: Layout.MidView.height)
          self.state = .horizontal
          print("------------")
          defer {
            print("ENDED-STARTED: pre zero state")
            print("STATE: \(self.state)")
            self.printStates()
            print("------------")
          }
          break
        case 64:
          self.middleView.frame = CGRect(x: 0, y: Layout.TopView.topStateSize, width: self.bounds.width, height: Layout.MidView.height)
          self.state = .horizontal
          self.hideSCALV()
          print("------------")
          defer {
            print("ENDED-STARTED: top state")
            print("STATE: \(self.state)")
            self.printStates()
            print("------------")
          }
          break
        case 65..<Layout.TopView.middleStateSize / 2:
          self.middleView.frame = CGRect(x: 0, y: Layout.TopView.topStateSize, width: self.bounds.width, height: Layout.MidView.height)
          self.state = .horizontal
          print("------------")
          defer {
            print("ENDED-STARTED: post top state")
            print("STATE: \(self.state)")
            self.printStates()
            print("------------")
          }
          break
        case Layout.TopView.middleStateSize / 2 + 1..<Layout.TopView.middleStateSize:
          self.middleView.frame = CGRect(x: 0, y: Layout.TopView.middleStateSize, width: self.bounds.width, height: Layout.MidView.height)
          self.state = .horizontal
          print("------------")
          defer {
            print("ENDED-STARTED: pre mid state")
            print("STATE: \(self.state)")
            self.printStates()
            print("------------")
          }
          break
        case Layout.TopView.middleStateSize:
          self.middleView.frame = CGRect(x: 0, y: Layout.TopView.middleStateSize, width: self.bounds.width, height: Layout.MidView.height)
          self.state = .horizontal
          print("------------")
          defer {
            print("ENDED-STARTED: mid state")
            print("STATE: \(self.state)")
            self.printStates()
            print("------------")
          }
          self.hideSCALV()
          break
        case Layout.TopView.middleStateSize + 1..<Layout.TopView.middleStateSize + Layout.TopView.middleStateSize / 2:
          self.middleView.frame = CGRect(x: 0, y: Layout.TopView.middleStateSize, width: self.bounds.width, height: Layout.MidView.height)
          self.state = .vertical
          print("------------")
          defer {
            print("ENDED-STARTED: post mid state")
            print("STATE: \(self.state)")
            self.showCELLV()
            self.printStates()
            print("------------")
          }
          break
        case Layout.TopView.middleStateSize + 1 + Layout.TopView.middleStateSize / 2...self.bounds.height:
          self.middleView.frame = CGRect(x: 0, y: self.bounds.height, width: self.bounds.width, height: Layout.MidView.height)
          self.state = .vertical
          self.hideSCALV()
          print("------------")
          defer {
            print("ENDED-STARTED: bottom state")
            print("STATE: \(self.state)")
            self.printStates()
            print("------------")
          }
          break
        default:
          break
        }
        self.setNeedsLayout()
        self.layoutIfNeeded()
      }) { (completed) in
        switch self.middleView.frame.origin.y {
        case ..<0, 0..<64:
          self.state = .horizontal
          print("------------")
          defer {
            print("ENDED-COMPLETED: pre zero state")
            print("STATE: \(self.state)")
            self.printStates()
            print("------------")
          }
          break
        case 64:
          self.state = .horizontal
          print("------------")
          self.hideSCALV()
          self.hideCELLV()
          defer {
            print("ENDED-COMPLETED: top state")
            print("STATE: \(self.state)")
            self.printStates()
            print("------------")
          }
          break
        case 65..<Layout.TopView.middleStateSize / 2:
          self.state = .horizontal
          print("------------")
          defer {
            print("ENDED-COMPLETED: post top state")
            print("STATE: \(self.state)")
            self.printStates()
            print("------------")
          }
          break
        case Layout.TopView.middleStateSize / 2 + 1..<Layout.TopView.middleStateSize:
          self.state = .horizontal
          print("------------")
          defer {
            print("ENDED-COMPLETED: pre mid state")
            print("STATE: \(self.state)")
            self.printStates()
            print("------------")
          }
          break
        case Layout.TopView.middleStateSize:
          self.state = .horizontal
          print("------------")
          self.hideSCALV()
          self.hideTOPCOL()
          self.showMIDCOLTXT()
          self.hideCELLV()
          defer {
            print("ENDED-COMPLETED: mid state")
            print("STATE: \(self.state)")
            self.printStates()
            print("------------")
          }
          self.hideSCALV()
          self.hideTOPCOL()
          break
        case Layout.TopView.middleStateSize + 1..<Layout.TopView.middleStateSize + Layout.TopView.middleStateSize / 2:
          self.state = .vertical
          print("------------")
          defer {
            print("ENDED-COMPLETED: post mid state")
            print("STATE: \(self.state)")
            self.printStates()
            print("------------")
          }
          break
        case Layout.TopView.middleStateSize + 1 + Layout.TopView.middleStateSize / 2...self.bounds.height:
          self.state = .vertical
          print("------------")
          defer {
            print("ENDED-COMPLETED: bottom state")
            print("STATE: \(self.state)")
            self.printStates()
            print("------------")
          }
          break
        default:
          break
        }
        self.setNeedsLayout()
        self.layoutIfNeeded()
        switch self.state {
        case .horizontal:
          self.mainScrollview.contentInset = UIEdgeInsets(top: 0, left: -((self.cellViews.first?.frame.minX)!), bottom: -((self.self.cellViews.last?.frame.maxY)!), right: -1 * (self.mainScrollview.contentSize.width - ((self.cellViews.last?.frame.maxX)!)))
        case .vertical:
          self.mainScrollview.contentInset = UIEdgeInsets(top: 0, left: -(self.cellViews[self.currentIndex].frame.minX), bottom: 0, right: -1 * (self.mainScrollview.contentSize.width - ((self.cellViews.last?.frame.maxX)!)))
        }
      }
      break
    default:
      break
    }
  }
  
}

extension NavigationToolbarView {
  
  private func makeCells() {
    for i in 0..<screens.count {
      let view = CellView()
      view.delegate = self
      
      let gradient    : UIImage = UIImage.imageWithGradient(from    : UIColor.red, to    : UIColor.blue)
      let mergedImage : UIImage = UIImage.mergeImages(bottom : gradient, top : screens[i].image)
      
      view.setData(data: (text: screens[i].title, image: mergedImage), index: i)
      transitionImageView.images.append(mergedImage)
      transitionImageView.strings.append(screens[i].title)
      cellViews.append(view)
    }
    for view in cellViews {
      mainScrollview.addSubview(view)
    }
    let gradient    : UIImage = UIImage.imageWithGradient(from    : UIColor.red, to    : UIColor.blue)
    let mergedImage : UIImage = UIImage.mergeImages(bottom : gradient, top : screens.first!.image)
    transitionImageView.scalingView.setData(title: (screens.first?.title)!, image: mergedImage, left: "", right: screens[1].title)
  }
  
  private func makeFrames() -> [CGRect] {
    var frames: [CGRect] = []
//    print("---------------------")
//    print("MAKE FRAMES STATE: \(state)")
//    print("---------------------")
    if state == .horizontal {
      for i in 0..<cellViews.count {
        let frame = CGRect(x: CGFloat(i) * self.bounds.width, y: 0, width: self.bounds.width, height: middleView.frame.minY)
        frames.append(frame)
      }
    } else {
      let vertical : CGFloat = CGFloat(Layout.TopView.bottomStateInterval)
      let progress = getNormalizedProgress()
      let w: CGFloat = self.bounds.width
      
      for i in 0..<cellViews.count {
        let iterator  : CGFloat = CGFloat(i)
        let tempIndex : CGFloat = CGFloat(currentIndex)
        let heightDiff          = Layout.TopView.middleStateSize - Layout.TopView.bottomStateSize

        let frame = CGRect(x: w * iterator + progress * (w * tempIndex - w * iterator),
                           y: (iterator * Layout.TopView.bottomStateSize + iterator * CGFloat(vertical)) * progress,
                       width: w,
                      height: Layout.TopView.middleStateSize - (heightDiff * progress))
        
        frames.append(frame)
        
        cellViews[i].setState(progress: progress, state: state)
      }
    }
    
    return frames
  }
  
  private func getNormalizedProgress() -> CGFloat {
    if Layout.TopView.middleStateSize...self.bounds.height ~= middleView.frame.origin.y {
      let diff: CGFloat = self.bounds.height - Layout.TopView.middleStateSize
      
      menuButton.setProgress((middleView.frame.minY - Layout.TopView.middleStateSize) / diff > 1.0 ? 1.0 : (middleView.frame.minY - Layout.TopView.middleStateSize) / diff) 
      
      return (middleView.frame.minY - Layout.TopView.middleStateSize) / diff > 1.0 ? 1.0 : (middleView.frame.minY - Layout.TopView.middleStateSize) / diff
    }
    
    return 0.0
  }
  
  private func setScrollOffset() {
    let cellView = cellViews.filter({$0.index == Int(currentIndex)}).first
    
    let vertical : CGFloat = CGFloat(Layout.TopView.bottomStateInterval)
    
    let minY = CGFloat(currentIndex) * (Layout.TopView.bottomStateSize + CGFloat(vertical))
    
    let diffX = mainScrollview.contentOffset.x - (cellView?.frame.minX)!
    let diffY = min(minY, self.mainScrollview.contentSize.height - self.bounds.height)
    
    self.mainScrollview.contentOffset.x = (cellView?.frame.minX)! - diffX * getNormalizedProgress()
    self.mainScrollview.contentOffset.y = diffY * getNormalizedProgress()
  }
  
  private func setViewsState(progress: CGFloat, state: State) {
    for view in cellViews {
      view.setState(progress: progress, state: state)
    }
  }
  
}

extension NavigationToolbarView: CellViewDelegate {
  
  func didTapCell(index: Int, cell: CellView) {
    if state == .vertical {
      print("CELL INDEX TAPPED: \(index)")
      currentIndex = index
      
      UIView.animate(withDuration: duration, animations: {
        self.middleView.frame = CGRect(x: 0, y: Layout.TopView.middleStateSize, width: self.bounds.width, height: Layout.MidView.height)
        self.setNeedsLayout()
        self.layoutIfNeeded()
      } ) { ( completed) in
        if completed {
          self.state = .horizontal
          self.mainScrollview.contentInset = UIEdgeInsets(top: 0, left: -((self.cellViews.first?.frame.minX)!), bottom: -((self.cellViews.last?.frame.maxY)!), right: -1 * (self.mainScrollview.contentSize.width - ((self.cellViews.last?.frame.maxX)!)))
          self.processPan()
        }
      }
    }
    bottomView.setActiveView(index: index)
    transitionImageView.setActiveView(index: index)
  }
  
}

extension NavigationToolbarView {
  
  private func showSCALV() {
//    if shouldShowSCALV {
      self.transitionImageView.scalingView.isHidden = false
//    }
  }
  
  private func hideSCALV() {
    self.transitionImageView.scalingView.isHidden = true
  }
  
  private func showTOPCOL() {
    self.transitionImageView.collectionViewNavbar.isHidden = false
  }
  
  private func hideTOPCOL() {
    self.transitionImageView.collectionViewNavbar.isHidden = true
  }
  
  private func showMIDCOLTXT() {
    self.transitionImageView.collectionViewMidImage.isHidden = false
    self.transitionImageView.collectionViewMidText.isHidden = false
  }
  
  private func hideMIDCOLTXT() {
    self.transitionImageView.collectionViewMidImage.isHidden = true
    self.transitionImageView.collectionViewMidText.isHidden = true
  }
  
  private func showCELLV() {
    self.mainScrollview.isHidden = false
  }
  
  private func hideCELLV() {
    self.mainScrollview.isHidden = true
  }
  
  private func printStates() {
    print("‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡")
    print(" ---------------")
    print("|isHidden - ▼▼▼▼|")
    print(" ---------------")
    print("|SCALV    : \(self.transitionImageView.scalingView.isHidden)|")
    print("|TOPCOL   : \(self.transitionImageView.collectionViewNavbar.isHidden)|")
    print("|MIDCOLTXT: \(self.transitionImageView.collectionViewMidImage.isHidden)|")
    print("|CELLV    : \(self.mainScrollview.isHidden)|")
    print(" ---------------")
    print("‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡‡")
    
//    let bin = 0b0001
//
//    print(bin << 0 & bin)
//    print(bin << 1 & bin)
//    print(bin << 2 & bin)
//    print(bin << 3 & bin)
  }
  
}