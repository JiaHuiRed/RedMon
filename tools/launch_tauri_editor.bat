@echo off
chcp 65001 >nul
cd /d "%~dp0editor\src-tauri\target\release"
if not exist "redmon-editor.exe" (
	echo 还没有打包好的正式版，先运行 build_tauri_editor.bat 打包一次。
	pause
	exit /b 1
)
start "" "redmon-editor.exe"
