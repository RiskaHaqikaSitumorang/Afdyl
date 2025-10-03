#!/bin/bash

# Script untuk menjalankan app dengan logging yang lebih jelas

echo "🚀 Menjalankan Flutter app dengan logging..."
echo "======================================"
echo ""
echo "📋 Pilihan:"
echo "  1. Run dengan filter log (hanya tampil log penting)"
echo "  2. Run verbose (semua log)"
echo "  3. Run dan save ke file"
echo "  4. Monitor logcat (Android)"
echo ""
read -p "Pilih (1-4): " choice

case $choice in
  1)
    echo "▶️  Running dengan filter..."
    flutter run --debug 2>&1 | grep --line-buffered -E "\[MAIN\]|\[LatihanKataPage\]|\[LatihanService\]|\[QuranSTT\]|\[RecordingButton\]|Error|Exception"
    ;;
  2)
    echo "▶️  Running verbose..."
    flutter run --debug --verbose
    ;;
  3)
    LOG_FILE="flutter_log_$(date +%Y%m%d_%H%M%S).txt"
    echo "▶️  Running dan save ke $LOG_FILE..."
    flutter run --debug 2>&1 | tee "$LOG_FILE"
    echo "✅ Log disimpan ke: $LOG_FILE"
    ;;
  4)
    echo "▶️  Monitoring Android logcat..."
    adb logcat -c  # Clear buffer
    adb logcat | grep --line-buffered -E "flutter|LatihanKataPage|QuranSTT"
    ;;
  *)
    echo "❌ Pilihan tidak valid"
    exit 1
    ;;
esac
