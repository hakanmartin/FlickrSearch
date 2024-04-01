//
//  ViewController.swift
//  FlickrSearch
//
//  Created by Hakan Martin on 1.04.2024.
//

import UIKit

class ViewController: UIViewController {
    private let searchTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter keyword"
        textField.textAlignment = .center
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.layer.borderWidth = 1.0
        textField.layer.borderColor = UIColor.white.cgColor
        textField.layer.cornerRadius = 5.0
        textField.textColor = .white
        textField.attributedPlaceholder = NSAttributedString(string: "Enter keyword", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        return textField
    }()
    
    private let searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Search", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .gray
        button.layer.cornerRadius = 5.0
        return button
    }()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let photoContainerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        view.addSubview(searchTextField)
        NSLayoutConstraint.activate([
            searchTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            searchTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            searchTextField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.67),
            searchTextField.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        view.addSubview(searchButton)
        NSLayoutConstraint.activate([
            searchButton.topAnchor.constraint(equalTo: searchTextField.topAnchor),
            searchButton.leadingAnchor.constraint(equalTo: searchTextField.trailingAnchor, constant: 10),
            searchButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            searchButton.heightAnchor.constraint(equalTo: searchTextField.heightAnchor)
        ])
        
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        scrollView.addSubview(photoContainerStackView)
        NSLayoutConstraint.activate([
            photoContainerStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            photoContainerStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            photoContainerStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            photoContainerStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            photoContainerStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
    }
    
    @objc private func searchButtonTapped() {
        guard let keyword = searchTextField.text else { return }
        searchPhotos(keyword: keyword)
    }
    
    private func searchPhotos(keyword: String) {
        // Önceki resimleri temizle
        for subview in photoContainerStackView.arrangedSubviews {
            photoContainerStackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        
        // Flickr API'ye istek yapmak için gereken URL'yi oluşturun
        let apiKey = "API_KEY"
        let urlString = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apiKey)&text=\(keyword)&format=json&nojsoncallback=1"
        guard let url = URL(string: urlString) else { return }
        
        // URLSession kullanarak Flickr API'sine istek yapın
        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                // API yanıtını JSON'dan çözümleyin
                let result = try JSONDecoder().decode(FlickrSearchResponse.self, from: data)
                print(result)
                // Alınan resimlerin URL'lerini kullanarak resimleri görüntüleyin
                DispatchQueue.main.async {
                    self?.displayPhotos(result.photos.photo)
                }
            } catch {
                print("Error decoding JSON: \(error)")
            }
        }
        
        task.resume()
    }
    
    private func displayPhotos(_ photos: [FlickrPhoto]) {
        var rowStackView: UIStackView?
        // Her resim için bir UIImageView oluşturun ve photoContainerStackView'e ekleyin
        for (index, photo) in photos.enumerated() {
            if index % 2 == 0 { // Her iki resimden sonra yeni bir satır oluşturun
                rowStackView = UIStackView()
                rowStackView?.axis = .horizontal
                rowStackView?.spacing = 10
                rowStackView?.distribution = .fillEqually
                rowStackView?.translatesAutoresizingMaskIntoConstraints = false
                photoContainerStackView.addArrangedSubview(rowStackView!)
            }
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.heightAnchor.constraint(equalToConstant: 150).isActive = true // Resmin yüksekliği 150 birim olsun
            imageView.widthAnchor.constraint(equalToConstant: 150).isActive = true // Resmin genişliği 150 birim olsun (kare formunda)
            
            // Resmi yükle
            URLSession.shared.dataTask(with: photo.imageUrl) { (data, response, error) in
                guard let data = data, error == nil else {
                    print("Error loading image: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                DispatchQueue.main.async {
                    imageView.image = UIImage(data: data) // Yüklenen resmi imageView'e ata
                }
            }.resume()
            
            // Oluşturulan imageView'i rowStackView'e ekle
            rowStackView?.addArrangedSubview(imageView)
        }
    }
}

struct FlickrSearchResponse: Codable {
    let photos: FlickrPhotos
}

struct FlickrPhotos: Codable {
    let photo: [FlickrPhoto]
}

struct FlickrPhoto: Codable {
    let id: String
    let farm: Int
    let server: String
    let secret: String
    
    var imageUrl: URL {
        return URL(string: "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret).jpg")!
    }
}

