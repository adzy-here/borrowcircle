# BorrowCircle

BorrowCircle is a neighbourhood borrowing app with a FastAPI + MySQL backend and a plain HTML/CSS/JavaScript frontend. FastAPI serves both the API and the files in `web/`, so local development uses one server at `http://localhost:8000`.

## Run on localhost (Windows PowerShell)

### 1. Install prerequisites

- Install Python 3.10 or later and MySQL 8.0 or later. Ensure `python` and `mysql` are available in PowerShell. If `mysql` is not on PATH, use the full path to `mysql.exe` from your MySQL installation.
- Get a Gemini API key from [Google AI Studio](https://aistudio.google.com/apikey). The current backend requires this key to start, even if you do not use its AI features.

### 2. Create the database

From the project folder, open the MySQL client as an administrator:

```powershell
mysql -u root -p
```

At the `mysql>` prompt, load the schema (use your actual project path):

```sql
SOURCE C:/Users/ADVITH/OneDrive/Desktop/borrow_final/database.sql;
```

Create an application user and grant it access. Replace the example password with a strong password of your choice:

```sql
CREATE USER 'borrowcircle_app'@'localhost' IDENTIFIED BY 'replace-with-a-strong-password';
GRANT ALL PRIVILEGES ON borrowcircle.* TO 'borrowcircle_app'@'localhost';
```

Then type `exit` to close the MySQL client.

### 3. Configure environment variables

```powershell
Copy-Item .env.example .env
notepad .env
```

Set `DB_PASSWORD` to the MySQL application user's password, set `JWT_SECRET` to a long random string, and set `GEMINI_API_KEY` to your key. Do not commit or share `.env`.

To generate a random JWT secret, run:

```powershell
python -c "import secrets; print(secrets.token_urlsafe(48))"
```

### 4. Install Python dependencies

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

If PowerShell blocks activation, allow scripts for this terminal only, then activate again:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\.venv\Scripts\Activate.ps1
```

### 5. Start and open the app

```powershell
python -m uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

Open [http://localhost:8000](http://localhost:8000). The API docs are at [http://localhost:8000/docs](http://localhost:8000/docs), and the health endpoint is [http://localhost:8000/api/health](http://localhost:8000/api/health).

Keep that PowerShell window open while using the app. Stop the server with `Ctrl+C`. Uploaded listing photos are stored in `uploads/` by default.

### Email verification in local development

SMTP is optional. When it is not configured, the backend prints verification and password reset links in the Uvicorn terminal. Open the printed link in the same browser where BorrowCircle is running. The default link origin is `http://localhost:8000`, matching the app's single-server setup.

## Frontend and API

- Frontend files: `web/index.html`, `web/styles.css`, and `web/app.js`
- API implementation: `main.py`
- Database schema and starter categories: `database.sql`
- AI listing, catalogue recommendations, and report triage require the Gemini API key.

The frontend calls relative `/api/...` URLs, so it works on the same origin without a separate Node.js server or frontend build step.
