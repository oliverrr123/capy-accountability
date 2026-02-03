import CoreText
import Foundation

enum FontRegistrar {
    static func registerFonts() {
        guard let resourceURL = Bundle.main.resourceURL else {
            return
        }

        let fileManager = FileManager.default
        let resourceEnumerator = fileManager.enumerator(at: resourceURL, includingPropertiesForKeys: nil)

        while let url = resourceEnumerator?.nextObject() as? URL {
            guard url.pathExtension.lowercased() == "ttf" else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
