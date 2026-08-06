# Billway App (Frontend)

The modern, responsive Flutter application for the **Billway** billing and invoicing system. Built with Clean Architecture and Riverpod for robust, scalable state management.

## Features

- **Beautiful UI/UX:** A stunning, responsive Material Design interface with fluid animations and a cohesive dashboard.
- **Clean Architecture:** Strictly separated Domain, Data, and Presentation layers for all modules.
- **State Management:** Powered by `Riverpod` for reactive, predictable UI states.
- **Routing:** Handled via `go_router` for seamless navigation.
- **Modules Include:**
  - **Dashboard:** At-a-glance metrics and a mini-sales chart for the last 30 days.
  - **Customers:** Easily add and manage clients.
  - **Products & Categories:** Manage inventory, upload images (via camera/gallery), and set tax brackets.
  - **Invoices (Wizard):** An intuitive, multi-step bottom-sheet flow to quickly add products, apply discounts, and generate invoices with optimistic local calculation.
  - **PDF Integration:** Seamlessly downloads and opens generated invoice PDFs natively on the device using `path_provider` and `open_file`.
  - **Payments Ledger:** Record partial or full payments (Cash, UPI, Card) against invoices.
  - **Reporting:** Rich, interactive data visualization (Line Charts) using `fl_chart` with dynamic date-range filtering.

## Tech Stack
- **Flutter 3.x**
- **Riverpod** (State Management)
- **Dio** (Networking)
- **GoRouter** (Navigation)
- **fl_chart** (Data Visualization)
- **image_picker** (Product Photos)

## Setup & Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/shahasil12/Billway.git
   cd Billway
   ```

2. **Get dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure API Endpoint:**
   - Ensure the `billway_api` backend is running locally.
   - The default base URL in `lib/core/network/api_client.dart` points to `http://10.0.2.2:8000/api/` (for Android Emulator) or `http://127.0.0.1:8000/api/` (for iOS/Web). Update this if your backend is hosted elsewhere.

4. **Run the App:**
   ```bash
   flutter run
   ```

## Project Structure
```text
lib/
├── core/             # Global configurations, networking, routing, theme
└── features/         # Feature-based modules (Clean Architecture)
    ├── auth/
    ├── dashboard/
    ├── customers/
    ├── products/
    ├── categories/
    ├── invoices/
    ├── payments/
    └── reports/
```
