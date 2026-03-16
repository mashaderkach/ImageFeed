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
    
    var imageURL: URL?
    
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
        loadFullImage()
    }
    
    // MARK: - Setup
    private func setupScrollView() {
        scrollView.delegate = self
        scrollView.minimumZoomScale = Constants.minZoomScale
        scrollView.maximumZoomScale = Constants.maxZoomScale
        scrollView.delegate = self
        scrollView.contentInsetAdjustmentBehavior = .never
    }
    
    private func loadFullImage() {
        guard let url = imageURL else { return }
        
        UIBlockingProgressHUD.show()
        imageView.kf.setImage(with: url) { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            
            guard let self else { return }
            
            switch result {
            case .success(let imageResult):
                self.imageView.image = imageResult.image
                self.imageView.sizeToFit()
                self.rescaleAndCenterImage(imageResult.image)
            case .failure:
                self.showError()
            }
        }
    }
    
    private func updateImage() {
        guard let image else { return }
        imageView.image = image
        imageView.frame.size = image.size
        scrollView.contentSize = image.size
        rescaleAndCenterImage(image)
        
    }
    
    // MARK: - Layout
    
    private func rescaleAndCenterImage(_ image: UIImage) {
        view.layoutIfNeeded()
        
        let scrollViewSize = scrollView.bounds.size
        let imageSize = image.size
        
        let widthScale = scrollViewSize.width / imageSize.width
        let heightScale = scrollViewSize.height / imageSize.height
        let scale = max(widthScale, heightScale)
        
        
        scrollView.setZoomScale(scale, animated: false)
        scrollView.layoutIfNeeded()
        
        let offsetX = max((imageView.frame.width - scrollView.bounds.width) / 2, 0)
            let offsetY = max((imageView.frame.height - scrollView.bounds.height) / 2, 0)
            scrollView.contentOffset = CGPoint(x: offsetX, y: offsetY)
        
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
    
    private func showError() {
        let alert = UIAlertController(
                title: nil,
                message: "Что-то пошло не так. Попробовать ещё раз?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Не надо", style: .cancel))
            
            alert.addAction(UIAlertAction(title: "Повторить", style: .default, handler: { [weak self] _ in
                self?.loadFullImage()
            }))
            
            present(alert, animated: true)
    }
}

// MARK: - Extensions

extension SingleImageViewController: UIScrollViewDelegate{
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
    }
}
