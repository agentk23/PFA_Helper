# BREAKING CHANGES - Tax Calculation Corrections

## Version 2.0.0 - Critical Tax Calculation Fix (November 2025)

### **❌ CRITICAL BUG FIXED: Incorrect 3% Tax Rate for PFA**

#### Problem:

The previous version of PFA Helper incorrectly calculated income tax at 3% for certain IT-related CAEN codes (6201, 6202, 6209, 6210, 5821, 5829, 6311, 6312).

**This was fundamentally WRONG and could lead to severe financial and legal consequences.**

#### Legal Reality:

**ALL Persoane Fizice Autorizate (PFA) in Romania pay 10% income tax on net taxable income, REGARDLESS of their field of activity or CAEN code.**

The 3% special tax rate **ONLY applies to SRL (Societate cu Răspundere Limitată)** companies with microenterprise status and specific conditions, **NOT to PFA.**

**Legal basis:**
- Codul Fiscal, Art. 68: PFA income taxation at 10%
- Codul Fiscal, Art. 52: Microenterprise taxation (applies to SRL only)

#### Impact:

Users who relied on the previous calculations may have:
1. **Underpaid taxes** - expecting to pay only 3% instead of 10%
2. **Incorrect financial planning** - budgeting based on wrong tax rates
3. **Potential ANAF penalties** - for underpayment of taxes

#### What Changed:

**Before (INCORRECT):**
```dart
// WRONG - Mixed tax rates
Income tax = (IT income × 3%) + (Other income × 10%)
```

**After (CORRECT):**
```dart
// CORRECT - Single 10% rate for ALL PFA income
Income tax = Net Taxable Income × 10%

Where:
Net Taxable Income = Gross Income - Deductible Expenses - CAS - CASS
```

#### Code Changes:

1. **Removed** `incomeAt3PercentRate` from calculations
2. **Removed** `specialRateCodes` logic from tax calculation
3. **Updated** to uniform 10% tax rate for all income
4. **Kept** CAEN code tracking for informational/reporting purposes only

#### Migration Guide:

If you were using PFA Helper before this fix:

1. **Review your past tax calculations** - all calculations showing 3% tax were INCORRECT
2. **Recalculate your actual tax obligations** using the correct 10% rate
3. **Check your D212 declarations** - ensure they reflect the correct 10% rate
4. **Consult a tax advisor** if you've already submitted incorrect declarations

#### Example Correction:

**Scenario:** IT Freelancer, CAEN 6201, Net Income 100,000 RON

**Old (WRONG) Calculation:**
```
Income Tax = 100,000 × 3% = 3,000 RON ❌
```

**New (CORRECT) Calculation:**
```
Gross Income: 150,000 RON
Deductible Expenses: 30,000 RON
Gross Profit: 120,000 RON

CAS (24 minimum salaries): 24,300 RON
CASS (10% of 120,000): 12,000 RON

Net Taxable Income: 120,000 - 24,300 - 12,000 = 83,700 RON
Income Tax: 83,700 × 10% = 8,370 RON ✅

Total Taxes: 24,300 + 12,000 + 8,370 = 44,670 RON
Net Profit After Taxes: 120,000 - 44,670 = 75,330 RON
```

---

## Version 2.0.0 - Other Fixes

### 2. VAT Registration Threshold Updated

**Before:** 395,000 RON
**After:** 300,000 RON

**Reason:** Legislative change in 2024 reduced the VAT registration threshold.

**Legal basis:** Codul Fiscal, Art. 291, modified 2024

---

## Recommendations

1. **Immediately recalculate** all tax estimates using the corrected 10% rate
2. **Review D212 declarations** submitted with the old calculations
3. **Consult a certified accountant** (expert contabil autorizat) for:
   - Verification of past declarations
   - Potential rectificative declarations
   - Accurate tax planning going forward
4. **Do NOT rely solely on this app** for tax filing - always verify with a professional

---

## Disclaimer

This application is provided for informational purposes only. Tax laws are complex and subject to change. Always consult with a qualified Romanian tax professional (expert contabil) before making tax decisions or filing declarations with ANAF.

The developers of PFA Helper cannot be held liable for:
- Incorrect tax calculations from previous versions
- Penalties or interest from ANAF
- Financial losses resulting from use of this software

By using this app, you acknowledge that you are responsible for the accuracy of your tax filings and compliance with Romanian fiscal legislation.

---

**Last updated:** November 18, 2025
**Applicable from:** Version 2.0.0
