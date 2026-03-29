# Kale R12 — Grocery Delivery Integration & Household Planning

## Overview
R12 adds grocery delivery integration for seamless purchasing, social features for sharing meals with family and friends, and multi-user household meal planning.

## Features

### 1. Grocery Delivery Integration
- **Direct ordering**: Send grocery list to Instacart, Amazon Fresh, or local stores
- **Price comparison**: Show prices from multiple stores for the same items
- **Store preferences**: Save preferred stores and delivery addresses
- **Order tracking**: Monitor delivery status from within the app
- **Deal awareness**: Highlight items on sale or with coupons
- **Substitution preferences**: Set rules for item replacements (generic ok, no subs, etc.)

### 2. Meal Sharing
- **Share meal plans**: Export weekly plan as PDF, image, or link
- **Social recipes**: Share individual recipes with preparation tips
- **Meal rating**: Rate meals after cooking (1-5 stars + optional notes)
- **Recipe collections**: Create themed collections (Weeknight Dinners, Healthy Lunches, etc.)
- **Public recipe library**: Browse and import recipes shared by other Kale users
- **Export to Instagram/Stories**: Beautiful meal prep cards for social sharing

### 3. Household Meal Planning
- **Family accounts**: Multiple users under one roof share a meal plan
- **Individual preferences**: Each family member has dietary restrictions and favorites
- **Serving scaling**: Automatically scale recipes for 2, 4, 6+ people
- **Delegate meals**: Assign "You cook Monday, I'll cook Tuesday"
- **Grocery split**: Track who bought what for shared households
- **Kids mode**: Simplified UI with avatar selection and gamification

## Technical Approach
- OAuth integration with grocery delivery APIs
- Cloud sync via Supabase or Firebase for household data
- PDF generation for meal plan exports
- ShareExtension for social sharing on iOS/macOS
- Family sharing via iCloud / Apple Family

## UI/UX Changes
- New "Grocery" tab becomes "Order Groceries" with store selection
- Share button on meal plans and recipes
- Family avatars in Settings with preference management
- New "Household" dashboard showing who's cooking what
- Grocery delivery status banner when order is active

## Success Metrics
- 50% of users connect at least one grocery delivery account
- Average household has 2+ members sharing meal plans
- Shared recipes receive engagement within 7 days of posting
