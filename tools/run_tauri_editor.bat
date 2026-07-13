@echo off
chcp 65001 >nul
echo 启动 RedMon Tauri 编辑器...
cd /d "%~dp0editor"
bun run tauri dev
pause
