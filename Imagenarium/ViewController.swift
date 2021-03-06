//
//  ViewController.swift
//  Imagenarium
//
//  Created by Алексей Удалов on 20/09/16.
//  Copyright © 2016 udalovas. All rights reserved.
//

import UIKit
import CoreImage

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    /* Constants */
    
    fileprivate static let FADE_ANIMATION_DURATION:TimeInterval = 0.4
    fileprivate static let FILTER_MENU_HEIGHT:UInt8 = 50
    fileprivate static let ORIGINAL_LABEL = "Original"
    fileprivate static let SAMPLE_IMAGE = UIImage(named: "default")!
    fileprivate static let FILTER_CELL_ID = "FilterCell"
    
    /* Controls */
    
    @IBOutlet var mainContainerStackView: UIStackView!
    @IBOutlet var originalImageOverlayView: UIImageView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var filtersCollectionView: UICollectionView!
    @IBOutlet var bottomMenuView: UIView!
    
    @IBOutlet var filterButton: UIButton!
    @IBOutlet var compareButton: UIButton!
    @IBOutlet var newPhotoButton: UIButton!
    
    /* State */
    
    fileprivate var originalImage: UIImage?
    fileprivate var filteredImage: UIImage?
    fileprivate var ciContext: CIContext!
    fileprivate var currentFilter: CIFilter!
    
    /* Action! */

    @IBAction func onNewPhoto(_ sender: UIButton) {
        self.present(createPhotoPickerActionSheet(), animated: true, completion: nil)
    }
    
    private func createPhotoPickerActionSheet() -> UIAlertController {
        let photoActionSheet = UIAlertController(title: "New Photo", message: nil, preferredStyle: .actionSheet)
        photoActionSheet.popoverPresentationController?.sourceView = newPhotoButton
        photoActionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { action in
            self.showCamera()
        }))
        photoActionSheet.addAction(UIAlertAction(title: "Album", style: .default, handler: { action in
            self.showAlbum()
        }))
        photoActionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        return photoActionSheet
    }
    
    @IBAction func onShare(_ sender: UIButton) {
        present(UIActivityViewController(activityItems: [imageView.image!], applicationActivities: nil), animated: true, completion: nil)
    }
    
    @IBAction func onFilterMenu(_ sender: UIButton) {
        toggleFilterMenu(!sender.isSelected)
    }
    
    fileprivate func toggleFilterMenu(_ on:Bool) {
        if(on && !filterButton.isSelected) {
            showFiltersCollection()
            filterButton.isSelected = true
        } else if(!on && filterButton.isSelected) {
            hide(filtersCollectionView)
            filterButton.isSelected = false
        }
    }
    
    @IBAction func onImageTouch(_ sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            imageView.image = originalImage
        case .ended:
            imageView.image = filteredImage
        default:
            break
        }
    }
    
    /* UIImagePickerControllerDelegate: start */
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true, completion: nil)
        setOriginalImage(info[UIImagePickerControllerOriginalImage] as! UIImage)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    /* UIImagePickerControllerDelegate: end */
    
    /* UICollectionViewDataSource: start */
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ImageProcessor.FILTERS.count + 1 // +1 for an original image cell
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = filtersCollectionView.dequeueReusableCell(withReuseIdentifier: ViewController.FILTER_CELL_ID, for: indexPath) as! FilterCellView
        if((indexPath as NSIndexPath).row == 0) {
            cell.labelView.text = ViewController.ORIGINAL_LABEL
            cell.imageView.image = originalImage
        } else {
            let filterKey = ImageProcessor.FILTERS[(indexPath as NSIndexPath).row - 1]
            cell.labelView.text = filterKey
            cell.imageView.image = ImageProcessor
                .apply(filterKey: ImageProcessor.FILTERS[(indexPath as NSIndexPath).row - 1],
                       to: originalImage!,
                       in: ciContext)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if((indexPath as NSIndexPath).row == 0) {
            filteredImage = originalImage
            imageView.image = originalImage
        } else {
            filteredImage = ImageProcessor.apply(
                filterKey: ImageProcessor.FILTERS[(indexPath as NSIndexPath).row - 1],
                to: originalImage!,
                in: ciContext)
            imageView.image = filteredImage
            compareButton.isEnabled = true
        }
    }
    
    /* UICollectionViewDataSource: end */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ciContext = CIContext()
        initImageViews()
        initCompareButton()
        initFilterMenu()
        setOriginalImage(ViewController.SAMPLE_IMAGE)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated..
    }
    
    @IBAction func onCompareTouchDown(_ sender: UIButton) {
        if(sender.isSelected) {
            hide(originalImageOverlayView)
        } else {
            showOriginalOverlay()
            toggleFilterMenu(false)
        }
        sender.isSelected = !sender.isSelected
    }
    
    fileprivate func showCamera() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    fileprivate func showAlbum() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    fileprivate func initCompareButton() {
        compareButton.isEnabled = false
    }
    
    func showFiltersCollection() {
        view.addSubview(filtersCollectionView)
        let bottomConstraint = filtersCollectionView.bottomAnchor.constraint(equalTo: bottomMenuView.topAnchor)
        let leftConstraint = filtersCollectionView.leftAnchor.constraint(equalTo: bottomMenuView.leftAnchor)
        let rightConstraint = filtersCollectionView.rightAnchor.constraint(equalTo: bottomMenuView.rightAnchor)
        let heightConstraint = filtersCollectionView.heightAnchor.constraint(equalToConstant: CGFloat(ViewController.FILTER_MENU_HEIGHT))
        NSLayoutConstraint.activate([bottomConstraint, leftConstraint, rightConstraint, heightConstraint])
        view.layoutIfNeeded()
        show(filtersCollectionView)
    }
    
    func showOriginalOverlay() {
        view.addSubview(originalImageOverlayView)
        let topConstraint = originalImageOverlayView.topAnchor.constraint(equalTo: mainContainerStackView.topAnchor)
        let bottomConstraint = originalImageOverlayView.bottomAnchor.constraint(equalTo: bottomMenuView.topAnchor)
        let leftConstraint = originalImageOverlayView.leftAnchor.constraint(equalTo: mainContainerStackView.leftAnchor)
        let rightConstraint = originalImageOverlayView.rightAnchor.constraint(equalTo: mainContainerStackView.rightAnchor)
        NSLayoutConstraint.activate([topConstraint, leftConstraint, rightConstraint, bottomConstraint])
        view.layoutIfNeeded()
        show(originalImageOverlayView)
    }
    
    fileprivate func hide(_ view: UIView) {
        UIView.animate(withDuration: ViewController.FADE_ANIMATION_DURATION, animations: {
            view.alpha = 0
        }, completion: { completed in
            if(completed == true) {
                view.removeFromSuperview()
            }
        }) 
    }
    
    fileprivate func show(_ view: UIView) {
        view.alpha = 0
        UIView.animate(withDuration: ViewController.FADE_ANIMATION_DURATION, animations: {
            view.alpha = 1
        }) 
    }
    
    fileprivate func initFilterMenu() {
        filtersCollectionView.dataSource = self
        filtersCollectionView.delegate = self
        filtersCollectionView.translatesAutoresizingMaskIntoConstraints = false
        filtersCollectionView.backgroundColor = UIColor.white.withAlphaComponent(0.5)
    }
    
    fileprivate func initImageViews() {
        originalImageOverlayView.translatesAutoresizingMaskIntoConstraints = false
        let pressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.onImageTouch(_:)))
        pressRecognizer.minimumPressDuration = 0.1
        imageView.addGestureRecognizer(pressRecognizer)
        imageView.image = originalImage
        imageView.isUserInteractionEnabled = true
    }
    
    fileprivate func setOriginalImage(_ image: UIImage) {
        originalImage = image
        originalImageOverlayView.image = ImageProcessor.drawText(ViewController.ORIGINAL_LABEL, inImage: originalImage!, atPoint: CGPoint(x: 20, y: 20))
        imageView.image = originalImage
        filtersCollectionView.reloadData()
    }
}

