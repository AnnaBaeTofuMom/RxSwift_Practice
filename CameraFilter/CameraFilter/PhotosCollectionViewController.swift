//
//  PhotosCollectionViewController.swift
//  CameraFilter
//
//  Created by KEEN on 2022/02/16.
//

import UIKit
import Photos
import RxSwift

class PhotosCollectionViewController: UICollectionViewController {
  
  private let selectedPhotoSubject = PublishSubject<UIImage>()
  var selectedPhoto: Observable<UIImage> {
    return selectedPhotoSubject.asObservable()
  }
  
  private var images = [PHAsset]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    populatePhotos()
  }
  
  private func populatePhotos() {
    PHPhotoLibrary.requestAuthorization { [weak self] status in
      if status == .authorized { // 사진첩 접근 권한이 있는 경우
        let assets = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: nil)
        
        assets.enumerateObjects { (object, count, stop) in
          self?.images.append(object)
        }
        
        self?.images.reverse() // 가장 마지막에 선택한 이미지를 사용하기 위해서
        
        DispatchQueue.main.async {
          self?.collectionView.reloadData()
        }
      }
    }
  }
  
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.images.count
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCollectionViewCell.identifier, for: indexPath) as? PhotoCollectionViewCell else { return UICollectionViewCell() }
    
    let asset = self.images[indexPath.item]
    let manager = PHImageManager.default()
    manager.requestImage(for: asset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFill, options: nil) { image, _ in
      DispatchQueue.main.async {
        cell.photoImageView.image = image
      }
    }
    
    return cell
  }
  
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let selectedAsset = self.images[indexPath.item]
    PHImageManager.default().requestImage(for: selectedAsset, targetSize: CGSize(width: 300, height: 300), contentMode: .aspectFit, options: nil) { [weak self] image, info in
      guard let info = info else { return }
      
      let isDegradedImage = info["PHImageResultIsDegradedKey"] as! Bool
      
      if !isDegradedImage {
        if let image = image {
          self?.selectedPhotoSubject.onNext(image)
          self?.dismiss(animated: true, completion: nil)
        }
      }
    }
  }
}
