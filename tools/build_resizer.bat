@echo off
chcp 65001 >nul
title 打包 resize_sprites.exe

echo ================================
echo  精灵缩放工具 - PyInstaller 打包
echo ================================
echo.

:: 检查 pyinstaller
where pyinstaller >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] 未检测到 PyInstaller，正在安装...
    pip install pyinstaller
    if %errorlevel% neq 0 (
        echo [失败] 安装 PyInstaller 失败，请手动执行: pip install pyinstaller
        pause
        exit /b 1
    )
)

:: 清理旧构建
if exist dist\resize_sprites.exe del dist\resize_sprites.exe

:: 打包
echo [INFO] 正在打包...
pyinstaller --onefile --console --name resize_sprites resize_sprites.py

if %errorlevel% equ 0 (
    echo.
    echo ================================
    echo  打包成功!
    echo.
    echo  可执行文件: dist\resize_sprites.exe
    echo.
    echo  用法: 丢进 sprites 文件夹双击运行
    echo  或拖拽文件夹到 exe 上
    echo ================================
) else (
    echo [失败] 打包出错，请检查报错信息
)

pause
