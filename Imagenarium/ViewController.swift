//
//  ViewController.swift
//  Imagenarium
//
//  Created by Алексей Удалов on 20/09/16.
//  Copyright © 2016 udalovas. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    /* Constants */
    
    private static let FADE_ANIMATION_DURATION:NSTimeInterval = 0.4
    
    /* Controls */
    
    @IBOutlet var mainStackView: UIStackView!
    @IBOutlet var originalImageView: UIImageView!
    @IBOutlet var imageView: UIImageView!
    
    @IBOutlet var secondaryMenu: UIView!
    @IBOutlet var filtersContainer: UIStackView!
    
    @IBOutlet var bottomMenu: UIView!
    @IBOutlet var filterButton: UIButton!
    @IBOutlet var compareButton: UIButton!
    @IBOutlet var newPhotoButton: UIButton!
    
    private var filterButtons:[UIButton] = []
    
    /* State */
    
    private var originalRGBAImage: RGBAImage?
    private var originalImage: UIImage?
    
    private var filteredRGBAImage: RGBAImage?
    private var filteredImage: UIImage?
    
    /* Action! */

    @IBAction func onNewPhoto(sender: UIButton) {
        
        // TODO need to create each time?..
        
        let photoActionSheet = UIAlertController(title: "New Photo", message: nil, preferredStyle: .ActionSheet)
        
        photoActionSheet.popoverPresentationController?.sourceView = newPhotoButton
        photoActionSheet.addAction(UIAlertAction(title: "Camera", style: .Default, handler: { action in
            self.showCamera()
        }))
        photoActionSheet.addAction(UIAlertAction(title: "Album", style: .Default, handler: { action in
            self.showAlbum()
        }))
        photoActionSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        self.presentViewController(photoActionSheet, animated: true, completion: nil)
    }
    
    @IBAction func onShare(sender: UIButton) {
        presentViewController(UIActivityViewController(activityItems: [imageView.image!], applicationActivities: nil),
                              animated: true,
                              completion: nil)
    }
    
    @IBAction func onFilterMenu(sender: UIButton) {
        if(!sender.selected) {
            showSecondaryMenu()
        } else {
            hideSecondaryMenu()
        }
        sender.selected = !sender.selected
    }
    
    @IBAction func onFilterTap(sender: UIButton) {
        
        if(sender.selected) {
            imageView.image = originalImage
            compareButton.enabled = false
        } else {
            // state
            filteredRGBAImage = RGBAImage(image: sender.currentBackgroundImage!)
            filteredImage = sender.currentBackgroundImage
            // view
            filterButtons
                .filter { button -> Bool in
                    button != sender
                }.forEach { button in
                    button.selected = false
            }
            compareButton.enabled = true
            imageView.image = sender.currentBackgroundImage
        }
        sender.selected = !sender.selected
    }
    
    @IBAction func onImageTap(sender: UIImageView) {
        imageView.image = originalImage // TODO test on device
    }
    
    /* UIImagePickerControllerDelegate: start */
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        dismissViewControllerAnimated(true, completion: nil)
        updateOriginalImage(info[UIImagePickerControllerOriginalImage] as! UIImage)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    /* UIImagePickerControllerDelegate: end */
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        initImageViews()
        initCompareButton()
        initFilterMenu()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated..
    }
    
    @IBAction func onCompareTouchDown(sender: UIButton) {
        if(sender.selected) {
            hideOriginalOverlay()
        } else {
            showOriginalOverlay()
        }
        sender.selected = !sender.selected
    }
    
    private func showCamera() {
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .Camera
        
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    private func showAlbum() {
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .PhotoLibrary
        
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    private func initCompareButton() {
        compareButton.enabled = false
    }
    
    func showSecondaryMenu() {
        
        view.addSubview(secondaryMenu)
        
        // TODO: check that we really need to calculate constraints each time..
        
        let bottomConstraint = secondaryMenu.bottomAnchor.constraintEqualToAnchor(bottomMenu.topAnchor)
        let leftConstraint = secondaryMenu.leftAnchor.constraintEqualToAnchor(bottomMenu.leftAnchor)
        let rightConstraint = secondaryMenu.rightAnchor.constraintEqualToAnchor(bottomMenu.rightAnchor)
        let heightConstraint = secondaryMenu.heightAnchor.constraintEqualToConstant(44)
        
        NSLayoutConstraint.activateConstraints([bottomConstraint, leftConstraint, rightConstraint, heightConstraint])
        
        view.layoutIfNeeded()
        
        self.secondaryMenu.alpha = 0
        UIView.animateWithDuration(ViewController.FADE_ANIMATION_DURATION) {
            self.secondaryMenu.alpha = 1
        }
    }
    
    func hideOriginalOverlay() {
        UIView.animateWithDuration(ViewController.FADE_ANIMATION_DURATION, animations: {
            self.originalImageView.alpha = 0
        }) { completed in
            if(completed == true) {
                self.originalImageView.removeFromSuperview()
            }
        }
    }
    
    func showOriginalOverlay() {
        
        view.addSubview(originalImageView)
        
        // TODO: check that we really need to calculate constraints each time..
        
        let topConstraint = originalImageView.topAnchor.constraintEqualToAnchor(mainStackView.topAnchor)
        let bottomConstraint = originalImageView.bottomAnchor.constraintEqualToAnchor(bottomMenu.topAnchor)
        let leftConstraint = originalImageView.leftAnchor.constraintEqualToAnchor(mainStackView.leftAnchor)
        let rightConstraint = originalImageView.rightAnchor.constraintEqualToAnchor(mainStackView.rightAnchor)
        
        NSLayoutConstraint.activateConstraints([topConstraint, leftConstraint, rightConstraint, bottomConstraint])
        
        view.layoutIfNeeded()
        
        self.originalImageView.alpha = 0
        UIView.animateWithDuration(ViewController.FADE_ANIMATION_DURATION) {
            self.originalImageView.alpha = 1
        }
    }
    
    private func hideSecondaryMenu () {
        
        UIView.animateWithDuration(ViewController.FADE_ANIMATION_DURATION, animations: {
            self.secondaryMenu.alpha = 0
        }) { completed in
            if(completed == true) {
                self.secondaryMenu.removeFromSuperview()
            }
        }
    }
    
    private func initFilterMenu() {
        
        secondaryMenu.translatesAutoresizingMaskIntoConstraints = false
        secondaryMenu.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.5)
        
        for filter in ImageProcessor.FilterType.all {
            
            let filterButton = UIButton(type: .System)
            filterButton.setTitle(filter.rawValue, forState: .Normal)
            filterButton.addTarget(self, action: #selector(ViewController.onFilterTap(_:)), forControlEvents: .TouchUpInside)
            filterButton.adjustsImageWhenDisabled = true
            
            filtersContainer.addArrangedSubview(filterButton)
            filterButtons.append(filterButton)
        }
        
        setPreviewImage()
    }
    
    private func setPreviewImage() {
        
        filterButtons.forEach { button in
            let previewImage = ImageProcessor.getFilter(button.currentTitle!).apply(originalRGBAImage!).toUIImage()
            button.setBackgroundImage(previewImage, forState: .Normal)
        }
    }
    
    private func initImageViews() {
        
        updateOriginalImage(UIImage(named: "default")!)
        
        imageView.userInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ViewController.onImageTap(_:))))
        imageView.image = originalImage
        
        originalImageView.translatesAutoresizingMaskIntoConstraints = false
        
    }
    
    private func updateOriginalImage(image: UIImage) {
        
        originalImage = image
        originalRGBAImage = RGBAImage(image: image)
        
        originalImageView.image = originalImage
        imageView.image = originalImage
        setPreviewImage()
    }

}

