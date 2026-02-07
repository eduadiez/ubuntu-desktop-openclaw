# Security Policy

## Supported Versions

We release patches for security vulnerabilities for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Security Considerations

### Intended Use

This Docker container is designed for **local testing and development environments**. Please be aware of the following:

1. **Unencrypted VNC Traffic**: VNC communication is not encrypted by default
2. **No Built-in Authentication**: Beyond the VNC password, there's no additional authentication layer
3. **Root Access**: The desktop user has passwordless sudo access inside the container
4. **Insecure Flag**: The VNC server runs with `--I-KNOW-THIS-IS-INSECURE` flag

### Recommended Security Practices

#### For Local Testing
- Change the default VNC password in `.env` if needed
- Use on localhost or trusted networks only
- Don't expose port 6080 or 5900 to the internet

#### For Remote/Server Use
If deploying on a remote server:

1. **Use SSH Tunneling**
   ```bash
   ssh -L 6080:localhost:6080 user@your-server
   ```

2. **Use a Reverse Proxy with TLS**
   - nginx with Let's Encrypt
   - Caddy with automatic HTTPS
   - Traefik with TLS

3. **Network Isolation**
   - Use Docker networks
   - Implement firewall rules
   - Use VPN for access

4. **Additional Authentication**
   - Add basic auth at reverse proxy level
   - Implement SSO/OAuth if needed

5. **Regular Updates**
   - Keep the base image updated
   - Rebuild periodically to get security patches
   - Update the repository to get latest improvements

---

## Disclaimer

**USE AT YOUR OWN RISK**

This software is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and noninfringement. In no event shall the authors or copyright holders be liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, out of, or in connection with the software or the use or other dealings in the software.

By using this software, you acknowledge that:
- You understand the security limitations described in this document
- You are solely responsible for securing your deployment
- You accept all risks associated with using this software
- The maintainers are not responsible for any data loss, security breaches, or other issues

---

**Note**: This security policy applies to the Docker container configuration and scripts in this repository. The included software (Ubuntu, MATE Desktop, Brave, TigerVNC, noVNC) has its own security policies and should be kept updated through regular image rebuilds.