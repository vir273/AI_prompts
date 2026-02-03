@echo off
echo ====================================
echo Git Quick Push
echo ====================================
echo.

REM Check if there are any changes
git status

REM Check for both modified files and untracked files
git status --porcelain > nul 2>&1
for /f %%i in ('git status --porcelain ^| find /c /v ""') do set changecount=%%i

if "%changecount%"=="0" (
    echo.
    echo No changes to commit!
    echo Working tree is clean.
    goto end
)

echo.
echo Staging all changes...
git add .

echo.
set /p commit_msg="Enter commit message: "

echo.
echo Committing changes...
git commit -m "%commit_msg%"

echo.
echo Pushing to GitHub...
git -c http.sslVerify=false push

:end
echo.
echo ====================================
echo Done! Press any key to close...
echo ====================================
pause >> nul
