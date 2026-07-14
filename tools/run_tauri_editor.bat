@echo off
chcp 65001 >nul
cd /d "%~dp0editor"
if not exist node_modules (
	echo 首次运行，安装依赖...
	bun install
)
echo 启动 RedMon Tauri 编辑器...
bun run tauri dev
pause
