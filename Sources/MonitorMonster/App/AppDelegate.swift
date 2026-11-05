import AppKit
import SwiftUI

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Pure Menu Bar Accessory app (no window in the middle of desktop)
        NSApp.setActivationPolicy(.accessory)

        // Setup Status Item in Menu Bar with Glowing Monster Ball icon
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = createMonsterBallIcon()
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        // Setup Popover to drop down from the Menu Bar item
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 420, height: 540)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: DashboardView())
        self.popover = popover

        // Open popover directly under the menu bar icon on launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self, let button = self.statusItem.button else { return }
            self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            self.popover.contentViewController?.view.window?.makeKey()
        }
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            AppState.shared.refreshAll()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func createMonsterBallIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }

            // 1. Soft Outer Glow Aura
            let glowRect = CGRect(x: 0.8, y: 0.8, width: 16.4, height: 16.4)
            ctx.addPath(CGPath(ellipseIn: glowRect, transform: nil))
            ctx.setFillColor(NSColor.labelColor.withAlphaComponent(0.25).cgColor)
            ctx.fillPath()

            // 2. Monster Ball Body
            let bodyRect = CGRect(x: 2.2, y: 2.2, width: 13.6, height: 13.6)
            ctx.addPath(CGPath(ellipseIn: bodyRect, transform: nil))
            ctx.setFillColor(NSColor.labelColor.cgColor)
            ctx.fillPath()

            // 3. Two Expressive Cute Eyes
            ctx.setBlendMode(.clear)
            let leftEye = CGRect(x: 5.2, y: 7.2, width: 2.7, height: 4.2)
            let rightEye = CGRect(x: 10.1, y: 7.2, width: 2.7, height: 4.2)
            ctx.addPath(CGPath(ellipseIn: leftEye, transform: nil))
            ctx.addPath(CGPath(ellipseIn: rightEye, transform: nil))
            ctx.fillPath()

            return true
        }
        image.isTemplate = true
        return image
    }
}
