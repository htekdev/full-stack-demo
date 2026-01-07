# Contributing to Full Stack Demo

Thank you for your interest in contributing! This document provides guidelines and information for contributors.

## How to Contribute

### Reporting Issues

- Use GitHub Issues to report bugs or request features
- Provide detailed information about the issue
- Include steps to reproduce for bugs
- Include your environment details (OS, Node version, etc.)

### Submitting Changes

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**
4. **Test your changes locally**
5. **Commit with clear messages**
   ```bash
   git commit -m "Add: feature description"
   ```
6. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```
7. **Open a Pull Request**

## Development Setup

### Prerequisites

- Node.js 20.x
- Azure CLI
- Terraform 1.7.0+
- Azure Functions Core Tools (for local function testing)

### Local Development

#### Frontend Development

```bash
cd frontend
npm install
npm start
```

Frontend will run on http://localhost:3000

#### Backend Development

```bash
cd api
npm install
npm start
```

Functions will run on http://localhost:7071

#### Infrastructure Development

```bash
cd infra
terraform init
terraform plan
```

## Code Style Guidelines

### JavaScript/React

- Use functional components with hooks
- Follow ESLint rules
- Use meaningful variable names
- Add comments for complex logic
- Keep functions small and focused

### Terraform

- Use `terraform fmt` to format code
- Add comments for complex resources
- Use variables for configurable values
- Follow HCL naming conventions
- Document outputs with descriptions

### GitHub Actions

- Use descriptive job and step names
- Add comments for complex workflows
- Use environment variables for configuration
- Keep secrets in GitHub Secrets

## Testing

### Frontend Testing

```bash
cd frontend
npm test
```

### Function Testing

```bash
# Test locally running functions
curl http://localhost:7071/api/hello?name=Test
curl http://localhost:7071/api/healthcheck
```

### Infrastructure Testing

```bash
cd infra
terraform validate
terraform plan
```

## Documentation

- Update README.md for significant changes
- Add JSDoc comments for complex functions
- Update SETUP_GUIDE.md if setup process changes
- Include inline comments for complex code

## Pull Request Guidelines

### PR Title Format

Use conventional commits format:
- `feat: Add new feature`
- `fix: Fix bug in component`
- `docs: Update documentation`
- `chore: Update dependencies`
- `refactor: Refactor code`

### PR Description

Include:
- Summary of changes
- Related issue numbers
- Testing performed
- Screenshots (for UI changes)
- Breaking changes (if any)

### PR Checklist

- [ ] Code follows project style guidelines
- [ ] Changes have been tested locally
- [ ] Documentation has been updated
- [ ] Commit messages are clear
- [ ] No sensitive data in commits
- [ ] Tests pass (if applicable)

## Architecture Decisions

### Why These Choices?

1. **React**: Modern, widely-used, great ecosystem
2. **Azure Functions**: Serverless, cost-effective, scalable
3. **Static Web Apps**: Free tier, integrated hosting, easy deployment
4. **Terraform**: Infrastructure as Code, version control, reproducible
5. **GitHub Actions**: Native CI/CD, free for public repos, OIDC support

### Adding New Features

#### Adding a New React Component

1. Create component file in `frontend/src/components/`
2. Import and use in `App.js`
3. Add styles in corresponding `.css` file
4. Test locally before committing

#### Adding a New Azure Function

1. Create function file in `api/src/functions/`
2. Use Azure Functions v4 programming model
3. Test locally with Functions Core Tools
4. Update API documentation

#### Adding Infrastructure

1. Add resources to `infra/main.tf`
2. Add required variables to `infra/variables.tf`
3. Add outputs to `infra/outputs.tf`
4. Run `terraform plan` to verify
5. Update documentation

## Security

### Security Best Practices

- Never commit secrets or credentials
- Use environment variables for sensitive data
- Keep dependencies updated
- Use HTTPS for all endpoints
- Implement proper authentication where needed
- Review Azure security recommendations

### Reporting Security Issues

Please report security issues privately to the maintainers, not in public issues.

## Code of Conduct

### Our Pledge

We pledge to make participation in our project a harassment-free experience for everyone.

### Our Standards

- Be respectful and inclusive
- Accept constructive criticism
- Focus on what's best for the community
- Show empathy towards others

### Unacceptable Behavior

- Harassment or discrimination
- Trolling or insulting comments
- Publishing others' private information
- Any unprofessional conduct

## Community

- GitHub Discussions: Ask questions, share ideas
- GitHub Issues: Report bugs, request features
- Pull Requests: Contribute code

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (MIT License).

## Questions?

If you have questions about contributing, feel free to:
- Open a Discussion
- Comment on relevant Issues
- Ask in Pull Requests

Thank you for contributing! 🎉
