import Foundation
import SwiftUI
import ObjectiveC

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: String = UserDefaults.standard.string(forKey: "AppLanguage") ?? Locale.current.languageCode ?? "en" {
        didSet {
            if oldValue != currentLanguage {
                UserDefaults.standard.set(currentLanguage, forKey: "AppLanguage")
                UserDefaults.standard.synchronize()
                
                // Force UI update
                self.objectWillChange.send()
                
                // Update the bundle
                Bundle.setLanguage(currentLanguage)
                
                // Notify all subscribers
                NotificationCenter.default.post(name: .languageChanged, object: nil)
                
                // Log for debugging
                print("Language changed to: \(currentLanguage)")
            }
        }
    }
    
    init() {
        // Make sure the language is properly set during initialization
        if let savedLanguage = UserDefaults.standard.string(forKey: "AppLanguage") {
            self.currentLanguage = savedLanguage
            Bundle.setLanguage(savedLanguage)
        } else {
            // Default language if not set
            let defaultLanguage = Locale.current.languageCode ?? "en"
            self.currentLanguage = defaultLanguage
            UserDefaults.standard.set(defaultLanguage, forKey: "AppLanguage")
            Bundle.setLanguage(defaultLanguage)
        }
    }
    
    // Helper function to get localized string
    func localizedString(for key: String, comment: String = "") -> String {
        let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj")
        let bundle = path != nil ? Bundle(path: path!) : Bundle.main
        return bundle?.localizedString(forKey: key, value: nil, table: nil) ?? key
    }
}

extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}

// Bundle extension to handle language changes
private var bundleKey: UInt8 = 0

class BundleEx: Bundle {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        guard let path = objc_getAssociatedObject(self, &bundleKey) as? String,
              let bundle = Bundle(path: path) else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}

extension Bundle {
    static func setLanguage(_ language: String) {
        defer {
            // Ensure UI updates happen on main thread
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .languageChanged, object: nil)
            }
        }
        
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj") else {
            print("Failed to find \(language).lproj")
            return
        }
        
        objc_setAssociatedObject(Bundle.main, &bundleKey, path, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // Swizzle Bundle.main to use our custom BundleEx for localization
        object_setClass(Bundle.main, BundleEx.self)
    }
}

// String extension to make localization easier in views
extension String {
    var localized: String {
        return LocalizationManager.shared.localizedString(for: self)
    }
    
    func localized(comment: String = "") -> String {
        return LocalizationManager.shared.localizedString(for: self, comment: comment)
    }
}