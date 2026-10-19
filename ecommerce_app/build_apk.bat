@echo off
rem Self-healing Android build - see build_apk.ps1 for details.
rem Usage: build_apk.bat [--release|--debug ...]
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build_apk.ps1" %*
