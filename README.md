# FieldFolio

iPhone job book for solo cleaners, detailers, and handymen.

Show up → photograph the work → send an estimate or invoice PDF → mark it paid.

- Native SwiftUI + SwiftData (iOS 17+)
- Offline, no account, no FieldFolio cloud
- StoreKit 2 Pro unlock (`Jobslip/Jobslip.storekit` for local testing)
- Home Screen widget (Pro)

## Open in Xcode

```bash
open Jobslip.xcodeproj
```

Run the **Jobslip** scheme on a Simulator (app displays as **FieldFolio**). Sample clients and jobs load on first launch.

Regenerate the project after changing `project.yml`:

```bash
xcodegen generate
```

## Publish

See [store/SUBMIT.md](store/SUBMIT.md) and [store/metadata.md](store/metadata.md).  
Privacy/support pages live in [docs/](docs/).

## Bundle IDs

| Target | ID |
| --- | --- |
| App | `com.fieldfolio.app` |
| Widget | `com.fieldfolio.app.widget` |
| App Group | `group.com.fieldfolio.app` |
