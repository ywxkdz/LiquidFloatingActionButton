//
//  LiquidFloatingActionButton.swift
//  Pods
//
//  Created by Takuma Yoshida on 2015/08/25.
//
//

import Foundation
import QuartzCore

// LiquidFloatingButton DataSource methods
@objc public protocol LiquidFloatingActionButtonDataSource {
    func numberOfCells(_ liquidFloatingActionButton: LiquidFloatingActionButton) -> Int
    func cellForIndex(_ index: Int) -> LiquidFloatingCell
}

@objc public protocol LiquidFloatingActionButtonDelegate {
    // selected method
    @objc optional func liquidFloatingActionButton(_ liquidFloatingActionButton: LiquidFloatingActionButton, didSelectItemAtIndex index: Int)
    @objc optional func liquidFloatingActionButtonWillOpenDrawer(_ liquidFloatingActionButton: LiquidFloatingActionButton) -> Bool
    @objc optional func liquidFloatingActionButtonWillCloseDrawer(_ liquidFloatingActionButton: LiquidFloatingActionButton)
}

public enum LiquidFloatingActionButtonAnimateStyle : Int {
    case up
    case right
    case left
    case down
}

@IBDesignable
open class LiquidFloatingActionButton : UIView {
    
    fileprivate let internalRadiusRatio: CGFloat = 20.0 / 56.0
    open var cellRadiusRatio: CGFloat      = 0.45
    open var animateStyle: LiquidFloatingActionButtonAnimateStyle = .up {
        didSet {
            baseView.animateStyle = animateStyle
        }
    }
    open var enableShadow = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    weak open var delegate:   LiquidFloatingActionButtonDelegate?
    weak open var dataSource: LiquidFloatingActionButtonDataSource?
    
    @objc public  func setUpDelegate(Delegate:LiquidFloatingActionButtonDelegate){
        self.delegate = Delegate
    }
    
    @objc public  func setDataSource(DataSource:LiquidFloatingActionButtonDataSource){
        self.dataSource = DataSource
    }
    
    open var responsible = true
    open var isOpening: Bool  {
        get {
            return !baseView.openingCells.isEmpty
        }
    }
    open fileprivate(set) var isClosed: Bool = true
    
    @IBInspectable open var color: UIColor = .clear {
        
        didSet {
            if #available(iOS 10.0, *) {
                baseView.color = UIColor(displayP3Red: 255.0/255.0, green: 95.0/255.0, blue: 62.0/255.0, alpha: 1.0)
            } else {
                // Fallback on earlier versions
            }
        }
    }
    
    @objc open var image: UIImage? {
        didSet {
            if image != nil {
                plusLayer.contents = image!.cgImage
                plusLayer.path = nil
            }
        }
    }
    
    @IBInspectable open var rotationDegrees: CGFloat = 45.0
    
    fileprivate var plusLayer   = CAShapeLayer()
    fileprivate let circleLayer = CAShapeLayer()
    
    fileprivate var touching = false
    
    fileprivate var baseView = CircleLiquidBaseView()
    fileprivate let liquidView = UIView()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    fileprivate func insertCell(_ cell: LiquidFloatingCell) {
        cell.color  = .clear
        cell.radius = self.frame.width * cellRadiusRatio
        cell.center = self.center.minus(self.frame.origin)
        cell.actionButton = self
        insertSubview(cell, aboveSubview: baseView)
    }
    
    fileprivate func cellArray() -> [LiquidFloatingCell] {
        var result: [LiquidFloatingCell] = []
        if let source = dataSource {
            for i in 0..<source.numberOfCells(self) {
                result.append(source.cellForIndex(i))
            }
        }
        return result
    }
    
    // open all cells
    open func open() {
        guard let isOk = delegate?.liquidFloatingActionButtonWillOpenDrawer?(self) else { return  }
        
        if !isOk{
            return
        }
        // rotate plus icon
        CATransaction.setAnimationDuration(0.25)
        self.plusLayer.transform = CATransform3DMakeRotation((CGFloat(Double.pi) * rotationDegrees) / 180, 0, 0, 1)
        
        let cells = cellArray()
        for cell in cells {
            insertCell(cell)
        }
        
        self.baseView.open(cells)
        
        self.isClosed = false
    }
    
    // close all cells
    open func close() {
        delegate?.liquidFloatingActionButtonWillCloseDrawer?(self)
        
        // rotate plus icon
        CATransaction.setAnimationDuration(0.25)
        self.plusLayer.transform = CATransform3DMakeRotation(0, 0, 0, 1)
        
        self.baseView.close(cellArray())
        
        self.isClosed = true
    }
    
    // MARK: draw icon
    open override func draw(_ rect: CGRect) {
        drawCircle()
        drawShadow()
    }
    
    /// create, configure & draw the plus layer (override and create your own shape in subclass!)
    open func createPlusLayer(_ frame: CGRect) -> CAShapeLayer {
        
        // draw plus shape
        let plusLayer = CAShapeLayer()
        plusLayer.lineCap = CAShapeLayerLineCap.round
        plusLayer.strokeColor = UIColor.white.cgColor
        plusLayer.lineWidth = 3.0
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: frame.width * internalRadiusRatio, y: frame.height * 0.5))
        path.addLine(to: CGPoint(x: frame.width * (1 - internalRadiusRatio), y: frame.height * 0.5))
        path.move(to: CGPoint(x: frame.width * 0.5, y: frame.height * internalRadiusRatio))
        path.addLine(to: CGPoint(x: frame.width * 0.5, y: frame.height * (1 - internalRadiusRatio)))
        
        plusLayer.path = path.cgPath
        return plusLayer
    }
    
    fileprivate func drawCircle() {
        self.circleLayer.cornerRadius = self.frame.width * 0.5
        self.circleLayer.masksToBounds = true
        if touching && responsible {
            self.circleLayer.backgroundColor = self.color.white(0.5).cgColor
        } else {
            self.circleLayer.backgroundColor = self.color.cgColor
        }
    }
    
    fileprivate func drawShadow() {
        if enableShadow {
            circleLayer.appendShadow()
        }
    }
    
    // MARK: Events
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touching = true
        setNeedsDisplay()
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touching = false
        setNeedsDisplay()
        didTapped()
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        self.touching = false
        setNeedsDisplay()
    }
    
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for cell in cellArray() {
            let pointForTargetView = cell.convert(point, from: self)
            
            if (cell.bounds.contains(pointForTargetView)) {
                if cell.isUserInteractionEnabled {
                    return cell.hitTest(pointForTargetView, with: event)
                }
            }
        }
        
        return super.hitTest(point, with: event)
    }
    
    // MARK: private methods
    fileprivate func setup() {
        //        if #available(iOS 10.0, *) {
        //            self.backgroundColor = UIColor(displayP3Red: 255.0/255.0, green: 95.0/255.0, blue: 62.0/255.0, alpha: 1.0)
        //        } else {
        //            // Fallback on earlier versions
        //        }
        if #available(iOS 10.0, *) {
            self.color = UIColor(displayP3Red: 255.0/255.0, green: 95.0/255.0, blue: 62.0/255.0, alpha: 1.0)
        } else {
            // Fallback on earlier versions
        }
        self.clipsToBounds = false
        
        baseView.setup(self)
        addSubview(baseView)
        
        liquidView.frame = baseView.frame
        liquidView.isUserInteractionEnabled = true
        addSubview(liquidView)
        
        liquidView.layer.addSublayer(circleLayer)
        circleLayer.frame = liquidView.layer.bounds
        
        plusLayer = createPlusLayer(circleLayer.bounds)
        circleLayer.addSublayer(plusLayer)
        plusLayer.frame = circleLayer.bounds
    }
    
    fileprivate func didTapped() {
        if isClosed {
            open()
        } else {
            close()
        }
    }
    
    open func didTappedCell(_ target: LiquidFloatingCell) {
        
        if target.actionButton?.isClosed ?? true {
            self.didTapped()
            return;
        }
        if let _ = dataSource {
            let cells = cellArray()
            for i in 0..<cells.count {
                let cell = cells[i]
                if target === cell {
                    delegate?.liquidFloatingActionButton?(self, didSelectItemAtIndex: i)
                    close()
                }
            }
        }
    }
    
}

class ActionBarBaseView : UIView {
    var opening = false
    func setup(_ actionButton: LiquidFloatingActionButton) {
    }
    
    func translateY(_ layer: CALayer, duration: CFTimeInterval, f: (CABasicAnimation) -> ()) {
        let translate = CABasicAnimation(keyPath: "transform.translation.y")
        f(translate)
        translate.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        translate.isRemovedOnCompletion = false
        translate.fillMode = CAMediaTimingFillMode.forwards
        translate.duration = duration
        layer.add(translate, forKey: "transYAnim")
    }
}

class CircleLiquidBaseView : ActionBarBaseView {
    
    let openDuration: CGFloat  = 0.15
    let closeDuration: CGFloat = 0.2
    let viscosity: CGFloat     = 0.65
    var animateStyle: LiquidFloatingActionButtonAnimateStyle = .up
    var color: UIColor =  .red{
        didSet {
            //            engine?.color = color
            //            bigEngine?.color = color
        }
        
    }
    
    var baseLiquid: LiquittableCircle?
    var engine:     SimpleCircleLiquidEngine?
    var bigEngine:  SimpleCircleLiquidEngine?
    var enableShadow = false
    
    fileprivate var openingCells: [LiquidFloatingCell] = []
    fileprivate var keyDuration: CGFloat = 0
    fileprivate var displayLink: CADisplayLink?
    
    override func setup(_ actionButton: LiquidFloatingActionButton) {
        self.frame = actionButton.frame
        self.center = actionButton.center.minus(actionButton.frame.origin)
        self.animateStyle = actionButton.animateStyle
        let radius = min(self.frame.width, self.frame.height) * 0.45
        self.engine = SimpleCircleLiquidEngine(radiusThresh: radius * 0.73, angleThresh: 0.45)
        engine?.viscosity = viscosity
        self.bigEngine = SimpleCircleLiquidEngine(radiusThresh: radius, angleThresh: 0.55)
        bigEngine?.viscosity = viscosity
        //        self.engine?.color = actionButton.color
        //        self.bigEngine?.color = actionButton.color
        
        baseLiquid = LiquittableCircle(center: self.center.minus(self.frame.origin), radius: radius, color: actionButton.color)
        baseLiquid?.clipsToBounds = false
        baseLiquid?.layer.masksToBounds = false
        
        clipsToBounds = false
        layer.masksToBounds = false
        addSubview(baseLiquid!)
    }
    
    func open(_ cells: [LiquidFloatingCell]) {
        stop()
        displayLink = CADisplayLink(target: self, selector: #selector(CircleLiquidBaseView.didDisplayRefresh(_:)))
        displayLink?.add(to: RunLoop.current, forMode: RunLoop.Mode.common)
        opening = true
        for cell in cells {
            cell.layer.removeAllAnimations()
            cell.layer.eraseShadow()
            openingCells.append(cell)
        }
    }
    
    func close(_ cells: [LiquidFloatingCell]) {
        stop()
        opening = false
        displayLink = CADisplayLink(target: self, selector: #selector(CircleLiquidBaseView.didDisplayRefresh(_:)))
        displayLink?.add(to: RunLoop.current, forMode: RunLoop.Mode.common)
        for cell in cells {
            cell.layer.removeAllAnimations()
            cell.layer.eraseShadow()
            openingCells.append(cell)
            cell.isUserInteractionEnabled = true
        }
    }
    
    func didFinishUpdate() {
        if opening {
            for cell in openingCells {
                cell.isUserInteractionEnabled = true
            }
        } else {
            for cell in openingCells {
                cell.removeFromSuperview()
            }
        }
    }
    
    func update(_ delay: CGFloat, duration: CGFloat, f: (LiquidFloatingCell, Int, CGFloat) -> ()) {
        if openingCells.isEmpty {
            return
        }
        
        let maxDuration = duration + CGFloat(openingCells.count) * CGFloat(delay)
        let t = keyDuration
        let allRatio = easeInEaseOut(t / maxDuration)
        
        if allRatio >= 1.0 {
            didFinishUpdate()
            stop()
            return
        }
        
        engine?.clear()
        bigEngine?.clear()
        for i in 0..<openingCells.count {
            let liquidCell = openingCells[i]
            let cellDelay = CGFloat(delay) * CGFloat(i)
            let ratio = easeInEaseOut((t - cellDelay) / duration)
            f(liquidCell, i, ratio)
        }
        
        if let firstCell = openingCells.first {
            bigEngine?.push(circle: baseLiquid!, other: firstCell)
        }
        for i in 1..<openingCells.count {
            let prev = openingCells[i - 1]
            let cell = openingCells[i]
            engine?.push(circle: prev, other: cell)
        }
        engine?.draw(parent: baseLiquid!)
        bigEngine?.draw(parent: baseLiquid!)
    }
    
    func updateOpen() {
        update(0.01, duration: openDuration) { cell, i, ratio in
            
            let fi = CGFloat(i)
            
            let posRatio = ratio > CGFloat(i) / CGFloat(self.openingCells.count) ? ratio : 0
            let distance = (cell.frame.height * 0.2 + CGFloat(fi + 1.0) * cell.frame.height * 1.5) * posRatio
            cell.center = self.center.plus(self.differencePoint(distance))
            cell.update(ratio, open: true)
            
            
            
        }
    }
    
    func updateClose() {
        update(0, duration: closeDuration) { cell, i, ratio in
            
            let fi = CGFloat(i)
            
            let distance = (cell.frame.height * 0.2 + CGFloat(fi + 1.0) * cell.frame.height * 1.5) * (1 - ratio)
            cell.center = self.center.plus(self.differencePoint(distance))
            cell.update(ratio, open: false)
        }
    }
    
    func differencePoint(_ distance: CGFloat) -> CGPoint {
        switch animateStyle {
        case .up:
            return CGPoint(x: 0, y: -distance)
        case .right:
            return CGPoint(x: distance, y: 0)
        case .left:
            return CGPoint(x: -distance, y: 0)
        case .down:
            return CGPoint(x: 0, y: distance)
        }
    }
    
    func stop() {
        for cell in openingCells {
            if enableShadow {
                cell.layer.appendShadow()
            }
        }
        openingCells = []
        keyDuration = 0
        displayLink?.invalidate()
    }
    
    func easeInEaseOut(_ t: CGFloat) -> CGFloat {
        if t >= 1.0 {
            return 1.0
        }
        if t < 0 {
            return 0
        }
        return -1 * t * (t - 2)
    }
    
    @objc func didDisplayRefresh(_ displayLink: CADisplayLink) {
        if opening {
            keyDuration += CGFloat(displayLink.duration)
            updateOpen()
        } else {
            keyDuration += CGFloat(displayLink.duration)
            updateClose()
        }
    }
    
}

open class LiquidFloatingCell : LiquittableCircle {
    
    let internalRatio: CGFloat = 0.05
    
    open var responsible = true
    open var imageView = UIImageView()
    weak var actionButton: LiquidFloatingActionButton?
    
    // for implement responsible color
    fileprivate var originalColor: UIColor
    
    open override var frame: CGRect {
        didSet {
            resizeSubviews()
        }
    }
    
    init(center: CGPoint, radius: CGFloat, color: UIColor, icon: UIImage) {
        self.originalColor = color
        super.init(center: center, radius: radius, color: color)
        setup(icon)
    }
    
    init(center: CGPoint, radius: CGFloat, color: UIColor, view: UIView) {
        self.originalColor = color
        super.init(center: center, radius: radius, color: color)
        setupView(view)
    }
    
    @objc public init(icon: UIImage) {
        self.originalColor = UIColor.white
        super.init()
        setup(icon)
        self.isUserInteractionEnabled = true
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(_ image: UIImage, tintColor: UIColor = UIColor.white) {
        imageView.image = image.withRenderingMode(UIImage.RenderingMode.alwaysOriginal)
        //        imageView.tintColor = tintColor
        imageView.isUserInteractionEnabled = true
        setupView(imageView)
    }
    
    open func setupView(_ view: UIView) {
        isUserInteractionEnabled = true
        addSubview(view)
        resizeSubviews()
    }
    
    fileprivate func resizeSubviews() {
        
        // internalRatio * 2 +  0.75 = 1
        
        let size = CGSize(width: frame.width * 0.90, height: frame.height * 0.90)
        imageView.frame = CGRect(x: frame.width * internalRatio, y:frame.height * internalRatio, width: size.width, height: size.height)
        //        imageView.center = center
    }
    
    func update(_ key: CGFloat, open: Bool) {
        for subview in self.subviews {
            let ratio = max(2 * (key * key - 0.5), 0)
            subview.alpha = open ? ratio : -ratio
        }
    }
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if responsible {
            originalColor = color
            //            color = originalColor.white(0.5)
            setNeedsDisplay()
        }
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        if responsible {
            color = originalColor
            setNeedsDisplay()
        }
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        color = originalColor
        
        actionButton?.didTappedCell(self)
    }
    
}
