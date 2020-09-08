import Cocoa
import SafariServices.SFSafariApplication

class ViewController: NSViewController {

    @IBOutlet var appNameLabel: NSTextField!
    @IBOutlet var saveLocationLabel: NSTextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        self.appNameLabel.stringValue = "Userscripts - Version \(appVersion)";
        // seems like a lot of work to id path for another target's documents directory
        let hostID = Bundle.main.bundleIdentifier!
        let extensionID = "com.userscripts.macos.Userscripts-Extension"
        let documentsDirectory = getDocumentsDirectory().appendingPathComponent("scripts").absoluteString
        let location = documentsDirectory.replacingOccurrences(of: hostID, with: extensionID)
        // check if bookmark data exists
        guard
            let sharedBookmark = UserDefaults(suiteName: SharedDefaults.suiteName)?.data(forKey: SharedDefaults.keyName),
            let url = readBookmark(data: sharedBookmark, isSecure: false),
            directoryExists(path: url.path)
        else {
            // sharedBookmark removed, or in trash
            // renamed directories retain association
            // moved directories retain association
            UserDefaults(suiteName: SharedDefaults.suiteName)?.removeObject(forKey: SharedDefaults.keyName)
            NSLog("removed sharedbookmark because it is non-existent, permanently deleted or exists in trash")
            self.saveLocationLabel.stringValue = location
            return
        }
        self.saveLocationLabel.stringValue = url.absoluteString
    }
    
    @IBAction func changeSaveLocation(_ sender: NSButton) {
        guard let window = self.view.window else { return }
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.canChooseFiles = false
        panel.beginSheetModal(for: window, completionHandler: { response in
            if let url: URL = panel.urls.first {
                // check it is a writeable path
                let canWrite = FileManager.default.isWritableFile(atPath: url.path)
                if !canWrite {
                    // display error message
                    let alert = NSAlert()
                    alert.messageText = "Can not write to path. Choose a different path."
                    alert.runModal()
                } else {
                    if !saveBookmark(url: url, isShared: true, keyName: SharedDefaults.keyName, isSecure: false) {
                        err("couldn't save new location from host app")
                        return
                    }
                    self.saveLocationLabel.stringValue = url.absoluteString
                }
            }
        })
    }
    
    @IBAction func openSafariExtensionPreferences(_ sender: AnyObject?) {
        SFSafariApplication.showPreferencesForExtension(withIdentifier: "com.userscripts.macos.Userscripts-Extension") { error in
            if let _ = error {
                // Insert code to inform the user that something went wrong.
            }
        }
    }
}
