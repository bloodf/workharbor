import Foundation
struct AgendaEvent:Identifiable {
    let id:String
    let title:String
    let calendarName:String
    let start:Date
    let end:Date
    let allDay:Bool
    let red:Double
    let green:Double
    let blue:Double
    static var demo:[AgendaEvent] {
        let day=Calendar.current.startOfDay(for:Date())
        return [AgendaEvent(id:"a",title:"Design review",calendarName:"Studio",start:day+15*3600,end:day+16*3600,allDay:false,red:0.25,green:0.5,blue:0.95),AgendaEvent(id:"b",title:"Coffee with Alex",calendarName:"Personal",start:day+17*3600,end:day+17.5*3600,allDay:false,red:0.25,green:0.7,blue:0.6),AgendaEvent(id:"c",title:"A little time outside",calendarName:"Personal",start:day+86400+9*3600,end:day+86400+10*3600,allDay:false,red:0.65,green:0.4,blue:0.9)]
    }
}
