import AppKit
import SwiftUI
import Combine
import CoreLocation

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate, CLLocationManagerDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var cancellables = Set<AnyCancellable>()
    private var locationManager: CLLocationManager?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Pure Menu Bar Accessory app (no window in the middle of desktop)
        NSApp.setActivationPolicy(.accessory)

        // Request Location permission so macOS unredacts the Wi-Fi SSID
        let lm = CLLocationManager()
        lm.delegate = self
        lm.requestWhenInUseAuthorization()
        self.locationManager = lm

        // Setup Status Item in Menu Bar with Glowing Monster Ball icon
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = createMonsterBallIcon(mood: AppState.shared.currentMood, isBlinking: false)
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

        // Observe Monster's Mood & Blink expressions
        setupMonsterObserver()
    }

    private func setupMonsterObserver() {
        Publishers.CombineLatest(AppState.shared.$currentMood, AppState.shared.$isBlinking)
            .receive(on: RunLoop.main)
            .sink { [weak self] mood, isBlinking in
                guard let self = self, let button = self.statusItem?.button else { return }
                button.image = self.createMonsterBallIcon(mood: mood, isBlinking: isBlinking)
            }
            .store(in: &cancellables)
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

    private func createMonsterBallIcon(mood: MonsterMood, isBlinking: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }

            // 1. Soft Outer Glow Aura
            let glowRect = CGRect(x: 0.8, y: 0.8, width: 16.4, height: 16.4)
            ctx.addPath(CGPath(ellipseIn: glowRect, transform: nil))
            ctx.setFillColor(NSColor.labelColor.withAlphaComponent(0.22).cgColor)
            ctx.fillPath()

            // 2. Monster Ball Body
            let bodyRect = CGRect(x: 2.2, y: 2.2, width: 13.6, height: 13.6)
            ctx.addPath(CGPath(ellipseIn: bodyRect, transform: nil))
            ctx.setFillColor(NSColor.labelColor.cgColor)
            ctx.fillPath()

            // 3. Eyes (Cutout via .clear blend mode)
            ctx.setBlendMode(.clear)

            if isBlinking || mood == .sleepy {
                // Natural Blink or Sleepy slits (- -)
                let leftSlit = CGRect(x: 4.8, y: 8.5, width: 3.5, height: 1.2)
                let rightSlit = CGRect(x: 9.7, y: 8.5, width: 3.5, height: 1.2)
                ctx.fill([leftSlit, rightSlit])
            } else if mood == .fever || mood == .laggy {
                // Squinty / Strained angled eyes (> <)
                ctx.setLineWidth(1.3)
                ctx.setLineCap(.round)

                // Left '>'
                ctx.beginPath()
                ctx.move(to: CGPoint(x: 5.0, y: 10.5))
                ctx.addLine(to: CGPoint(x: 7.5, y: 8.5))
                ctx.addLine(to: CGPoint(x: 5.0, y: 6.5))
                ctx.strokePath()

                // Right '<'
                ctx.beginPath()
                ctx.move(to: CGPoint(x: 13.0, y: 10.5))
                ctx.addLine(to: CGPoint(x: 10.5, y: 8.5))
                ctx.addLine(to: CGPoint(x: 13.0, y: 6.5))
                ctx.strokePath()
            } else if mood == .offline {
                // Wide surprised hollow circles (O O)
                let leftEye = CGRect(x: 4.8, y: 7.0, width: 3.4, height: 4.5)
                let rightEye = CGRect(x: 9.8, y: 7.0, width: 3.4, height: 4.5)
                ctx.addPath(CGPath(ellipseIn: leftEye, transform: nil))
                ctx.addPath(CGPath(ellipseIn: rightEye, transform: nil))
                ctx.fillPath()
            } else {
                // Normal / Happy cute oval eyes
                let leftEye = CGRect(x: 5.2, y: 7.2, width: 2.7, height: 4.2)
                let rightEye = CGRect(x: 10.1, y: 7.2, width: 2.7, height: 4.2)
                ctx.addPath(CGPath(ellipseIn: leftEye, transform: nil))
                ctx.addPath(CGPath(ellipseIn: rightEye, transform: nil))
                ctx.fillPath()
            }

            return true
        }
        image.isTemplate = true
        return image
    }
}
