import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    super.awakeFromNib()
    
    // Hide the window initially (invisible)
    self.alphaValue = 0.0
    
    // Regular Flutter initialization
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    
    // Wait and verify that Flutter is ready before showing
    waitForFlutterAndShow()
  }
  
  /// This function waits for Flutter to be ready and then shows the window with a fade-in effect.
  private func waitForFlutterAndShow() {
    var attempts = 0
    let maxAttempts = 20 // Maximum 2 seconds (20 * 0.1)
    
    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
      guard let self = self else {
        timer.invalidate()
        return
      }
      
      attempts += 1
      
      // Check if Flutter is ready
      if let flutterViewController = self.contentViewController as? FlutterViewController {
        let view = flutterViewController.view
        let hasValidSize = view.frame.width > 0 && view.frame.height > 0
        let engineReady = flutterViewController.engine != nil
        
        // Check if Flutter has rendered at least one frame
        // This is more secure than just checking the size
        if (hasValidSize && engineReady) || attempts >= maxAttempts {
          timer.invalidate()
          
          // Small additional delay to ensure the first frame is completely rendered
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.showWindowWithFadeIn()
          }
        }
      } else if attempts >= maxAttempts {
        // Timeout: show the window anyway
        timer.invalidate()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
          self?.showWindowWithFadeIn()
        }
      }
    }
  }
  
  private func showWindowWithFadeIn() {
    // Ensure the window is visible (but still transparent)
    self.makeKeyAndOrderFront(nil)
    
    // Do fade-in
    NSAnimationContext.runAnimationGroup({ context in
      context.duration = 0.3
      self.animator().alphaValue = 1.0
    })
  }
}