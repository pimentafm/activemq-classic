# ActiveMQ Classic - Docker Compose

Docker Compose project to run Apache ActiveMQ Classic, optimized for local and Coolify deployment.

## Table of Contents

- [Features](#features)
- [Exposed Ports](#exposed-ports)
- [Quick Start](#quick-start)
- [Local Usage](#local-usage)
- [Coolify Deployment](#coolify-deployment)
- [Connecting to ActiveMQ](#connecting-to-activemq)
- [Advanced Configuration](#advanced-configuration)
- [Security](#security)
- [Backup and Recovery](#backup-and-recovery)
- [Troubleshooting](#troubleshooting)
- [Resources](#resources)

## Features

- **ActiveMQ Classic** latest version (6.2.0)
- **Multiple protocols** supported: OpenWire, AMQP, STOMP, MQTT, WebSocket
- **Web Console** for administration
- **Data persistence** with Docker volumes
- **Health checks** configured
- **Makefile** with convenient commands
- **Environment variables** for easy configuration
- **Production-ready** for Coolify

## Exposed Ports

| Port  | Protocol  | Description                             |
| ----- | --------- | --------------------------------------- |
| 61616 | OpenWire  | JMS (default for Java clients)          |
| 5672  | AMQP      | Advanced Message Queuing Protocol       |
| 61613 | STOMP     | Simple Text Oriented Messaging Protocol |
| 1883  | MQTT      | Message Queuing Telemetry Transport     |
| 61614 | WebSocket | WebSocket                               |
| 8161  | HTTP      | Web Admin Console                       |

## Quick Start

### Initial Setup (First Time)

```bash
# Install and start
make install

# View logs
make logs
```

**Access console:**
- URL: http://localhost:8161/admin
- Username: `admin`
- Password: `admin`

### Makefile Commands

```bash
make                 # Show all available commands
make up              # Start ActiveMQ
make down            # Stop ActiveMQ
make logs            # Show real-time logs
make console         # Open web console in browser
make status          # Show container status
make restart         # Restart ActiveMQ
make shell           # Open shell in container
make info            # Show information and ports
make health          # Check container health
make clean           # Remove containers and volumes
make pull            # Update ActiveMQ image
make stats           # Show CPU/memory usage
```

## Local Usage

### Direct Docker Compose Commands

If you prefer not to use the Makefile:

**1. Configure environment variables:**

```bash
cp .env.example .env
# Edit the .env file as needed
```

**2. Start ActiveMQ:**

```bash
docker compose up -d
```

**3. Access Web Console:**

Open: `http://localhost:8161/admin`

**Default credentials:**
- Username: `admin`
- Password: `admin`

⚠️ **IMPORTANT**: Change credentials in production!

**4. Check logs:**

```bash
docker compose logs -f activemq
```

**5. Stop ActiveMQ:**

```bash
docker compose down
```

### Important Technical Configuration

This project is configured to solve common ActiveMQ 6.2.0 issues:

**1. Jetty listening on all interfaces:**
```yaml
-Djetty.host=0.0.0.0
```
By default, Jetty listens only on `127.0.0.1` inside the container, preventing external access.

**2. Explicit JAAS configuration:**
```yaml
-Djava.security.auth.login.config=/opt/apache-activemq/conf/login.config
```
Required for authentication to work correctly.

These settings are in `docker-compose.yml` via `ACTIVEMQ_OPTS`.

## Coolify Deployment

### Option 1: Via Git Repository

**Step 1: Prepare Repository**

```bash
# Initialize Git repository
git init
git add .
git commit -m "Initial commit - ActiveMQ Docker setup"

# Add remote and push
git remote add origin <your-repository-url>
git push -u origin main
```

**Step 2: Configure in Coolify**

1. Access Coolify dashboard
2. Go to **"Services"** → **"+ New Service"**
3. Choose **"Docker Compose"**
4. Connect to your Git repository
5. Select `main` branch

**Step 3: Configure Environment Variables**

In Coolify dashboard, add:

```bash
# Memory Settings
ACTIVEMQ_MIN_MEMORY=1G
ACTIVEMQ_MAX_MEMORY=4G

# Admin Credentials (CHANGE THESE VALUES!)
ACTIVEMQ_ADMIN_USER=admin_production
ACTIVEMQ_ADMIN_PASSWORD=your_super_secure_password_123!@#

# Broker Name
ACTIVEMQ_BROKER_NAME=production-broker

# Ports (use defaults)
ACTIVEMQ_OPENWIRE_PORT=61616
ACTIVEMQ_AMQP_PORT=5672
ACTIVEMQ_STOMP_PORT=61613
ACTIVEMQ_MQTT_PORT=1883
ACTIVEMQ_WS_PORT=61614
ACTIVEMQ_ADMIN_PORT=8161
```

**Step 4: Configure Domain**

1. Set up a domain for the service (e.g., `activemq.yourdomain.com`)
2. Coolify will automatically create reverse proxy with HTTPS
3. Configure proxy to port **8161** (Web Console)

**Step 5: Deploy**

1. Click **"Deploy"**
2. Wait for container to start (a few minutes)
3. Check logs

**Step 6: Access**

- URL: `https://activemq.yourdomain.com/admin`
- Use configured credentials

### Option 2: Direct Deploy (without Git)

1. In Coolify: **"Services"** → **"+ New Service"** → **"Docker Compose"**
2. Choose **"Paste Docker Compose"**
3. Paste `docker-compose.yml` content:

```yaml
services:
  activemq:
    image: apache/activemq-classic:latest
    container_name: activemq
    restart: unless-stopped

    ports:
      - "${ACTIVEMQ_OPENWIRE_PORT:-61616}:61616"
      - "${ACTIVEMQ_AMQP_PORT:-5672}:5672"
      - "${ACTIVEMQ_STOMP_PORT:-61613}:61613"
      - "${ACTIVEMQ_MQTT_PORT:-1883}:1883"
      - "${ACTIVEMQ_WS_PORT:-61614}:61614"
      - "${ACTIVEMQ_ADMIN_PORT:-8161}:8161"

    environment:
      ACTIVEMQ_OPTS: "-Xms${ACTIVEMQ_MIN_MEMORY:-512M} -Xmx${ACTIVEMQ_MAX_MEMORY:-2G} -Djetty.host=0.0.0.0 -Djava.security.auth.login.config=/opt/apache-activemq/conf/login.config"
      ACTIVEMQ_ADMIN_LOGIN: ${ACTIVEMQ_ADMIN_USER:-admin}
      ACTIVEMQ_ADMIN_PASSWORD: ${ACTIVEMQ_ADMIN_PASSWORD:-admin}
      ACTIVEMQ_BROKER_NAME: ${ACTIVEMQ_BROKER_NAME:-localhost}

    volumes:
      - activemq_data:/opt/apache-activemq/data

    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:8161/ || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

    networks:
      - activemq_network

volumes:
  activemq_data:
    driver: local

networks:
  activemq_network:
    driver: bridge
```

4. Configure environment variables (see Step 3 from Option 1)
5. Deploy

### Expose Additional Ports in Coolify

If you need to access other ports besides 8161, configure in **"Network"** panel:

- **61616** (OpenWire/JMS): For Java clients
- **5672** (AMQP): For AMQP clients
- **61613** (STOMP): For STOMP clients
- **1883** (MQTT): For MQTT clients
- **61614** (WebSocket): For WebSocket clients

### Common Issue: Domain Not Working (503 Error)

**Problem:** Domain returns "Server Not Available" but direct IP works.

**Symptoms:**
- ✅ Works: `http://YOUR-IP:8161`
- ❌ Doesn't work: `https://your-domain.com`

**Solution:**

1. In Coolify, go to your ActiveMQ service
2. Click **"Domains"** tab
3. Configure:
   - **Domain:** `your-domain.com`
   - **Port:** `8161`
   - **Scheme:** `http` (Coolify adds HTTPS)
   - **Path:** `/`
4. Enable **"Generate Let's Encrypt Certificate"**
5. Click **"Save"** and **"Redeploy"**
6. Wait 2-3 minutes and test

## Connecting to ActiveMQ

### Connection URLs (Production)

```
OpenWire (JMS): tcp://activemq.yourdomain.com:61616
AMQP:           amqp://activemq.yourdomain.com:5672
STOMP:          stomp://activemq.yourdomain.com:61613
MQTT:           mqtt://activemq.yourdomain.com:1883
```

### Code Examples

**Java (OpenWire/JMS):**

```java
String brokerUrl = "tcp://your-domain.com:61616";
ConnectionFactory factory = new ActiveMQConnectionFactory(brokerUrl);
Connection connection = factory.createConnection();
connection.start();
```

**Python (STOMP):**

```python
import stomp

conn = stomp.Connection([('your-domain.com', 61613)])
conn.connect('admin', 'admin', wait=True)

# Send message
conn.send(body='Hello World', destination='/queue/test')

# Disconnect
conn.disconnect()
```

**Node.js (STOMP):**

```javascript
const Stomp = require("stompjs");

const client = Stomp.overTCP("your-domain.com", 61613);

client.connect("admin", "admin", () => {
  console.log("Connected to ActiveMQ");

  // Send message
  client.send("/queue/test", {}, "Hello World");
});
```

## Advanced Configuration

### Adjust Memory

Edit `.env` file:

```bash
ACTIVEMQ_MIN_MEMORY=512M
ACTIVEMQ_MAX_MEMORY=2G
```

**Recommendations:**
- **Development**: 512M - 1G
- **Small Production**: 1G - 2G
- **Medium Production**: 2G - 4G
- **Large Production**: 4G - 8G

After changing, restart:
```bash
make restart
```

### Customize ActiveMQ Configuration

**1. Create configuration directory:**

```bash
mkdir -p conf
```

**2. Copy configuration files:**

```bash
# Copy from running container
docker compose exec activemq cat /opt/apache-activemq/conf/activemq.xml > conf/activemq.xml
docker compose exec activemq cat /opt/apache-activemq/conf/jetty.xml > conf/jetty.xml
```

**3. Edit as needed**

**4. Uncomment volumes in `docker-compose.yml`:**

```yaml
volumes:
  - activemq_data:/opt/apache-activemq/data
  - ./conf/activemq.xml:/opt/apache-activemq/conf/activemq.xml:ro
  - ./conf/jetty.xml:/opt/apache-activemq/conf/jetty.xml:ro
```

**5. Restart:**

```bash
make restart
```

### Customize Credentials (Advanced Method)

**1. Copy authentication files:**

```bash
mkdir -p conf
docker compose exec activemq cat /opt/apache-activemq/conf/users.properties > conf/users.properties
docker compose exec activemq cat /opt/apache-activemq/conf/groups.properties > conf/groups.properties
```

**2. Edit `conf/users.properties`:**

```properties
# Format: username=password
admin=new_strong_password
user2=another_password
```

**3. Edit `conf/groups.properties`:**

```properties
# Format: group=user1,user2
admins=admin
users=user2
```

**4. Mount in docker-compose.yml:**

```yaml
volumes:
  - activemq_data:/opt/apache-activemq/data
  - ./conf/users.properties:/opt/apache-activemq/conf/users.properties:ro
  - ./conf/groups.properties:/opt/apache-activemq/conf/groups.properties:ro
```

**5. Restart:**

```bash
make restart
```

## Security

### Production Recommendations

✅ **Required:**

1. **Change default credentials**
   ```bash
   ACTIVEMQ_ADMIN_USER=custom_admin
   ACTIVEMQ_ADMIN_PASSWORD=very_strong_password_123!@#
   ```

2. **Use HTTPS** (Coolify configures automatically)

3. **Restrict port access** via firewall

4. **Configure regular backups** of `activemq_data` volume

5. **Monitor logs** for unauthorized access

6. **Update regularly** Docker image:
   ```bash
   make pull
   make rebuild
   ```

### Security Checklist

- [ ] Password changed to strong value
- [ ] HTTPS configured (if production)
- [ ] Firewall configured
- [ ] Automatic backup configured
- [ ] Log monitoring active
- [ ] Non-essential ports blocked
- [ ] Persistent volumes configured

## Backup and Recovery

### Create Backup

**Via SSH on server:**

```bash
docker run --rm \
  -v activemq-docker_activemq_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/activemq-backup-$(date +%Y%m%d).tar.gz /data
```

This creates an `activemq-backup-YYYYMMDD.tar.gz` file with all data.

### Restore Backup

**1. Upload backup file to server**

**2. Restore:**

```bash
docker run --rm \
  -v activemq-docker_activemq_data:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/activemq-backup-YYYYMMDD.tar.gz -C /
```

**3. Restart service:**

```bash
make restart
# or in Coolify, redeploy
```

### Automatic Backup

Add to server crontab:

```bash
# Edit crontab
crontab -e

# Add line (daily backup at 2 AM)
0 2 * * * docker run --rm -v activemq-docker_activemq_data:/data -v /backups:/backup alpine tar czf /backup/activemq-backup-$(date +\%Y\%m\%d).tar.gz /data
```

## Troubleshooting

### Web Console Inaccessible

**Symptom:** Cannot access `http://localhost:8161/admin`

**Checks:**

1. **Is container running?**
   ```bash
   make status
   # or
   docker compose ps
   ```

2. **Test HTTP connection:**
   ```bash
   curl -I http://localhost:8161/
   ```
   Should return `HTTP/1.1 401 Unauthorized` (requesting authentication)

3. **Test with credentials:**
   ```bash
   curl -u admin:admin http://localhost:8161/admin/
   ```
   Should return HTML from console

4. **Check if Jetty is on 0.0.0.0:**
   ```bash
   docker compose logs activemq | grep "WebConsole available"
   ```
   Should show: `ActiveMQ WebConsole available at http://0.0.0.0:8161/`

5. **View complete logs:**
   ```bash
   make logs
   ```

**Solution:** If still not working, verify `ACTIVEMQ_OPTS` settings are correct in `docker-compose.yml`.

### Container Won't Start

**Check logs:**
```bash
docker compose logs activemq
```

**Common causes:**
- Insufficient server memory
- Port already in use
- Incorrect environment variables
- Corrupted volume

**Solutions:**
```bash
# Recreate from scratch
make clean-force
make up

# Check memory usage
make stats
```

### Memory Error

**Symptom:** Logs show `OutOfMemoryError`

**Solution:** Increase memory in `.env`:

```bash
ACTIVEMQ_MIN_MEMORY=1G
ACTIVEMQ_MAX_MEMORY=4G
```

Restart:
```bash
make restart
```

### Poor Performance

**Diagnosis:**

```bash
# View statistics
make stats

# View health
make health

# Check error logs
make logs | grep ERROR
```

**Solutions:**
1. Increase `ACTIVEMQ_MAX_MEMORY`
2. Increase server resources
3. Clear accumulated messages (via web console)
4. Check persistence settings

### Authentication Failing

**Symptom:** HTTP 401 even with correct credentials

**Cause:** JAAS configuration not loaded

**Verify:** Confirm `ACTIVEMQ_OPTS` in `docker-compose.yml` contains:
```
-Djava.security.auth.login.config=/opt/apache-activemq/conf/login.config
```

**Solution:**
```bash
# Recreate container
make down
make up
```

### Connectivity Tests

```bash
# Test web console port
curl -I http://localhost:8161/

# Test OpenWire port
nc -zv localhost 61616

# Test STOMP port
nc -zv localhost 61613

# Test MQTT port
nc -zv localhost 1883
```

## Resources

### Official Documentation

- [ActiveMQ Classic](https://activemq.apache.org/components/classic/)
- [ActiveMQ Security](https://activemq.apache.org/security)
- [ActiveMQ Performance Tuning](https://activemq.apache.org/performance-tuning)
- [Jetty JAAS](https://www.eclipse.org/jetty/documentation/current/jaas-support.html)
- [Coolify Docs](https://coolify.io/docs/)

### Docker Images

- [Apache ActiveMQ Classic - Docker Hub](https://hub.docker.com/r/apache/activemq-classic)

### Useful Commands

```bash
# View all Makefile commands
make help

# Complete environment information
make info

# Enter container
make shell

# Execute custom command
make exec CMD="ls -la /opt/apache-activemq/conf"

# Update ActiveMQ
make update
```

## Project Structure

```
activemq-docker/
├── docker-compose.yml    # Docker Compose configuration
├── Makefile             # Convenient commands
├── .env                 # Environment variables (do not version!)
├── .env.example         # Environment variables example
├── .gitignore          # Files ignored by Git
├── README.md           # This documentation
└── conf/               # Custom configurations (optional)
    ├── activemq.xml
    ├── jetty.xml
    ├── users.properties
    └── groups.properties
```

## License

This project is provided as is, without warranties.

---

**Developed to facilitate ActiveMQ Classic deployment with Docker and Coolify.**

For questions or issues, consult the [Troubleshooting](#troubleshooting) section or [official documentation](https://activemq.apache.org/).
