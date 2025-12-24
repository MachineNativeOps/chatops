package naming

# Deny by default for security
default deny = false

# Main policy evaluation
deny[msg] {
    # Check file naming conventions
    invalid_filename
    msg := sprintf("File '%s' does not follow kebab-case naming convention", [input.filename])
}

deny[msg] {
    # Check YAML resource naming
    invalid_resource_name
    msg := sprintf("Resource '%s' in file '%s' does not follow kebab-case naming", [resource.name, input.filename])
}

deny[msg] {
    # Check for missing required labels
    missing_required_labels
    msg := sprintf("Resource in file '%s' missing required labels", [input.filename])
}

deny[msg] {
    # Check for camelCase in YAML files
    camelcase_detected
    msg := sprintf("CamelCase detected in file '%s'. Use kebab-case instead", [input.filename])
}

deny[msg] {
    # Check for snake_case in YAML files
    snakecase_detected
    msg := sprintf("Snake_case detected in file '%s'. Use kebab-case instead", [input.filename])
}

# Helper functions for file naming
invalid_filename {
    # Skip special files
    not is_special_file(input.filename)
    
    # Check if filename follows kebab-case pattern
    not regex.match("^[a-z0-9-]+(\\.(yaml|yml|md|sh|json|rego|txt))?$", basename(input.filename))
}

is_special_file(filename) {
    special_files := [
        "README.md",
        "LICENSE",
        "VERSION", 
        "SECURITY.md",
        "CONTRIBUTING.md",
        "Makefile",
        ".gitignore",
        ".gitkeep",
        "Dockerfile",
        "docker-compose.yml",
        "docker-compose.yaml"
    ]
    basename(filename) == special_files[_]
}

basename(path) {
    parts := split(path, "/")
    parts[count(parts) - 1]
}

# Helper functions for YAML resource naming
invalid_resource_name {
    # Only check YAML files
    is_yaml_file(input.filename)
    
    # Parse YAML content
    document := yaml.parse(input.content)
    
    # Check for metadata.name in resources
    document.metadata != null
    document.metadata.name != null
    
    # Check if resource name follows kebab-case
    not regex.match("^[a-z0-9-]+$", document.metadata.name)
}

is_yaml_file(filename) {
    endswith(filename, ".yaml") or endswith(filename, ".yml")
}

# Helper functions for label checking
missing_required_labels {
    # Only check Kubernetes-like resources
    is_kubernetes_resource
    
    # Get required labels
    required_labels := ["app.kubernetes.io/name", "app.kubernetes.io/component", "app.kubernetes.io/managed-by"]
    
    # Parse YAML content
    document := yaml.parse(input.content)
    
    # Check if metadata exists and has labels
    document.metadata != null
    document.metadata.labels != null
    
    # Check if any required label is missing
    missing_labels := [label | label := required_labels[_]; object.get(document.metadata.labels, label, null) == null]
    count(missing_labels) > 0
}

is_kubernetes_resource {
    # Check for Kubernetes-like structure
    is_yaml_file(input.filename)
    document := yaml.parse(input.content)
    
    # Common Kubernetes API versions
    k8s_api_versions := [
        "apps/v1",
        "v1",
        "networking.k8s.io/v1",
        "rbac.authorization.k8s.io/v1",
        "batch/v1",
        "autoscaling/v2"
    ]
    
    document.apiVersion == k8s_api_versions[_]
}

# Helper functions for case detection
camelcase_detected {
    # Check for camelCase patterns in YAML files
    is_yaml_file(input.filename)
    regex.match("[a-z][A-Z]", input.content)
}

snakecase_detected {
    # Check for snake_case patterns in YAML files
    is_yaml_file(input.filename)
    regex.match("[a-z]_[a-z]", input.content)
}

# Additional policy rules for specific naming patterns

# Workflow naming rules
deny[msg] {
    is_workflow_file
    not valid_workflow_name
    msg := sprintf("Workflow file '%s' should use descriptive kebab-case naming", [basename(input.filename)])
}

is_workflow_file {
    startswith(input.filename, ".github/workflows/")
}

valid_workflow_name {
    filename := basename(input.filename)
    base_name := replace(filename, ".yaml", "")
    base_name = replace(base_name, ".yml", "")
    
    # Workflows should be descriptive
    valid_workflow_patterns := [
        "ci",
        "cd",
        "build",
        "test",
        "deploy",
        "security",
        "scan",
        "audit",
        "lint",
        "validate",
        "release",
        "notify",
        "cleanup",
        "backup",
        "monitor",
        "health-check",
        "dependency-update",
        "auto-fix",
        "provenance",
        "sbom",
        "policy-check",
        "naming-convention"
    ]
    
    # Check if it's a valid pattern or compound pattern
    is_valid_workflow_pattern(base_name, valid_workflow_patterns)
}

is_valid_workflow_pattern(name, patterns) {
    # Direct match
    name == patterns[_]
} {
    # Compound pattern (e.g., "security-scan")
    some pattern in patterns
    some suffix in ["scan", "check", "test", "validate", "enforce", "generate", "upload", "build", "deploy"]
    name == sprintf("%s-%s", [pattern, suffix])
}

# Policy file naming rules
deny[msg] {
    is_policy_file
    not valid_policy_name
    msg := sprintf("Policy file '%s' should follow policy naming conventions", [basename(input.filename)])
}

is_policy_file {
    contains(input.filename, "policy") or endswith(input.filename, ".rego")
}

valid_policy_name {
    filename := basename(input.filename)
    
    # Policy files should be descriptive
    valid_policy_patterns := [
        "naming",
        "security",
        "compliance",
        "validation",
        "admission",
        "authorization",
        "authentication",
        "resource",
        "network",
        "pod",
        "service",
        "ingress",
        "rbac",
        "cost",
        "performance",
        "scaling"
    ]
    
    # Check if it's a valid pattern
    filename == sprintf("%s.rego", [valid_policy_patterns[_]])
} {
    # Or a compound policy name
    is_compound_policy_name(filename, valid_policy_patterns)
}

is_compound_policy_name(filename, patterns) {
    # Remove .rego extension
    base_name := replace(filename, ".rego", "")
    
    # Check for compound patterns
    some prefix in patterns
    some suffix in ["policy", "rules", "validation", "check", "enforce"]
    base_name == sprintf("%s-%s", [prefix, suffix])
}

# Script naming rules
deny[msg] {
    is_script_file
    not valid_script_name
    msg := sprintf("Script file '%s' should use kebab-case naming", [basename(input.filename)])
}

is_script_file {
    script_extensions := [".sh", ".bash", ".py", ".js", ".ts"]
    some ext in script_extensions
    endswith(input.filename, ext)
}

valid_script_name {
    filename := basename(input.filename)
    
    # Shell scripts should be kebab-case
    endswith(filename, ".sh") or endswith(filename, ".bash")
    regex.match("^[a-z0-9-]+(\\.sh|\\.bash)$", filename)
    
    # Other scripts can use kebab-case or snake_case for Python, but not camelCase
    endswith(filename, ".py") or endswith(filename, ".js") or endswith(filename, ".ts")
    not regex.match("[a-z][A-Z]", filename)
}

# Configuration file naming rules
deny[msg] {
    is_config_file
    not valid_config_name
    msg := sprintf("Configuration file '%s' should follow configuration naming conventions", [basename(input.filename)])
}

is_config_file {
    config_patterns := ["config", "settings", "options", "env", "properties", "conf"]
    some pattern in config_patterns
    contains(lower(input.filename), pattern)
}

valid_config_name {
    filename := basename(input.filename)
    
    # Config files should be clear and specific
    valid_config_patterns := [
        "app",
        "server",
        "database", 
        "cache",
        "queue",
        "logging",
        "security",
        "auth",
        "network",
        "storage",
        "monitoring",
        "metrics",
        "tracing"
    ]
    
    # Check for valid config patterns with extensions
    config_extensions := [".yaml", ".yml", ".json", ".toml", ".ini", ".properties", ".conf"]
    some ext in config_extensions
    
    some base in valid_config_patterns
    filename == sprintf("%s%s", [base, ext]) or filename == sprintf("%s-config%s", [base, ext])
}

# Documentation naming rules
deny[msg] {
    is_documentation_file
    not valid_documentation_name
    msg := sprintf("Documentation file '%s' should follow documentation naming conventions", [basename(input.filename)])
}

is_documentation_file {
    doc_extensions := [".md", ".rst", ".txt"]
    some ext in doc_extensions
    endswith(input.filename, ext)
}

valid_documentation_name {
    filename := basename(input.filename)
    
    # README is always valid
    filename == "README.md"
} {
    # Other docs should be Title-Case or kebab-case
    endswith(filename, ".md")
    regex.match("^[A-Z][A-Za-z0-9-_]*\\.md$", filename)  # Title-Case
} {
    endswith(filename, ".md")
    regex.match("^[a-z0-9-]+\\.md$", filename)  # kebab-case
}

# Warning messages (not denials)
warn[msg] {
    # Warn about potentially confusing names
    confusing_name
    msg := sprintf("File '%s' has a potentially confusing name. Consider renaming for clarity", [basename(input.filename)])
}

confusing_name {
    filename := basename(input.filename)
    
    # Check for potentially confusing patterns
    confusing_patterns := [
        "temp",
        "test",
        "old",
        "backup",
        "copy",
        "draft",
        "wip",
        "todo"
    ]
    
    some pattern in confusing_patterns
    contains(lower(filename), pattern)
}

# Utility functions for reporting
get_violations = [msg | deny[msg]]

get_warnings = [msg | warn[msg]]

# Compliance scoring
compliance_score = score {
    total_checks := count([
        "file_naming",
        "resource_naming", 
        "label_requirements",
        "case_conventions",
        "workflow_naming",
        "policy_naming",
        "script_naming",
        "config_naming",
        "documentation_naming"
    ])
    
    passed_checks := total_checks - count(get_violations)
    score := (passed_checks / total_checks) * 100
}

# Summary report
summary = {
    "violations": get_violations,
    "warnings": get_warnings,
    "compliance_score": compliance_score,
    "file_analyzed": input.filename,
    "timestamp": time.now_ns()
}