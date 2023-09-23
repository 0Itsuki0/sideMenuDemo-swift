//
//  ViewController.swift
//  sideMenuDemo
//
//  Created by Itsuki on 2023/09/22.
//
//

import UIKit

class MainViewController: UIViewController {
    
    private var tabBarShadowView: UIView!

    
    private var sideMenuViewController: SideMenuViewController!
    private var sideMenuShadowView: UIView!
    private var sideMenuRevealWidth: CGFloat = 260
    private let paddingForRotation: CGFloat = 0
    private var isExpanded: Bool = false
    private var draggingIsEnabled: Bool = false
    private var panBaseLocation: CGFloat = 0.0
    
    // Expand/Collapse the side menu by changing leading constraint constant
    private var sideMenuLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainControllerLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainControllerTrailingConstriant: NSLayoutConstraint!
    private var revealSideMenuOnTop: Bool = true
    
    var gestureEnabled: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBarShadowView = UIView(frame: tabBarController?.tabBar.bounds ?? CGRect(x: 0, y: 0, width: 0, height: 0))
        self.tabBarShadowView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.tabBarShadowView.backgroundColor = .black
        self.tabBarShadowView.alpha = 0
        tabBarController?.tabBar.insertSubview(self.tabBarShadowView, at: 1)
        

        // Shadow Background View
        self.sideMenuShadowView = UIView(frame: self.view.bounds)
        self.sideMenuShadowView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.sideMenuShadowView.backgroundColor = .black
        self.sideMenuShadowView.alpha = 0
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(TapGestureRecognizer))
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.delegate = self
        self.sideMenuShadowView.addGestureRecognizer(tapGestureRecognizer)
        view.insertSubview(self.sideMenuShadowView, at: 1)

        
        
        // Side Menu
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        self.sideMenuViewController = storyboard.instantiateViewController(withIdentifier: "SideMenuViewController") as? SideMenuViewController
        sideMenuViewController.delegate = self

        view.insertSubview(self.sideMenuViewController!.view, at: 2)
        addChild(self.sideMenuViewController!)
        self.sideMenuViewController!.didMove(toParent: self)

        // Side Menu AutoLayout

        self.sideMenuViewController.view.translatesAutoresizingMaskIntoConstraints = false
        self.sideMenuLeadingConstraint = self.sideMenuViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -self.sideMenuRevealWidth - self.paddingForRotation)
        self.sideMenuLeadingConstraint.isActive = true

        NSLayoutConstraint.activate([
            self.sideMenuViewController.view.widthAnchor.constraint(equalToConstant: self.sideMenuRevealWidth),
            self.sideMenuViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            self.sideMenuViewController.view.topAnchor.constraint(equalTo: view.topAnchor)
        ])

        // Side Menu Gestures
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleMainViewPanGesture))
        panGestureRecognizer.delegate = self
        view.addGestureRecognizer(panGestureRecognizer)

    }
    


    func animateShadow(alpha: CGFloat) {
        UIView.animate(withDuration: 0.5) {
            self.sideMenuShadowView.alpha = alpha
            self.tabBarShadowView.alpha = alpha
        }
    }

    @IBAction open func revealSideMenu() {
        self.toggleSideMenu(expanded: self.isExpanded ? false : true)
    }
    

    func toggleSideMenu(expanded: Bool) {
        if expanded {
            self.animateSideMenu(targetPosition: 0) { _ in
                self.isExpanded = true
            }
            self.animateShadow(alpha: 0.6)
        }
        else {
            self.animateSideMenu(targetPosition: (-self.sideMenuRevealWidth - self.paddingForRotation)) { _ in
                self.isExpanded = false
            }
            self.animateShadow(alpha: 0)
        }
    }
    
    func animateSideMenu(targetPosition: CGFloat, completion: @escaping (Bool) -> ()) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: .layoutSubviews, animations: {
                self.sideMenuLeadingConstraint.constant = targetPosition
                self.mainControllerLeadingConstraint.constant = targetPosition + self.sideMenuRevealWidth
                self.mainControllerTrailingConstriant.constant = targetPosition + self.sideMenuRevealWidth
                self.tabBarController?.tabBar.frame.origin.x = targetPosition + self.sideMenuRevealWidth
                
                
                self.view.layoutIfNeeded()

        }, completion: completion)
    }


}


extension MainViewController: UIGestureRecognizerDelegate {
    @objc func TapGestureRecognizer(sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            if self.isExpanded {
                self.toggleSideMenu(expanded: false)
            }
        }
    }

    // Close side menu when you tap on the shadow background view
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if (touch.view?.isDescendant(of: self.sideMenuViewController.view))! {
            return false
        }
        return true
    }
    
    // Dragging Side Menu
    @objc func handleMainViewPanGesture(sender: UIPanGestureRecognizer) {
        handlePanGesture(sender)
    }
    
    private func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        
        guard gestureEnabled == true else { return }

        let position: CGFloat = sender.translation(in: self.view).x
        let velocity: CGFloat = sender.velocity(in: self.view).x

        switch sender.state {
        case .began:

            // cancel if the menu is expanded and drag is from left to right
            if velocity > 0, self.isExpanded {
                sender.state = .cancelled
            }

            // Enable dragging if menu is not expanded and drag is from left to right
            if velocity > 0, !self.isExpanded {
                self.draggingIsEnabled = true
            }
            // Enable dragging if menu is expanded and drag is from right to left
            else if velocity < 0, self.isExpanded {
                self.draggingIsEnabled = true
            }

            if self.draggingIsEnabled {
                // If swipe is fast, Expand/Collapse the side menu with animation instead of dragging
                let velocityThreshold: CGFloat = 550
                if abs(velocity) > velocityThreshold {
                    self.toggleSideMenu(expanded: self.isExpanded ? false : true)
                    self.draggingIsEnabled = false
                    return
                }
                self.panBaseLocation = 0.0
                if self.isExpanded {
                    self.panBaseLocation = self.sideMenuRevealWidth
                }
            }

        case .changed:

            // Animate side menu along with dragging action
            if self.draggingIsEnabled {
                
                let xLocation: CGFloat = self.panBaseLocation + position
                let percentage = (xLocation * 150 / self.sideMenuRevealWidth) / self.sideMenuRevealWidth

                let alpha = percentage >= 0.6 ? 0.6 : percentage
                self.sideMenuShadowView.alpha = alpha
                self.tabBarShadowView.alpha = alpha

                // Move side menu while dragging
                if xLocation <= self.sideMenuRevealWidth {
                    self.sideMenuLeadingConstraint.constant = xLocation - self.sideMenuRevealWidth
                    self.mainControllerLeadingConstraint.constant = xLocation
                    self.mainControllerTrailingConstriant.constant = xLocation
                    self.tabBarController?.tabBar.frame.origin.x = xLocation

                }

            }
        case .ended:
            self.draggingIsEnabled = false
            // If the side menu is half Open/Close, then Expand/Collapse with animation
            let movedMoreThanHalf = self.sideMenuLeadingConstraint.constant > -(self.sideMenuRevealWidth * 0.5)
            self.toggleSideMenu(expanded: movedMoreThanHalf)

        default:
            break
        }
    }
}


// side menu related functions
extension MainViewController: SideMenuViewControllerDelegate {
    
    func handleSideMenuPanGesture(_ sender: UIPanGestureRecognizer) {
        handlePanGesture(sender)
    }
    
}
