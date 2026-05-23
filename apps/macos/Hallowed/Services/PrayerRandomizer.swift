import Foundation

class PrayerRandomizer {

    func pickTopic(from topics: [PrayerTopic]) -> PrayerTopic? {
        topics.randomElement()
    }

    func pickPrayer(from prayers: [Prayer]) -> Prayer? {
        prayers.randomElement()
    }

    /// Picks a random topic from a random theme using all loaded content.
    /// Returns nil if themes are empty or the chosen theme has no topics.
    func randomSession(
        themes: [PrayerTheme],
        topicsByTheme: [UUID: [PrayerTopic]]
    ) -> (PrayerTheme, PrayerTopic)? {
        guard let theme = themes.randomElement(),
              let topics = topicsByTheme[theme.id],
              let topic = topics.randomElement() else { return nil }
        return (theme, topic)
    }
}
