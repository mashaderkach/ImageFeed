// SingleImageViewController.swift

import UIKit

final class SingleImageViewController: UIViewController {
    
    // MARK: - Constants
    
    private enum Constants {
        static let minZoomScale: CGFloat = 0.1
        static let maxZoomScale: CGFloat = 1.25
    }
    
    
    // MARK: - Properties
    
    var image: UIImage? {
        didSet {
            guard isViewLoaded else { return }
            updateImage()
        }
    }
    
    
    // MARK: - Outlets
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var scrollView: UIScrollView!
    
    
    // MARK: - Actions
    
    @IBAction func didTapBackButton() {
        dismiss(animated: true)
    }
    
    @IBAction func didTapShareButton(_ sender: UIButton) {
        guard let image else { return }
        let controller = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        present(controller, animated: true)
    }
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
        updateImage()
    }
    
    
    // MARK: - Setup
    private func setupScrollView() {
        scrollView.minimumZoomScale = Constants.minZoomScale
        scrollView.maximumZoomScale = Constants.maxZoomScale
        scrollView.delegate = self
    }
    
    private func updateImage() {
        guard let image else { return }
        imageView.image = image
        imageView.frame.size = image.size
        rescaleAndCenterImage(image)
    }
    
    
    // MARK: - Layout
    
    private func rescaleAndCenterImage(_ image: UIImage) {
        view.layoutIfNeeded()
        
        let scrollViewSize = scrollView.bounds.size
        let imageSize = image.size
        
        let widthScale = scrollViewSize.width / imageSize.width
        let heightScale = scrollViewSize.height / imageSize.height
        let scale = min(Constants.maxZoomScale, max(Constants.minZoomScale, min(widthScale, heightScale)))
        
        scrollView.setZoomScale(scale, animated: false)
        centerImage()
    }
    
    private func centerImage() {
        let scrollViewSize = scrollView.bounds.size
        let imageSize = imageView.frame.size
        
        let horizontalInset = max(0, (scrollViewSize.width - imageSize.width) / 2)
        let verticalInset = max(0, (scrollViewSize.height - imageSize.height) / 2)
        
        scrollView.contentInset = UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: verticalInset,
            right: horizontalInset
        )
    }
}


// MARK: - Extestions

extension SingleImageViewController: UIScrollViewDelegate{
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
    }
}
