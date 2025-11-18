# PFA Helper - Romanian PFA Management Application

A comprehensive Flutter application for managing PFA (Persoană Fizică Autorizată) finances and taxes in Romania, built following Romanian fiscal law.

## ✨ Features

### 📊 PFA Management
- **Profile Setup**: Register and manage your PFA information
  - Personal information (name, CUI)
  - CAEN code selection for your business activity
  - Tax system selection (Real Income / Norms-based)
  - VAT registration status

### 💰 Transaction Tracking
- **Income Management**: Track all revenue with detailed categorization
- **Expense Management**: Record deductible and non-deductible expenses
- **Categorization**: Organize transactions by category
- **VAT Support**: Handle transactions with 19% VAT
- **Invoicing**: Link transactions to invoice numbers and clients/suppliers

### 📈 Tax Calculations
Based on Romanian fiscal law (2023), the app automatically calculates:

- **Impozit pe venit** (10%): Income tax on net income
- **CAS** (25%): Social security contribution
  - Minimum: 12 minimum wages annually
  - Maximum: 24 minimum wages annually
- **CASS** (10%): Health insurance contribution
  - Minimum: 6 minimum wages annually

### 📄 Reports & PDF Generation
- **Detailed Tax Reports**: Comprehensive breakdowns of income, expenses, and taxes
- **PDF Export**: Professional PDF reports for sharing or record keeping
- **Period Selection**: View reports for any custom date range

## 🚀 Getting Started

### Installation
```bash
# Get dependencies
flutter pub get

# Generate Hive adapters
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run -d macos  # or your target platform
```

## 📱 Usage

1. **First Launch**: Register your PFA information
2. **Add Transactions**: Track income and expenses
3. **View Reports**: See tax calculations and generate PDFs
4. **Manage**: Edit profile and categorize transactions

## ⚖️ Romanian Tax Compliance

- Based on **Codul Fiscal 2023**
- Minimum wage: 3,700 RON/month (2024)
- VAT rate: 19%

**Note**: This app provides estimates for planning. Always consult a licensed Romanian accountant for official tax filing.

## 🛠 Technical Stack

- Flutter 3.38+
- Hive (local database)
- PDF generation
- GoRouter navigation
- Material 3 design

## ⚠️ Disclaimer

This application is for informational purposes only. It does not constitute financial or legal advice. Consult with qualified professionals for tax decisions.

---

Made with ❤️ for Romanian freelancers
