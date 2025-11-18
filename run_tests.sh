#!/bin/bash

# PFA Helper Test Runner
# Runs all tests before committing changes

echo "🧪 Running PFA Helper Test Suite..."
echo ""

# Run Flutter analyze
echo "📊 Running Flutter analyze..."
flutter analyze
if [ $? -ne 0 ]; then
    echo "❌ Flutter analyze failed!"
    exit 1
fi
echo "✅ Flutter analyze passed"
echo ""

# Run all tests
echo "🧪 Running unit tests..."
flutter test
if [ $? -ne 0 ]; then
    echo "❌ Tests failed!"
    exit 1
fi
echo ""
echo "✅ All tests passed!"
echo ""

# Summary
echo "📈 Test Summary:"
echo "   - Flutter analyzer: ✅ No issues"
echo "   - Unit tests: ✅ All passing"
echo "   - Ready to commit! 🚀"
