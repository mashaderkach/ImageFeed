// ImagesListViewController.swift

import UIKit
import Kingfisher

protocol ImageListViewControllerProtocol: AnyObject {
    func reloadTable()
    func insertRows(at indexPath: [IndexPath])
    func showLikeError(message: String)
}

final class ImagesListViewController: UIViewController {
    
    // MARK: - Properties
    
    var presenter: ImageListPresenterProtocol!
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    private let showSingleImageSegueIdentifier = "ShowSingleImage"
    
    // MARK: - Outlets
    
    @IBOutlet private weak var tableView: UITableView!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        if presenter == nil {
            presenter = ImageListPresenter()
        }
        
        presenter.view = self
        presenter.viewDidLoad()
    }
    
    // MARK: - Methods
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == showSingleImageSegueIdentifier,
              let vc = segue.destination as? SingleImageViewController,
              let indexPath = sender as? IndexPath
        else {
            super.prepare(for: segue, sender: sender)
            return
        }
        
        let photo = presenter.photos[indexPath.row]
        vc.imageURL = URL(string: photo.fullImageURL)
    }
}

// MARK: - Extensions

extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let photo = presenter.photos[indexPath.row]
        
        let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let imageViewWidth = tableView.bounds.width - imageInsets.left - imageInsets.right
        
        let scale = imageViewWidth / photo.size.width
        let cellHeight = photo.size.height * scale + imageInsets.top + imageInsets.bottom
        return cellHeight
    }
    
    func tableView(_: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == presenter.photos.count - 3 {
            presenter.fetchNextPage()
        }
    }
}

extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        presenter.photos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ImagesListCell.reuseIdentifier,
            for: indexPath
        ) as? ImagesListCell else {
            return UITableViewCell()
        }
        cell.delegate = self
        
        let photo = presenter.photos[indexPath.row]
        
        let placeholderImage = UIImage(resource: .stub)
        cell.cellImage.kf.indicatorType = .activity
        
        if let url = URL(string: photo.thumbImageURL) {
            cell.cellImage.kf.setImage(with: url, placeholder: placeholderImage)
        }
        
        if let date = photo.createdAt {
            cell.dataLabel.text = dateFormatter.string(from: date)
        } else {
            cell.dataLabel.text = ""
        }
        
        cell.setIsLiked(photo.isLiked)
        return cell
    }
}

extension ImagesListViewController: ImageListCellDelegate {
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        UIBlockingProgressHUD.show()
        let isLiked = !presenter.photos[indexPath.row].isLiked
        cell.setIsLiked(isLiked)
        
        presenter.toggleLike(at: indexPath.row) { [weak self] in
            guard let self else { return }
            UIBlockingProgressHUD.dismiss()
            
            let isLiked = self.presenter.photos[indexPath.row].isLiked
            cell.setIsLiked(isLiked)
        }
    }
}

extension ImagesListViewController: ImageListViewControllerProtocol {
    
    func reloadTable() {
        tableView.reloadData()
    }
    
    func insertRows(at indexPaths: [IndexPath]) {
        tableView.insertRows(at: indexPaths, with: .automatic)
    }
    
    func showLikeError(message: String) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "ОК", style: .default))
        present(alert, animated: true)
    }
}
