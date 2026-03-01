# PROGRAMMING_GENERAL.md
# version 1.7
# Updated: bin/rails test → [full test suite command] (projects may not be Rails)
# Added: Database Column Types section — VARCHAR with length required; TEXT requires approval
# Added: End-of-task test coverage check — mandatory proactive review after every implementation

**General Programming Rules for All Technical Projects**

**Last Updated:** February 28, 2026 (v1.7: end-of-task test coverage check added)

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
4. ✅ Run lint check
5. ✅ Fix any lint offenses, then re-verify
6. ✅ Test manually (if applicable)
7. ✅ **ONLY AFTER successful testing AND clean lint:** Stage, commit, push

**NEVER suggest git operations before testing AND lint are confirmed successful.**

### Testing Commands
```bash
# ALWAYS run full test suite when making changes
[full test suite command]       # e.g. bin/rails test, pytest, npm test

# Test specific file only for debugging
[test-command-for-file]

# Manual testing
[start-server-command]
# Then verify in browser/CLI
```

---

## Database Column Types — MANDATORY

### Always Use VARCHAR with Explicit Length for Application Data

**Rule:** All application string/text columns MUST use `VARCHAR(n)` with an
explicit maximum length. Do NOT use unqualified `VARCHAR` or `TEXT` for
application data without prior approval.

**Rationale:** Explicit lengths document intent, enforce data integrity at the
database level, and prevent runaway data from reaching the application.

**Good:**
```sql
user_name    VARCHAR(15)
real_name    VARCHAR(40)
order_number VARCHAR(20)
```

**Bad:**
```sql
user_name    VARCHAR     -- no length = no enforcement
description  TEXT        -- TEXT should be explicitly approved
```

### Exceptions — VARCHAR length NOT required:
- Rails/framework internal columns: `password_digest`, `reset_password_token`,
  `remember_digest`, and similar framework-managed fields
- Email addresses and URLs (length limits are complex and framework-managed)

### TEXT data type — requires explicit approval:
- ❌ Do NOT use `TEXT` without asking first
- ✅ Only use `TEXT` when the user explicitly instructs it, OR
  when the field is clearly free-form long content (e.g. `history`, `description`,
  `body`) AND the user has confirmed TEXT is appropriate for that field
- When uncertain: ask "Should this be TEXT or VARCHAR(n)?"

**Cross-reference:** SQLite does not enforce VARCHAR length at runtime without
CHECK constraints. See RAILS_SPECIFICS.md for the SQLite-specific implementation
pattern (CHECK constraints required alongside VARCHAR declarations).

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
- Database constraint — Cannot be bypassed (SQL, bulk imports, external access)
- Model validation — User-friendly error messages, catches errors early

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

### Code Comments
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

**Test file template:**
```ruby
# project/test/type/feature_test.rb - version 1.0
# Description of what this test file covers

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

### MANDATORY: End-of-Task Test Coverage Check

**After completing ANY implementation task, Claude MUST explicitly ask:**

> "Did we add or change anything that should have an automated test?"

This check is NOT optional and must happen at the end of every session or task,
regardless of whether tests were mentioned in the original request.

**What to check:**
- ✅ New service objects / business logic classes → always testable, always test
- ✅ New controller actions → test happy path, auth guard, error paths
- ✅ New model validations or scopes → unit test each case
- ✅ Changed import/export logic, calculations, or data transformations → test thoroughly
- ❌ View layout changes (CSS, column restructuring) → no server-side logic, skip
- ❌ Stimulus JS controllers → no server-side logic; would need system tests (separate track)
- ❌ Routes-only changes with no new logic → skip

**Format of the check:**

Claude presents a brief analysis:
```
## Test Coverage Check

New server-side logic this task:
  OwnerExportService    — yes, testable: headers, rows, FK reference, spare handling
  OwnerImportService    — yes, testable: happy path, two-pass, duplicates, atomicity
  DataTransfersController — yes, testable: show/export/import actions, auth
  View layout changes   — no server-side logic, skip

Recommendation: write tests for the three items above before merging.
```

Then either:
- ✅ Proceed to write the tests (if the user agrees and fixture files are available)
- ✅ Ask for fixture files if they are needed but not yet in context
- ✅ Note the tests as pending if the user defers them

**Why this rule exists (Session 10, February 28, 2026):**
After implementing OwnerExportService, OwnerImportService, and DataTransfersController,
no tests were produced and no check was offered — the user had to ask explicitly.
This is a recurring failure pattern: implementation work is complete and the session
moves on without anyone asking whether tests should follow.

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

4. Run full test suite            [full test suite command]

5. Run lint (auto-fix + verify)   [lint fix command]
                                  [lint verify command]

6. Run security scan              [security scan command]

7. Manual / local testing         <start server, verify in browser>

8. Stage all changes              git add -A

9. Commit                         git commit -m "<descriptive message>"

10. Push branch                   git push origin feature/<branch-name>

11. Create PR                     gh pr create --fill

12. Wait for CI checks            gh pr checks feature/<branch-name>
    (BEFORE merging)

13. Merge PR (regular merge)      gh pr merge --merge feature/<branch-name>

14. Switch back to main           git switch main
    and sync                      git pull origin main

15. Delete local branch           git branch -d feature/<branch-name>

16. Delete remote branch          git push origin --delete feature/<branch-name>
    (if not auto-deleted by PR)

17. Deploy                        [deploy command]
```

**For Rails projects:** See RAILS_SPECIFICS.md for the Rails-specific commands
at steps 4–6 (`bin/rails test`, `bundle exec rubocop`, `bin/brakeman`).

**Why steps 4–6 run BEFORE committing, not after:**
- Catches failures locally without a push-fail-fix cycle
- CI should confirm what local checks already verified — not discover problems

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

### PR Merge Strategy
- Always use regular merge (not squash) unless project explicitly requires otherwise
- Squash creates divergence between local and remote main on solo dev workflows
- See project-specific docs for the merge flag required

### CRITICAL: Destructive Git Commands

**ALWAYS check `git status` before suggesting ANY destructive git command.**

Destructive commands include:
- `git reset --hard`
- `git clean -f`
- `git checkout -f`
- `git restore`

**These commands PERMANENTLY DESTROY uncommitted changes with no recovery possible.**

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
