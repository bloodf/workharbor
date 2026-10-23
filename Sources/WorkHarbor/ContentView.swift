import SwiftUI
import HarborCore
struct ContentView:View {
    @State private var confirmReconnect=false
    @ObservedObject var model:AppModel
    @State private var tab="general"
    @State private var selectedCleanupIDs:Set<String>=[]
    @State private var includeDeletions=false
    @State private var confirmApply=false
    @State private var automaticRule:MirrorRule?
    @State private var removingRule:MirrorRule?
    var body:some View {
        HStack(spacing:0) {
            VStack(alignment:.leading,spacing:8) {
                Image(systemName:"calendar.badge.clock").font(.system(size:32)).foregroundStyle(.teal).padding(.bottom,8)
                Text("WorkHarbor").font(.title3.bold())
                Text(model.t("tagline")).font(.caption).foregroundStyle(.secondary).padding(.bottom,24)
                nav("general","slider.horizontal.3");nav("agenda","calendar");nav("sync","arrow.triangle.2.circlepath")
                Spacer()
                Text("0.2 · "+model.t("edition")).font(.caption2).foregroundStyle(.tertiary)
            }.padding(20).frame(width:190).frame(maxHeight:.infinity).background(.thinMaterial)
            Divider()
            ScrollView {
                VStack(alignment:.leading,spacing:22) {
                    Text(model.t(tab)).font(.system(size:27,weight:.bold,design:.rounded))
                    if tab == "general" { general }
                    else if tab == "agenda" { agenda }
                    else { sync }
                    if let issue=model.automaticSyncIssue { Label(model.t("attention"),systemImage:"exclamationmark.triangle.fill").foregroundStyle(.orange);Text(issue.split(separator:"\n").map{model.t(String($0))}.joined(separator:"\n")).font(.caption).textSelection(.enabled) }
                    if !model.status.isEmpty { Text(model.t(model.status)).font(.caption).foregroundStyle(.secondary).textSelection(.enabled) }
                }.padding(28).frame(maxWidth:.infinity,alignment:.leading)
            }
        }.tint(.teal).environment(\.locale,L10n.locale(model.settings.language))
        .onChange(of:model.review?.id) { _,_ in selectedCleanupIDs=[];includeDeletions=false }
        .alert(model.t("attention"),isPresented:Binding(get:{model.error != nil},set:{if !$0 {model.error=nil}})) { Button("OK") { model.error=nil } } message:{Text(model.t(model.error ?? ""))}
        .confirmationDialog(model.t("confirm"),isPresented:$confirmApply,titleVisibility:.visible) {
            Button(model.t("confirm"),role:.destructive) { model.apply(includeDeletions:model.review?.cleanupOnly == true || includeDeletions,cleanupIDs:selectedCleanupIDs);model.refreshAgenda() }
            Button(model.t("cancel"),role:.cancel) {}
        } message:{Text(model.t("confirmInfo"))}
        .confirmationDialog(model.t("removeRule"),isPresented:Binding(get:{removingRule != nil},set:{if !$0 {removingRule=nil}}),titleVisibility:.visible) {
            Button(model.t("removeRule"),role:.destructive) {
                if let rule=removingRule { model.settings.rules.removeAll{$0.id==rule.id};model.save() };removingRule=nil
            }
            Button(model.t("cancel"),role:.cancel) {removingRule=nil}
        } message:{Text(model.t("removeRuleInfo"))}
        .confirmationDialog(model.t("automatic"),isPresented:Binding(get:{automaticRule != nil},set:{if !$0 {automaticRule=nil}}),titleVisibility:.visible) {
            Button(model.t("automatic")) { if let rule=automaticRule { model.setAutomatic(true,for:rule) };automaticRule=nil }
            Button(model.t("cancel"),role:.cancel) { automaticRule=nil }
        } message:{Text(model.t("autoInfo"))}
    }
    private func nav(_ key:String,_ icon:String)->some View {
        Button { tab=key } label:{Label(model.t(key),systemImage:icon).frame(maxWidth:.infinity,alignment:.leading).padding(10).background(tab == key ? Color.teal.opacity(0.13) : Color.clear,in:RoundedRectangle(cornerRadius:9))}.buttonStyle(.plain)
    }
    private var general:some View {
        VStack(alignment:.leading,spacing:20) {
            Text(model.t("privacy")).foregroundStyle(.secondary)
            Picker(model.t("language"),selection:$model.settings.language) { Text(model.t("system")).tag("system");Text("English").tag("en");Text("Português (Brasil)").tag("pt-BR");Text("Español").tag("es") }.onChange(of:model.settings.language) { _,_ in model.save() }
            Divider()
            Text(model.t("connectDetail"))
            Button(model.t(model.calendar.fullAccess ? "refresh" : "access")) { Task { if model.calendar.fullAccess {model.refreshAgenda()} else {await model.requestCalendar()} } }.buttonStyle(.borderedProminent)
            Text(model.t("range")).font(.caption).foregroundStyle(.secondary)
        }
    }
    private var agenda:some View {
        VStack(alignment:.leading,spacing:14) {
            Text(model.t("agendaDetail")).font(.callout).foregroundStyle(.secondary)
            if model.calendars.isEmpty { Text(model.t("loading")) }
            Toggle(model.t("allCalendars"),isOn:$model.settings.showAllCalendars).onChange(of:model.settings.showAllCalendars) { _,_ in if model.save() {model.refreshAgenda()} }
            ForEach(model.calendars) { calendar in
                Toggle(calendar.name,isOn:Binding(get:{model.settings.agendaCalendarIDs.contains(calendar.id)},set:{enabled in
                    if enabled {model.settings.agendaCalendarIDs.append(calendar.id)} else {model.settings.agendaCalendarIDs.removeAll{$0==calendar.id}}
                    if model.save() {model.refreshAgenda()}
                })).disabled(model.settings.showAllCalendars)
            }
        }
    }
    private var sync:some View {
        VStack(alignment:.leading,spacing:18) {
            Text(model.t("autoInfo")).font(.caption).foregroundStyle(.secondary)
            ForEach($model.settings.rules) { $rule in
                VStack(alignment:.leading,spacing:12) {
                    HStack {Image(systemName:"arrow.triangle.2.circlepath").foregroundStyle(.teal);Text(model.t("route")).font(.headline);Spacer();Text(model.t(AutomaticSyncPolicy.isAuthorized(rule) ? "automatic" : "reviewOnly")).font(.caption).foregroundStyle(.secondary)}
                    Picker(model.t("source"),selection:$rule.sourceID) {Text(model.t("choose")).tag("");ForEach(model.calendars) {Text($0.name).tag($0.id)}}
                    Picker(model.t("destination"),selection:$rule.destinationID) {Text(model.t("choose")).tag("");ForEach(model.calendars.filter(\.writable)) {Text($0.name).tag($0.id)}}
                    Picker(model.t("mode"),selection:$rule.mode) {Text(model.t("busy")).tag(MirrorMode.busy);Text(model.t("details")).tag(MirrorMode.details)}.pickerStyle(.segmented)
                    if rule.mode == .busy { HStack {Stepper("\(model.t("before")): \(rule.beforeMinutes)",value:$rule.beforeMinutes,in:0...240,step:5);Stepper("\(model.t("after")): \(rule.afterMinutes)",value:$rule.afterMinutes,in:0...240,step:5)}.font(.caption) }
                    Toggle(model.t("automatic"),isOn:Binding(get:{AutomaticSyncPolicy.isAuthorized(rule)},set:{enabled in if enabled {automaticRule=rule} else {model.setAutomatic(false,for:rule)}}))
                    HStack {Button(model.t("review")) {model.preview(rule)};Button(model.t("cleanup")) {model.previewCleanup(rule)};Button(model.t("inspectCopies")) {model.inspectCopies(rule)};Spacer();Button {removingRule=rule} label:{Image(systemName:"trash")}.help(model.t("removeRule"))}.controlSize(.small)
                }.padding(16).background(Color.primary.opacity(0.035),in:RoundedRectangle(cornerRadius:14))
            }
            HStack {Button {model.settings.rules.append(MirrorRule())} label:{Label(model.t("add"),systemImage:"plus")};Spacer();Button(model.t("save")) {model.save()}.buttonStyle(.borderedProminent).disabled(!model.storageReady)}
            if let inspection=model.copyInspection { inspectionView(inspection) }
            if let review=model.review { reviewView(review) }
        }
    }
    private func inspectionView(_ report:CopyInspectionReport)->some View {
        VStack(alignment:.leading,spacing:10) {
            Divider();Text(model.t("inspectCopies")).font(.title3.bold())
            Text(model.calendars.first(where:{$0.id == report.rule.destinationID})?.name ?? model.t("route")).font(.caption)
            Text(model.t("inspectionReadOnly")).font(.caption).foregroundStyle(.secondary)
            Text(report.interval.start.formatted(date:.abbreviated,time:.omitted)+" – "+report.interval.end.formatted(date:.abbreviated,time:.omitted)).font(.caption)
            ForEach([CopyIdentityState.located,.recoverable,.missing,.mismatch,.ambiguous,.unsafe],id:\.rawValue) {state in
                HStack {Text(model.t("identity_"+state.rawValue));Spacer();Text(String(report.findings.filter {$0.state == state}.count)).monospacedDigit()}.font(.callout)
            }
            Text(model.t("inspectionUnknown")).font(.caption).foregroundStyle(.orange)
            Button(model.t("reconnectCopies")+" ("+String(report.repairable.count)+")") {confirmReconnect=true}
                .disabled(report.repairable.isEmpty || !model.storageReady)
                .confirmationDialog(model.t("reconnectQuestion"),isPresented:$confirmReconnect,titleVisibility:.visible) {
                    Button(model.t("confirm")) {model.reconnectCopies()}
                    Button(model.t("cancel"),role:.cancel) {}
                } message: {Text(model.t("reconnectDetail"))}
        }.padding(12).background(Color.primary.opacity(0.03),in:RoundedRectangle(cornerRadius:10))
    }
    private func reviewView(_ review:CalendarReview)->some View {
        VStack(alignment:.leading,spacing:12) {
            Divider();Text(model.t("preview")).font(.title3.bold())
            Text(model.calendars.first(where:{$0.id==review.rule.destinationID})?.name ?? review.rule.destinationID).font(.caption).foregroundStyle(.secondary)
            if review.cleanupOnly {Text(model.t("cleanupInfo")).font(.caption).foregroundStyle(.orange)}
            if !review.snapshot.unlocatedTrackedIDs.isEmpty {
                Text(model.t("missingIdentityBlock")+" ("+String(review.snapshot.unlocatedTrackedIDs.count)+")")
                    .font(.callout).foregroundStyle(.orange)
            }
            if review.changes.isEmpty {Text(model.t("noChanges"))}
            ForEach(review.changes) { change in
                VStack(alignment:.leading,spacing:6) {
                    if review.cleanupOnly,let id=change.existingID {Toggle(model.t("delete"),isOn:Binding(get:{selectedCleanupIDs.contains(id)},set:{if $0 {selectedCleanupIDs.insert(id)} else {selectedCleanupIDs.remove(id)}}))}
                    Text(model.t(change.kind == .create ? "create" : change.kind == .update ? "update" : "delete")).font(.caption.bold()).foregroundStyle(change.kind == .delete ? .orange : .teal)
                    if let value=change.before {eventLine(value,label:model.t("previous"))}
                    if let value=change.after {eventLine(value,label:model.t("updated"))}
                }.padding(12).frame(maxWidth:.infinity,alignment:.leading).background(Color.primary.opacity(0.035),in:RoundedRectangle(cornerRadius:10))
            }
            if !review.cleanupOnly {Toggle(model.t("includeDelete"),isOn:$includeDeletions)}
            Button(model.t("confirm")) {confirmApply=true}.disabled(review.demo || !review.snapshot.unlocatedTrackedIDs.isEmpty || !model.storageReady || review.changes.isEmpty || (review.cleanupOnly && selectedCleanupIDs.isEmpty)).buttonStyle(.borderedProminent)
        }
    }
    private func eventLine(_ value:EventValue,label:String)->some View {
        VStack(alignment:.leading,spacing:3) {Text(label+": "+value.title).font(.callout);Text(value.start.formatted(date:.abbreviated,time:.shortened)+" – "+value.end.formatted(date:.abbreviated,time:.shortened)).font(.caption).foregroundStyle(.secondary)}
    }
}
