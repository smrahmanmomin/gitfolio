# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

We take the security of GitFolio seriously. If you discover a security vulnerability, please follow these steps:

### How to Report

1. **DO NOT** open a public issue
2. Email security concerns to: [your-email@example.com]
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### What to Expect

- **Response Time**: We aim to respond within 48 hours
- **Updates**: You'll receive updates on the progress
- **Credit**: Security researchers will be credited (unless you prefer anonymity)

## Security Best Practices

### For Users

1. **OAuth Credentials**: Never share your GitHub OAuth credentials
2. **Environment Variables**: Keep `.env` files secure and never commit them
3. **Browser Security**: Use HTTPS and verify URLs before entering credentials
4. **Token Storage**: Tokens are stored locally - clear browser data when using shared devices

### For Developers

1. **Secrets Management**:
   - Never commit credentials to Git
   - Use environment variables
   - Keep `.env` in `.gitignore`

2. **Dependencies**:
   - Regularly update dependencies
   - Run `flutter pub outdated` to check for updates
   - Monitor security advisories

3. **OAuth Security**:
   - Use state parameter for CSRF protection
   - Validate callback URLs
   - Use HTTPS in production

4. **API Security**:
   - Rate limit API calls
   - Handle errors gracefully
   - Don't expose sensitive data in logs

## Known Security Considerations

### OAuth Token Storage

- Tokens are stored in browser's localStorage/sessionStorage
- Clear session data when using public computers
- Consider implementing token refresh mechanism

### CORS

- App makes requests to GitHub API
- CORS is handled by GitHub's servers
- No server-side proxy in default setup

### XSS Protection

- Flutter web has built-in XSS protections
- User input is sanitized
- No innerHTML usage in custom code

## Security Updates

Security updates will be released as patch versions (e.g., 1.0.1, 1.0.2) and documented in the CHANGELOG.

## Responsible Disclosure

We appreciate the security community's efforts to improve GitFolio's security. We're committed to:

- Acknowledging receipt of your report
- Working with you to understand the issue
- Keeping you informed of our progress
- Crediting you for the discovery (if desired)

Thank you for helping keep GitFolio secure!
