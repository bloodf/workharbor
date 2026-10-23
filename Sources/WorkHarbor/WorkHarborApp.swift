import SwiftUI
import AppKit
import EventKit
import HarborCore

@main
struct WorkHarborApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        MenuBarExtra("WorkHarbor", systemImage: "calendar.badge.clock") {
            AgendaPopover(model:delegate.model,openSettings:delegate.showWindow)
        }.menuBarExtraStyle(.window)
    }
}
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()
    private var window: NSWindow?
    private var instanceLock: ProcessLock?
    private var observers: [NSObjectProtocol] = []
    private var syncTimer: Timer?
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        if !model.isSyntheticDemo {
            do {
                if let identifier=Bundle.main.bundleIdentifier,
                   NSRunningApplication.runningApplications(withBundleIdentifier:identifier).contains(where:{$0.processIdentifier != ProcessInfo.processInfo.processIdentifier}) {
                    throw HarborError.invalid("Uma versão do WorkHarbor já está aberta. Use Sair no menu dela antes de iniciar esta versão.")
                }
                let directory=FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("WorkHarbor")
                instanceLock=try ProcessLock(file:directory.appendingPathComponent("instance.lock"))
            } catch {
                let alert=NSAlert();alert.messageText="WorkHarbor";alert.informativeText=model.t(error.localizedDescription);alert.addButton(withTitle:"OK");alert.runModal()
                NSApplication.shared.terminate(nil);return
            }
        }
        if model.isSyntheticDemo, let index=CommandLine.arguments.firstIndex(of:"--render-previews"),CommandLine.arguments.count > index+1 {
            let folder=URL(fileURLWithPath:CommandLine.arguments[index+1],isDirectory:true)
            do {
                try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
                for language in ["en","pt-BR","es"] {
                    model.settings.language=language
                    for dark in [false,true] {
                        let name="agenda-"+language+(dark ? "-dark" : "-light")+".png"
                        let view=AgendaPopover(model:model,openSettings:{}).frame(width:380,height:620).environment(\.colorScheme,dark ? .dark : .light)
                        let host=NSHostingView(rootView:view)
                        host.frame=NSRect(x:0,y:0,width:380,height:620)
                        let previewWindow=NSWindow(contentRect:host.frame,styleMask:[.borderless],backing:.buffered,defer:false)
                        previewWindow.isReleasedWhenClosed=false
                        previewWindow.appearance=NSAppearance(named:dark ? .darkAqua : .aqua)
                        previewWindow.contentView=host
                        host.layoutSubtreeIfNeeded()
                        RunLoop.main.run(until:Date().addingTimeInterval(0.25))
                        host.layoutSubtreeIfNeeded();host.displayIfNeeded()
                        guard let bitmap=host.bitmapImageRepForCachingDisplay(in:host.bounds) else { throw HarborError.invalid("Preview bitmap unavailable") }
                        host.cacheDisplay(in:host.bounds,to:bitmap)
                        guard let data=bitmap.representation(using:.png,properties:[:]) else { throw HarborError.invalid("Preview PNG unavailable") }
                        try data.write(to:folder.appendingPathComponent(name))
                        previewWindow.close()
                    }
                }
                print("SYNTHETIC_PREVIEWS_OK")
            } catch { print("SYNTHETIC_PREVIEWS_FAILED: \(error)") }
            NSApplication.shared.terminate(nil);return
        }
        observers.append(NotificationCenter.default.addObserver(forName: .EKEventStoreChanged, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.model.invalidateReview() }
        })
        observers.append(NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.model.invalidateReview() }
        })
        syncTimer = Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.model.refreshAgenda(); self?.model.scheduleAutomaticSync() }
        }
        model.scheduleAutomaticSync()
        model.refreshAgenda()
    }
    func showWindow() {
        if window == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 760, height: 640), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
            window.title = "WorkHarbor · " + model.t("settings")
            window.minSize = NSSize(width: 680, height: 550)
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: ContentView(model: model))
            window.center()
            self.window = window
        }
        window?.title="WorkHarbor · "+model.t("settings")
        NSApplication.shared.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}
