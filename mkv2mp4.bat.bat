@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

:: ffmpeg.exeのパス設定
set "FFMPEG_PATH=..\program\ffmpeg.exe"

:: ffmpeg.exeが存在するかチェック
if not exist "%FFMPEG_PATH%" (
    echo エラー: ffmpeg.exeが見つかりません
    echo パス: %FFMPEG_PATH%
    pause
    exit /b 1
)

:: 引数がない場合の説明表示
if "%~1"=="" (
    echo.
    echo 使用方法: 動画ファイルをこのバッチファイルにドラッグ＆ドロップしてください
    echo.
    echo 対応形式: avi, mkv, mov, flv, wmv, webm, m4v など
    echo 出力: 無劣化でMP4形式に変換
    echo.
    pause
    exit /b 0
)

:: 各ファイルを処理
for %%i in (%*) do (
    call :process_file "%%~i"
)

echo.
echo すべての変換が完了しました。
pause
exit /b 0

:process_file
set "input_file=%~1"
set "input_name=%~n1"
set "input_dir=%~dp1"

:: 出力ファイル名を設定（元のファイルと同じディレクトリに出力）
set "output_file=%input_dir%%input_name%_converted.mp4"

echo.
echo 処理中: %input_file%
echo 出力先: %output_file%

:: 入力ファイルの情報を取得
echo ファイル情報を取得中...
"%FFMPEG_PATH%" -i "%input_file%" -f null - 2>temp_info.txt

:: 動画コーデックと音声コーデックを判定
findstr /C:"Video:" temp_info.txt >nul
set video_exists=%errorlevel%

findstr /C:"Audio:" temp_info.txt >nul
set audio_exists=%errorlevel%

:: コーデック情報を抽出
set "video_codec="
set "audio_codec="
set "need_video_encode=0"
set "need_audio_encode=0"

if %video_exists%==0 (
    for /f "tokens=*" %%a in ('findstr /C:"Video:" temp_info.txt') do (
        set "video_line=%%a"
        echo !video_line! | findstr /C:"h264" >nul
        if !errorlevel!==0 (
            set "video_codec=copy"
        ) else (
            echo !video_line! | findstr /C:"hevc" >nul
            if !errorlevel!==0 (
                set "video_codec=copy"
            ) else (
                set "video_codec=h264_nvenc"
                set "need_video_encode=1"
            )
        )
    )
)

if %audio_exists%==0 (
    for /f "tokens=*" %%a in ('findstr /C:"Audio:" temp_info.txt') do (
        set "audio_line=%%a"
        echo !audio_line! | findstr /C:"aac" >nul
        if !errorlevel!==0 (
            set "audio_codec=copy"
        ) else (
            echo !audio_line! | findstr /C:"mp3" >nul
            if !errorlevel!==0 (
                set "audio_codec=copy"
            ) else (
                set "audio_codec=flac"
                set "need_audio_encode=1"
            )
        )
    )
)

:: 変換実行
echo.
if %video_exists%==0 if %audio_exists%==0 (
    echo 動画と音声の両方が存在
    if !need_video_encode!==1 echo 動画: 再エンコード（NVIDIA GPU使用）
    if !need_video_encode!==0 echo 動画: コピー（無劣化）
    if !need_audio_encode!==1 echo 音声: 再エンコード（ロスレス）
    if !need_audio_encode!==0 echo 音声: コピー（無劣化）
    
    if !need_video_encode!==1 (
        "%FFMPEG_PATH%" -i "%input_file%" -c:v h264_nvenc -preset lossless -c:a !audio_codec! "%output_file%"
    ) else if !need_audio_encode!==1 (
        "%FFMPEG_PATH%" -i "%input_file%" -c:v copy -c:a flac "%output_file%"
    ) else (
        "%FFMPEG_PATH%" -i "%input_file%" -c:v copy -c:a copy "%output_file%"
    )
) else if %video_exists%==0 (
    echo 動画のみ存在
    if !need_video_encode!==1 (
        echo 動画: 再エンコード（NVIDIA GPU使用）
        "%FFMPEG_PATH%" -i "%input_file%" -c:v h264_nvenc -preset lossless -an "%output_file%"
    ) else (
        echo 動画: コピー（無劣化）
        "%FFMPEG_PATH%" -i "%input_file%" -c:v copy -an "%output_file%"
    )
) else if %audio_exists%==0 (
    echo 音声のみ存在
    if !need_audio_encode!==1 (
        echo 音声: 再エンコード（ロスレス）
        "%FFMPEG_PATH%" -i "%input_file%" -vn -c:a flac "%output_file%"
    ) else (
        echo 音声: コピー（無劣化）
        "%FFMPEG_PATH%" -i "%input_file%" -vn -c:a copy "%output_file%"
    )
) else (
    echo エラー: 有効な動画または音声ストリームが見つかりません
    del temp_info.txt 2>nul
    goto :eof
)

:: 変換結果をチェック
if %errorlevel%==0 (
    echo 成功: %output_file%
) else (
    echo エラー: 変換に失敗しました
)

:: 一時ファイルを削除
del temp_info.txt 2>nul

goto :eof