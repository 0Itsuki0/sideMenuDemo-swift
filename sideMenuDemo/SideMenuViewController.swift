//
//  SideMenuViewController.swift
//  sideMenuDemo
//
//  Created by Itsuki on 2023/09/22.



import UIKit

protocol SideMenuViewControllerDelegate {
    func handleSideMenuPanGesture(_ sender: UIPanGestureRecognizer )
}


class SideMenuViewController: UIViewController {

    var presentationViewController: MainViewController?
    var delegate: SideMenuViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        panGestureRecognizer.delegate = self
        view.addGestureRecognizer(panGestureRecognizer)

    }


}


extension SideMenuViewController: UIGestureRecognizerDelegate {
    // Dragging Side Menu
    @objc private func handlePanGesture(sender: UIPanGestureRecognizer) {
        delegate?.handleSideMenuPanGesture(sender)
      
    }
}
