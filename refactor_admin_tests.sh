#!/bin/bash
# decor/refactor_admin_tests.sh - version 1.1
# Refactors all admin controller tests to use centralized AuthenticationHelper
# Removes local log_in_as methods and explicit password arguments
# Added comprehensive error handling - exits on any failure

# Exit immediately if any command fails
set -e
# Exit if any variable is undefined
set -u
# Exit if any command in a pipeline fails
set -o pipefail

echo "========================================================="
echo "Refactoring Admin Controller Tests"
echo "========================================================="
echo ""

# Define admin test files
ADMIN_TESTS=(
  "test/controllers/admin/component_types_controller_test.rb"
  "test/controllers/admin/computer_models_controller_test.rb"
  "test/controllers/admin/conditions_controller_test.rb"
  "test/controllers/admin/invites_controller_test.rb"
  "test/controllers/admin/owners_controller_test.rb"
  "test/controllers/admin/run_statuses_controller_test.rb"
)

# Verify all files exist before starting
echo "Verifying all files exist..."
MISSING_FILES=0
for file in "${ADMIN_TESTS[@]}"; do
  if [ ! -f "$file" ]; then
    echo "  ✗ ERROR: File not found: $file"
    MISSING_FILES=$((MISSING_FILES + 1))
  else
    echo "  ✓ Found: $file"
  fi
done

if [ $MISSING_FILES -gt 0 ]; then
  echo ""
  echo "ERROR: $MISSING_FILES file(s) missing. Cannot proceed."
  echo "Are you running this from the decor/ project directory?"
  exit 1
fi

echo ""

# Create backup directory
BACKUP_DIR="test/controllers/admin/backup_$(date +%Y%m%d_%H%M%S)"
echo "Creating backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR" || {
  echo "ERROR: Failed to create backup directory"
  exit 1
}

# Backup all files
echo "Backing up original files..."
for file in "${ADMIN_TESTS[@]}"; do
  cp "$file" "$BACKUP_DIR/" || {
    echo "ERROR: Failed to backup $file"
    exit 1
  }
  echo "  ✓ Backed up: $(basename "$file")"
done

echo ""
echo "Backup complete. Original files saved in: $BACKUP_DIR"
echo ""

# Step 1: Remove local log_in_as method definitions
echo "Step 1: Removing local log_in_as method definitions..."
STEP1_ERRORS=0
for file in "${ADMIN_TESTS[@]}"; do
  # Check if file contains the method to remove
  if grep -q "def log_in_as" "$file"; then
    # Remove the method definition (lines containing "def log_in_as" through "end")
    sed -i '/def log_in_as/,/^  end$/d' "$file" || {
      echo "  ✗ ERROR: Failed to remove log_in_as from $file"
      STEP1_ERRORS=$((STEP1_ERRORS + 1))
      continue
    }
    
    # Verify it was removed
    if grep -q "def log_in_as" "$file"; then
      echo "  ✗ ERROR: log_in_as still present in $file after deletion"
      STEP1_ERRORS=$((STEP1_ERRORS + 1))
    else
      echo "  ✓ Removed log_in_as from $file"
    fi
  else
    echo "  ⚠ No log_in_as method found in $file (already removed?)"
  fi
done

if [ $STEP1_ERRORS -gt 0 ]; then
  echo ""
  echo "ERROR: Step 1 failed with $STEP1_ERRORS error(s)"
  echo "Original files preserved in: $BACKUP_DIR"
  exit 1
fi

echo ""

# Step 2: Change log_in_as to login_as (lowercase 'l')
echo "Step 2: Changing log_in_as to login_as..."
STEP2_ERRORS=0
for file in "${ADMIN_TESTS[@]}"; do
  # Count occurrences before
  BEFORE_COUNT=$(grep -c "log_in_as(" "$file" || true)
  
  if [ "$BEFORE_COUNT" -eq 0 ]; then
    echo "  ⚠ No log_in_as calls found in $file (already updated?)"
    continue
  fi
  
  sed -i 's/log_in_as(/login_as(/g' "$file" || {
    echo "  ✗ ERROR: Failed to update $file"
    STEP2_ERRORS=$((STEP2_ERRORS + 1))
    continue
  }
  
  # Count occurrences after
  AFTER_COUNT=$(grep -c "log_in_as(" "$file" || true)
  
  if [ "$AFTER_COUNT" -eq 0 ]; then
    echo "  ✓ Updated $file ($BEFORE_COUNT occurrences changed)"
  else
    echo "  ✗ ERROR: $AFTER_COUNT log_in_as calls remain in $file"
    STEP2_ERRORS=$((STEP2_ERRORS + 1))
  fi
done

if [ $STEP2_ERRORS -gt 0 ]; then
  echo ""
  echo "ERROR: Step 2 failed with $STEP2_ERRORS error(s)"
  echo "Original files preserved in: $BACKUP_DIR"
  exit 1
fi

echo ""

# Step 3: Remove explicit password arguments
echo "Step 3: Removing explicit password arguments..."
STEP3_ERRORS=0
for file in "${ADMIN_TESTS[@]}"; do
  # Count occurrences before
  BEFORE_COUNT=$(grep -c ', password: "[^"]*"' "$file" || true)
  
  if [ "$BEFORE_COUNT" -eq 0 ]; then
    echo "  ✓ No explicit passwords in $file (clean)"
    continue
  fi
  
  # Remove ", password: " followed by quoted string
  sed -i 's/, password: "[^"]*"//g' "$file" || {
    echo "  ✗ ERROR: Failed to clean $file"
    STEP3_ERRORS=$((STEP3_ERRORS + 1))
    continue
  }
  
  # Count occurrences after
  AFTER_COUNT=$(grep -c ', password: "[^"]*"' "$file" || true)
  
  if [ "$AFTER_COUNT" -eq 0 ]; then
    echo "  ✓ Cleaned $file ($BEFORE_COUNT occurrences removed)"
  else
    echo "  ✗ ERROR: $AFTER_COUNT explicit passwords remain in $file"
    STEP3_ERRORS=$((STEP3_ERRORS + 1))
  fi
done

if [ $STEP3_ERRORS -gt 0 ]; then
  echo ""
  echo "ERROR: Step 3 failed with $STEP3_ERRORS error(s)"
  echo "Original files preserved in: $BACKUP_DIR"
  exit 1
fi

echo ""

# Step 4: Add version comment at top of each file
echo "Step 4: Updating version comments..."
STEP4_ERRORS=0
for file in "${ADMIN_TESTS[@]}"; do
  # Get filename for comment
  filename=$(basename "$file")
  
  # Check if file already has a version comment
  if grep -q "# decor/test/controllers/admin/$filename - version" "$file"; then
    # Update existing version comment
    sed -i "s|# decor/test/controllers/admin/$filename - version [0-9.]*|# decor/test/controllers/admin/$filename - version 1.1|" "$file" || {
      echo "  ✗ ERROR: Failed to update version in $file"
      STEP4_ERRORS=$((STEP4_ERRORS + 1))
      continue
    }
    echo "  ✓ Updated version in $file"
  else
    # Add new version comment at top
    {
      echo "# decor/test/controllers/admin/$filename - version 1.1"
      echo "# Refactored to use centralized AuthenticationHelper"
      echo "# Removed local log_in_as method - now inherited"
      echo ""
      cat "$file"
    } > "${file}.tmp" || {
      echo "  ✗ ERROR: Failed to add version comment to $file"
      STEP4_ERRORS=$((STEP4_ERRORS + 1))
      continue
    }
    
    mv "${file}.tmp" "$file" || {
      echo "  ✗ ERROR: Failed to replace $file"
      STEP4_ERRORS=$((STEP4_ERRORS + 1))
      continue
    }
    
    echo "  ✓ Added version comment to $file"
  fi
done

if [ $STEP4_ERRORS -gt 0 ]; then
  echo ""
  echo "ERROR: Step 4 failed with $STEP4_ERRORS error(s)"
  echo "Original files preserved in: $BACKUP_DIR"
  exit 1
fi

echo ""
echo "========================================================="
echo "Refactoring Complete - All Operations Successful!"
echo "========================================================="
echo ""
echo "Backups saved in: $BACKUP_DIR"
echo ""
echo "Verification:"
echo "  - No local log_in_as methods remain"
echo "  - All calls use login_as (lowercase)"
echo "  - No explicit password arguments"
echo "  - Version comments added/updated"
echo ""
echo "Next steps:"
echo "1. Review changes: git diff test/controllers/admin/"
echo "2. Run tests: bin/rails test"
echo "3. Expected: All tests passing"
echo "4. If successful, remove backup: rm -rf $BACKUP_DIR"
echo ""

exit 0
