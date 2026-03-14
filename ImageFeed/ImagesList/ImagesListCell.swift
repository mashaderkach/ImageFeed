// ImagesListCell.swift

import UIKit

protocol ImageListCellDelegate: AnyObject {
    func imageListCellDidTapLike(_ cell: ImagesListCell)
}

final class ImagesListCell: UITableViewCell {
    
    // MARK: - Properties
    
    static let reuseIdentifier = "ImagesListCell"
    weak var delegate: ImageListCellDelegate?
    
    // MARK: - Outlets
    
    @IBOutlet var cellImage: UIImageView!
    @IBOutlet var likeButton: UIButton!
    @IBOutlet var dataLabel: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        cellImage.kf.cancelDownloadTask()
        cellImage.image = nil
        setIsLiked(false)
    }
    
    @IBAction private func likeButtonClicked() {
        delegate?.imageListCellDidTapLike(self)
    }
    
    func setIsLiked(_ isLiked: Bool) {
        let imageName = isLiked ? "like_button_on" : "like_button_off"
        likeButton.setImage(UIImage(named: imageName), for: .normal)
    }
}
