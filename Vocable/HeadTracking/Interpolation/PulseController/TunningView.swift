//
//  TunningView.swift
//  Pulse
//
//  Created by Dawid Cieslak on 15/04/2018.
//  Copyright © 2018 Dawid Cieslak. All rights reserved.
//

import UIKit

/// All possible states of tuning view visibility
///
/// - notVisible: View is not visible at all
/// - graphOnly: Only graph is visible
/// - fullyVisible: Both graph and tuning controls are visible
enum VisibilityState {
    case notVisible
    case graphOnly
    case fullyVisible
}

/// Wraps all controsl for
class TunningView: UIView {
  
    struct Configuration {
        /// Minimum target value that might be set as `setPoint`
        let minimumValue: CGFloat
        
        /// Maximum target value that might be set as `setPoint`
        let maximumValue: CGFloat
        
        /// Initial configuration for `PID` controller
        let initialConfiguration: Pulse.Configuration
    }
    
    private struct LayoutConstants {
        
        /// Colors of graph's background gradinet
        static let GraphColors: [UIColor] = [UIColor(red: 72.0/255.0, green: 35.0/255.0, blue: 174.0/255.0, alpha: 1.0),
                                             UIColor(red: 184.0/255.0, green: 109.0/255.0, blue: 215.0/255.0, alpha: 1.0)]
    }
    
    /// Defines if and how, tuning view is visible on the screen
    var visibilityState: VisibilityState = .notVisible {
        didSet {
            update()
        }
    }
    
    private var didSetConstraints: Bool = false
    
    /// Button for closing tuning view
    private let closeButton = UIButton(type: .custom)
    
    /// Wraps all sliders to control `PID` configuration
    private let controlsView: ControlsView
    
    private var topConstraint: NSLayoutConstraint?

    // Constraints
    private lazy var containerStackView: UIStackView = {
        let stackView: UIStackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.alignment = .trailing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 20
        return stackView
    }()

    var closeClosure: ((TunningView) -> Void)
    
    var configurationChanged: ((TunningView, Pulse.Configuration) -> Void)

    required init(isHorizontal: Bool, configuration: Configuration, closeClosure: @escaping ((TunningView) -> Void), configurationChanged: @escaping ((TunningView, Pulse.Configuration) -> Void)) {
        self.closeClosure = closeClosure
        self.configurationChanged = configurationChanged

        controlsView = ControlsView(initialConfiguration: configuration.initialConfiguration, isHorizontal: isHorizontal)
   
        super.init(frame: .zero)
        
        closeButton.setTitle("X", for: .normal)
        closeButton.layer.cornerRadius = 20
        closeButton.backgroundColor = .white
        closeButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        closeButton.isUserInteractionEnabled = true
        
        // Controls View
        controlsView.translatesAutoresizingMaskIntoConstraints = false
        
        // Listen to configuration changes
        controlsView.configurationChanged = { [weak self] (_, configuration) in
            guard let `self` = self else { return }
            self.configurationChanged(self, configuration)
        }

        // Add views to `UIStackView`
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(containerStackView)
      
        containerStackView.addArrangedSubview(closeButton)
        containerStackView.addArrangedSubview(controlsView)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        let respondingView = containerStackView.frame.contains(point) ? view : nil
        return respondingView
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        guard didSetConstraints == false else {
            return
        }
        didSetConstraints = true
        
        topConstraint =  self.containerStackView.topAnchor.constraint(equalTo: self.bottomAnchor, constant: -20)
        
        NSLayoutConstraint.activate([
            self.containerStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            self.containerStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),

            self.controlsView.widthAnchor.constraint(equalTo: containerStackView.widthAnchor),
            self.closeButton.widthAnchor.constraint(equalToConstant: 40),
            self.closeButton.heightAnchor.constraint(equalToConstant: 40),
           topConstraint!
        ])
    }
    
    private func heightForVisibilityState() -> CGFloat {
        let margin: CGFloat = 10
        let newHeight: CGFloat

        if visibilityState == .notVisible {
           newHeight = 0
        } else {

            newHeight = containerStackView.bounds.height + margin
        }
        
        return -newHeight
    }
    
    @objc func buttonPressed() {
        switch visibilityState {
        case .fullyVisible:
            visibilityState = .notVisible//.graphOnly
        case .graphOnly:
            visibilityState = .notVisible
        case .notVisible:
            visibilityState = .fullyVisible
        }
    }
    
    /// Updates UI according to current
    private func update() {
        self.topConstraint?.constant = heightForVisibilityState()
        
        UIView.animate(withDuration: 1.0, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [], animations: { [weak self] in
            guard let self = self else { return }
            self.layoutIfNeeded()
        }, completion: { [weak self] _ in
            guard let self = self else { return }
            
            if self.visibilityState == .notVisible {
                self.closeClosure(self)
            }
        })
    }
}
