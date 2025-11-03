# Makefile for bank-cli-dafny
#
# Provides convenient targets for building, testing, and running the Dafny project.
# All build artifacts are output to .build/ directory for clean separation from source.

.PHONY: help build rebuild clean clean-temp clean-debug clean-release \
        verify test run publish install-deps check-deps all

# Configuration
PROJECT_ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
BUILD_DIR := .build
DAFNY_SRC := src/Main.dfy
DAFNY_TESTS := tests
CSPROJ := bank-cli.csproj
OUTPUT_NAME := bank-cli
CONFIG ?= Debug
TARGET_FRAMEWORK := net9.0

# Paths
BIN_OUTPUT := $(BUILD_DIR)/bin/$(CONFIG)/$(TARGET_FRAMEWORK)
OBJ_OUTPUT := $(BUILD_DIR)/obj/$(CONFIG)/$(TARGET_FRAMEWORK)
DAFNY_CSHARP := $(BUILD_DIR)/dafny/csharp
PUBLISH_OUTPUT := $(BUILD_DIR)/publish/$(CONFIG)
CACHE_DIR := $(BUILD_DIR)/cache
LOG_DIR := $(BUILD_DIR)/logs

# Executable name (platform-specific)
ifeq ($(OS),Windows_NT)
    EXECUTABLE := $(BIN_OUTPUT)/$(OUTPUT_NAME).exe
else
    EXECUTABLE := $(BIN_OUTPUT)/$(OUTPUT_NAME)
endif

# Color output for better readability
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# ============================================================================
# HELP
# ============================================================================

help:
	@echo "$(CYAN)bank-cli-dafny Build System$(NC)"
	@echo ""
	@echo "$(GREEN)Main Targets:$(NC)"
	@echo "  make all              - Verify and build (default target)"
	@echo "  make build            - Compile to .build/bin"
	@echo "  make rebuild          - Full clean rebuild"
	@echo "  make verify           - Verify Dafny code"
	@echo "  make test             - Run Dafny tests"
	@echo "  make run              - Build and run application"
	@echo "  make publish          - Create publishable Release build to .build/publish/"
	@echo ""
	@echo "$(GREEN)Cleaning:$(NC)"
	@echo "  make clean            - Remove all artifacts in .build/"
	@echo "  make clean-debug      - Remove Debug build"
	@echo "  make clean-release    - Remove Release build"
	@echo "  make clean-temp       - Remove temporary files only"
	@echo "  make clean-cache      - Remove build cache"
	@echo ""
	@echo "$(GREEN)Configuration:$(NC)"
	@echo "  CONFIG=Debug          - Debug build (default)"
	@echo "  CONFIG=Release        - Optimized Release build"
	@echo ""
	@echo "$(GREEN)Examples:$(NC)"
	@echo "  make                  - Build Debug configuration"
	@echo "  make verify test      - Verify then run tests"
	@echo "  make publish          - Create Release distribution"
	@echo "  make clean rebuild    - Full clean rebuild"
	@echo "  make run CONFIG=Release - Run Release build"
	@echo ""
	@echo "$(YELLOW)Output Locations:$(NC)"
	@echo "  Source:       src/, tests/, ffi/"
	@echo "  Build:        $(BUILD_DIR)/"
	@echo "  Dafny C#:     $(DAFNY_CSHARP)/"
	@echo "  Binaries:     $(BIN_OUTPUT)/"
	@echo "  Objects:      $(OBJ_OUTPUT)/"
	@echo "  Publish:      $(PUBLISH_OUTPUT)/"
	@echo ""

# ============================================================================
# MAIN TARGETS
# ============================================================================

# Default target: verify and build
all: verify build
	@echo "$(GREEN)✓ Build complete$(NC)"

# Build application
build: check-deps $(EXECUTABLE)
	@echo "$(GREEN)✓ Build successful$(NC)"
	@echo "Output: $(EXECUTABLE)"

$(EXECUTABLE): | $(BUILD_DIR)
	@echo "$(CYAN)Building $(CONFIG) configuration...$(NC)"
	dotnet build $(CSPROJ) -c $(CONFIG) -o $(BIN_OUTPUT)

# Rebuild from scratch
rebuild: clean build
	@echo "$(GREEN)✓ Rebuild complete$(NC)"

# ============================================================================
# DAFNY VERIFICATION & TESTING
# ============================================================================

# Verify all Dafny code
verify:
	@echo "$(CYAN)Verifying Dafny code...$(NC)"
	@mkdir -p $(LOG_DIR)
	dafny verify $(DAFNY_SRC) 2>&1 | tee $(LOG_DIR)/dafny-verify.log
	@echo "$(GREEN)✓ Verification complete$(NC)"

# Run Dafny tests
test: verify
	@echo "$(CYAN)Running Dafny tests...$(NC)"
	@mkdir -p $(LOG_DIR)
	dafny test $(DAFNY_TESTS)/BankTests.dfy 2>&1 | tee $(LOG_DIR)/dafny-test.log
	@echo "$(GREEN)✓ Tests complete$(NC)"

# ============================================================================
# RUNNING THE APPLICATION
# ============================================================================

# Build and run
run: build
	@echo "$(CYAN)Running $(OUTPUT_NAME)...$(NC)"
	@if [ -z "$$DOTNET_ROOT" ] && [ -d "/opt/homebrew/opt/dotnet/libexec" ]; then \
		DOTNET_ROOT="/opt/homebrew/opt/dotnet/libexec" $(EXECUTABLE); \
	else \
		$(EXECUTABLE); \
	fi

# Run without building (assumes build exists)
run-quick:
	@if [ ! -f "$(EXECUTABLE)" ]; then \
		echo "$(RED)Error: Executable not found at $(EXECUTABLE)$(NC)"; \
		echo "Run 'make build' first"; \
		exit 1; \
	fi
	@if [ -z "$$DOTNET_ROOT" ] && [ -d "/opt/homebrew/opt/dotnet/libexec" ]; then \
		DOTNET_ROOT="/opt/homebrew/opt/dotnet/libexec" $(EXECUTABLE); \
	else \
		$(EXECUTABLE); \
	fi

# ============================================================================
# PUBLISHING & DISTRIBUTION
# ============================================================================

# Publish self-contained release
publish: clean-release
	@echo "$(CYAN)Publishing Release build...$(NC)"
	dotnet publish $(CSPROJ) -c Release -o $(PUBLISH_OUTPUT)
	@echo "$(GREEN)✓ Published to $(PUBLISH_OUTPUT)$(NC)"
	@echo "$(YELLOW)Contents:$(NC)"
	@ls -lh $(PUBLISH_OUTPUT)/$(OUTPUT_NAME)* 2>/dev/null || echo "  No executable found"

# ============================================================================
# CLEANING TARGETS
# ============================================================================

# Remove all artifacts
clean:
	@echo "$(CYAN)Cleaning all artifacts...$(NC)"
	rm -rf $(BUILD_DIR)
	dotnet clean $(CSPROJ) 2>/dev/null || true
	@echo "$(GREEN)✓ Clean complete$(NC)"

# Remove only Debug build
clean-debug:
	@echo "$(CYAN)Cleaning Debug build...$(NC)"
	rm -rf $(BUILD_DIR)/bin/Debug
	rm -rf $(BUILD_DIR)/obj/Debug
	dotnet clean $(CSPROJ) -c Debug 2>/dev/null || true
	@echo "$(GREEN)✓ Debug clean complete$(NC)"

# Remove only Release build
clean-release:
	@echo "$(CYAN)Cleaning Release build...$(NC)"
	rm -rf $(BUILD_DIR)/bin/Release
	rm -rf $(BUILD_DIR)/obj/Release
	rm -rf $(BUILD_DIR)/publish
	dotnet clean $(CSPROJ) -c Release 2>/dev/null || true
	@echo "$(GREEN)✓ Release clean complete$(NC)"

# Remove temporary files only
clean-temp:
	@echo "$(CYAN)Cleaning temporary files...$(NC)"
	rm -rf $(BUILD_DIR)/temp
	find . -type f -name "*.tmp" -delete
	@echo "$(GREEN)✓ Temp clean complete$(NC)"

# Remove build cache
clean-cache:
	@echo "$(CYAN)Cleaning build cache...$(NC)"
	rm -rf $(CACHE_DIR)
	rm -rf .dafny-cache
	@echo "$(GREEN)✓ Cache clean complete$(NC)"

# ============================================================================
# DEPENDENCY MANAGEMENT
# ============================================================================

# Check for required dependencies
check-deps:
	@echo "$(CYAN)Checking dependencies...$(NC)"
	@command -v dafny >/dev/null 2>&1 || { \
		echo "$(RED)Error: dafny not found in PATH$(NC)"; \
		echo "Install Dafny from: https://github.com/dafny-lang/dafny/releases"; \
		exit 1; \
	}
	@command -v dotnet >/dev/null 2>&1 || { \
		echo "$(RED)Error: dotnet not found in PATH$(NC)"; \
		echo "Install .NET from: https://dotnet.microsoft.com/download"; \
		exit 1; \
	}
	@echo "$(GREEN)✓ dafny $(shell dafny --version 2>/dev/null | head -1)$(NC)"
	@echo "$(GREEN)✓ dotnet $(shell dotnet --version)$(NC)"

# Install/restore dependencies
install-deps:
	@echo "$(CYAN)Restoring NuGet dependencies...$(NC)"
	dotnet restore $(CSPROJ)
	@echo "$(GREEN)✓ Dependencies restored$(NC)"

# ============================================================================
# DAFNY COMPILATION (Advanced)
# ============================================================================

# Translate Dafny to C# (generates .build/dafny/csharp/bank-cli.cs)
translate-csharp: check-deps
	@echo "$(CYAN)Translating Dafny to C#...$(NC)"
	@mkdir -p $(DAFNY_CSHARP)
	@mkdir -p $(LOG_DIR)
	dafny translate csharp $(DAFNY_SRC) --output:$(DAFNY_CSHARP) 2>&1 | tee $(LOG_DIR)/dafny-translate.log
	@echo "$(GREEN)✓ Translation complete: $(DAFNY_CSHARP)/bank-cli.cs$(NC)"

# Build using Dafny (creates executable directly)
dafny-build: verify
	@echo "$(CYAN)Building with Dafny...$(NC)"
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(LOG_DIR)
	dafny build $(DAFNY_SRC) --output:$(BUILD_DIR)/$(OUTPUT_NAME) 2>&1 | tee $(LOG_DIR)/dafny-build.log
	@echo "$(GREEN)✓ Dafny build complete$(NC)"

# ============================================================================
# UTILITY TARGETS
# ============================================================================

# Create build directory structure
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)/{dafny/csharp,dafny/intermediate,dafny/debug}
	@mkdir -p $(BUILD_DIR)/{bin/Debug/$(TARGET_FRAMEWORK),bin/Release/$(TARGET_FRAMEWORK)}
	@mkdir -p $(BUILD_DIR)/{obj/Debug/$(TARGET_FRAMEWORK),obj/Release/$(TARGET_FRAMEWORK)}
	@mkdir -p $(BUILD_DIR)/{publish,cache/dafny,cache/dotnet,logs,temp}

# Show build directory structure
show-structure:
	@echo "$(CYAN)Build Directory Structure:$(NC)"
	@tree -L 3 -I '__pycache__|*.pyc' $(BUILD_DIR) 2>/dev/null || find $(BUILD_DIR) -type d | head -30

# Show build outputs
show-outputs:
	@echo "$(CYAN)Build Outputs:$(NC)"
	@if [ -d "$(BIN_OUTPUT)" ]; then \
		echo "$(GREEN)Binaries:$(NC)"; \
		ls -lh $(BIN_OUTPUT)/ 2>/dev/null | grep -v "^total" || echo "  (empty)"; \
	fi
	@if [ -d "$(DAFNY_CSHARP)" ]; then \
		echo "$(GREEN)Generated C#:$(NC)"; \
		ls -lh $(DAFNY_CSHARP)/ 2>/dev/null | grep -v "^total" || echo "  (empty)"; \
	fi

# Show build configuration
show-config:
	@echo "$(CYAN)Build Configuration:$(NC)"
	@echo "  Configuration: $(CONFIG)"
	@echo "  Output Dir:    $(BIN_OUTPUT)"
	@echo "  Objects Dir:   $(OBJ_OUTPUT)"
	@echo "  Dafny C#:      $(DAFNY_CSHARP)"
	@echo "  Publish Dir:   $(PUBLISH_OUTPUT)"
	@echo "  Executable:    $(EXECUTABLE)"

# ============================================================================
# COMPOSITE TARGETS (Useful workflows)
# ============================================================================

# Verify, build, and run
dev: verify build run-quick

# Verify and test
test-full: verify test build

# Full release workflow
release: clean test publish
	@echo "$(GREEN)✓ Release build complete$(NC)"
	@echo "  Output: $(PUBLISH_OUTPUT)"

# Quick rebuild and run (skip verification for faster iteration)
quick: build run-quick

# ============================================================================
# DOCUMENTATION
# ============================================================================

docs:
	@echo "$(CYAN)Build Documentation:$(NC)"
	@echo "  - docs/BUILD_STRUCTURE.md     : Architecture and directory layout"
	@echo "  - docs/MIGRATION_GUIDE.md     : Migration from legacy structure"
	@echo "  - CLAUDE.md                   : Development guidelines"
	@echo ""
	@echo "$(CYAN)Key Directories:$(NC)"
	@echo "  - src/                        : Dafny source code"
	@echo "  - tests/                      : Dafny tests"
	@echo "  - ffi/                        : C# FFI implementations"
	@echo "  - .build/                     : All generated artifacts (not version controlled)"
	@echo ""

# ============================================================================
# PHONY TARGETS (targets that don't represent files)
# ============================================================================

.PHONY: help all build rebuild verify test run run-quick publish
.PHONY: clean clean-debug clean-release clean-temp clean-cache
.PHONY: check-deps install-deps
.PHONY: translate-csharp dafny-build
.PHONY: show-structure show-outputs show-config
.PHONY: dev test-full release quick docs
