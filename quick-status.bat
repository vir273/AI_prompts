@echo off
echo ====================================
echo Git Status Checker (Fast)
echo ====================================
echo.

echo ====================================
echo LOCAL CHANGES (not yet committed):
echo ====================================

git status --porcelain > %TEMP%\git_status_temp.txt
type %TEMP%\git_status_temp.txt

for /f %%A in ('type %TEMP%\git_status_temp.txt ^| find /c /v ""') do set COUNT=%%A
del %TEMP%\git_status_temp.txt

if %COUNT% EQU 0 (
    echo No local changes found.
    echo Working tree is clean.
    echo.
    echo Skipping GitHub fetch - nothing to sync.
    goto end
)

echo.
echo Found %COUNT% local change(s) NOT YET COMMITTED

echo.
echo Fetching latest info from GitHub...
git -c http.sslVerify=false fetch origin

echo.
echo ====================================
echo COMMITTED CHANGES vs GITHUB:
echo ====================================

for /f %%i in ('git rev-list HEAD..origin/main --count') do set BEHIND=%%i
for /f %%i in ('git rev-list origin/main..HEAD --count') do set AHEAD=%%i

REM Check all 4 scenarios with goto
if %AHEAD% EQU 0 if %BEHIND% EQU 0 goto uptodate
if %AHEAD% EQU 0 if %BEHIND% GTR 0 goto behind
if %AHEAD% GTR 0 if %BEHIND% EQU 0 goto ahead
if %AHEAD% GTR 0 if %BEHIND% GTR 0 goto diverged
goto end

:uptodate
echo Commits: UP TO DATE with GitHub
echo (But you have %COUNT% uncommitted local change(s))
echo.
echo Next step: Commit your changes, then push.
goto end

:behind
echo Commits: BEHIND by %BEHIND% commit(s)
echo (Plus you have %COUNT% uncommitted local change(s))
echo.
echo Next step: Pull from GitHub, then commit and push your changes.
goto end

:ahead
echo Commits: AHEAD by %AHEAD% commit(s)
echo (Plus you have %COUNT% uncommitted local change(s))
echo.
echo Next step: Commit your local changes, then push everything.
goto end

:diverged
echo Commits: DIVERGED
echo AHEAD by %AHEAD% commit(s)
echo BEHIND by %BEHIND% commit(s)
echo (Plus you have %COUNT% uncommitted local change(s))
echo.
echo Next step: Merge changes before pushing.
goto end

:end
echo.
echo ====================================
echo Done! Press any key to close...
echo ====================================
pause >> nul
