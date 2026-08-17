# AquaVerse AI - Work Procedure

This document outlines the standard operating procedure for starting and running the complete AquaVerse AI stack locally for development.

## Prerequisites
- **Python 3.11+**
- **uv** (Python package manager)
- **Docker & Docker Compose** (for infrastructure)
- **Node.js & npm** (for the frontend Digital Twin)

---

## 1. Setup Environment (First Time Only)

Initialize the Python virtual environment and install all dependencies:
```bash
make install
```

Set up the database and run migrations:
```bash
make db-setup
```

*(This will run Alembic migrations and seed the database with required default data via `scripts/seed_db.py`).*

---

## 2. Start Infrastructure (Docker)

Start the supporting infrastructure (Redis, MinIO, Keycloak, etc.):
```bash
docker compose -f infra/docker-compose.yml up -d
```
> **Note:** If you run into port `8000` conflicts when starting the backend later, ensure the backend container defined in docker-compose is either removed or stopped, as we run the backend locally during development.

---

## 3. Start the Backend API

Run the main FastAPI backend server on port `8000`:
```bash
make run
```
*The server will start at `http://0.0.0.0:8000` with hot-reloading enabled.*

---

## 4. Start the ML Model Serving (M3)

The M3 machine learning models run as a separate microservice. Open a new terminal and run:
```bash
cd ml/serving/m3
../../../.venv/bin/uvicorn serve_m3:app --host 0.0.0.0 --port 8001 --reload
```
*The ML serving API will be accessible at `http://0.0.0.0:8001`.*

---

## 5. Start the Digital Twin Frontend

To connect the React/Vite Digital Twin frontend, ensure you update its `.env` to point to the backend's local network IP.

1. **Update Frontend `.env`**:
   ```env
   # Replace with your backend PC's local IP address
   VITE_API_URL=http://<BACKEND_IP>:8000
   ```

2. **Start the Frontend**:
   ```bash
   npm run dev -- --host
   ```
*The frontend will run on `http://localhost:5173` and will be accessible across the local network.*

---

## 6. Accessing the Twin Visual Dashboard (Backend)

The backend provides a fallback HTML visual dashboard for the twin state at:
```text
http://localhost:8000/v1/twin/<pond_id>/view
```
*(Example: `http://localhost:8000/v1/twin/123e4567-e89b-12d3-a456-426614174000/view`)*

---

## Useful Commands

| Command | Description |
|---|---|
| `make test` | Run all pytest unit and integration tests |
| `make lint` | Run the Ruff linter |
| `make format` | Auto-format codebase with Ruff |
| `make typecheck` | Run MyPy strict type checking |
| `make check` | Run linter + type checks (CI equivalent) |
