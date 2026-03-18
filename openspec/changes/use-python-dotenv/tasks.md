## 1. Dependency Setup

- [x] 1.1 Add python-dotenv to agent/pyproject.toml dependencies
- [ ] 1.2 Install python-dotenv in development environment

## 2. Code Changes

- [ ] 2.1 Remove custom load_env function from agent.py (lines 90-106)
- [ ] 2.2 Add from dotenv import load_dotenv import to agent.py imports section
- [ ] 2.3 Replace load_env call with load_dotenv call at line 109
- [ ] 2.4 Remove comment about manual env loading (lines 87-88)
- [ ] 2.5 Remove custom load_env_file function from agent/src/rag/settings.py (lines 8-26)
- [ ] 2.6 Add from dotenv import load_dotenv import to agent/src/rag/settings.py
- [ ] 2.7 Replace load_env_file call with load_dotenv call in agent/src/rag/settings.py init_settings function

## 3. Testing

- [ ] 3.1 Verify agent starts without errors after changes
- [ ] 3.2 Confirm environment variables are loaded correctly from .env file
- [ ] 3.3 Test that all agent tools work correctly with loaded environment variables
- [ ] 3.4 Test with various .env file formats (simple values, quoted values, comments)
- [ ] 3.5 Run existing test suite to ensure no regressions

## 4. Validation

- [ ] 4.1 Verify no performance degradation in agent startup time
- [ ] 4.2 Check for security vulnerabilities in python-dotenv dependency
- [ ] 4.3 Confirm backward compatibility with existing .env files
- [ ] 4.4 Test edge cases (multiline values, quoted strings with =, comments)

## 5. Deployment

- [ ] 5.1 Commit dependency changes to version control
- [ ] 5.2 Commit code changes to version control
- [ ] 5.3 Update CHANGELOG with migration notes
- [ ] 5.4 Deploy to production environment
- [ ] 5.5 Monitor for any issues after deployment
