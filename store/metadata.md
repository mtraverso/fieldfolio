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
• Add multiple line items with tax and discount
• Put Venmo / Zelle / Cash App instructions on invoices
• Send estimate PDFs, then convert them to jobs
• Share numbered invoice PDFs via Messages or Mail
• Mark jobs paid when the money lands
• Export a ZIP backup of your data and photos
• Use the app in English or Spanish
• Optional Face ID lock for privacy

WHY FIELDFOLIO
Jobber-class software is overkill when you already have the clients. FieldFolio replaces Camera Roll chaos and notebook guesses with a clean job slip — offline, private, and ready in two minutes.

FREE
• 3 clients
• 8 jobs
• Watermarked PDFs
• Sample data does not count toward Free limits

FIELDFOLIO PRO
• Unlimited clients and jobs
• Clean PDFs without a watermark
• Home Screen widget
• Job reminders

$4.99/month · $29.99/year (7-day trial) · $59.99 lifetime

Privacy first: no account, no FieldFolio cloud, no ads, no tracking. Your data stays on your device.

Invoices are records, not tax or legal advice.

Terms of Use: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
```

## What’s New (1.0.0)
```
First release. Track jobs, capture before/after photos, send estimates and invoices, and mark work paid.
```

## Spanish (es-MX) listing

### Name
```
FieldFolioTracker
```

### Subtitle
```
Trabajos · fotos · facturas
```

### Keywords (100 char max)
```
factura,presupuesto,limpieza,detallado,trabajos,fotos,pdf,venmo,handyman,limpieza
```

### Promotional text
```
Llega. Fotografía el trabajo. Factura desde la entrada. FieldFolio es la agenda simple para limpiezas, detallado y oficios — sin cuenta ni relleno.
```

### Description
```
FieldFolio es la agenda de trabajos para quienes llegan y cobran.

Hecha para limpiezas, detallado móvil, oficios, jardinería y cualquiera que agenda por mensaje y cobra por Venmo o efectivo.

QUÉ PUEDES HACER
• Ver los trabajos de hoy y las facturas sin pagar de un vistazo
• Guardar clientes, tarifas e historial en un solo lugar
• Tomar fotos de antes y después en el sitio
• Agregar varios conceptos con impuesto y descuento
• Incluir instrucciones de pago (Venmo / Zelle / Cash App) en la factura
• Enviar presupuestos en PDF y convertirlos en trabajos
• Compartir facturas numeradas por Mensajes o Mail
• Marcar trabajos como pagados
• Exportar un respaldo ZIP con tus datos y fotos
• Usar la app en inglés o español
• Bloqueo opcional con Face ID

POR QUÉ FIELDFOLIO
El software tipo Jobber es demasiado cuando ya tienes clientes. FieldFolio reemplaza el caos del Carrete y las libretas con una boleta clara — sin conexión, privada y lista en dos minutos.

GRATIS
• 3 clientes
• 8 trabajos
• PDFs con marca de agua
• Los datos de ejemplo no cuentan para los límites Gratis

FIELDFOLIO PRO
• Clientes y trabajos ilimitados
• PDFs limpios sin marca de agua
• Widget de Hoy
• Recordatorios de trabajos

$4.99/mes · $29.99/año (prueba de 7 días) · $59.99 de por vida

Privacidad primero: sin cuenta, sin nube de FieldFolio, sin anuncios ni rastreo. Tus datos se quedan en tu dispositivo.

Las facturas son registros, no asesoría fiscal ni legal.

Términos de uso: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
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
FieldFolio requires no account. Sample data loads on first launch so you can open Today → a job → share an estimate or invoice PDF. Sample clients/jobs do not count toward Free limits; Settings includes Remove sample data.

Camera permission is used only to attach before/after photos to a job; photos stay on device.

In-app purchases unlock Pro limits and remove the PDF watermark. Use the StoreKit configuration Jobslip.storekit for local testing, or sandbox Apple ID for TestFlight.

No user-generated public content, no messaging network, no location tracking beyond optional address text the user types.
```

## Privacy Nutrition Label
- **Data Not Collected**

## Screenshots (captured)

Upload the App Store Connect-compatible files from
`store/screenshots/app-store/` (English) and `store/screenshots/es-MX/` when present:

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
- Privacy: https://mtraverso.github.io/fieldfolio/docs/privacy.html
- Support: https://mtraverso.github.io/fieldfolio/docs/support.html
- Privacy (es-MX): https://mtraverso.github.io/fieldfolio/docs/es/privacy.html
- Support (es-MX): https://mtraverso.github.io/fieldfolio/docs/es/support.html
- Marketing: optional; can reuse support URL
- In-app Settings and Paywall open the Spanish pages when the app runs in Spanish.
