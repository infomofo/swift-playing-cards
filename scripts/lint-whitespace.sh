#!/bin/bash

# Simple whitespace linter for Swift files
# This is a fallback for environments where SwiftLint is not available

echo "Checking for whitespace issues in Swift files..."

exit_code=0

# Check for trailing whitespace
echo "Checking for trailing whitespace..."
trailing_files=$(find Sources Tests -name "*.swift" -exec grep -l " $" {} \; 2>/dev/null)
if [ -n "$trailing_files" ]; then
    echo "❌ Found files with trailing whitespace:"
    echo "$trailing_files"
    exit_code=1
else
    echo "✅ No trailing whitespace found"
fi

# Check for files without final newline
echo "Checking for missing final newlines..."
missing_newlines=0
for file in $(find Sources Tests -name "*.swift" 2>/dev/null); do
    if [ -s "$file" ] && [ "$(tail -c1 "$file" | wc -l)" -eq 0 ]; then
        echo "❌ Missing final newline: $file"
        missing_newlines=1
        exit_code=1
    fi
done

if [ $missing_newlines -eq 0 ]; then
    echo "✅ All files have proper final newlines"
fi

if [ $exit_code -eq 0 ]; then
    echo "✅ All whitespace checks passed!"
else
    echo "❌ Some whitespace issues found"
fi

exit $exit_code