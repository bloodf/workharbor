import AppKit
import SwiftUI
import HarborCore

/// In-process AppKit QA, never global mouse/keyboard injection or live calendar access.
@MainActor
private final class MenuTrackingProbe: NSObject, NSMenuDelegate {
    var opens = 0
    weak var menu:NSMenu?
    func menuWillOpen(_ menu: NSMenu) { opens += 1 }
}
@MainActor
enum StatusItemSyntheticQA {
    static func run(model:AppModel) async throws {
        guard model.isSyntheticDemo else { throw HarborError.invalid("Synthetic mode required") }
        var checks=0, failures:[String]=[]
        func check(_ value:Bool,_ message:String) {checks+=1;if !value {failures.append(message)}}
        func settle() async { try? await Task.sleep(for:.milliseconds(100)) }
        func awaitAgenda(_ controller:StatusItemController) async {
            let deadline=Date().addingTimeInterval(2)
            while !controller.popover.isShown && Date()<deadline {try? await Task.sleep(for:.milliseconds(20))}
        }
        var callbacks:[String]=[], refreshAllowed=true, choice:StatusQuickAction?
        var tracking=false, presentations=0, revokeWhileTracking=false
        weak var weakController:StatusItemController?
        let settings=NSWindow(contentRect:NSRect(x:0,y:0,width:760,height:640),styleMask:[.titled,.closable],backing:.buffered,defer:false)
        settings.isReleasedWhenClosed=false
        settings.title="WorkHarbor synthetic QA settings"
        settings.contentView=NSHostingView(rootView:ContentView(model:model))
        let agenda=NSHostingController(rootView:AgendaPopover(model:model,openSettings:{}))
        let controller=StatusItemController(agenda:agenda,title:{model.t($0)},canRefresh:{refreshAllowed},
            openSettings:{check(!tracking,"settings dispatched during tracking");callbacks.append("settings");settings.orderFront(nil)},
            refresh:{check(!tracking,"refresh dispatched during tracking");callbacks.append("refresh");model.refreshAgenda()},
            quit:{check(!tracking,"quit dispatched during tracking");callbacks.append("quit")},
            presentMenu:{menu,button in
                presentations+=1
                let probe=MenuTrackingProbe();probe.menu=menu;menu.delegate=probe
                check(menu.items.filter{!$0.isSeparatorItem}.count==4,"four product actions")
                check(weakController?.item.menu == nil,"primary must never retain menu")
                let before=callbacks
                // Ensure a nested request cannot reset tracking or display a second menu.
                weakController?.showQuickMenu()
                let timer=Timer(timeInterval:0.08,repeats:false) {_ in
                    MainActor.assumeIsolated {
                    guard let menu=probe.menu else {return}
                    if revokeWhileTracking {refreshAllowed=false}
                    if let choice,let index=menu.items.firstIndex(where:{$0.identifier?.rawValue==choice.rawValue}) {menu.performActionForItem(at:index)}
                    check(callbacks==before,"opening/selecting must defer callbacks until tracking ends")
                    menu.cancelTrackingWithoutAnimation()
                    }
                }
                RunLoop.main.add(timer,forMode:.eventTracking);RunLoop.main.add(timer,forMode:.common)
                tracking=true
                menu.popUp(positioning:nil,at:NSPoint(x:0,y:button.bounds.minY),in:button)
                tracking=false;timer.invalidate()
                check(probe.opens==1,"native menu tracking actually opened")
                menu.delegate=nil
            })
        weakController=controller;controller.popover.animates=false
        let readyDeadline=Date().addingTimeInterval(2)
        while (controller.item.button?.window?.isVisible != true || controller.item.button?.bounds.width == 0) && Date()<readyDeadline {await settle()}
        print("QA_READY active=\(NSApp.isActive) visible=\(controller.item.button?.window?.isVisible == true) bounds=\(controller.item.button?.bounds ?? .zero)")
        defer {controller.invalidate();settings.close()}
        check(controller.item.button?.target === controller,"native button target")
        check(controller.item.button?.action != nil,"native button action")
        check(controller.item.button?.accessibilityLabel()=="WorkHarbor","accessible label")
        check(controller.item.button?.accessibilityCustomActions()?.count==2,"agenda and quick-options accessibility actions")
        func mouse(_ type:NSEvent.EventType,control:Bool=false)->NSEvent {
            NSEvent.mouseEvent(with:type,location:.zero,modifierFlags:control ? [.control] : [],timestamp:ProcessInfo.processInfo.systemUptime,
                windowNumber:controller.item.button?.window?.windowNumber ?? 0,context:nil,eventNumber:0,clickCount:1,pressure:0)!
        }
        for cycle in 0..<8 {
            controller.handleButtonEvent(mouse(.leftMouseUp));if cycle==0 {print("QA_FIRST_IMMEDIATE shown=\(controller.popover.isShown) active=\(NSApp.isActive)")};await awaitAgenda(controller);if cycle==0 {print("QA_FIRST_SETTLED shown=\(controller.popover.isShown) active=\(NSApp.isActive)")};check(controller.popover.isShown,"primary opens agenda cycle \(cycle)")
            controller.handleButtonEvent(mouse(.leftMouseUp));await settle();check(!controller.popover.isShown,"primary closes agenda")
            controller.handleButtonEvent(mouse(.rightMouseUp));check(!controller.popover.isShown,"secondary cancel leaves no popover")
            check(callbacks.isEmpty,"cancellation must not execute actions")
        }
        controller.handleButtonEvent(mouse(.leftMouseUp));controller.handleButtonEvent(mouse(.leftMouseUp));await settle()
        check(!controller.popover.isShown,"two rapid primary inputs cancel pending agenda")
        controller.handleButtonEvent(mouse(.leftMouseUp))
        let beforeControl=presentations
        controller.handleButtonEvent(mouse(.leftMouseUp,control:true))
        check(presentations==beforeControl+1,"Control-click opens quick menu")
        check(!controller.popover.isShown,"secondary closes old agenda")
        check(callbacks.isEmpty,"Control-click cancel is side-effect-free")
        let beforeOther=presentations;controller.handleButtonEvent(mouse(.otherMouseUp));check(presentations==beforeOther && !controller.popover.isShown,"middle button ignored")
        check(controller.accessibleAgenda(),"accessible agenda action");await settle();check(controller.popover.isShown,"accessible agenda opens")
        check(controller.accessibleOptions(),"accessible options action");check(!controller.popover.isShown,"accessible options closes agenda")
        check(callbacks.isEmpty,"accessible cancel is side-effect-free")
        // Default accessibility press follows the primary button target/action.
        _=controller.item.button?.accessibilityPerformPress();await settle();check(controller.popover.isShown,"AX press preserves primary agenda")
        controller.closeAgenda();await settle()
        let keyboard=NSEvent.keyEvent(with:.keyDown,location:.zero,modifierFlags:[],timestamp:ProcessInfo.processInfo.systemUptime,windowNumber:0,context:nil,characters:"\r",charactersIgnoringModifiers:"\r",isARepeat:false,keyCode:36)!
        controller.handleButtonEvent(keyboard);await awaitAgenda(controller);check(controller.popover.isShown,"keyboard activation preserves agenda")
        controller.closeAgenda();await settle()
        model.settings.language="pt-BR";controller.updateAccessibility()
        check(controller.makeMenu().items.first?.title=="Abrir agenda","menu uses current language")
        check(controller.item.button?.accessibilityCustomActions()?.map(\.name).contains("Opções rápidas")==true,"accessibility uses current language")
        choice = .agenda;controller.showQuickMenu();await settle();check(controller.popover.isShown,"selected agenda opens popover")
        check(callbacks.isEmpty,"agenda does not run other actions");controller.closeAgenda()
        choice = .settings;controller.showQuickMenu();await settle();check(settings.isVisible,"selected settings opens window")
        check(callbacks==["settings"],"settings dispatched once");settings.orderOut(nil)
        choice = .refresh;controller.showQuickMenu();check(callbacks==["settings","refresh"],"selected refresh once")
        refreshAllowed=false
        check(controller.makeMenu().items.first(where:{$0.identifier?.rawValue=="refresh"})?.isEnabled==false,"refresh disabled without access")
        controller.showQuickMenu();check(callbacks==["settings","refresh"],"disabled refresh cannot execute")
        refreshAllowed=true;revokeWhileTracking=true;controller.showQuickMenu()
        check(callbacks==["settings","refresh"],"refresh availability rechecked after selection")
        revokeWhileTracking=false;refreshAllowed=true;choice = .quit;controller.showQuickMenu()
        check(callbacks==["settings","refresh","quit"],"quit selected once (test callback only)")
        choice=nil;controller.showQuickMenu();check(callbacks==["settings","refresh","quit"],"next cancel does not replay selection")
        check(controller.item.menu==nil,"primary route restored after all menus")
        controller.invalidate();controller.invalidate();check(!controller.accessibleOptions(),"removed status item cannot reopen")
        print("STATUS_MENU_QA checks=\(checks) nativeMenus=\(presentations) callbacks=\(callbacks.joined(separator:",")) physicalTrackpad=false")
        if !failures.isEmpty { throw HarborError.invalid(failures.joined(separator:"; ")) }
    }
}
