#!/bin/bash
# decor/fix_all_test_passwords.sh - version 1.0
# Complete fix for all test password issues
# Run from decor/ directory: bash fix_all_test_passwords.sh

echo "==================================================================="
echo "Fixing ALL test password issues"
echo "==================================================================="
echo ""

echo "Step 1: Fix non-admin tests (password456 → password45678)"
echo "-----------------------------------------------------------"
find test/controllers/admin -name "*_test.rb" -exec sed -i 's/password: "password456"/password: "password45678"/g' {} \;
echo "✓ Updated all admin controller tests"

echo ""
echo "Step 2: Search for any remaining short passwords in tests"
echo "-----------------------------------------------------------"
echo "Checking for password123 references:"
grep -rn 'password123' test/controllers/ test/models/ 2>/dev/null | grep -v "password12345" || echo "  ✓ None found"

echo ""
echo "Checking for password456 references:"
grep -rn 'password456' test/controllers/ test/models/ 2>/dev/null | grep -v "password45678" || echo "  ✓ None found"

echo ""
echo "Step 3: Check for Owner.new/create with short passwords"
echo "-----------------------------------------------------------"
# Look for Owner.new or Owner.create that might have short passwords
echo "Searching owners_controller_test.rb for password issues..."
if [ -f "test/controllers/owners_controller_test.rb" ]; then
    echo "  File exists - checking for short passwords..."
    grep -n "password:" test/controllers/owners_controller_test.rb | head -5
else
    echo "  File not found"
fi

echo ""
echo "==================================================================="
echo "Fix complete!"
echo "==================================================================="
echo ""
echo "Next steps:"
echo "1. Run: bin/rails test"
echo "2. If OwnersControllerTest#test_create_accepts_invite still fails:"
echo "   Upload test/controllers/owners_controller_test.rb for analysis"
echo ""
