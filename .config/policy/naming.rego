package policy.naming

# Default allow decision
default allow = false

# Allow decision - only true if all checks pass
allow {
    check_naming_conventions
    check_resource_naming
    check_label_standards
}

# Check overall naming conventions
check_naming_conventions {
    # Check that all files follow kebab-case naming
    input.files[_].name matches "^[a-z0-9-]+(\\.(yaml|yml|md|sh|json))?$"
}

# Check resource naming within files
check_resource_naming {
    # Check YAML resource naming
    count(valid_yaml_resources) == count(all_yaml_resources)
}

# Check label standards
check_label_standards {
    # Ensure resources have required labels
    all_resources_have_required_labels
}

# Helper functions for file naming
valid_files = [file | file := input.files[_]; is_valid_filename(file.name)]

is_valid_filename(name) {
    # Allow kebab-case names with appropriate extensions
    matches := regex.match_n("^[a-z0-9-]+(\\.(yaml|yml|md|sh|json))?$", name)
    matches == true
} {
    # Allow special files
    special_files := ["README.md", "LICENSE", "VERSION", "SECURITY.md", "CONTRIBUTING.md", "Makefile", ".gitignore"]
    name == special_files[_]
}

# Helper functions for YAML resources
all_yaml_resources = [resource | file := input.files[_]; is_yaml_file(file.name); resource := yaml.parse(file.content)[_]]

valid_yaml_resources = [resource | resource := all_yaml_resources[_]; is_valid_resource_name(resource)]

is_yaml_file(name) {
    endswith(name, ".yaml") or endswith(name, ".yml")
}

is_valid_resource_name(resource) {
    # Check metadata.name if it exists
    resource.metadata.name != null
    resource.metadata.name matches "^[a-z0-9-]+$"
}

# Helper functions for label checking
all_resources_have_required_labels {
    # Check that all resources have required labels
    every resource in all_yaml_resources {
        has_required_labels(resource)
    }
}

has_required_labels(resource) {
    # Only check resources that have metadata
    resource.metadata != null
    resource.metadata.labels != null
    
    # Check for required labels
    required_labels := ["app.kubernetes.io/name", "app.kubernetes.io/component", "app.kubernetes.io/managed-by"]
    every label in required_labels {
        object.get(resource.metadata.labels, label, null) != null
    }
}

# Violation messages
violation[msg] {
    not is_valid_filename(input.filename)
    msg := sprintf("Invalid filename: %s. Must use kebab-case naming", [input.filename])
}

violation[msg] {
    is_yaml_file(input.filename)
    content := input.files[_].content
    resource := yaml.parse(content)[_]
    resource.metadata.name != null
    not (resource.metadata.name matches "^[a-z0-9-]+$")
    msg := sprintf("Invalid resource name: %s. Must use kebab-case naming", [resource.metadata.name])
}

violation[msg] {
    is_yaml_file(input.filename)
    content := input.files[_].content
    resource := yaml.parse(content)[_]
    resource.metadata != null
    resource.metadata.labels != null
    not has_required_labels(resource)
    msg := "Resource missing required labels: app.kubernetes.io/name, app.kubernetes.io/component, app.kubernetes.io/managed-by"
}

# Additional naming policy rules
check_directory_naming {
    # Ensure directory names follow kebab-case
    all_valid_directories
}

all_valid_directories {
    every dir in input.directories {
        dir.name matches "^[a-z0-9-]+$" or is_special_directory(dir.name)
    }
}

is_special_directory(name) {
    special_dirs := [".git", ".github", ".config", "node_modules", "__pycache__"]
    name == special_dirs[_]
}

# Security naming conventions
check_security_naming {
    # Security-related files should have specific naming
    security_files_have_proper_naming
}

security_files_have_proper_naming {
    every file in input.files {
        is_security_file(file.name) implies has_security_naming(file.name)
    }
}

is_security_file(name) {
    security_patterns := ["policy", "security", "vulnerability", "scan", "audit"]
    some pattern in security_patterns
    contains(lower(name), pattern)
}

has_security_naming(name) {
    # Security files should follow strict naming
    name matches "^[a-z0-9-]+(\\.(policy|security|yaml|yml|rego))?$"
}

# Workflow naming conventions
check_workflow_naming {
    # GitHub Actions workflows should have specific naming
    workflow_files_have_proper_naming
}

workflow_files_have_proper_naming {
    every file in input.files {
        is_workflow_file(file.name) implies has_workflow_naming(file.name)
    }
}

is_workflow_file(name) {
    startswith(name, ".github/workflows/")
    endswith(name, ".yaml") or endswith(name, ".yml")
}

has_workflow_naming(name) {
    # Workflows should be descriptive and use kebab-case
    base_name := basename(name)
    base_name matches "^[a-z0-9-]+$"
    not contains(base_name, "_")
}

# Configuration file naming
check_config_naming {
    # Configuration files should follow naming standards
    config_files_have_proper_naming
}

config_files_have_proper_naming {
    every file in input.files {
        is_config_file(file.name) implies has_config_naming(file.name)
    }
}

is_config_file(name) {
    config_patterns := ["config", "settings", "options", "parameters"]
    some pattern in config_patterns
    contains(lower(name), pattern)
}

has_config_naming(name) {
    # Config files should be clear and specific
    name matches "^[a-z0-9-]+(\\.(yaml|yml|json|toml|ini))?$"
}

# Documentation naming
check_documentation_naming {
    # Documentation files should follow naming standards
    doc_files_have_proper_naming
}

doc_files_have_proper_naming {
    every file in input.files {
        is_doc_file(file.name) implies has_doc_naming(file.name)
    }
}

is_doc_file(name) {
    endswith(name, ".md") or endswith(name, ".rst") or endswith(name, ".txt")
}

has_doc_naming(name) {
    # Docs should be readable and SEO-friendly
    name matches "^[A-Z0-9][A-Za-z0-9-_\\s]*\\.(md|rst|txt)$" or name == "README.md"
}

# Script naming
check_script_naming {
    # Script files should follow naming standards
    script_files_have_proper_naming
}

script_files_have_proper_naming {
    every file in input.files {
        is_script_file(file.name) implies has_script_naming(file.name)
    }
}

is_script_file(name) {
    script_extensions := [".sh", ".py", ".js", ".ts", ".bash", ".zsh"]
    some ext in script_extensions
    endswith(name, ext)
}

has_script_naming(name) {
    # Scripts should use kebab-case for executables
    endswith(name, ".sh") implies name matches "^[a-z0-9-]+\\.sh$"
    endswith(name, ".py") implies name matches "^[a-z0-9_-]+\\.py$"
    endswith(name, ".js") implies name matches "^[a-z0-9_-]+\\.js$"
}

# Environment and namespace naming
check_environment_naming {
    # Environment names should follow standards
    all_valid_environments
}

all_valid_environments {
    every env in input.environments {
        env.name matches "^(dev|development|test|staging|stage|prod|production)$"
    }
}

# Service naming conventions
check_service_naming {
    # Service names should follow domain-driven naming
    all_valid_services
}

all_valid_services {
    every service in input.services {
        service.name matches "^[a-z0-9-]+(-service|-app|-api|-worker)$"
    }
}

# Data resource naming
check_data_naming {
    # Database and data resources should follow naming
    all_valid_data_resources
}

all_valid_data_resources {
    every resource in input.data_resources {
        resource.name matches "^[a-z0-9-]+(-table|-collection|-index|-bucket)$"
    }
}

# Infrastructure naming
check_infrastructure_naming {
    # Infrastructure components should follow naming
    all_valid_infrastructure
}

all_valid_infrastructure {
    every infra in input.infrastructure {
        infra.name matches "^[a-z0-9-]+(-vpc|-subnet|-security-group|-load-balancer|-cluster)$"
    }
}