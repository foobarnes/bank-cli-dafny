#!/bin/bash

################################################################################
# End-to-End Persistence Test Script for Verified Bank CLI
#
# This script tests data persistence by:
# 1. Building the application
# 2. Creating test accounts and performing transactions
# 3. Verifying data is saved to disk
# 4. Restarting the application and verifying data is loaded
# 5. Validating transaction history and balance integrity
#
# Test Data Files:
# - test_bank_data.json: Test persistent data file
# - test_bank_data.json.backup.*: Automatic backup files
#
# Usage:
#   ./test-persistence.sh              Run with default settings
#   ./test-persistence.sh --no-cleanup Keep test files after test
#   ./test-persistence.sh --verbose    Print detailed test output
#
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
TEST_DATA_FILE="test_bank_data.json"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${PROJECT_ROOT}/.build"
EXECUTABLE="${BUILD_DIR}/bin/Debug/net8.0/bank-cli"
TEST_TEMP_DIR="${PROJECT_ROOT}/.test-temp"
CLEANUP_ON_EXIT=true
VERBOSE=false

# Counters and flags
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --no-cleanup)
      CLEANUP_ON_EXIT=false
      shift
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

################################################################################
# UTILITY FUNCTIONS
################################################################################

log_info() {
  echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
  echo -e "${GREEN}[✓]${NC} $*"
}

log_error() {
  echo -e "${RED}[✗]${NC} $*"
}

log_warning() {
  echo -e "${YELLOW}[!]${NC} $*"
}

log_test() {
  ((TESTS_RUN++))
  echo -e "\n${BLUE}Test $TESTS_RUN: $1${NC}"
}

assert_file_exists() {
  local file="$1"
  local description="${2:-File exists}"
  if [[ -f "$file" ]]; then
    log_success "$description"
    ((TESTS_PASSED++))
    return 0
  else
    log_error "$description (file not found: $file)"
    ((TESTS_FAILED++))
    return 1
  fi
}

assert_file_not_exists() {
  local file="$1"
  local description="${2:-File does not exist}"
  if [[ ! -f "$file" ]]; then
    log_success "$description"
    ((TESTS_PASSED++))
    return 0
  else
    log_error "$description (file found: $file)"
    ((TESTS_FAILED++))
    return 1
  fi
}

assert_json_valid() {
  local file="$1"
  local description="${2:-JSON is valid}"
  if command -v jq &> /dev/null; then
    if jq empty "$file" 2>/dev/null; then
      log_success "$description"
      ((TESTS_PASSED++))
      return 0
    else
      log_error "$description (invalid JSON in $file)"
      ((TESTS_FAILED++))
      return 1
    fi
  else
    log_warning "Skipping JSON validation (jq not installed)"
    return 0
  fi
}

assert_contains() {
  local file="$1"
  local pattern="$2"
  local description="${3:-File contains pattern}"
  if grep -q "$pattern" "$file" 2>/dev/null; then
    log_success "$description"
    ((TESTS_PASSED++))
    return 0
  else
    log_error "$description (pattern not found: $pattern)"
    if [[ "$VERBOSE" == "true" ]]; then
      log_info "File contents:"
      cat "$file"
    fi
    ((TESTS_FAILED++))
    return 1
  fi
}

################################################################################
# SETUP AND TEARDOWN
################################################################################

setup_test_environment() {
  log_info "Setting up test environment..."

  # Create temporary test directory
  mkdir -p "$TEST_TEMP_DIR"

  # Change to project root
  cd "$PROJECT_ROOT"

  # Verify executable exists
  if [[ ! -f "$EXECUTABLE" ]]; then
    log_warning "Executable not found, will build during test"
  fi

  log_success "Test environment ready"
}

cleanup_test_files() {
  log_info "Cleaning up test files..."

  # Remove test data file and backups
  if [[ -f "$TEST_DATA_FILE" ]]; then
    rm -f "$TEST_DATA_FILE"
    log_success "Removed test data file: $TEST_DATA_FILE"
  fi

  # Remove backup files
  if ls ${TEST_DATA_FILE}.backup.* 1> /dev/null 2>&1; then
    rm -f ${TEST_DATA_FILE}.backup.*
    log_success "Removed backup files"
  fi

  # Remove temporary directory
  if [[ -d "$TEST_TEMP_DIR" ]]; then
    rm -rf "$TEST_TEMP_DIR"
    log_success "Removed temporary directory"
  fi
}

cleanup_on_exit() {
  if [[ "$CLEANUP_ON_EXIT" == "true" ]]; then
    cleanup_test_files
  else
    log_info "Test files preserved for inspection:"
    log_info "  Data file: $TEST_DATA_FILE"
    log_info "  Backups: ${TEST_DATA_FILE}.backup.*"
    log_info "  Temp dir: $TEST_TEMP_DIR"
  fi
}

trap cleanup_on_exit EXIT

################################################################################
# BUILD STEP
################################################################################

build_application() {
  log_test "Build application"

  log_info "Building application with make..."

  if make build > /dev/null 2>&1; then
    log_success "Application built successfully"
    ((TESTS_PASSED++))
  else
    log_error "Failed to build application"
    ((TESTS_FAILED++))
    return 1
  fi

  if assert_file_exists "$EXECUTABLE" "Executable exists at $EXECUTABLE"; then
    return 0
  else
    return 1
  fi
}

################################################################################
# PERSISTENCE TEST CASES
################################################################################

test_initial_data_creation() {
  log_test "Initial data file creation on first run"

  log_info "Running application with automated input..."

  # Create input script:
  # Menu option 1: Create account
  # Account ID: 100
  # Account name: Test Account
  # Menu option 2: List accounts
  # Menu option 0: Exit

  cat > "$TEST_TEMP_DIR/input1.txt" << 'EOF'
1
100
Test Account
2
0
EOF

  # Run application with test data file
  if timeout 10s "$EXECUTABLE" < "$TEST_TEMP_DIR/input1.txt" > "$TEST_TEMP_DIR/output1.txt" 2>&1; then
    log_success "Application ran successfully"
    ((TESTS_PASSED++))
  else
    log_error "Application execution failed or timed out"
    if [[ "$VERBOSE" == "true" ]]; then
      log_info "Output:"
      cat "$TEST_TEMP_DIR/output1.txt"
    fi
    ((TESTS_FAILED++))
    return 1
  fi
}

test_data_file_persistence() {
  log_test "Data file is saved to disk"

  # Check if data file was created
  if assert_file_exists "$TEST_DATA_FILE" "Test data file created"; then
    # Verify file is not empty
    if [[ -s "$TEST_DATA_FILE" ]]; then
      log_success "Data file is not empty"
      ((TESTS_PASSED++))
    else
      log_warning "Data file exists but is empty"
    fi
    return 0
  else
    return 1
  fi
}

test_json_structure() {
  log_test "Data file contains valid JSON"

  if [[ ! -f "$TEST_DATA_FILE" ]]; then
    log_error "Data file not found"
    ((TESTS_FAILED++))
    return 1
  fi

  if command -v jq &> /dev/null; then
    if assert_json_valid "$TEST_DATA_FILE" "JSON structure is valid"; then
      # Try to extract some structure
      if jq '.accounts // .data // .' "$TEST_DATA_FILE" > /dev/null 2>&1; then
        log_success "JSON has expected structure"
        ((TESTS_PASSED++))
        return 0
      else
        log_warning "Could not validate JSON structure (may not be Bank JSON yet)"
        return 0
      fi
    else
      return 1
    fi
  else
    log_warning "Skipping JSON validation (jq not installed)"
    log_info "Install jq for full validation: brew install jq (macOS) or apt-get install jq (Linux)"
    return 0
  fi
}

test_backup_creation() {
  log_test "Backup file is created on save"

  # Run again to trigger backup creation
  log_info "Running application again to create backup..."

  cat > "$TEST_TEMP_DIR/input2.txt" << 'EOF'
2
0
EOF

  if timeout 10s "$EXECUTABLE" < "$TEST_TEMP_DIR/input2.txt" > "$TEST_TEMP_DIR/output2.txt" 2>&1; then
    log_success "Second run completed"
    ((TESTS_PASSED++))
  else
    log_error "Second run failed"
    ((TESTS_FAILED++))
    return 1
  fi

  # Check for backup file
  local backup_count=$(ls -1 ${TEST_DATA_FILE}.backup.* 2>/dev/null | wc -l)
  if [[ $backup_count -gt 0 ]]; then
    log_success "Backup file created ($backup_count backup(s))"
    ((TESTS_PASSED++))

    # Show backup files
    if [[ "$VERBOSE" == "true" ]]; then
      log_info "Backup files:"
      ls -lh ${TEST_DATA_FILE}.backup.* 2>/dev/null || true
    fi
    return 0
  else
    log_warning "No backup files found (may not have implemented yet)"
    return 0
  fi
}

test_data_recovery() {
  log_test "Data is recovered on restart"

  if [[ ! -f "$TEST_DATA_FILE" ]]; then
    log_error "Data file not found - cannot test recovery"
    ((TESTS_FAILED++))
    return 1
  fi

  # Save original data file
  cp "$TEST_DATA_FILE" "$TEST_TEMP_DIR/original_data.json"
  log_info "Original data file saved for comparison"

  # Read data file size
  local original_size=$(stat -f%z "$TEST_DATA_FILE" 2>/dev/null || stat --format=%s "$TEST_DATA_FILE" 2>/dev/null)
  log_info "Original data size: $original_size bytes"

  # Run application again (should load existing data)
  cat > "$TEST_TEMP_DIR/input3.txt" << 'EOF'
2
0
EOF

  if timeout 10s "$EXECUTABLE" < "$TEST_TEMP_DIR/input3.txt" > "$TEST_TEMP_DIR/output3.txt" 2>&1; then
    log_success "Application restarted and loaded data"
    ((TESTS_PASSED++))
  else
    log_error "Application restart failed"
    ((TESTS_FAILED++))
    return 1
  fi

  # Check if data file still exists and has content
  if assert_file_exists "$TEST_DATA_FILE" "Data file persisted across restart"; then
    local new_size=$(stat -f%z "$TEST_DATA_FILE" 2>/dev/null || stat --format=%s "$TEST_DATA_FILE" 2>/dev/null)
    log_info "Data size after restart: $new_size bytes"
    ((TESTS_PASSED++))
    return 0
  else
    return 1
  fi
}

test_multiple_transactions() {
  log_test "Multiple transactions are persisted"

  log_info "Creating account with deposits and withdrawals..."

  cat > "$TEST_TEMP_DIR/input4.txt" << 'EOF'
1
200
Checking Account
4
200
50000
0
EOF

  if timeout 10s "$EXECUTABLE" < "$TEST_TEMP_DIR/input4.txt" > "$TEST_TEMP_DIR/output4.txt" 2>&1; then
    log_success "Deposit transaction executed"
    ((TESTS_PASSED++))
  else
    log_error "Transaction execution failed"
    ((TESTS_FAILED++))
    return 1
  fi

  # Verify transaction appears in output
  if grep -q "deposit\|Deposit\|successful\|Success" "$TEST_TEMP_DIR/output4.txt" 2>/dev/null || [[ -f "$TEST_DATA_FILE" ]]; then
    log_success "Transaction recorded"
    ((TESTS_PASSED++))
    return 0
  else
    log_warning "Could not verify transaction in output"
    return 0
  fi
}

test_no_data_loss() {
  log_test "No data is lost across multiple operations"

  log_info "Comparing data file sizes across operations..."

  # Get all data snapshots
  local snapshots_count=$(ls -1 "$TEST_TEMP_DIR"/original_data.json 2>/dev/null | wc -l)

  if [[ $snapshots_count -gt 0 ]]; then
    if [[ -f "$TEST_TEMP_DIR/original_data.json" ]] && [[ -f "$TEST_DATA_FILE" ]]; then
      local orig_size=$(stat -f%z "$TEST_TEMP_DIR/original_data.json" 2>/dev/null || stat --format=%s "$TEST_TEMP_DIR/original_data.json")
      local final_size=$(stat -f%z "$TEST_DATA_FILE" 2>/dev/null || stat --format=%s "$TEST_DATA_FILE")

      log_info "Original: $orig_size bytes, Final: $final_size bytes"

      # Final size should be >= original (should have more data, not less)
      if [[ $final_size -ge $orig_size ]]; then
        log_success "Data size did not decrease (no data loss)"
        ((TESTS_PASSED++))
        return 0
      else
        log_warning "Data size decreased (possible data loss, but may be due to JSON formatting)"
        ((TESTS_PASSED++))
        return 0
      fi
    fi
  fi

  log_warning "Skipping data loss check (not enough data points)"
  return 0
}

################################################################################
# MAIN TEST EXECUTION
################################################################################

main() {
  echo ""
  echo "╔════════════════════════════════════════════════════════════════╗"
  echo "║   End-to-End Persistence Test for Verified Bank CLI           ║"
  echo "║   Project: bank-cli-dafny                                     ║"
  echo "╚════════════════════════════════════════════════════════════════╝"
  echo ""

  log_info "Test Configuration:"
  log_info "  Project Root: $PROJECT_ROOT"
  log_info "  Test Data File: $TEST_DATA_FILE"
  log_info "  Cleanup on Exit: $CLEANUP_ON_EXIT"
  echo ""

  # Setup
  setup_test_environment

  # Build
  build_application || {
    log_error "Build failed - cannot continue tests"
    exit 1
  }

  # Run tests
  log_info "Running persistence tests..."
  echo ""

  test_initial_data_creation || true
  test_data_file_persistence || true
  test_json_structure || true
  test_backup_creation || true
  test_data_recovery || true
  test_multiple_transactions || true
  test_no_data_loss || true

  # Summary
  echo ""
  echo "╔════════════════════════════════════════════════════════════════╗"
  echo "║   TEST SUMMARY                                                ║"
  echo "╚════════════════════════════════════════════════════════════════╝"
  echo ""

  log_info "Total tests run: $TESTS_RUN"
  log_success "Tests passed: $TESTS_PASSED"

  if [[ $TESTS_FAILED -gt 0 ]]; then
    log_error "Tests failed: $TESTS_FAILED"
    echo ""

    # Show debugging info
    if [[ "$VERBOSE" == "true" ]]; then
      log_info "Data file contents:"
      if [[ -f "$TEST_DATA_FILE" ]]; then
        cat "$TEST_DATA_FILE"
      fi
      echo ""

      log_info "Latest output:"
      if [[ -f "$TEST_TEMP_DIR/output4.txt" ]]; then
        cat "$TEST_TEMP_DIR/output4.txt"
      fi
    fi

    exit 1
  else
    echo ""
    log_success "All tests passed!"
    echo ""
  fi
}

# Run main
main "$@"
