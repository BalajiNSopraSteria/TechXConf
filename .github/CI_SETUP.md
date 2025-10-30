# GitHub Actions CI Setup

## Overview

This repository includes a comprehensive CI/CD pipeline that validates Terraform configurations across multiple cloud providers (AWS, Azure, Google Cloud).

## CI Workflow Jobs

### 1. Terraform Validation
- **Purpose**: Validates Terraform syntax and configuration
- **Runs on**: All directories (aws, azure, google, more_examples)
- **Checks**:
  - Terraform format compliance (`terraform fmt`)
  - Terraform initialization
  - Configuration validation (`terraform validate`)

### 2. Terraform Lint (TFLint)
- **Purpose**: Enforces best practices and catches common errors
- **Tool**: [TFLint](https://github.com/terraform-linters/tflint)
- **Runs on**: All Terraform directories

### 3. Security Scan (tfsec)
- **Purpose**: Identifies potential security issues in Terraform code
- **Tool**: [tfsec](https://github.com/aquasecurity/tfsec)
- **Runs on**: Entire repository
- **Mode**: Soft fail (warns but doesn't block)

### 4. Infracost Analysis
- **Purpose**: Estimates cloud infrastructure costs
- **Trigger**: Pull requests only
- **Features**:
  - Cost breakdown for AWS, Azure, and Google Cloud
  - Automated PR comments with cost estimates
  - Uses custom usage files for accurate estimates

### 5. Code Quality Checks
- **Checks**:
  - Trailing whitespace detection
  - Markdown linting

### 6. CI Summary
- **Purpose**: Aggregates results from all jobs
- **Behavior**: Fails if critical checks (validation, lint) fail

## Triggers

The CI workflow runs on:
- **Push** to `main` or `develop` branches
- **Pull requests** targeting `main` or `develop` branches
- **Manual trigger** via workflow_dispatch

## Required Secrets

To enable all features, configure the following secrets in your repository settings:

### INFRACOST_API_KEY
Get your API key from [Infracost](https://www.infracost.io/):
1. Sign up at https://dashboard.infracost.io
2. Generate an API key
3. Add it to GitHub: Settings → Secrets and variables → Actions → New repository secret

## Local Development

### Prerequisites
- Terraform CLI
- TFLint
- tfsec (optional)
- Infracost CLI (optional)

### Running Checks Locally

#### Format Check
```bash
terraform fmt -check -recursive
```

#### Validation
```bash
cd aws  # or azure, google, more_examples
terraform init -backend=false
terraform validate
```

#### Linting
```bash
cd aws
tflint --init
tflint
```

#### Security Scan
```bash
tfsec .
```

#### Cost Estimation
```bash
infracost breakdown --path=aws --usage-file=aws/infracost-usage.yml
```

## Customization

### Adding New Directories
To include additional Terraform directories in the CI pipeline, update the matrix strategy in `.github/workflows/ci.yml`:

```yaml
strategy:
  matrix:
    directory: [aws, azure, google, more_examples, your_new_directory]
```

### Modifying Security Rules
Create a `.tfsec/config.yml` file to customize tfsec rules.

### Adjusting Cost Usage
Edit the `infracost-usage.yml` files in each directory to reflect your expected resource usage patterns.

## Badges

Add CI status badges to your README:

```markdown
![CI](https://github.com/BalajiNSopraSteria/TechXConf/workflows/CI/badge.svg)
```

## Troubleshooting

### Terraform Format Failures
Run `terraform fmt -recursive` to automatically fix formatting issues.

### TFLint Errors
Review the [TFLint documentation](https://github.com/terraform-linters/tflint/tree/master/docs/rules) for specific rule guidance.

### Infracost Not Working
- Verify the `INFRACOST_API_KEY` secret is set correctly
- Check that usage files exist for each directory
- Ensure the Infracost service is accessible

## Best Practices

1. **Always run format before committing**: `terraform fmt -recursive`
2. **Test locally before pushing**: Run validation and lint checks
3. **Review security warnings**: Address tfsec findings even if soft-fail is enabled
4. **Monitor costs**: Review Infracost reports on PRs to understand cost impacts
5. **Keep dependencies updated**: Regularly update Terraform and tool versions

## Support

For issues or questions:
- GitHub Actions logs: Check the Actions tab in the repository
- Terraform: https://developer.hashicorp.com/terraform/docs
- TFLint: https://github.com/terraform-linters/tflint
- tfsec: https://github.com/aquasecurity/tfsec
- Infracost: https://www.infracost.io/docs/
