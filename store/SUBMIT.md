# Submit FieldFolio to the App Store

Apple will not let an agent publish under your account. These are the only clicks required.

## Before you start

1. Open `Jobslip.xcodeproj` in Xcode.
2. Signing & Capabilities → select your Team for **Jobslip** and **JobslipWidget** targets (home-screen name is **FieldFolio**; Connect app name is **FieldFolioTracker**).
3. Confirm App Groups `group.com.fieldfolio.app` is enabled on both targets (or Xcode will create it under your team prefix).
4. Privacy/Support are live:
   - https://mtraverso.github.io/fieldfolio/privacy.html
   - https://mtraverso.github.io/fieldfolio/support.html
   Paste those into App Store Connect (and they match Settings in the app).

## App Store Connect

1. [Apps](https://appstoreconnect.apple.com/apps) → **+** → New App.
2. Platforms: iOS. **Name: FieldFolioTracker** (Connect listing — unique). Bundle ID: `com.fieldfolio.app`. In-app display name stays **FieldFolio**.
3. Create IAP products from `store/metadata.md` (monthly, yearly, lifetime).
4. Paste description, keywords, review notes from `store/metadata.md`.
5. Privacy Policy URL → your hosted `privacy.html`.
6. Support URL → your hosted `support.html`.
7. Privacy Nutrition Label → **Data Not Collected**.
8. Age rating → 4+. Category → Business.



## Archive & upload

1. In Xcode: scheme **Jobslip**, destination **Any iOS Device**.
2. Product → Archive.
3. Distribute App → App Store Connect → Upload.
4. In Connect, select the build, attach screenshots, submit for review.



## Local testing (no Connect needed)

1. Scheme Jobslip already references `Jobslip/Jobslip.storekit`.
2. Run on Simulator or device.
3. Complete onboarding → browse sample clients/jobs → open a job → Share estimate/invoice → Settings → Upgrade (StoreKit test purchases) or Debug unlock Pro.



## After approval

ASO is the distribution. No sales calls. Iterate on screenshots and subtitle based on search terms like `invoice`, `cleaner`, `detailer`.