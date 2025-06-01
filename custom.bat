@echo off
setlocal enabledelayedexpansion

REM スクリプトのディレクトリに移動
pushd %~dp0

REM ログファイルパスの設定
set "log_file=%~dp0log.txt"

REM エンコードオプションの事前定義
set "enc_desc[1]=エンコードなし    (原形式  無劣化    最速        原サイズ    サイト依存)"
set "enc_desc[2]=GPU - H.264       (NVIDIA  無劣化  　標準        最大サイズ  高互換性)"
set "enc_desc[3]=GPU - H.265/HEVC  (NVIDIA  高画質    やや遅い    中サイズ    中互換性)"
set "enc_desc[4]=GPU - H.264       (NVIDIA  標準画質  超高速      中大サイズ  高互換性)"
set "enc_desc[5]=CPU - H.264       (CPU     高画質    非常に遅い  大サイズ    高互換性)"
set "enc_desc[6]=CPU - H.264       (CPU     標準画質  やや遅い    中大サイズ  高互換性)"
set "enc_desc[7]=エンコードなし    (原形式  無劣化    最速        原サイズ    サイト依存)"
set "enc_desc[8]=AAC - MP3         (MP3     高音質    高速        小サイズ    高互換性)"
set "enc_desc[9]=PCM - WAV         (WAV     無劣化    高速        大サイズ    高互換性)"

set "enc_opts[1]=再エンコードなし"
set "enc_opts[2]=-c:v h264_nvenc -preset lossless -rc constqp -qp 0 -c:a pcm_s32le"
set "enc_opts[3]=-c:v hevc_nvenc -preset p7 -rc vbr -cq 12 -c:a aac -b:a 320k"
set "enc_opts[4]=-c:v h264_nvenc -preset p1 -rc vbr -cq 25 -c:a aac -b:a 256k"
set "enc_opts[5]=-c:v libx264 -preset veryslow -crf 12 -c:a aac -b:a 320k"
set "enc_opts[6]=-c:v libx264 -preset ultrafast -crf 25 -c:a aac -b:a 256k"
set "enc_opts[7]=音声のみ-原形式"
set "enc_opts[8]=音声のみ-MP3"
set "enc_opts[9]=音声のみ-WAV"

set "enc_name[1]=再エンコードなし"
set "enc_name[2]=GPUエンコード（NVIDIA・H.264・高画質）"
set "enc_name[3]=GPUエンコード（NVIDIA・H.265・高画質）"
set "enc_name[4]=GPUエンコード（NVIDIA・H.264・標準品質・超高速）"
set "enc_name[5]=CPUエンコード（H.264・高画質）"
set "enc_name[6]=CPUエンコード（H.264・標準品質・高速）"
set "enc_name[7]=音声のみ（RAW）"
set "enc_name[8]=音声のみ（MP3・320kbps）"
set "enc_name[9]=音声のみ（WAV・無圧縮）"

REM エンコードオプションの選択
echo ================================================================
echo                   エンコードオプションを選択                   
echo ================================================================
echo.
echo 【動画＋音声】
for /L %%i in (1,1,6) do (
    echo  %%i. !enc_desc[%%i]!
    if %%i==1 echo.
    if %%i==3 echo.
)
echo.
echo 【音声のみ】
for /L %%i in (7,1,9) do (
    echo  %%i. !enc_desc[%%i]!
)
echo.
echo ※ GPUエンコードはNVIDIA GPUが必要です
echo ※ CPUエンコードは処理が遅いですが、どの環境でも動作します
echo ※ エンコードなしの場合、サイト側の形式がそのまま使用されます
echo ================================================================
set /p encode_option=選択 (1-9): 

REM 選択の検証
if not defined enc_opts[%encode_option%] (
    echo 無効な選択です。デフォルトの「エンコードなし」で続行します。
    set "encode_option=1"
)

REM URLを取得
if "%~1"=="" (
    set /p url=ダウンロードするURLを入力: 
) else (
    set "url=%~1"
)

REM 出力ディレクトリの設定
if "%~2"=="" (
    set "output_dir=%~dp0..\downloads"
) else (
    set "output_dir=%~2"
)

REM 出力ディレクトリが存在しない場合は作成
if not exist "!output_dir!" mkdir "!output_dir!"

REM ダウンロード開始メッセージ
echo.
echo [情報] !enc_name[%encode_option%]! で実行します。
echo [情報] URLのダウンロードを開始します: !url!
echo.

REM 動画情報を取得する
echo [情報] 動画情報を取得しています...
set "site_name=不明"
set "video_title=不明"
set "video_url=!url!"

for /f "delims=" %%a in ('yt-dlp --cookies "%~dp0cookies.txt" --skip-download --get-filename -o "%%%(extractor)s" "!url!" 2^>nul') do (
    set "site_name=%%a"
)

for /f "delims=" %%a in ('yt-dlp --cookies "%~dp0cookies.txt" --skip-download --get-filename -o "%%%(title)s" "!url!" 2^>nul') do (
    set "video_title=%%a"
)

echo [情報] 取得したメタデータ:
echo サイト名: !site_name!
echo タイトル: !video_title!
echo URL: !video_url!

REM ログファイルに情報を記録
echo --------------------------------------------------------------- >> "!log_file!"
echo ダウンロード日時: %date% %time% >> "!log_file!"
echo エンコード方式: !enc_name[%encode_option%]! >> "!log_file!"
echo サイト名: !site_name! >> "!log_file!"
echo タイトル: !video_title! >> "!log_file!"
echo URL: !video_url! >> "!log_file!"

REM 基本コマンドの構築
set "download_cmd=yt-dlp --cookies "%~dp0cookies.txt" --yes-playlist --retries 3 --continue --concurrent-fragments 10 -N 10"

REM フォーマット選択とエンコードオプションの追加
if "%encode_option%"=="7" (
    REM 音声のみ（原形式）
    set "download_cmd=!download_cmd! -f "bestaudio" --extract-audio"
) else if "%encode_option%"=="8" (
    REM 音声のみ（MP3形式）
    set "download_cmd=!download_cmd! -f "bestaudio" --extract-audio --audio-format mp3 --audio-quality 0"
) else if "%encode_option%"=="9" (
    REM 音声のみ（WAV形式）
    set "download_cmd=!download_cmd! -f "bestaudio" --extract-audio --audio-format wav"
) else if "%encode_option%"=="1" (
    REM エンコードなしの場合
    set "download_cmd=!download_cmd! -f "bestvideo+bestaudio" --merge-output-format mkv --write-subs --all-subs --embed-subs --fixup detect_or_warn --add-metadata --embed-chapters"
) else (
    REM 動画エンコードオプション
    set "download_cmd=!download_cmd! -f "bestvideo+bestaudio" --merge-output-format mp4 --write-subs --all-subs --embed-subs --fixup detect_or_warn --add-metadata --recode mp4 --prefer-ffmpeg"
    set "download_cmd=!download_cmd! --postprocessor-args "ffmpeg:!enc_opts[%encode_option%]!""
)

REM 出力先とURLを追加
set "download_cmd=!download_cmd! "!url!" -o "!output_dir!\%%(title)s.%%(ext)s""

REM ダウンロード実行
echo ダウンロード中です...（完了までしばらくお待ちください）
echo -------------------------------------------------------------
!download_cmd!
set "exit_code=!errorlevel!"

REM ダウンロード結果の処理
if "!exit_code!"=="0" (
    echo -------------------------------------------------------------
    echo [成功] ダウンロードが完了しました: !url!
    echo ダウンロード成功 >> "!log_file!"
) else if "!exit_code!"=="1" (
    REM 出力ファイルが存在するか確認
    for /f "delims=" %%a in ('dir /b "!output_dir!\*.mp4" 2^>nul') do (
        echo [成功] メタデータ埋め込みは一部失敗しましたが、ダウンロードは成功しました。
        echo ダウンロード成功（メタデータ一部なし） >> "!log_file!"
        goto :success_cleanup
    )
    
    echo [エラー] ダウンロードに失敗しました: !url!
    echo エラーコード: !exit_code!
    echo ダウンロード失敗 >> "!log_file!"
) else (
    echo [エラー] ダウンロードに失敗しました: !url!
    echo エラーコード: !exit_code!
    echo ダウンロード失敗 >> "!log_file!"
)

:success_cleanup
echo --------------------------------------------------------------- >> "!log_file!"
echo. >> "!log_file!"
echo [情報] ダウンロード情報をlog.txtに記録しました。

REM 一時ファイル削除
echo 一時ファイルを削除しています...
for %%i in (vtt jpg webp json png) do (
    if exist "!output_dir!\*.%%i" del /q "!output_dir!\*.%%i"
)
if exist "!output_dir!\*.temp.mp4" del /q "!output_dir!\*.temp.mp4"
echo クリーンアップが完了しました。
echo 何かキーを押すと終了します...
pause > nul

popd
exit