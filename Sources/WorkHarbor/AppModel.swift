import SwiftUI
import HarborCore
@MainActor
final class AppModel:ObservableObject {
    let isSyntheticDemo=CommandLine.arguments.contains("--synthetic-demo")
    @Published var settings=AppSettings()
    @Published var calendars:[CalendarInfo]=[]
    @Published var events:[AgendaEvent]=[]
    @Published var status=""
    @Published var error:String?
    @Published var agendaError:String?
    @Published var automaticSyncIssue:String?
    @Published var review:CalendarReview?
    @Published var storageReady=true
    @Published var lastRefresh:Date?
    private var automaticTask:Task<Void,Never>?
    private let persistence:SettingsStore
    let calendar:CalendarService
    init() {
        let directory=isSyntheticDemo ? FileManager.default.temporaryDirectory.appendingPathComponent("WorkHarbor-Demo-"+UUID().uuidString) : FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("WorkHarbor")
        persistence=SettingsStore(file:directory.appendingPathComponent("settings.json"))
        calendar=CalendarService(directory:directory)
        do { settings=try persistence.load() } catch { storageReady=false;self.error="Configuration could not be read. Original files were preserved." }
        if isSyntheticDemo { events=AgendaEvent.demo;lastRefresh=Date() }
    }
    func t(_ key:String)->String { L10n.text(key,language:settings.language) }
    @discardableResult func save()->Bool {
        guard storageReady else { return false }
        do { try persistence.save(settings);review=nil;status=t("saved");return true }
        catch { self.error=error.localizedDescription;return false }
    }
    func refreshAgenda() {
        guard !isSyntheticDemo else { return }
        guard calendar.fullAccess else { events=[];return }
        do { calendars=try calendar.calendars();events=calendar.upcoming(calendarIDs:settings.agendaCalendarIDs,showAll:settings.showAllCalendars);lastRefresh=Date();agendaError=nil }
        catch { events=[];self.agendaError=error.localizedDescription }
    }
    func requestCalendar() async {
        guard !isSyntheticDemo else { error = "Demonstração: acesso a calendários reais bloqueado."; return }
        do { try await calendar.requestAccess(); try reloadCalendars(); refreshAgenda() }
        catch { self.error = error.localizedDescription }
    }
    func reloadCalendars() throws {
        guard !isSyntheticDemo else { throw HarborError.invalid("Demonstração: use a prévia sintética, sem contas reais.") }
        calendars = try calendar.calendars(); review = nil; status = "Calendários locais carregados. Escolha as rotas explicitamente." }
    func preview(_ rule: MirrorRule) {
        guard !isSyntheticDemo else { demo(); return }
        do {
            try Reconciler.validate(settings.rules, calendars: calendar.calendars())
            calendar.configureRoutes(settings.rules)
            review = try calendar.preview(rule: rule, installation: settings.installationID)
            status = "Prévia local pronta. Nenhuma escrita efetuada."
        } catch { review = nil; self.error = error.localizedDescription }
    }
    func previewCleanup(_ rule:MirrorRule) {
        guard !isSyntheticDemo else { error="Demonstração: não há eventos reais para limpar.";return }
        do {
            try Reconciler.validate(settings.rules,calendars:calendar.calendars());calendar.configureRoutes(settings.rules)
            review=try calendar.previewCleanup(rule:rule,installation:settings.installationID)
            status="Prévia de duplicatas identificadas. Nenhuma exclusão selecionada. Versão de criação legada é desconhecida."
        } catch { review=nil;self.error=error.localizedDescription }
    }
    func demo() { do { review = try CalendarService.demo() } catch { self.error = error.localizedDescription } }
    func apply(includeDeletions: Bool, cleanupIDs:Set<String> = []) {
        guard !isSyntheticDemo else { error = "Demonstração: gravação bloqueada."; return }
        guard var review, storageReady, settings.rules.contains(review.rule), review.installation == settings.installationID else { self.error = "Configuração mudou. Gere outra prévia."; return }
        do {
            try Reconciler.validate(settings.rules, calendars: calendar.calendars())
            // Persist the identity before creating any copy, including a first-run review.
            try persistence.save(settings)
            calendar.configureRoutes(settings.rules)
            if review.cleanupOnly { review.changes=review.changes.filter { $0.existingID.map(cleanupIDs.contains) == true } }
            let count = try calendar.apply(review, confirmed: true, includeDeletions: includeDeletions)
            self.review = nil
            status = t("syncCount")+": "+String(count)
        } catch { self.review = nil; self.error = error.localizedDescription }
    }
    func invalidateReview() {
        if review?.demo == false { review = nil }
        status = "O Mac despertou ou o calendário mudou. Rotas automáticas autorizadas serão verificadas."
        refreshAgenda(); scheduleAutomaticSync()
    }
    func setAutomatic(_ enabled: Bool, for rule: MirrorRule) {
        guard !isSyntheticDemo else { error = "Demonstração: ativação automática bloqueada."; return }
        guard storageReady, let index = settings.rules.firstIndex(where: { $0.id == rule.id }) else { return }
        do {
            if enabled {
                let fresh = try calendar.calendars()
                try Reconciler.validate(settings.rules, calendars: fresh)
                for id in [rule.sourceID, rule.destinationID] {
                    guard let shown = calendars.first(where: { $0.id == id }),
                          let actual = fresh.first(where: { $0.id == id }), shown == actual else {
                        throw HarborError.invalid("Atualize a lista de calendários antes de autorizar esta rota; origem e destino precisam estar identificados.")
                    }
                }
            }
            settings.rules[index].automaticConsent = enabled ? AutomaticRouteConsent(rule: settings.rules[index]) : nil
            // Pausing must not depend on unrelated webmail or AI URL validation.
            try persistence.save(settings)
            review = nil
            if enabled { scheduleAutomaticSync() }
            else { status = "Automático desativado e salvo para esta rota. Cópias existentes preservadas." }
        } catch {
            automaticTask?.cancel(); automaticTask = nil
            settings.rules[index].automaticConsent = nil
            self.error = error.localizedDescription
            status = "Mudança NÃO confirmada no disco. Automático suspenso nesta sessão; se houve falha ao pausar, feche o app e resolva o armazenamento antes de reabri-lo."
        }
    }
    func scheduleAutomaticSync() {
        // Coalesce notifications without postponing forever when changes are frequent.
        guard automaticTask == nil else { return }
        guard !isSyntheticDemo, storageReady, calendar.fullAccess, settings.rules.contains(where: AutomaticSyncPolicy.isAuthorized) else { return }
        automaticTask = Task { @MainActor [weak self] in
            do { try await Task.sleep(for: .seconds(2)) } catch { return }
            guard !Task.isCancelled, let self else { return }
            self.automaticTask = nil
            self.runAutomaticSync()
        }
    }
    private func runAutomaticSync() {
        guard storageReady, calendar.fullAccess else { return }
        do {
            try Reconciler.validate(settings.rules, calendars: calendar.calendars())
            try persistence.save(settings)
            var changed = 0
            var unresolved = 0
            calendar.configureRoutes(settings.rules)
            var issues: [String] = []
            var blockedCalendars: Set<String> = []
            for rule in try RouteGraph.ordered(settings.rules) where AutomaticSyncPolicy.isAuthorized(rule) {
                if blockedCalendars.contains(rule.sourceID) { blockedCalendars.insert(rule.destinationID); continue }
                do {
                    let candidate = try calendar.preview(rule: rule, installation: settings.installationID)
                    unresolved += candidate.unresolvedCopies.count + candidate.snapshot.unlocatedTrackedIDs.count
                    changed += try calendar.apply(candidate, confirmed: true, includeDeletions: false, automatic: true)
                } catch { issues.append(error.localizedDescription); blockedCalendars.insert(rule.destinationID) }
            }
            automaticSyncIssue = issues.isEmpty ? nil : Array(Set(issues)).sorted().joined(separator: "\n")
            status = t("syncCount")+": "+String(changed)+" · "+t("pendingCount")+": "+String(unresolved)
        } catch {
            automaticSyncIssue = error.localizedDescription
            status = "Calendários: há uma pendência. Consulte o painel; nenhuma duplicata será criada para contornar o bloqueio."
        }
    }
}
