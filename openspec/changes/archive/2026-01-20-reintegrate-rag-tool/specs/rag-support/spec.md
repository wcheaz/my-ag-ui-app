# RAG Support

## ADDED Requirements

### Requirement: Robust Index Loading
The system MUST attempt to load the RAG index from multiple potential locations to support various execution contexts.

#### Scenario: Running from Project Root
Given the agent is executed from the project root
When the RAG system initializes
Then it should successfully locate the index in `agent/data/storage`

#### Scenario: Running from Agent Directory
Given the agent is executed from the `agent/` directory
When the RAG system initializes
Then it should successfully locate the index in `../agent/data/storage` or `data/storage`
