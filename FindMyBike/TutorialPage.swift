//
//  TutorialPage.swift
//  FindMyBike
//
//  Created by budi on 2018/12/24.
//  Copyright © 2018 V.Lab. All rights reserved.
//

import Foundation
import UIKit

class TutorialPage: UIViewController {
    
    var image: UIImage!
    var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        image = UIImage(named: "tutorial_page.png")
        imageView = UIImageView(image: image)
        imageView.frame = CGRect(x: 0, y: 88, width: UIScreen.main.bounds.size.width, height: screenH)
        view.addSubview(imageView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}
