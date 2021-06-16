import UIKit

class PhotoEditorViewController: UIViewController {

    // MARK: Private Types

    private typealias BlurStyle = UIBlurEffect.Style
    private struct EditorConfiguration {

        var blurEffectView: UIVisualEffectView?
        var selectedImageIndex = 0
        var thumbnailImagesWithFilters: [String : UIImage] = [:]
    }
    
    // MARK: - Private Properties

    @IBOutlet private weak var intensitySlider: UISlider!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var thumbnailPhotosCollectionView: UICollectionView!
    @IBOutlet private weak var backgroundImageView: UIImageView!

    private var configuration: EditorConfiguration = EditorConfiguration()
    private let loadingViewController = LoadingViewController()
    private var currentFilter: FilterDescription = FilterDescription(filter: .NoFilters, intensity: 0)
    private var imageFilter: ImageFilter?

    // MARK: - Internal Properties

    var editImage: UIImage?

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        thumbnailPhotosCollectionView.delegate = self
        thumbnailPhotosCollectionView.dataSource = self

        currentFilter.intensity = CGFloat(intensitySlider.value)
        intensitySlider.isHidden = true
        imageView.image = editImage
        applyBlur()
        applyFilters()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configuration.selectedImageIndex = Int.random(in: 1...11)
        backgroundImageView.image = UIImage(named: String(describing: configuration.selectedImageIndex))
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        configuration.blurEffectView?.frame = view.bounds
    }

    // MARK: - Private Methods

    @IBAction private func didValueChange() {
        DispatchQueue.main.async { [unowned self] in
            currentFilter.intensity = CGFloat(intensitySlider.value)
        }
        let queue = DispatchQueue.global(qos: .utility)

        queue.async {[unowned self] in
            applyProcessing(with: currentFilter.filter)
        }

    }

    @IBAction private func saveButtonPressed() {
        displayContentController(content: loadingViewController)
        guard let image = imageView.image,
              let pngData = image.pngData(),
              let compressedImage = UIImage(data: pngData) else {
            return
        }
        UIImageWriteToSavedPhotosAlbum(compressedImage, self, #selector(saveError(_:didFinishSavingWithError:contextInfo:)), nil)

    }

    @objc func saveError(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        hideContentController(content: loadingViewController)
        navigationController?.popToRootViewController(animated: true)
    }

    private func applyBlur() {
        let style: BlurStyle = UITraitCollection.current.userInterfaceStyle == .light ? .light : .dark
        let blurEffect = UIBlurEffect(style: style)
        configuration.blurEffectView = UIVisualEffectView(effect: blurEffect)
        configuration.blurEffectView?.frame = view.bounds
        backgroundImageView.addSubview(configuration.blurEffectView!)
    }

    private func applyFilters() {

        displayContentController(content: loadingViewController)
        let group = DispatchGroup()
        let queue = DispatchQueue.global(qos: .utility)

        for filter in Filter.allCases {
            queue.async(group: group) { [unowned self] in

                switch filter {

                    case .NoFilters:
                        self.configuration.thumbnailImagesWithFilters[filter.identifier] = self.editImage!
                        DispatchQueue.main.async {
                            self.thumbnailPhotosCollectionView.reloadData()
                        }

                    case .CIGaussianBlur:
                        applyThumbnailProcessing(with: .CIGaussianBlur)

                    case .CIPhotoEffectNoir:
                        applyThumbnailProcessing(with: .CIPhotoEffectNoir)

                    case .CIColorInvert:
                        applyThumbnailProcessing(with: .CIColorInvert)

                    case .CISepiaTone:
                        applyThumbnailProcessing(with: .CISepiaTone)

                    case .CIPixellate:
                        applyThumbnailProcessing(with: .CIPixellate)

                    case .CIPhotoEffectChrome:
                        applyThumbnailProcessing(with: .CIPhotoEffectChrome)

                    case .CIPhotoEffectFade:
                        applyThumbnailProcessing(with: .CIPhotoEffectFade)

                    case .CIPhotoEffectInstant:
                        applyThumbnailProcessing(with: .CIPhotoEffectInstant)

                    case .CIPhotoEffectMono:
                        applyThumbnailProcessing(with: .CIPhotoEffectMono)

                    case .CIPhotoEffectProcess:
                        applyThumbnailProcessing(with: .CIPhotoEffectProcess)

                    case .CIPhotoEffectTonal:
                        applyThumbnailProcessing(with: .CIPhotoEffectTonal)

                    case .CIPhotoEffectTransfer:
                        applyThumbnailProcessing(with: .CIPhotoEffectTransfer)

                    case .CITwirlDistortion:
                        applyThumbnailProcessing(with: .CITwirlDistortion)

                    case .CIVignette:
                        applyThumbnailProcessing(with: .CIVignette)

                    case .CIUnsharpMask:
                        applyThumbnailProcessing(with: .CIUnsharpMask)

                    case .CIBumpDistortion:
                        applyThumbnailProcessing(with: .CIBumpDistortion)
                }
            }
        }

        group.notify(queue: .main, execute: { [unowned self] in
            hideContentController(content: loadingViewController)
        })
    }

    private func displayContentController(content: UIViewController) {
        self.navigationController?.addChild(content)
        self.navigationController?.view.addSubview(content.view)
        content.didMove(toParent: self)
    }

    private func hideContentController(content: UIViewController) {
        content.willMove(toParent: nil)
        content.view.removeFromSuperview()
        content.removeFromParent()
    }

    private func applyThumbnailProcessing(with filter: Filter) {
        let imageFilter = ImageFilter(name: filter.rawValue)
        if let filteredImage = imageFilter?.applyFilter(image: editImage!,
                                                       description: FilterDescription(filter: filter,
                                                                                      intensity: 0.7)) {
            self.configuration.thumbnailImagesWithFilters[filter.identifier] = filteredImage
            DispatchQueue.main.async {
                self.thumbnailPhotosCollectionView.reloadData()
            }
        }
    }

    private func applyProcessing(with filter: Filter) {
        if let filteredImage = imageFilter?.applyFilter(image: editImage!,
                                                       description: FilterDescription(filter: filter,
                                                                                      intensity: currentFilter.intensity)) {
            DispatchQueue.main.async {[unowned self] in
                hideContentController(content: loadingViewController)
                self.imageView.image = filteredImage
            }
        }
    }

}

// MARK: UICollectionViewDelegate Protocol

extension PhotoEditorViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        intensitySlider.setValue(0, animated: true)
        intensitySlider.isHidden = false

        let queue = DispatchQueue.global(qos: .utility)

        displayContentController(content: loadingViewController)

        currentFilter.intensity = 0
        currentFilter.filter = Filter.allCases[indexPath.row]
        imageFilter = ImageFilter(name: currentFilter.filter.rawValue)

        queue.async {[unowned self] in
            switch currentFilter.filter {
                case .NoFilters:
                    DispatchQueue.main.async {
                        hideContentController(content: loadingViewController)
                        intensitySlider.isHidden = true
                        self.imageView.image = editImage
                    }

                case .CIGaussianBlur:
                    applyProcessing(with: .CIGaussianBlur)

                case .CIPhotoEffectNoir:
                    DispatchQueue.main.async {
                        intensitySlider.isHidden = true
                    }
                    applyProcessing(with: .CIPhotoEffectNoir)

                case .CIColorInvert:
                    DispatchQueue.main.async {
                        intensitySlider.isHidden = true
                    }
                    applyProcessing(with: .CIColorInvert)

                case .CISepiaTone:
                    applyProcessing(with: .CISepiaTone)

                case .CIPixellate:
                    applyProcessing(with: .CIPixellate)

                case .CIPhotoEffectChrome:
                    DispatchQueue.main.async {
                        intensitySlider.isHidden = true
                    }
                    applyProcessing(with: .CIPhotoEffectChrome)

                case .CIPhotoEffectFade:
                    DispatchQueue.main.async {
                        intensitySlider.isHidden = true
                    }
                    applyProcessing(with: .CIPhotoEffectFade)

                case .CIPhotoEffectInstant:
                    DispatchQueue.main.async {
                        intensitySlider.isHidden = true
                    }
                    applyProcessing(with: .CIPhotoEffectInstant)

                case .CIPhotoEffectMono:
                    DispatchQueue.main.async {
                        intensitySlider.isHidden = true
                    }
                    applyProcessing(with: .CIPhotoEffectMono)

                case .CIPhotoEffectProcess:
                    DispatchQueue.main.async {
                        intensitySlider.isHidden = true
                    }
                    applyProcessing(with: .CIPhotoEffectProcess)

                case .CIPhotoEffectTonal:
                    DispatchQueue.main.async {
                        intensitySlider.isHidden = true
                    }
                    applyProcessing(with: .CIPhotoEffectTonal)

                case .CIPhotoEffectTransfer:
                    DispatchQueue.main.async {
                        intensitySlider.isHidden = true
                    }
                    applyProcessing(with: .CIPhotoEffectTransfer)

                case .CITwirlDistortion:
                    applyProcessing(with: .CITwirlDistortion)

                case .CIVignette:
                    applyProcessing(with: .CIVignette)

                case .CIUnsharpMask:
                    applyProcessing(with: .CIUnsharpMask)

                case .CIBumpDistortion:
                    applyProcessing(with: .CIBumpDistortion)
            }
        }
    }

}

// MARK: UICollectionViewDataSource Protocol

extension PhotoEditorViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Filter.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let thumbnailCell = thumbnailPhotosCollectionView.dequeueReusableCell(withReuseIdentifier: ThumbnailPhotoCollectionViewCell.identifier, for: indexPath) as! ThumbnailPhotoCollectionViewCell
        let identifier = Filter.allCases[indexPath.row].identifier

        thumbnailCell.thumbnailPhotoImageView.image = configuration.thumbnailImagesWithFilters[identifier]
        thumbnailCell.filterNameLabel.text = identifier

        return thumbnailCell
    }

}

// MARK: - Helper

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}
