# PFA Helper - Testing Documentation

## Overview

This document describes the comprehensive test suite for the PFA Helper application, which models Romanian PFA (Persoană Fizică Autorizată) accounting functionality for 2025.

## Test Coverage

### Total Tests: 46
- **Model Tests**: 30 tests
- **Tax Calculator Tests**: 16 tests

## Running Tests

### Quick Start
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/models/pfa_test.dart
flutter test test/utils/tax_calculator_test.dart

# Run with coverage
flutter test --coverage

# Use the test runner script
./run_tests.sh
```

### Pre-Commit Workflow
Before making any commit, always run:
```bash
./run_tests.sh
```

This script will:
1. Run `flutter analyze` to check for code issues
2. Run all unit tests
3. Provide a summary of results

## Test Suite Details

### 1. PFA Model Tests (`test/models/pfa_test.dart`)

Tests the PFA (Persoană Fizică Autorizată) model implementation.

**Key Tests:**
- ✅ PFA creation with required fields
- ✅ Optional phone and email fields
- ✅ **CAEN Code Validation**: Maximum 5 CAEN codes (Romanian law)
- ✅ Primary CAEN code identification
- ✅ Special tax rate detection
- ✅ `canAddMoreCAENCodes` validation
- ✅ `copyWith` functionality

**Romanian Legislation Covered:**
- Emergency Ordinance no. 44/2008 (maximum 5 CAEN codes per PFA)

### 2. Transaction Model Tests (`test/models/transaction_test.dart`)

Tests transaction management and categorization.

**Key Tests:**
- ✅ Transaction creation with categories
- ✅ Income/expense identification
- ✅ **Tax Rate Calculation**:
  - 3% for IT CAEN codes (6201, 6202, 6209, 6210)
  - 10% standard rate for other CAEN codes
  - Custom tax rate override
- ✅ Rate priority: custom > CAEN > standard
- ✅ Optional invoice number and notes

**Transaction Categories Tested:**
- `taxableIncome` - Subject to income tax
- `nonTaxableIncome` - Excluded from tax calculations
- `deductibleExpense` - Reduces taxable base
- `nonDeductibleExpense` - Does not reduce taxes

### 3. CAEN Code Tests (`test/models/caen_code_test.dart`)

Tests CAEN (economic activity classification) code functionality.

**Key Tests:**
- ✅ CAEN code creation
- ✅ Special 3% tax rate for IT codes
- ✅ 10% standard rate for non-IT codes
- ✅ IT CAEN code detection (8 special codes)
- ✅ Common CAEN codes list
- ✅ Primary activity marking
- ✅ Effective tax rate calculation

**IT Special Rate Codes (3%):**
- 6201 - Computer programming
- 6202 - IT consultancy
- 6209 - Other IT services
- 6210 - Custom software development
- 5821 - Publishing computer games
- 5829 - Other software publishing
- 6311 - Data processing/hosting
- 6312 - Web portals

### 4. Tax Calculator Tests (`test/utils/tax_calculator_test.dart`)

Comprehensive tests for Romanian PFA tax calculations (2025 rules).

#### Income Tax Tests
- ✅ 10% standard income tax
- ✅ 3% special rate for IT CAEN codes
- ✅ **Mixed rate calculations** with proportional expense allocation
- ✅ Non-taxable income exclusion

#### CAS (Pension Contribution) Tests
Based on minimum gross salary 2025: **4,050 RON**

| Net Taxable Income | CAS Amount | Threshold |
|-------------------|------------|-----------|
| < 48,600 RON | 0 RON | Below 12 min salaries |
| 48,600 - 97,200 RON | 12,150 RON | 12-24 min salaries |
| >= 97,200 RON | 24,300 RON | >= 24 min salaries |

- ✅ Zero CAS below threshold
- ✅ 12,150 RON for 12-24 minimum salaries
- ✅ 24,300 RON for >= 24 minimum salaries

#### CASS (Health Insurance) Tests

| Net Taxable Income | CASS Amount | Calculation |
|-------------------|-------------|-------------|
| < 24,300 RON | 2,430 RON | Minimum |
| 24,300 - 243,000 RON | 10% of income | Variable |
| > 243,000 RON | 24,300 RON | Maximum |

- ✅ Minimum CASS (2,430 RON)
- ✅ 10% CASS for medium income
- ✅ Maximum CASS (24,300 RON)

#### Other Tax Tests
- ✅ **VAT Registration**: Required above 395,000 RON total income
- ✅ Non-deductible expense exclusion
- ✅ Year filtering (multi-year support)
- ✅ Total tax calculation (income tax + CAS + CASS)
- ✅ Net profit after taxes

## Tax Calculation Examples

### Example 1: Standard 10% Rate
```dart
Income: 100,000 RON
Expenses: 20,000 RON
Net Taxable: 80,000 RON

Income Tax: 8,000 RON (10% of 80,000)
CAS: 24,300 RON (>= 24 min salaries)
CASS: 8,000 RON (10% of 80,000)
Total Taxes: 40,300 RON
```

### Example 2: IT Special 3% Rate
```dart
Income: 100,000 RON (CAEN 6201)
Expenses: 20,000 RON
Net Taxable: 80,000 RON

Income Tax: 2,400 RON (3% of 80,000)
CAS: 24,300 RON
CASS: 8,000 RON
Total Taxes: 34,700 RON
```

### Example 3: Mixed Rates
```dart
IT Income: 60,000 RON (CAEN 6201, 3% rate)
Consulting Income: 40,000 RON (CAEN 7022, 10% rate)
Total Income: 100,000 RON
Expenses: 20,000 RON

Proportional allocation:
- 60% of expenses to IT: 12,000 RON
- 40% of expenses to Consulting: 8,000 RON

Income Tax:
- IT: (60,000 - 12,000) * 3% = 1,440 RON
- Consulting: (40,000 - 8,000) * 10% = 3,200 RON
- Total: 4,640 RON

CAS: 24,300 RON
CASS: 9,000 RON (10% of 90,000)
Total Taxes: 37,940 RON
```

## Romanian Legislation References

### 2025 Tax Rules
- **Minimum Gross Salary**: 4,050 RON
- **Income Tax**: 10% standard, 3% for IT/software
- **CAS Thresholds**: 12 and 24 minimum salaries
- **CASS**: 10% with 6 and 60 minimum salary limits
- **VAT Threshold**: 395,000 RON annual income

### Legal References
- Emergency Ordinance no. 44/2008 (CAEN codes)
- Romanian Fiscal Code 2025
- ANAF regulations

## Continuous Testing

### When to Run Tests
- ✅ Before every commit
- ✅ After modifying models
- ✅ After changing tax calculations
- ✅ When updating Romanian tax rules
- ✅ Before creating pull requests

### Test Maintenance
When Romanian tax rules change (e.g., 2026 updates):
1. Update test values in `tax_calculator_test.dart`
2. Update minimum salary constant
3. Update threshold calculations
4. Verify all tests pass
5. Update this documentation

## Adding New Tests

### Template for New Tests
```dart
test('Description of what is being tested', () {
  // Arrange
  final testData = createTestData();

  // Act
  final result = performCalculation(testData);

  // Assert
  expect(result.value, expectedValue);
});
```

### Test Naming Convention
- Use descriptive names: "Should calculate X when Y"
- Include Romanian terminology: "RON", "CAEN", "PFA"
- Specify exact thresholds in test names

## CI/CD Integration

To integrate with CI/CD pipelines:
```yaml
# Example GitHub Actions
- name: Run Tests
  run: |
    flutter analyze
    flutter test --coverage
```

## Coverage Goals

Current coverage targets:
- **Models**: 100% (all public methods tested)
- **Tax Calculator**: 100% (all calculation paths tested)
- **Overall**: > 80% code coverage

---

**Last Updated**: January 2025
**Test Suite Version**: 1.0
**Romanian Tax Year**: 2025
