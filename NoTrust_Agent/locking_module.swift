
import Foundation
import Cocoa
import Quartz


class locking_module {
    func lockScreen() {
      
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", "tell application \"System Events\" to keystroke \"q\" using {control down, command down}"]
        task.launch()
    }
    
    func openScreen(){
        let task = Process()
       
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", """
            tell application "System Events"
                keystroke "Coolguy45"
                delay 1
                keystroke return
            end tell
            """]
        task.launch()
    }
    
    func isScreenLocked() -> Bool{
        if let status = Quartz.CGSessionCopyCurrentDictionary() as? [String : Any],
           let isLocked = status["CGSSessionScreenIsLocked"] as? Bool{
            return isLocked
        } else {
            return false
        }
    }
}
