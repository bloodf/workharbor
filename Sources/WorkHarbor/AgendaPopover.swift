import SwiftUI
import HarborCore
struct AgendaPopover:View {
    @ObservedObject var model:AppModel
    let openSettings:()->Void
    private var groups:[Date] { Array(Set(model.events.map { Calendar.current.startOfDay(for:max($0.start,Calendar.current.startOfDay(for:Date()))) })).sorted() }
    var body:some View {
        VStack(spacing:0) {
            HStack(spacing:12) {
                Image(systemName:"calendar.badge.clock").font(.system(size:24,weight:.medium)).foregroundStyle(.teal)
                VStack(alignment:.leading,spacing:3) { Text("WorkHarbor").font(.system(size:18,weight:.semibold,design:.rounded));Text(model.t("tagline")).font(.caption).foregroundStyle(.secondary) }
                Spacer()
                Button { model.refreshAgenda() } label:{Image(systemName:"arrow.clockwise")}.buttonStyle(.borderless).help(model.t("refresh"))
            }.padding(20)
            Divider().opacity(0.4)
            if !model.isSyntheticDemo && !model.calendar.fullAccess {
                emptyState(icon:"calendar.badge.plus",title:"connect",detail:"connectDetail")
                Button(model.t("settings"),action:openSettings).buttonStyle(.borderedProminent).tint(.teal).padding(.bottom,24)
            } else if let error=model.agendaError {
                VStack(spacing:12) { Image(systemName:"exclamationmark.triangle").font(.largeTitle).foregroundStyle(.orange);Text(model.t("attention")).font(.headline);Text(model.t(error)).font(.caption).foregroundStyle(.secondary).textSelection(.enabled);Button(model.t("settings"),action:openSettings) }.padding(24)
            } else if model.events.isEmpty { emptyState(icon:"sun.horizon",title:"empty",detail:"emptyDetail") }
            else {
                ScrollView {
                    VStack(alignment:.leading,spacing:18) {
                        if model.isSyntheticDemo { Text(model.t("demo")).font(.caption).foregroundStyle(.orange) }
                        ForEach(groups,id:\.self) { day in
                            VStack(alignment:.leading,spacing:8) {
                                Text(dayLabel(day)).font(.system(size:11,weight:.bold)).tracking(1).textCase(.uppercase).foregroundStyle(.secondary).padding(.leading,2)
                                ForEach(model.events.filter { Calendar.current.isDate(max($0.start,Calendar.current.startOfDay(for:Date())),inSameDayAs:day) }) { event in eventRow(event) }
                            }
                        }
                    }.padding(18)
                }.frame(maxHeight:460)
            }
            Divider().opacity(0.4)
            HStack(spacing:8) {
                Circle().fill(model.automaticSyncIssue == nil ? Color.teal : Color.orange).frame(width:6,height:6)
                Text(model.t(model.automaticSyncIssue == nil ? "local" : "attention")).font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Button(action:openSettings) { Image(systemName:"gearshape") }.help(model.t("settings"))
                Button { NSApplication.shared.terminate(nil) } label:{Image(systemName:"power")}.help(model.t("quit"))
            }.buttonStyle(.borderless).padding(.horizontal,20).padding(.vertical,14)
        }.frame(width:380).background(.regularMaterial).onAppear { model.refreshAgenda() }
        .environment(\.locale,L10n.locale(model.settings.language))
    }
    private func emptyState(icon:String,title:String,detail:String)->some View {
        VStack(spacing:12) { Image(systemName:icon).font(.system(size:38,weight:.light)).foregroundStyle(.teal);Text(model.t(title)).font(.title3.bold());Text(model.t(detail)).font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center) }.frame(maxWidth:.infinity).padding(30)
    }
    private func dayLabel(_ date:Date)->String {
        if Calendar.current.isDateInToday(date) { return model.t("today") }
        if Calendar.current.isDateInTomorrow(date) { return model.t("tomorrow") }
        return date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day().locale(L10n.locale(model.settings.language)))
    }
    private func eventRow(_ event:AgendaEvent)->some View {
        let color=Color(red:event.red,green:event.green,blue:event.blue)
        let ongoing = !event.allDay && event.start <= Date() && event.end > Date()
        return HStack(alignment:.top,spacing:12) {
            RoundedRectangle(cornerRadius:3).fill(color).frame(width:3)
            VStack(alignment:.leading,spacing:6) {
                HStack { Text(event.allDay ? model.t("allDay") : event.start.formatted(.dateTime.hour().minute().locale(L10n.locale(model.settings.language)))+" – "+event.end.formatted(.dateTime.hour().minute().locale(L10n.locale(model.settings.language)))).font(.system(size:11,weight:.medium)).foregroundStyle(.secondary)
                    Spacer();if ongoing { Text(model.t("now")).font(.system(size:9,weight:.bold)).foregroundStyle(.teal) }
                }
                Text(event.title).font(.system(size:14,weight:.semibold)).lineLimit(2)
                Text(event.calendarName).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
        }.padding(12).background(ongoing ? Color.teal.opacity(0.08) : Color.primary.opacity(0.035),in:RoundedRectangle(cornerRadius:12))
    }
}
