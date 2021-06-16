import UIKit

struct FilterDescription {

    var filter: Filter
    var intensity: CGFloat

}

enum Filter: String, CaseIterable {

    case NoFilters
    case CIGaussianBlur
    case CIPhotoEffectNoir
    case CIColorInvert
    case CISepiaTone
    case CIPixellate
    case CIPhotoEffectChrome
    case CIPhotoEffectFade
    case CIPhotoEffectInstant
    case CIPhotoEffectMono
    case CIPhotoEffectProcess
    case CIPhotoEffectTonal
    case CIPhotoEffectTransfer
    case CITwirlDistortion
    case CIVignette
    case CIUnsharpMask
    case CIBumpDistortion

    var identifier: String {
        var id = rawValue.replacingOccurrences(of: "CI", with: "")
        id = id.replacingOccurrences(of: "Photo", with: "")
        id = id.replacingOccurrences(of: "Effect", with: "")
        return id
    }

}


class ImageFilter {

    // MARK: - Private Properties

    private let context: CIContext
    private let filter: CIFilter

    init?(name: String) {
        self.context = CIContext()
        guard let filter = CIFilter(name: name) else {
            return nil
        }
        self.filter = filter
    }

    // MARK: - Public Properties

    public func applyFilter(image: UIImage, description: FilterDescription) -> UIImage? {
        guard let ciImage = CIImage(image: image) else {
            return nil
        }

        filter.setValue(ciImage, forKey: kCIInputImageKey)
        let inputKeys = filter.inputKeys

        if (inputKeys.contains(kCIInputIntensityKey)) { filter.setValue(description.intensity, forKey: kCIInputIntensityKey) }
        if (inputKeys.contains(kCIInputRadiusKey)) { filter.setValue(description.intensity * 200, forKey: kCIInputRadiusKey) }
        if (inputKeys.contains(kCIInputScaleKey)) { filter.setValue(description.intensity * 10, forKey: kCIInputScaleKey) }
        if (inputKeys.contains(kCIInputCenterKey)) { filter.setValue(CIVector(x: image.size.width / 2, y: image.size.height / 2), forKey: kCIInputCenterKey) }

        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

}
