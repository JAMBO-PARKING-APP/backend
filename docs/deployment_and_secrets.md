# 🐳 Docker Deployment & 🔐 Secrets Management Guide

This guide provides a deep-dive into the containerization strategy and security protocols used for JAMBO PARK.

---

## 🟢 1. Docker Deployment Workflow

We use Docker to ensure that the development, staging, and production environments are 100% identical.

### 1.1 Local Development (Dev Containers)
For local development, use **Docker Compose**. This spins up Django, PostgreSQL, Redis, and Celery in isolation.

```bash
# 1. Build and start all services
docker-compose up --build

# 2. Run migrations (in a separate terminal)
docker-compose exec web python manage.py migrate

# 3. Create an admin user
docker-compose exec web python manage.py createsuperuser
```

### 1.2 Production Image Optimization
The `Dockerfile` is optimized for production:
- **python:3.11-slim**: Uses a minimal base image to reduce attack surface and build time.
- **Dependency Caching**: Layers are ordered to cache `pip install` steps unless `requirements.txt` changes.
- **Environment Isolation**: `PYTHONDONTWRITEBYTECODE` and `PYTHONUNBUFFERED` ensure logs are real-time and no junk files are generated.

---

## 🔐 2. Secrets Management Strategy

Never commit hardcoded secrets (API keys, passwords, tokens) to version control. JAMBO PARK uses a multi-layered approach to secret security.

### 2.1 The `.env` Hierarchy
1.  **`.env.example`**: Committed to Git. Contains only variable names, acting as a template.
2.  **`.env`**: **NEVER COMMITTED**. Stored locally and injected into the container at runtime.

### 2.2 Secret Injection Methods

| Environment | Method | Description |
|-------------|--------|-------------|
| **Local** | `env_file` in Compose | Docker automatically reads `.env` and makes keys available to Django. |
| **CI/CD** | GitHub Actions Secrets | Encrypted at rest, injected into build pipelines via `${{ secrets.VAR_NAME }}`. |
| **Production** | Render Secret Groups | Render uses a centralized "Secret Group" that is shared across the API, Worker, and Beat services. |

### 2.3 Required Keys for JAMBO PARK

| Key | Example / Usage | Why is it a secret? |
|-----|-----------------|-------------------|
| `SECRET_KEY` | `django-insecure-...` | Used for session signing and CSRF tokens. |
| `DB_PASSWORD` | `jambo_admin_pass` | Password for the PostgreSQL cluster. |
| `PESAPAL_SECRET`| `pesapal_api_key_xxx` | Grants access to your payment accounts. |
| `GOOGLE_API_KEY`| `gemini_api_key_xxx` | Access to the Gemini AI models. |
| `FIREBASE_JSON` | `path/to/service.json`| Infrastructure access to push notifications. |

---

## 🚀 3. Best Practices for High-Security Systems

1.  **Rotation Policy**: Rotate `SECRET_KEY` and API keys every 90 days.
2.  **Least Privilege**: The Database user (`jambo_admin`) should only have access to its own database, not the entire PostgreSQL instance.
3.  **Audit Logs**: Enable Render/AWS/GCP logs to track who accessed the secret management dashboard.
4.  **No `DEBUG=True` in Prod**: Setting `DEBUG=False` ensures that detailed error traces (which might leak env vars) are never shown to users.

---
*© 2026 JAMBO PARK Solutions. Confidential and Proprietary.*
