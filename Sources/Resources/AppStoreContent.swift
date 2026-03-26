import SwiftUI

// MARK: - App Store Content

struct AppStoreContent {
    static let appName = "Kale"
    static let tagline = "Every day."
    static let category = "Health & Fitness"
    static let subcategory = "Medical Utilities"

    static let description = """
    Kale is the simplest daily vitamin tracker you'll find. Scan your supplement barcodes once, then every morning you get one gentle reminder to take what you need.

    **Why Kale?**
    • Takes 10 seconds a day — tap to confirm, that's it
    • Barcode scanning for instant setup
    • Beautiful monthly consistency view
    • Zero noise: no health advice, no nutrient databases, no fuss

    **How it works:**
    1. Scan your supplement barcodes once
    2. Receive one daily reminder at your chosen time
    3. Tap to confirm you've taken each vitamin
    4. Watch your consistency grow over time

    **Daily plan ($2.99/mo):**
    • Unlimited vitamins
    • Barcode scanning
    • Smart reminder notifications

    **Complete plan ($5.99/mo):**
    • Everything in Daily
    • Monthly consistency reports
    • Multi-user / family sharing
    • Health insights

    Start free — no credit card required. Take your vitamins. Every day.
    """

    static let keywords = [
        "vitamin tracker", "supplement tracker", "daily vitamins",
        "pill reminder", "health tracker", "barcode scanner",
        "vitamin app", "supplement app", "daily reminder",
        "health habits", "consistency", "wellness"
    ]

    static let keywordsString = keywords.joined(separator: ", ")

    static let releaseNotes = """
    • Initial release — scan, track, and never forget your vitamins again
    """
}

// MARK: - Real Vitamin Database for Suggestion

struct SampleVitamin {
    let name: String
    let dosage: String
    let barcode: String
    let emoji: String

    static let common: [SampleVitamin] = [
        SampleVitamin(name: "Vitamin D3", dosage: "2000 IU", barcode: "0634157000085", emoji: "💊"),
        SampleVitamin(name: "Vitamin D3 + K2", dosage: "5000 IU", barcode: "088395600714", emoji: "💊"),
        SampleVitamin(name: "Magnesium Glycinate", dosage: "400mg", barcode: "300059415145", emoji: "🫙"),
        SampleVitamin(name: "Omega-3 Fish Oil", dosage: "1000mg", barcode: "033984001128", emoji: "🐟"),
        SampleVitamin(name: "Vitamin B12", dosage: "1000mcg", barcode: "088395600653", emoji: "💊"),
        SampleVitamin(name: "Vitamin C", dosage: "1000mg", barcode: "898248001012", emoji: "🍊"),
        SampleVitamin(name: "Zinc Picolinate", dosage: "30mg", barcode: "749740700105", emoji: "💊"),
        SampleVitamin(name: "Ashwagandha", dosage: "600mg", barcode: "858259002144", emoji: "🌿"),
        SampleVitamin(name: "Probiotics", dosage: "50B CFU", barcode: "849081004989", emoji: "🧫"),
        SampleVitamin(name: "Collagen Peptides", dosage: "10g", barcode: "856676007005", emoji: "💊"),
        SampleVitamin(name: "Vitamin B-Complex", dosage: "1 capsule", barcode: "", emoji: "💊"),
        SampleVitamin(name: "Iron", dosage: "18mg", barcode: "", emoji: "🩸"),
        SampleVitamin(name: "Biotin", dosage: "10000mcg", barcode: "", emoji: "💊"),
        SampleVitamin(name: "Multivitamin", dosage: "1 tablet", barcode: "", emoji: "🫙"),
        SampleVitamin(name: "Elderberry", dosage: "500mg", barcode: "", emoji: "🫐"),
        SampleVitamin(name: "Turmeric", dosage: "500mg", barcode: "", emoji: "🌿"),
        SampleVitamin(name: "Vitamin E", dosage: "400 IU", barcode: "", emoji: "💊"),
        SampleVitamin(name: "Calcium + D3", dosage: "600mg", barcode: "", emoji: "🦴"),
        SampleVitamin(name: "Melatonin", dosage: "3mg", barcode: "", emoji: "😴"),
        SampleVitamin(name: "CoQ10", dosage: "100mg", barcode: "", emoji: "⚡"),
    ]
}

// MARK: - Realistic Reminder Copy

struct ReminderCopy {
    static let morningTitles = [
        "Good morning. 🌿",
        "Rise and shine. ☀️",
        "Time to start fresh.",
        "Good morning.",
    ]

    static let morningBodies = [
        "Today: {vitamins}",
        "Your daily vitamins are waiting: {vitamins}",
        "Don't forget: {vitamins}",
        "Ready for {vitamins}?",
    ]

    static let laterReminders = [
        "Still haven't taken your vitamins today. 💊",
        "Quick reminder: {vitamins}",
        "You almost forgot — vitamins time!",
    ]

    static func formatVitaminList(_ vitamins: [String]) -> String {
        if vitamins.isEmpty {
            return "your vitamins"
        } else if vitamins.count == 1 {
            return vitamins[0]
        } else if vitamins.count == 2 {
            return "\(vitamins[0]) + \(vitamins[1])"
        } else {
            let first = vitamins.prefix(vitamins.count - 1).joined(separator: ", ")
            return "\(first) + \(vitamins.last!)"
        }
    }

    static var sampleMorningBody: String {
        let body = morningBodies.randomElement() ?? "Time to take your vitamins!"
        let vitamins = SampleVitamin.common.prefix(3).map { $0.name }
        let formatted = formatVitaminList(Array(vitamins))
        return body.replacingOccurrences(of: "{vitamins}", with: formatted)
    }
}

// MARK: - App Icon Concept (SVG-ish description)

/*
 App Icon Concept:
 - Background: Fresh green gradient (#4ade80 → #22c55e)
 - Foreground: Stylized "K" letterform with a leaf integrated into the stem
   (like a vitamin pill capsule or a botanical leaf)
 - Shape: Standard iOS rounded rectangle with organic soft corners
 - Alternative concept: A simple botanical leaf with the "Kale" wordmark below

 Color Palette for Icon:
 - Primary green: #4ade80
 - Dark green: #16a34a
 - White for text/logo

 The icon should feel fresh, clean, and health-forward without being clinical.
 Think: a Muji supplement bottle meets Apple's design language.
 */
