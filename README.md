# ExpenseIQ AI

### Your AI Financial Assistant

A **portfolio-grade** Flutter fintech application that combines AI-powered expense tracking with intelligent financial coaching. Built with Clean Architecture, BLoC state management, and Gemini AI integration.

---

## ✨ Features

### Core
- **Manual Expense Entry** — Category, merchant, amount, date, tags, payment method
- **CRUD Operations** — Create, Read, Update, Delete with swipe-to-dismiss
- **Offline-First** — All data stored locally via Hive. Only AI features need internet
- **Dark/Light Themes** — Custom premium fintech themes (not default Flutter dark)

### AI-Powered
| Feature | Description |
|---------|-------------|
| **Receipt Scanner Pro** | Extract merchant, amount, date, category, tax, payment method + confidence score |
| **AI Spending Coach** | Personalized coaching — strengths, weaknesses, savings opportunities |
| **Financial Health Score** | 0–100 animated gauge with breakdown: consistency, balance, savings, control |
| **Smart Insights** | AI-generated spending analysis with section-based reports |
| **Smart Category Detection** | Gemini classifies merchants → categories (Swiggy → Food, Uber → Travel) |

### Analytics Dashboard
- **Summary Cards** — Total Spent, This Month
- **Quick Stats** — Today, This Week, Daily Average
- **Weekly Spending Trend** — Interactive line chart (fl_chart)
- **Category Distribution** — Interactive pie chart
- **Monthly Comparison** — This vs Last month with trend arrows
- **Spending Prediction** — Linear extrapolation for month-end forecast
- **Recurring Expense Detection** — Identifies subscriptions with monthly/annual costs
- **Highest Expense Banner** — Highlights biggest transaction

### Expense Management
- **Timeline View** — Grouped by Today / Yesterday / This Week / Month / Older
- **Category Filter Chips** — Horizontal scrollable filters
- **Search** — Live search by merchant name or notes
- **Sort Options** — Date (newest/oldest), Amount (highest/lowest)
- **Smart Tags** — Auto-generated (#food, #taxi) with manual addition

### Receipt Scanner
- **Camera + Gallery** support
- **AI Confidence Badge** — "AI: 94%" with color coding
- **Tax Extraction** — GST/tax amount from receipts
- **Payment Method Detection** — Cash, UPI, Card, Online
- **One-Tap Correction** — Review & edit before saving

---

## 🏗️ Architecture

```
lib/
├── core/
│   ├── constants/      # App, API, Color constants
│   ├── errors/         # Exception & Failure classes
│   ├── services/       # GeminiService (AI)
│   ├── theme/          # Material 3 light/dark themes
│   └── utils/          # Formatters, Validators
├── data/
│   ├── datasources/    # Hive local datasource
│   ├── models/         # ExpenseModel + Hive adapter
│   └── repositories/   # Repository implementations
├── domain/
│   ├── entities/       # Expense entity
│   ├── repositories/   # Repository contracts
│   └── usecases/       # GetExpenses, AddExpense, etc.
├── presentation/
│   ├── blocs/          # ExpenseBloc, ReceiptBloc, InsightsBloc, CoachBloc, ThemeCubit
│   ├── pages/          # Dashboard, List, Scanner, Insights, Coach, Add/Edit, Splash
│   └── widgets/        # SummaryCard, LineChart, PieChart, HealthGauge, AlertBanner, etc.
├── injection_container.dart  # GetIt DI setup
└── main.dart
```

### Design Principles
- **Clean Architecture** — Strict separation: Domain ← Data ← Presentation
- **BLoC Pattern** — Predictable state, single source of truth
- **Dependency Injection** — GetIt for testability and loose coupling
- **Offline-First** — Hive for zero-latency local persistence

---

## 🛠️ Tech Stack

| Category | Technology |
|----------|-----------|
| Framework | Flutter (Latest Stable) |
| State Management | flutter_bloc 9.x |
| Storage | Hive |
| AI | Google Generative AI (Gemini 2.5 Flash) |
| Charts | fl_chart |
| Animations | flutter_animate |
| DI | get_it |
| Image | image_picker |

---

## 🚀 Setup

```bash
# Clone
git clone <repo-url>
cd Ai_Flutter\ App

# Install dependencies
flutter pub get

# Configure API key
# Edit lib/core/constants/api_constants.dart
# Set your Gemini API key

# Run
flutter run
```

### Requirements
- Flutter SDK ≥ 3.10.4
- Android SDK / Xcode
- Gemini API key (for AI features)

---

## 📸 Screenshots

*Add screenshots of:*
1. Dashboard with charts and stats
2. AI Coach with health score gauge
3. Receipt Scanner with confidence badge
4. Expense timeline with filter chips
5. Dark mode variant

---

## ⚖️ Tradeoffs

| Decision | Rationale |
|----------|-----------|
| Hive over SQLite | Faster reads, simpler schema, no native dependencies |
| No Lottie | Reduced APK size; custom animated widgets instead |
| Manual Hive adapter | Faster than build_runner, full control over migration |
| Linear prediction | Simple but effective for month-end forecasting; ML would be overkill |
| Gemini for all AI | Single API simplifies auth, billing, and prompt engineering |

---

## 🔮 Future Improvements

- [ ] Multi-currency support with conversion
- [ ] Cloud sync (Firebase / Supabase)
- [ ] PDF export with charts
- [ ] Biometric authentication
- [ ] Budget alerts with local notifications
- [ ] Receipt OCR fallback (ML Kit) for offline scanning
- [ ] Shared expenses / split bills
- [ ] Recurring expense auto-detection with ML
- [ ] Widget for home screen (daily spending)

---

## 📄 License

MIT License
