//
//  CameraController.swift
//  Pods
//
//  Created by Reza Ali on 11/21/20.
//

import MetalKit

public enum CameraControllerState {
    case panning // moves the camera either up to right
    case rotating // rotates the camera around an arcball
    case dollying // moves the camera forward
    case zooming // moves the camera closer to target
    case rolling // rotates the camera around its forward axis
    case inactive
}

open class CameraController: Codable {
    public required init(from decoder: Decoder) throws {}
    open func encode(to encoder: Encoder) throws {}
    
    public private(set) var enabled: Bool = false {
        didSet {
            if enabled {
                onChange?()
            }
        }
    }
    
    public var view: MTKView? {
        willSet {
            if view != nil, enabled {
                disable()
            }
        }
        didSet {
            if view != nil {
                enable()
            }
        }
    }
    
    public var onChange: (() -> ())?
        
    public internal(set) var state: CameraControllerState = .inactive
    
    #if os(macOS)
    
    open var modifierFlags: NSEvent.ModifierFlags = .init() {
        didSet {
            if modifierFlags.isEmpty {
                flagsEnabled = true
            }
            else {
                flagsEnabled = false
            }
        }
    }

    var flagsEnabled: Bool = true
    
    var leftMouseDownHandler: Any?
    var leftMouseDraggedHandler: Any?
    var leftMouseUpHandler: Any?
    
    var rightMouseDownHandler: Any?
    var rightMouseDraggedHandler: Any?
    var rightMouseUpHandler: Any?
    
    var otherMouseDownHandler: Any?
    var otherMouseDraggedHandler: Any?
    var otherMouseUpHandler: Any?
    
    var scrollWheelHandler: Any?
    var flagsChangedHandler: Any?
    
    var magnification: Float = 1.0
    var magnifyGestureRecognizer: NSMagnificationGestureRecognizer!
    var rollGestureRecognizer: NSRotationGestureRecognizer!
    
    #elseif os(iOS)
    
    var pinchScale: Float = 1.0
    var rollGestureRecognizer: UIRotationGestureRecognizer!
    var panGestureRecognizer: UIPanGestureRecognizer!
    var pinchGestureRecognizer: UIPinchGestureRecognizer!
    var oneTapGestureRecognizer: UITapGestureRecognizer!
    var twoTapGestureRecognizer: UITapGestureRecognizer!
    var threeTapGestureRecognizer: UITapGestureRecognizer!
        
    #endif
    
    open var minimumPanningTouches: Int = 1 {
        didSet {
            #if os(iOS)
            panGestureRecognizer.minimumNumberOfTouches = minimumPanningTouches
            #endif
        }
    }
    
    open var maximumPanningTouches: Int = 2 {
        didSet {
            #if os(iOS)
            panGestureRecognizer.maximumNumberOfTouches = maximumPanningTouches
            #endif
        }
    }
    
    init(view: MTKView) {
        self.view = view
    }
    
    open func update() {}
    
    open func enable() {
        guard let view = self.view else { return }
        if !enabled { _enable(view) }
        enabled = true
    }
    
    open func disable() {
        guard let view = self.view else { return }
        if enabled { _disable(view) }
        enabled = false
    }
    
    open func reset() {}
        
    func _enable(_ view: MTKView) {
        #if os(macOS)
        
        leftMouseDownHandler = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [unowned self] event in
            if self.flagsEnabled {
                self.mouseDown(with: event)
            }
            return event
        }
        
        leftMouseDraggedHandler = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDragged) { [unowned self] event in
            if self.flagsEnabled {
                self.mouseDragged(with: event)
            }
            return event
        }
        
        leftMouseUpHandler = NSEvent.addLocalMonitorForEvents(matching: .leftMouseUp) { [unowned self] event in
            if self.flagsEnabled {
                self.mouseUp(with: event)
            }
            return event
        }
        
        rightMouseDownHandler = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { [unowned self] event in
            if self.flagsEnabled {
                self.rightMouseDown(with: event)
            }
            return event
        }
        
        rightMouseDraggedHandler = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDragged) { [unowned self] event in
            if self.flagsEnabled {
                self.rightMouseDragged(with: event)
            }
            return event
        }
        
        rightMouseUpHandler = NSEvent.addLocalMonitorForEvents(matching: .rightMouseUp) { [unowned self] event in
            if self.flagsEnabled {
                self.rightMouseUp(with: event)
            }
            return event
        }
        
        otherMouseDownHandler = NSEvent.addLocalMonitorForEvents(matching: .otherMouseDown) { [unowned self] event in
            if self.flagsEnabled {
                self.otherMouseDown(with: event)
            }
            return event
        }
        
        otherMouseDraggedHandler = NSEvent.addLocalMonitorForEvents(matching: .otherMouseDragged) { [unowned self] event in
            if self.flagsEnabled {
                self.otherMouseDragged(with: event)
            }
            return event
        }
        
        otherMouseUpHandler = NSEvent.addLocalMonitorForEvents(matching: .otherMouseUp) { [unowned self] event in
            if self.flagsEnabled {
                self.otherMouseUp(with: event)
            }
            return event
        }
        
        scrollWheelHandler = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [unowned self] event in
            if self.flagsEnabled {
                self.scrollWheel(with: event)
            }
            return event
        }
        
        flagsChangedHandler = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [unowned self] event -> NSEvent? in
            if self.modifierFlags.isStrictSubset(of: event.modifierFlags) || self.modifierFlags.isEmpty {
                self.flagsEnabled = true
            }
            else {
                self.flagsEnabled = false
            }
            return event
        }
        
        magnifyGestureRecognizer = NSMagnificationGestureRecognizer(target: self, action: #selector(_magnifyGesture))
        view.addGestureRecognizer(magnifyGestureRecognizer)
        
        rollGestureRecognizer = NSRotationGestureRecognizer(target: self, action: #selector(_rollGesture))
        view.addGestureRecognizer(rollGestureRecognizer)
        
        #elseif os(iOS)
        
        view.isMultipleTouchEnabled = true
        
        let allowedTouchTypes: [NSNumber] = [UITouch.TouchType.direct.rawValue as NSNumber]
        rollGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(rollGesture))
        rollGestureRecognizer.allowedTouchTypes = allowedTouchTypes
        view.addGestureRecognizer(rollGestureRecognizer)
        
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGesture))
        panGestureRecognizer.allowedTouchTypes = allowedTouchTypes
        panGestureRecognizer.minimumNumberOfTouches = minimumPanningTouches
        panGestureRecognizer.maximumNumberOfTouches = maximumPanningTouches
        view.addGestureRecognizer(panGestureRecognizer)
        
        oneTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGesture))
        oneTapGestureRecognizer.allowedTouchTypes = allowedTouchTypes
        oneTapGestureRecognizer.numberOfTouchesRequired = 1
        oneTapGestureRecognizer.numberOfTapsRequired = 2
        view.addGestureRecognizer(oneTapGestureRecognizer)
        
        twoTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGesture))
        twoTapGestureRecognizer.allowedTouchTypes = allowedTouchTypes
        twoTapGestureRecognizer.numberOfTouchesRequired = 2
        twoTapGestureRecognizer.numberOfTapsRequired = 2
        view.addGestureRecognizer(twoTapGestureRecognizer)
        
        threeTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGesture))
        threeTapGestureRecognizer.allowedTouchTypes = allowedTouchTypes
        threeTapGestureRecognizer.numberOfTouchesRequired = 3
        threeTapGestureRecognizer.numberOfTapsRequired = 2
        view.addGestureRecognizer(threeTapGestureRecognizer)
        
        pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinchGesture))
        pinchGestureRecognizer.allowedTouchTypes = allowedTouchTypes
        view.addGestureRecognizer(pinchGestureRecognizer)
        
        #endif
    }
    
    func _disable(_ view: MTKView) {
        #if os(macOS)
        
        if let leftMouseDownHandler = self.leftMouseDownHandler {
            NSEvent.removeMonitor(leftMouseDownHandler)
        }
        
        if let leftMouseDraggedHandler = self.leftMouseDraggedHandler {
            NSEvent.removeMonitor(leftMouseDraggedHandler)
        }
        
        if let leftMouseUpHandler = self.leftMouseUpHandler {
            NSEvent.removeMonitor(leftMouseUpHandler)
        }
        
        if let rightMouseDownHandler = self.rightMouseDownHandler {
            NSEvent.removeMonitor(rightMouseDownHandler)
        }
        
        if let rightMouseDraggedHandler = self.rightMouseDraggedHandler {
            NSEvent.removeMonitor(rightMouseDraggedHandler)
        }
        
        if let rightMouseUpHandler = self.rightMouseUpHandler {
            NSEvent.removeMonitor(rightMouseUpHandler)
        }
        
        if let otherMouseDownHandler = self.otherMouseDownHandler {
            NSEvent.removeMonitor(otherMouseDownHandler)
        }
        
        if let otherMouseDraggedHandler = self.otherMouseDraggedHandler {
            NSEvent.removeMonitor(otherMouseDraggedHandler)
        }
        
        if let otherMouseUpHandler = self.otherMouseUpHandler {
            NSEvent.removeMonitor(otherMouseUpHandler)
        }
        
        if let scrollWheelHandler = self.scrollWheelHandler {
            NSEvent.removeMonitor(scrollWheelHandler)
        }
        
        view.removeGestureRecognizer(magnifyGestureRecognizer)
        view.removeGestureRecognizer(rollGestureRecognizer)
        
        #elseif os(iOS)
        
        view.removeGestureRecognizer(rollGestureRecognizer)
        view.removeGestureRecognizer(panGestureRecognizer)
        view.removeGestureRecognizer(oneTapGestureRecognizer)
        view.removeGestureRecognizer(twoTapGestureRecognizer)
        view.removeGestureRecognizer(threeTapGestureRecognizer)
        view.removeGestureRecognizer(pinchGestureRecognizer)
        
        #endif
    }
    
    deinit {
        disable()
        view = nil
    }

    #if os(macOS)
    
    // MARK: - Mouse
    
    open func mouseDown(with event: NSEvent) {}
    open func mouseDragged(with event: NSEvent) {}
    open func mouseUp(with event: NSEvent) {}
    
    // MARK: - Right Mouse
    
    open func rightMouseDown(with event: NSEvent) {}
    open func rightMouseDragged(with event: NSEvent) {}
    open func rightMouseUp(with event: NSEvent) {}
    
    // MARK: - Other Mouse
    
    open func otherMouseDown(with event: NSEvent) {}
    open func otherMouseDragged(with event: NSEvent) {}
    open func otherMouseUp(with event: NSEvent) {}
    
    // MARK: - Scroll Wheel
    
    open func scrollWheel(with event: NSEvent) {}
    
    // MARK: - Gestures macOS
    
    @objc open func _magnifyGesture(_ gestureRecognizer: NSMagnificationGestureRecognizer) {
        if flagsEnabled {
            magnifyGesture(gestureRecognizer)
        }
    }
    
    @objc open func _rollGesture(_ gestureRecognizer: NSRotationGestureRecognizer) {
        if flagsEnabled {
            rollGesture(gestureRecognizer)
        }
    }
    
    open func magnifyGesture(_ gestureRecognizer: NSMagnificationGestureRecognizer) {}
    open func rollGesture(_ gestureRecognizer: NSRotationGestureRecognizer) {}
    
    #elseif os(iOS)
    
    // MARK: - Gestures iOS
    
    @objc open func tapGesture(_ gestureRecognizer: UITapGestureRecognizer) {}
    @objc open func rollGesture(_ gestureRecognizer: UIRotationGestureRecognizer) {}
    @objc open func panGesture(_ gestureRecognizer: UIPanGestureRecognizer) {}
    @objc open func pinchGesture(_ gestureRecognizer: UIPinchGestureRecognizer) {}
    
    #endif
}