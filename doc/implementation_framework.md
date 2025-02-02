# Thimble Implementation Framework

This document outlines the framework and strategy for implementing scripts across different programming languages in the Thimble project.

## Core Principles

1. **Functional Equivalence**: Each implementation should provide the same core functionality regardless of language
2. **Language Idioms**: Use language-specific best practices and idioms while maintaining functional equivalence
3. **Consistent Interface**: Maintain consistent command-line interfaces across implementations
4. **Error Handling**: Implement robust error handling following language conventions
5. **Documentation**: Provide clear documentation in a consistent format

## Project Style Guidelines

1. **Repository Structure**
   - Use the existing project repository for all operations
   - Do not create new directories without explicit instruction
   - Follow the established directory structure as documented in project memories
   - Message files and metadata should be tracked in the main repository

2. **Command Execution**
   - All commands must be executed through `thimble.sh`
   - New commands should be added to `thimble.sh` in the command-script pairs section
   - Never execute scripts directly; always use the `t` function from `thimble.sh`
   - Scripts do not need executable permissions (`chmod +x`) since they are executed through their respective interpreters
   - Example: Use `t commit` instead of directly running a commit script

3. **Code Organization**
   - Follow language-specific naming conventions
   - Implement proper error handling
   - Add logging/debugging capabilities
   - Include input validation
   - Add appropriate comments and documentation
   - Write unit tests

## Implementation Checklist

When implementing a script in a new language or adding a new script type, follow this checklist:

### 1. Script Analysis
- [ ] Identify the core functionality from existing implementations
- [ ] List all required input parameters and expected outputs
- [ ] Document external dependencies and system requirements
- [ ] Note any language-specific considerations

### 2. Interface Requirements
- [ ] Command-line argument structure
- [ ] Input validation approach
- [ ] Output format specification
- [ ] Exit codes and error messages
- [ ] Configuration file format (if applicable)

### 3. Implementation Guidelines
- [ ] Follow language-specific naming conventions
- [ ] Implement proper error handling
- [ ] Add logging/debugging capabilities
- [ ] Include input validation
- [ ] Add appropriate comments and documentation
- [ ] Write unit tests

## Template Structure

### Script Header Template
```
"""
[Script Name]
Purpose: [Brief description of the script's purpose]
Usage: [Command-line usage example]

Arguments:
    - arg1: [description]
    - arg2: [description]
    ...

Returns:
    - [Description of return values/exit codes]

Dependencies:
    - [List of required dependencies]

Author: [Author name]
Date: [Creation/Last update date]
"""
```

### Basic Implementation Structure
```
1. Import statements
2. Configuration/Constants
3. Helper functions
4. Main function/class
5. Command-line interface
6. Error handling
7. Main execution block
```

## Language-Specific Guidelines

### Python Implementation
- Use argparse for command-line arguments
- Follow PEP 8 style guide
- Use type hints (Python 3.6+)
- Implement logging using the `logging` module
- Use `pathlib` for file operations

### Node.js Implementation
- Use `commander` or `yargs` for CLI
- Follow StandardJS style
- Use async/await for asynchronous operations
- Implement proper error handling with Error classes
- Use ES6+ features appropriately

### PHP Implementation
- Follow PSR-12 coding standards
- Use composer for dependency management
- Implement proper error handling with Exceptions
- Use type declarations where possible
- Follow SOLID principles

### Perl Implementation
- Use Getopt::Long for argument parsing
- Follow Perl Best Practices
- Implement proper error handling
- Use strict and warnings
- Document with POD

## Implementation Process

1. **Analysis Phase**
   - Review existing implementations
   - Document required functionality
   - Identify language-specific challenges

2. **Development Phase**
   - Create basic structure following template
   - Implement core functionality
   - Add error handling and logging
   - Write tests

3. **Testing Phase**
   - Unit tests
   - Integration tests
   - Cross-platform testing
   - Performance testing

4. **Documentation Phase**
   - Update script header
   - Add usage examples
   - Document any language-specific considerations
   - Update main documentation

## Example Implementation Strategy

### Example: Implementing `commit_files` in a New Language

1. **Review Existing Implementations**
```bash
# Directory structure
template/
  python3/commit_files.py
  node/commit_files.js
  php/commit_files.php
  perl/commit_files.pl
```

2. **Core Functionality Requirements**
- File existence checking
- Git status checking
- File modification detection
- Commit message generation
- Git commit execution
- Error handling and reporting

3. **Common Interface Elements**
```
Input:
  - Directory path
  - [Optional] Commit message
  - [Optional] File patterns to include/exclude

Output:
  - Success/failure status
  - Commit hash (if successful)
  - Error message (if failed)
```

4. **Error Handling Requirements**
- Invalid directory
- Git repository not found
- No changes to commit
- Git command failures
- Permission issues

## Automation Possibilities

1. **Template Generator**
```bash
./generate_implementation.sh [script_name] [language]
```
- Creates basic structure
- Adds standard header
- Implements argument parsing
- Sets up error handling

2. **Test Generator**
```bash
./generate_tests.sh [script_name] [language]
```
- Creates test structure
- Adds basic test cases
- Sets up test environment

3. **Documentation Generator**
```bash
./generate_docs.sh [script_name] [language]
```
- Updates script catalog
- Generates usage documentation
- Updates language-specific docs

## Maintenance Guidelines

1. **Version Control**
- Use semantic versioning
- Maintain changelog
- Tag releases

2. **Testing**
- Run tests before committing
- Maintain test coverage
- Cross-platform testing

3. **Documentation**
- Keep README up to date
- Document breaking changes
- Maintain example usage

4. **Code Review**
- Cross-language review
- Functionality verification
- Style guide compliance

## Next Steps

1. Create template generators for each supported language
2. Implement automated testing framework
3. Set up continuous integration
4. Create documentation generation tools
5. Develop cross-language testing suite
