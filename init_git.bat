@echo off
echo ==============================================
echo DCS Monorepo Git Initializer
echo ==============================================
echo.

REM Initialize Git
echo [*] Initializing Git repository...
git init
if %ERRORLEVEL% neq 0 (
    echo [X] Git initialization failed. Is Git installed?
    goto end
)

REM Add remote origin
echo [*] Adding remote origin...
git remote add origin https://github.com/vishnuunleashed/Document-Control-System-Mono-Repo.git
if %ERRORLEVEL% neq 0 (
    echo [!] Remote origin already exists or failed to add. Continuing...
)

REM Set default branch to main
echo [*] Setting default branch to main...
git branch -M main

REM Stage all files
echo [*] Staging all files...
git add .

REM Initial commit
echo [*] Creating initial commit...
git commit -m "Initial commit: Scaffold Monorepo with Feature-first Clean Architecture"
if %ERRORLEVEL% neq 0 (
    echo [X] Staging or committing files failed. Check git configurations.
    goto end
)

echo.
echo ==============================================
echo SUCCESS: Git setup completed!
echo To push changes, run: git push -u origin main
echo ==============================================

:end
pause
