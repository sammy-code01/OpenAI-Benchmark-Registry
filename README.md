# OpenAI Benchmark Registry

A decentralized, tamper-resistant leaderboard for tracking and verifying AI model performance on standardized tasks.

## Overview

OpenAI Benchmark Registry provides an immutable record of AI model performance across various benchmarks. Results are recorded on-chain and verified by authorized validators, creating a trustless performance tracking system.

## Features

- **Benchmark Creation**: Define standardized AI evaluation tasks
- **Result Submission**: Submit model performance with cryptographic proof
- **Verification System**: Authorized verifiers validate submissions
- **Immutable Records**: All results permanently recorded on blockchain
- **Transparent Rankings**: Public leaderboard based on verified scores

## Contract Functions

### Public Functions

- `create-benchmark`: Create a new benchmark task
- `submit-result`: Submit model performance results
- `verify-submission`: Verify a submission (verifiers only)
- `add-verifier`: Authorize new verifier (owner only)
- `remove-verifier`: Revoke verifier status (owner only)

### Read-Only Functions

- `get-benchmark`: Retrieve benchmark details
- `get-submission`: Get submission information
- `is-verifier`: Check if address is authorized verifier
- `get-benchmark-count`: Total benchmarks created
- `get-submission-count`: Total submissions recorded

## Getting Started
```bash
clarinet contract new benchmark-registry
clarinet check
clarinet test
```

## Workflow

1. Create standardized benchmark with max possible score
2. Developers submit their model results with proof hash
3. Authorized verifiers review and verify submissions
4. Verified results appear on public leaderboard