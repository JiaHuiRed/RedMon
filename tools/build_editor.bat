@echo off
cd /d "%~dp0.."
python -m PyInstaller --onefile --noconsole --name "RedMon-Editor" ^
    --distpath tools\dist ^
    --workpath tools\build ^
    --specpath tools ^
    tools\mon_editor.py
if exist "tools\dist\RedMon-Editor.exe" (
    echo [OK] tools\dist\RedMon-Editor.exe
) else (
    echo [FAIL] pip install pyinstaller
)
pause
