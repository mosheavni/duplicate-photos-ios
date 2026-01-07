# Epic 7: Deployment 🚀

**Status**: ⏳ Pending
**Phase**: 4 - Testing & Release
**Duration**: 2-3 days (+ review time)

---

## Overview
Release the app to TestFlight for beta testing, then eventually to the App Store.

---

## Tasks

### Task 7.1: TestFlight Beta

**Status**: ⏳ Pending

#### Prerequisites:
- [ ] App Store Connect account configured
- [ ] Paid Apple Developer Program membership ($99/year)
  - OR free tier with limited features
- [ ] App identifier registered
- [ ] Provisioning profiles configured

#### Subtasks:
- [ ] Create App Store Connect entry
  - Bundle ID: `com.[yourname].DuplicatePhotos`
  - App name: "Duplicate Photos Cleaner" (or similar)
  - Primary language: English
- [ ] Configure app metadata (TestFlight only)
  - What to Test notes
  - Beta App Description
- [ ] Archive and upload build
  - Product → Archive in Xcode
  - Upload to App Store Connect
  - Wait for processing (~10-30 mins)
- [ ] Add internal testers (up to 100)
  - Add email addresses
  - Automatic distribution
- [ ] Invite external testers (optional)
  - Create testing group
  - Submit for Beta App Review
- [ ] Gather feedback
  - Use TestFlight feedback
  - Track crash reports
  - Monitor analytics
- [ ] Fix critical bugs
  - Prioritize crashes
  - Fix major UX issues
  - Upload new builds as needed

---

### Task 7.2: App Store Release (Future)

**Status**: ⏳ Pending (Post-MVP)

#### Requirements:
- [ ] App Store listing
  - App name (max 30 chars)
  - Subtitle (max 30 chars)
  - Description (max 4000 chars)
  - Keywords (max 100 chars)
  - Support URL
  - Marketing URL (optional)
- [ ] Privacy policy
  - Explain photo library access
  - Data collection (none if on-device only)
  - User rights
  - Host somewhere (GitHub Pages, etc.)
- [ ] Screenshots
  - 6.5" display (iPhone 15 Pro Max) - required
  - 5.5" display (older devices) - required
  - 12.9" iPad Pro (if supporting iPad)
  - Use in-app actual screens
- [ ] App Preview video (optional)
  - 15-30 seconds
  - Show key features
- [ ] App icon (1024x1024)
- [ ] Age rating questionnaire
- [ ] App Review Information
  - Contact info
  - Demo account (if login required - N/A)
  - Notes for reviewer

#### Monetization Decision:
Choose one:
- [ ] Free (with optional tip jar)
- [ ] Paid upfront ($0.99 - $4.99)
- [ ] Free with IAP (unlock features)
- [ ] Subscription (monthly/yearly)

#### Submission:
- [ ] Submit for App Review
- [ ] Respond to reviewer questions/rejections
- [ ] Release when approved

**Review Timeline**: Typically 1-3 days, can be up to 2 weeks

---

## Definition of Done

### For TestFlight:
- [ ] Build uploaded successfully
- [ ] At least 5 beta testers invited
- [ ] No critical crashes
- [ ] Positive feedback from testers

### For App Store (Future):
- [ ] App approved by Apple
- [ ] Live on App Store
- [ ] No crashes reported
- [ ] Positive initial reviews

---

## Dependencies

**Blocked By**:
- Epic 6 (Testing & Polish) - must be complete and bug-free

---

## Post-Launch

After App Store release:
- [ ] Monitor crash reports (Xcode Organizer)
- [ ] Respond to user reviews
- [ ] Plan v1.1 features (from backlog)
- [ ] Consider analytics (optional)
  - Firebase Analytics
  - TelemetryDeck (privacy-focused)
- [ ] Marketing (optional)
  - Product Hunt launch
  - Twitter/social media
  - Tech blogs

---

## Common Rejection Reasons to Avoid

- Crashes on launch
- Missing privacy policy
- Photo library usage not clearly explained
- UI not working properly
- Performance issues
- Not providing core functionality
- Metadata mentions competitors

Make sure to test thoroughly before submission!
