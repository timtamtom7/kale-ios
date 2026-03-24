import Foundation

struct SupplementInteraction: Identifiable, Codable {
    var id: String { trigger }
    let trigger: String       // vitamin name that triggers the hint
    let hint: String          // the tip to show
    let priority: Int         // lower = more important

    static let allInteractions: [SupplementInteraction] = [
        SupplementInteraction(trigger: "Vitamin D", hint: "Tip: Taking with Magnesium improves absorption.", priority: 1),
        SupplementInteraction(trigger: "Vitamin D3", hint: "Tip: Taking with Magnesium improves absorption.", priority: 1),
        SupplementInteraction(trigger: "Iron", hint: "Tip: Vitamin C helps iron absorption. Take with orange juice!", priority: 1),
        SupplementInteraction(trigger: "Zinc", hint: "Tip: Zinc is best absorbed on an empty stomach.", priority: 2),
        SupplementInteraction(trigger: "Magnesium", hint: "Tip: Magnesium is best taken in the evening — it may help with sleep.", priority: 2),
        SupplementInteraction(trigger: "Calcium", hint: "Tip: Calcium competes with iron for absorption. Space them 2+ hours apart.", priority: 1),
        SupplementInteraction(trigger: "Vitamin C", hint: "Tip: Vitamin C enhances iron absorption. Great combo!", priority: 3),
        SupplementInteraction(trigger: "Vitamin B12", hint: "Tip: B12 is best absorbed sublingually. Consider that form if you're deficient.", priority: 2),
        SupplementInteraction(trigger: "Omega-3", hint: "Tip: Taking fish oil with a fatty meal boosts absorption.", priority: 3),
        SupplementInteraction(trigger: "Fish Oil", hint: "Tip: Taking fish oil with a fatty meal boosts absorption.", priority: 3),
        SupplementInteraction(trigger: "Vitamin E", hint: "Tip: Vitamin E works better with a little fat in your meal.", priority: 3),
        SupplementInteraction(trigger: "Vitamin K", hint: "Tip: Vitamin K2 pairs well with Vitamin D for bone health.", priority: 2),
        SupplementInteraction(trigger: "Probiotics", hint: "Tip: Take probiotics on an empty stomach for better survival.", priority: 2),
        SupplementInteraction(trigger: "Collagen", hint: "Tip: Collagen peptides dissolve easily in hot or cold drinks.", priority: 3),
        SupplementInteraction(trigger: "Ashwagandha", hint: "Tip: Best taken with meals. Avoid taking before bed if it makes you wired.", priority: 2),
        SupplementInteraction(trigger: "Vitamin B6", hint: "Tip: Taking B6 too late in the day may disrupt sleep.", priority: 2),
        SupplementInteraction(trigger: "Melatonin", hint: "Tip: Take 30–60 minutes before bed for best results.", priority: 1),
    ]
}
