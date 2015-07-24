//
//  ViewController.swift
//  Examples
//
//  Created by Neil Gall on 23/07/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    func showModal(completion: () -> ()) {
        let modal = UIViewController()
        let animations = { modal.view.center = CGPointZero }

        asyncChain {
            self.presentViewController(modal, animated: true, completion: $0)
            
        } >>| {
            UIView.animateWithDuration(3.0, animations: animations, completion: $0)

        } >>> {
            print("finished: \($0)")
            self.dismissViewControllerAnimated(true, completion: $1)
        
        } >>| {
            print("done")

        }
    }
}

