# FieldFolio — App Store metadata

## Identity
- **App Store Connect name:** FieldFolioTracker (registration / listing name — must be unique)
- **In-app / home screen name:** FieldFolio
- **Subtitle:** Job book · photos · invoices
- **Bundle ID:** `com.fieldfolio.app`
- **SKU:** `fieldfolio-ios-001`
- **Primary category:** Business
- **Secondary category:** Productivity
- **Age rating:** 4+
- **Price:** Free (with IAP)

## Keywords (100 char max)
```
invoice,estimate,cleaner,detailer,handyman,job,photo,pdf,solo,venmo
```

## Promotional text (170 char)
```
Show up. Photograph the job. Invoice from the driveway. FieldFolio is the simple job book for solo cleaners, detailers, and handymen — no account, no bloat.
```

## Description
```
FieldFolio is the job book for people who show up and get paid.

Built for solo cleaners, mobile detailers, handymen, lawn care, and anyone who books by text and gets paid by Venmo or cash.

WHAT YOU CAN DO
• See today’s jobs and unpaid invoices at a glance
• Keep clients, rates, and history in one place
• Capture before and after photos on site
• Send estimate PDFs, then convert them to jobs
• Share numbered invoice PDFs via Messages or Mail
• Mark jobs paid when the money lands
• Optional Face ID lock for privacy

WHY FIELDFOLIO
Jobber-class software is overkill when you already have the clients. FieldFolio replaces Camera Roll chaos and notebook guesses with a clean job slip — offline, private, and ready in two minutes.

FREE
• 3 clients
• 8 jobs
• Watermarked PDFs

FIELDFOLIO PRO
• Unlimited clients and jobs
• Clean PDFs without a watermark
• Home Screen widget
• Job reminders

$4.99/month · $29.99/year (7-day trial) · $59.99 lifetime

Privacy first: no account, no FieldFolio cloud, no ads, no tracking. Your data stays on your device.

Invoices are records, not tax or legal advice.
```

## What’s New (1.0.0)
```
First release. Track jobs, capture before/after photos, send estimates and invoices, and mark work paid.
```

## In-App Purchases (create in App Store Connect)
| Product ID | Type | Price |
| --- | --- | --- |
| `com.fieldfolio.app.pro.monthly` | Auto-renewable | $4.99 |
| `com.fieldfolio.app.pro.yearly` | Auto-renewable | $29.99 |
| `com.fieldfolio.app.pro.lifetime` | Non-consumable | $59.99 |

Subscription group name: **FieldFolio Pro**  
Introductory offer: 7-day free trial on monthly and yearly.

EULA: Apple Standard EULA  
https://www.apple.com/legal/internet-services/itunes/dev/stdeula/

## Review notes
```
FieldFolio requires no account. Sample data loads on first launch so you can open Today → a job → share an estimate or invoice PDF.

Camera permission is used only to attach before/after photos to a job; photos stay on device.

In-app purchases unlock Pro limits and remove the PDF watermark. Use the StoreKit configuration Jobslip.storekit for local testing, or sandbox Apple ID for TestFlight.

No user-generated public content, no messaging network, no location tracking beyond optional address text the user types.
```

## Privacy Nutrition Label
- **Data Not Collected**

## Screenshots (captured)

Upload the App Store Connect-compatible files from
`store/screenshots/app-store/`:

| # | Screen | App Store (1284×2778) |
| --- | --- | --- |
| 1 | Today dashboard | `app-store/01-today.png` |
| 2 | Job detail + photos | `app-store/02-job-detail.png` |
| 3 | Invoice PDF preview | `app-store/03-invoice-pdf.png` |
| 4 | Clients list | `app-store/04-clients.png` |
| 5 | Pro paywall | `app-store/05-paywall.png` |

Source captures remain in `6.1/` (1179×2556) and `6.7/` (1320×2868).
Release build. Branding: FieldFolio.

## URLs (host docs/ before submit)
- Privacy: https://mtraverso.github.io/fieldfolio/privacy.html
- Support: https://mtraverso.github.io/fieldfolio/support.html
- Marketing: optional; can reuse support URL
- In-app Settings uses the same Privacy/Support URLs.
