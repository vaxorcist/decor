# PROGRAMMING_GENERAL.md
# version 1.5

**General Programming Rules for All Technical Projects**

**Last Updated:** February 24, 2026 (v1.5: --merge flag required on gh pr merge to avoid interactive prompt)

---

## Core Principles - READ FIRST

### Always Provide Complete Files
- ✅ **NEVER give instructions to update files**
- ✅ **ALWAYS provide complete updated file contents**
- ✅ User should be able to copy/replace files directly
- ✅ No "change line X" or "add this section" - give entire file
- ✅ If multiple files need updates, provide ALL complete files

**Bad:**
```
Update line 45 in config.rb to change the timeout value
Add this method to your helper file:
```

**Good:**
```
# complete/path/to/config.rb - version 1.2
[entire file contents with the change]
```

### Think First, Code Later
- ✅ **PLAN COMPLETELY** before writing any code
- ✅ Analyze full impact across entire codebase
- ✅ Identify all files that need changes
- ✅ Design centralized solutions, not scattered fixes
- ✅ Present complete solution, not iterative patches

### NO Bandaid Solutions
- ✅ Find root cause, not symptoms
- ✅ Implement proper architecture, not quick hacks
- ✅ Centralize shared logic, don't repeat
- ✅ Think long-term maintenance
- ✅ Quality over speed

### Analyze Impact Comprehensively
**Before implementing ANY change that affects multiple files:**
1. Search ENTIRE codebase for affected code
2. List ALL files that need updates
3. Design ONE centralized solution
4. Present complete refactoring plan
5. Never suggest "fix file by file" approach

**Example:** Adding password validation requires:
- Check fixtures for all password values
- Search all test files for hardcoded passwords
- Search for `password:`, `"password`, `.new`, `.create`
- Design centralized test helper
- Refactor ALL affected files at once

---

## File Handling & Paths

### Always Specify Complete Paths
- ✅ ALWAYS specify complete file paths starting with project directory
- ✅ Format: `project-name/path/to/file.ext`
- ✅ Example: `decor/app/models/owner.rb` NOT just `owner.rb`

### File Version Control
- ✅ When adding/modifying files, include:
  - Complete path (project directory to filename)
  - Version number as comment in first line
  - Detailed comments in new/modified files

**Example:**
```ruby
# project/app/models/owner.rb - version 1.1
# Added user_name length validation (max 15 characters)

class Owner < ApplicationRecord
  # ... code ...
end
```

---

## Testing Workflow - CRITICAL

### Test BEFORE Committing

**The ONLY correct order:**
1. ✅ Make code changes
2. ✅ Run migrations (if any)
3. ✅ Run FULL test suite (not just one file)
4. ✅ Run lint check: `bundle exec rubocop -f github`
5. ✅ Fix any lint offenses: `bundle exec rubocop -A` then re-verify
6. ✅ Test manually (if applicable)
7. ✅ **ONLY AFTER successful testing AND clean lint:** Stage, commit, push

**NEVER suggest git operations before testing AND lint are confirmed successful.**

### Testing Commands
```bash
# ALWAYS run full test suite when making changes
bin/rails test  # or equivalent for project

# Test specific file only for debugging
[test-command-for-file]

# Manual testing
[start-server-command]
# Then verify in browser/CLI
```

---

## Test Data Management

### Centralize Test Data Constants

**RULE:** Never hardcode test data across multiple files.

**Bad (Scattered):**
```ruby
# file1_test.rb
password: "password123"

# file2_test.rb
password: "password123"

# file3_test.rb
password: "password123"
```

**Good (Centralized):**
```ruby
# test/support/test_constants.rb
module TestConstants
  TEST_PASSWORD = "password123".freeze
end

# All test files use:
password: TEST_PASSWORD
```

### Centralize Test Helper Methods

**RULE:** Shared test logic goes in ONE place, not duplicated.

**Bad (Duplicated):**
```ruby
# 10 different test files each have:
def log_in_as(user, password: "password123")
  # same code repeated 10 times
end
```

**Good (Centralized):**
```ruby
# test/support/authentication_helper.rb
module AuthenticationHelper
  def login_as(user, password: nil)
    # One implementation, inherited by all tests
  end
end
```

### Search Patterns for Test Data

**When changing validation rules, ALWAYS search:**
```bash
# Find hardcoded values
grep -rn "old_value" test/

# Find method definitions that might have defaults
grep -rn "def method_name" test/

# Find Model.new and Model.create
grep -rn "ModelName\.(new\|create)" test/

# Find password references
grep -rn "password.*[:=]" test/
```

---

## Database Considerations

### Always Check Database Type First

**Before creating migrations, ask:**
- What database is this project using? (PostgreSQL, MySQL, SQLite, etc.)
- Different databases have different capabilities
- SQLite has severe ALTER TABLE limitations
- PostgreSQL and MySQL have different syntax

### Check Production Data Before Adding Constraints

**3-Step Safe Process:**

#### Step 1: Check for Violations
```bash
# Check production database for violations BEFORE creating migration
[command to check for data that violates new constraint]
```

#### Step 2: Clean Data (if violations exist)
Create a data cleaning migration FIRST:
```ruby
class CleanDataBeforeConstraint < ActiveRecord::Migration
  def up
    # Option A: Fill in missing values
    Model.where(field: nil).find_each do |record|
      record.update_column(:field, "DEFAULT-#{record.id}")
    end

    # Option B: Delete invalid records (if acceptable)
    # Model.where(field: nil).destroy_all

    # Option C: Raise error and require manual fixing
    # count = Model.where(field: nil).count
    # raise "Found #{count} records with nil field. Fix manually." if count > 0
  end
end
```

Deploy, run migration, verify data is clean.

#### Step 3: Add Constraint
Only after data is verified clean:
```ruby
class AddConstraint < ActiveRecord::Migration
  def change
    # Add database constraint
  end
end
```

### Defense-in-Depth Approach

**Best practice: Database constraint + Model validation**

**Why both:**
- Database constraint - Cannot be bypassed (SQL, bulk imports, external access)
- Model validation - User-friendly error messages, catches errors early

**Example:**
```ruby
# Database migration
class AddLengthConstraint < ActiveRecord::Migration
  def change
    # Database-level enforcement
  end
end

# Model validation
class Model < ApplicationRecord
  validates :field, length: { maximum: 15 }
end
```

---

## Code Quality

### Shell Script Error Handling

**CRITICAL:** All shell scripts MUST have comprehensive error handling.

**Required at top of every script:**
```bash
#!/bin/bash
# Exit immediately if any command fails
set -e
# Exit if any variable is undefined
set -u
# Exit if any command in a pipeline fails
set -o pipefail
```

**Required checks:**
- ✅ Verify all input files exist before starting
- ✅ Create backups before modifying files
- ✅ Check return codes of all operations
- ✅ Verify operations succeeded (count before/after)
- ✅ Print meaningful error messages
- ✅ Exit with proper exit codes (0 = success, non-zero = failure)

**Example:**
```bash
set -euo pipefail

# Verify file exists
if [ ! -f "$FILE" ]; then
  echo "ERROR: File not found: $FILE"
  exit 1
fi

# Backup before modifying
cp "$FILE" "$FILE.backup" || {
  echo "ERROR: Failed to create backup"
  exit 1
}

# Perform operation and verify
sed -i 's/old/new/g' "$FILE" || {
  echo "ERROR: sed operation failed"
  exit 1
}

# Verify result
if grep -q "old" "$FILE"; then
  echo "ERROR: Operation incomplete - 'old' still present"
  exit 1
fi

echo "Success!"
exit 0
```

### Centralization Principles

**RULE:** Don't Repeat Yourself (DRY)
- ✅ Shared constants in ONE module
- ✅ Shared methods in ONE helper
- ✅ Configuration in ONE file
- ✅ Test data in ONE location

**When you find yourself copying code, STOP:**
1. Create centralized module/helper
2. Move shared logic there
3. Have all code reference the central location

### Comments & Documentation
- ✅ Add detailed comments explaining WHY, not just WHAT
- ✅ Document assumptions
- ✅ Note limitations or edge cases
- ✅ Reference related code or patterns

### Version History
- ✅ Track version numbers in file headers
- ✅ Note what changed in each version
- ✅ Document lessons learned from mistakes

---

## Test Maintenance

### When to Update Tests

**Always update tests when:**
- ✅ Adding new models/controllers/features
- ✅ Changing validation rules
- ✅ Making fields required
- ✅ Modifying business logic
- ✅ Adding routes or endpoints
- ✅ Changing associations between models

### Test Update Checklist for Validation Changes

**CRITICAL:** When adding/changing validations:

1. ✅ Search ENTIRE test directory for affected values
2. ✅ Check fixtures match new requirements
3. ✅ Search for `Model.new` with old values
4. ✅ Search for `Model.create` with old values
5. ✅ Search for hardcoded test data
6. ✅ Update ALL affected files at once
7. ✅ Run FULL test suite
8. ✅ Verify ALL tests pass

**Do NOT:**
- ❌ Fix one file at a time
- ❌ Run partial tests
- ❌ Assume you found all references
- ❌ Skip comprehensive search

### CRITICAL: Create Test Files for New Functionality

**When implementing new features that can be automatically tested:**
- ✅ **ALWAYS create an appropriate test file**
- ✅ Do NOT just suggest what tests COULD be written
- ✅ Create actual, runnable test code
- ✅ Include version number and detailed comments in test file
- ✅ Cover main scenarios: success cases, error cases, edge cases

**Examples of testable functionality:**
- New controller actions
- New model methods
- Authentication/authorization changes
- Data validation changes
- Business logic changes
- API endpoints

**Test file template:**
```ruby
# project/test/type/feature_test.rb - version 1.0
# Description of what this test file covers
# Lists main test scenarios included

require "test_helper"

class FeatureTest < ActiveSupport::TestCase
  def setup
    # Setup common test data
  end

  test "should handle success case" do
    # Test implementation
  end

  test "should handle error case" do
    # Test implementation
  end
end
```

**This is NOT optional** - if functionality can be tested, create the test file.

---

## Git Workflow

### Complete Branch Workflow — ALWAYS Follow This Order

```
Step                              Command
────────────────────────────────────────────────────────────────────────────
1. Start from clean main          git switch main
                                  git pull origin main

2. Create feature branch          git switch -c feature/<branch-name>

3. Do the work                    <coding>

4. Run full test suite            bin/rails test

5. Run lint (auto-fix + verify)   bundle exec rubocop -A
                                  bundle exec rubocop

6. Run security scan              bin/brakeman --no-pager

7. Manual / local testing         <start server, verify in browser>

8. Stage all changes              git add -A

9. Commit                         git commit -m "<descriptive message>"

10. Push branch                   git push origin feature/<branch-name>
    (first push on new branch)    (sets upstream automatically if
                                   push.autoSetupRemote = true, otherwise
                                   git push --set-upstream origin <branch>)

11. Create PR                     gh pr create --fill
    (uses commit msg as title)

12. Wait for CI checks            gh pr checks feature/<branch-name>
    (BEFORE merging)

13. Merge PR (regular merge)      gh pr merge --merge feature/<branch-name>
    (NOT --squash, see below)         (--merge flag REQUIRED — omitting it
                                       triggers an interactive prompt asking
                                       which merge strategy to use)

14. Switch back to main           git switch main
    and sync                      git pull origin main

15. Delete local branch           git branch -d feature/<branch-name>

16. Delete remote branch          git push origin --delete feature/<branch-name>
    (if not auto-deleted by PR)

17. Deploy                        kamal deploy
```

**Why steps 4–6 run BEFORE committing, not after:**
- Catches failures locally without a push-fail-fix cycle
- Brakeman locally avoids waiting for CI to report security issues
- Rubocop auto-fix before staging means the commit is clean from the start
- CI should confirm what local checks already verified — not discover problems

**Why `gh pr checks` runs BEFORE merging (step 12):**
- Running it after merge is too late — CI failures cannot be acted on
- Merge only when all checks pass

### Commit Messages
- ✅ Clear, descriptive commit messages
- ✅ Mention what changed and why
- ✅ Reference issue/ticket numbers if applicable

**Good examples:**
```
Update owners: add user_name validation, redesign page to match computers
Fix computers filtering: add owner_id parameter support
Add database constraint for serial_number (defense-in-depth)
Centralize test passwords to eliminate duplication
```

**`gh pr create --fill`** uses the commit message as PR title and body automatically.
Use explicit `--title "..."` only when the PR needs a different title from the commit.

### PR Merge Strategy - CRITICAL

**DECOR project uses: `gh pr merge --merge` (regular merge)**

**Why NOT `--squash`:**
- `--squash` creates a brand-new commit on main with a different SHA
- Local main and origin/main then diverge (1 commit each direction)
- `git pull` fails with "fatal: need to specify how to reconcile divergent branches"
- Requires an extra `git reset --hard origin/main` after every merge
- This is a recurring footgun in solo development workflows

**Why `--merge` (regular merge):**
- Creates a standard merge commit that preserves the feature branch history
- Local main fast-forwards cleanly with `git pull`
- No divergence, no extra steps after merge
- Simpler and safer for solo developers

**If `--squash` was used and divergence occurred:**
```bash
# Safe recovery (only if git status shows clean working directory):
git fetch origin
git reset --hard origin/main
git status                            # Verify clean
```

**Lesson learned:** `--squash` was recommended in a prior session for a "cleaner
git log" but the post-merge divergence is a recurring problem that outweighs
the benefit for a solo developer. Switched to `--merge` on February 18, 2026.

### CRITICAL: Destructive Git Commands

**ALWAYS check `git status` before suggesting ANY destructive git command.**

Destructive commands include:
- `git reset --hard`
- `git clean -f`
- `git checkout -f`
- `git restore`

**These commands PERMANENTLY DESTROY uncommitted changes with no recovery possible.**

**Safe workflow before any destructive command:**

```bash
# Step 1: Always check first
git status

# Step 2a: If uncommitted changes exist - commit or stash first
git add -A
git commit -m "WIP: save work before branch operation"
# OR
git stash

# Step 2b: Only THEN run the destructive command
git reset --hard origin/main
```

**Real example of what can go wrong:**
Without this check, `git reset --hard origin/main` silently destroyed 4 modified
files in one command. Files had to be manually recreated from session outputs.

**Rule for Claude:** Before suggesting `reset --hard` or similar, ALWAYS instruct
the user to run `git status` first and commit/stash any uncommitted changes.

### CRITICAL Rubocop Rules
- ✅ ALWAYS run `bundle exec rubocop` locally on the **entire project** before committing
- ✅ Fix all offenses: `bundle exec rubocop -A` then re-verify with `bundle exec rubocop`
- ✅ Use `bundle exec rubocop -f github` only when **debugging CI failures** — it mimics CI output format (shows filenames and line numbers), useful for matching against CI logs
- ❌ NEVER run rubocop on `.erb` files — it cannot parse them (will show false errors)
- ❌ NEVER check only changed files — CI checks entire project

**When debugging CI lint failures:**
```bash
bundle exec rubocop -f github   # same format as CI output
```

**Lesson learned:** Lint fixes committed to a feature branch AFTER the PR is merged never reach main. Fix lint BEFORE merging.

---

## Production Deployment Safety

### Pre-Deployment Checklist
- ✅ All tests pass locally
- ✅ Manual testing confirms functionality
- ✅ Database migrations tested locally
- ✅ Production data checked for constraint violations
- ✅ Rollback plan prepared

### Deployment Order
1. Deploy data cleaning (if needed)
2. Run data cleaning migration in production
3. Verify data is clean
4. Deploy constraint/code changes
5. Run constraint migration in production
6. Deploy application code
7. Verify production functionality

---

## Continuous Improvement

### Update Rules When Learning

**When new patterns or mistakes are discovered:**
1. ✅ Propose addition to appropriate rules document
2. ✅ Ask user for approval
3. ✅ Update document with lessons learned
4. ✅ Date the update
5. ✅ Include specific examples

**Rules documents are living documents.**

---

**End of PROGRAMMING_GENERAL.md**
