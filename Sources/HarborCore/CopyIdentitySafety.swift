public enum CopyIdentitySafety {
    public static func isUnsafe(hasAttendees: Bool, organizerPresent: Bool,
                                hasRecurrenceRules: Bool, isDetached: Bool) -> Bool {
        hasAttendees || organizerPresent || hasRecurrenceRules || isDetached
    }
}
