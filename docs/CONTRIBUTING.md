# Contributing to MATE Desktop Docker

Thank you for considering contributing to this project! Here are some guidelines to help you get started.

## How to Contribute

### Reporting Issues

- Check if the issue already exists before creating a new one
- Use the issue templates if available
- Include relevant details:
  - Your architecture (x86_64 or ARM64)
  - Docker version
  - Operating system
  - Steps to reproduce
  - Expected vs actual behavior
  - Relevant logs from `docker compose logs`

### Submitting Changes

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow the existing code style
   - Test on both x86_64 and ARM64 if possible
   - Update documentation as needed

4. **Test your changes**
   ```bash
   # Build and test locally
   docker compose up -d --build

   # Test on both architectures if possible
   docker buildx build --platform linux/amd64 -t mate-desktop:test-amd64 --load .
   docker buildx build --platform linux/arm64 -t mate-desktop:test-arm64 --load .
   ```

5. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

   Use conventional commit messages:
   - `feat:` for new features
   - `fix:` for bug fixes
   - `docs:` for documentation changes
   - `chore:` for maintenance tasks
   - `refactor:` for code refactoring

6. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create a Pull Request**
   - Describe your changes clearly
   - Reference any related issues
   - Include screenshots if relevant

## Development Guidelines

### Code Style

- Use 4 spaces for indentation in shell scripts
- Keep lines under 100 characters when possible
- Add comments for complex logic
- Follow existing patterns in the codebase

### Documentation

- Update README.md if you add new features
- Add entries to CHANGELOG.md
- Document environment variables
- Include examples where helpful

### Testing

- Test on both architectures when possible
- Verify the container starts successfully
- Check that VNC and noVNC work properly
- Ensure persistent packages reinstall correctly
- Test with a clean volume (no cached data)

### What to Contribute

We welcome contributions in these areas:

- **Bug fixes** - Always appreciated!
- **Documentation improvements** - Clarifications, examples, corrections
- **Performance optimizations** - Faster builds, lower resource usage
- **New features** - Discuss in an issue first for large changes
- **Testing** - Architecture-specific testing, edge cases
- **Examples** - Docker Compose examples, use case documentation

### What Not to Contribute

- Breaking changes without discussion
- Unrelated features outside project scope
- Code that only works on one architecture
- Changes without documentation updates
- Untested changes

## Getting Help

- Open an issue for questions
- Check existing documentation first
- Be patient and respectful

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on the code, not the person
- Help create a welcoming environment

## License

By contributing, you agree that your contributions will be licensed under the MIT License.