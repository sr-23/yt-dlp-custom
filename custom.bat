@echo off
setlocal enabledelayedexpansion

REM �X�N���v�g�̃f�B���N�g���Ɉړ�
pushd %~dp0

REM ���O�t�@�C���p�X�̐ݒ�
set "log_file=%~dp0log.txt"

REM �G���R�[�h�I�v�V�����̎��O��`
set "enc_desc[1]=�G���R�[�h�Ȃ�    (���`��  ����    �ő�        ���T�C�Y    �T�C�g�ˑ�)"
set "enc_desc[2]=GPU - H.264       (NVIDIA  ����  �@�W��        �ő�T�C�Y  ���݊���)"
set "enc_desc[3]=GPU - H.265/HEVC  (NVIDIA  ���掿    ���x��    ���T�C�Y    ���݊���)"
set "enc_desc[4]=GPU - H.264       (NVIDIA  �W���掿  ������      ����T�C�Y  ���݊���)"
set "enc_desc[5]=CPU - H.264       (CPU     ���掿    ���ɒx��  ��T�C�Y    ���݊���)"
set "enc_desc[6]=CPU - H.264       (CPU     �W���掿  ���x��    ����T�C�Y  ���݊���)"
set "enc_desc[7]=�G���R�[�h�Ȃ�    (���`��  ����    �ő�        ���T�C�Y    �T�C�g�ˑ�)"
set "enc_desc[8]=AAC - MP3         (MP3     ������    ����        ���T�C�Y    ���݊���)"
set "enc_desc[9]=PCM - WAV         (WAV     ����    ����        ��T�C�Y    ���݊���)"

set "enc_opts[1]=�ăG���R�[�h�Ȃ�"
set "enc_opts[2]=-c:v h264_nvenc -preset lossless -rc constqp -qp 0 -c:a pcm_s32le"
set "enc_opts[3]=-c:v hevc_nvenc -preset p7 -rc vbr -cq 12 -c:a aac -b:a 320k"
set "enc_opts[4]=-c:v h264_nvenc -preset p1 -rc vbr -cq 25 -c:a aac -b:a 256k"
set "enc_opts[5]=-c:v libx264 -preset veryslow -crf 12 -c:a aac -b:a 320k"
set "enc_opts[6]=-c:v libx264 -preset ultrafast -crf 25 -c:a aac -b:a 256k"
set "enc_opts[7]=�����̂�-���`��"
set "enc_opts[8]=�����̂�-MP3"
set "enc_opts[9]=�����̂�-WAV"

set "enc_name[1]=�ăG���R�[�h�Ȃ�"
set "enc_name[2]=GPU�G���R�[�h�iNVIDIA�EH.264�E���掿�j"
set "enc_name[3]=GPU�G���R�[�h�iNVIDIA�EH.265�E���掿�j"
set "enc_name[4]=GPU�G���R�[�h�iNVIDIA�EH.264�E�W���i���E�������j"
set "enc_name[5]=CPU�G���R�[�h�iH.264�E���掿�j"
set "enc_name[6]=CPU�G���R�[�h�iH.264�E�W���i���E�����j"
set "enc_name[7]=�����̂݁iRAW�j"
set "enc_name[8]=�����̂݁iMP3�E320kbps�j"
set "enc_name[9]=�����̂݁iWAV�E�����k�j"

REM �G���R�[�h�I�v�V�����̑I��
echo ================================================================
echo                   �G���R�[�h�I�v�V������I��                   
echo ================================================================
echo.
echo �y����{�����z
for /L %%i in (1,1,6) do (
    echo  %%i. !enc_desc[%%i]!
    if %%i==1 echo.
    if %%i==3 echo.
)
echo.
echo �y�����̂݁z
for /L %%i in (7,1,9) do (
    echo  %%i. !enc_desc[%%i]!
)
echo.
echo �� GPU�G���R�[�h��NVIDIA GPU���K�v�ł�
echo �� CPU�G���R�[�h�͏������x���ł����A�ǂ̊��ł����삵�܂�
echo �� �G���R�[�h�Ȃ��̏ꍇ�A�T�C�g���̌`�������̂܂܎g�p����܂�
echo ================================================================
set /p encode_option=�I�� (1-9): 

REM �I���̌���
if not defined enc_opts[%encode_option%] (
    echo �����ȑI���ł��B�f�t�H���g�́u�G���R�[�h�Ȃ��v�ő��s���܂��B
    set "encode_option=1"
)

REM URL���擾
if "%~1"=="" (
    set /p url=�_�E�����[�h����URL�����: 
) else (
    set "url=%~1"
)

REM �o�̓f�B���N�g���̐ݒ�
if "%~2"=="" (
    set "output_dir=%~dp0..\downloads"
) else (
    set "output_dir=%~2"
)

REM �o�̓f�B���N�g�������݂��Ȃ��ꍇ�͍쐬
if not exist "!output_dir!" mkdir "!output_dir!"

REM �_�E�����[�h�J�n���b�Z�[�W
echo.
echo [���] !enc_name[%encode_option%]! �Ŏ��s���܂��B
echo [���] URL�̃_�E�����[�h���J�n���܂�: !url!
echo.

REM ��������擾����
echo [���] ��������擾���Ă��܂�...
set "site_name=�s��"
set "video_title=�s��"
set "video_url=!url!"

for /f "delims=" %%a in ('yt-dlp --cookies "%~dp0cookies.txt" --skip-download --get-filename -o "%%%(extractor)s" "!url!" 2^>nul') do (
    set "site_name=%%a"
)

for /f "delims=" %%a in ('yt-dlp --cookies "%~dp0cookies.txt" --skip-download --get-filename -o "%%%(title)s" "!url!" 2^>nul') do (
    set "video_title=%%a"
)

echo [���] �擾�������^�f�[�^:
echo �T�C�g��: !site_name!
echo �^�C�g��: !video_title!
echo URL: !video_url!

REM ���O�t�@�C���ɏ����L�^
echo --------------------------------------------------------------- >> "!log_file!"
echo �_�E�����[�h����: %date% %time% >> "!log_file!"
echo �G���R�[�h����: !enc_name[%encode_option%]! >> "!log_file!"
echo �T�C�g��: !site_name! >> "!log_file!"
echo �^�C�g��: !video_title! >> "!log_file!"
echo URL: !video_url! >> "!log_file!"

REM ��{�R�}���h�̍\�z
set "download_cmd=yt-dlp --cookies "%~dp0cookies.txt" --yes-playlist --retries 3 --continue --concurrent-fragments 10 -N 10"

REM �t�H�[�}�b�g�I���ƃG���R�[�h�I�v�V�����̒ǉ�
if "%encode_option%"=="7" (
    REM �����̂݁i���`���j
    set "download_cmd=!download_cmd! -f "bestaudio" --extract-audio"
) else if "%encode_option%"=="8" (
    REM �����̂݁iMP3�`���j
    set "download_cmd=!download_cmd! -f "bestaudio" --extract-audio --audio-format mp3 --audio-quality 0"
) else if "%encode_option%"=="9" (
    REM �����̂݁iWAV�`���j
    set "download_cmd=!download_cmd! -f "bestaudio" --extract-audio --audio-format wav"
) else if "%encode_option%"=="1" (
    REM �G���R�[�h�Ȃ��̏ꍇ
    set "download_cmd=!download_cmd! -f "bestvideo+bestaudio" --merge-output-format mkv --write-subs --all-subs --embed-subs --fixup detect_or_warn --add-metadata --embed-chapters"
) else (
    REM ����G���R�[�h�I�v�V����
    set "download_cmd=!download_cmd! -f "bestvideo+bestaudio" --merge-output-format mp4 --write-subs --all-subs --embed-subs --fixup detect_or_warn --add-metadata --recode mp4 --prefer-ffmpeg"
    set "download_cmd=!download_cmd! --postprocessor-args "ffmpeg:!enc_opts[%encode_option%]!""
)

REM �o�͐��URL��ǉ�
set "download_cmd=!download_cmd! "!url!" -o "!output_dir!\%%(title)s.%%(ext)s""

REM �_�E�����[�h���s
echo �_�E�����[�h���ł�...�i�����܂ł��΂炭���҂����������j
echo -------------------------------------------------------------
!download_cmd!
set "exit_code=!errorlevel!"

REM �_�E�����[�h���ʂ̏���
if "!exit_code!"=="0" (
    echo -------------------------------------------------------------
    echo [����] �_�E�����[�h���������܂���: !url!
    echo �_�E�����[�h���� >> "!log_file!"
) else if "!exit_code!"=="1" (
    REM �o�̓t�@�C�������݂��邩�m�F
    for /f "delims=" %%a in ('dir /b "!output_dir!\*.mp4" 2^>nul') do (
        echo [����] ���^�f�[�^���ߍ��݂͈ꕔ���s���܂������A�_�E�����[�h�͐������܂����B
        echo �_�E�����[�h�����i���^�f�[�^�ꕔ�Ȃ��j >> "!log_file!"
        goto :success_cleanup
    )
    
    echo [�G���[] �_�E�����[�h�Ɏ��s���܂���: !url!
    echo �G���[�R�[�h: !exit_code!
    echo �_�E�����[�h���s >> "!log_file!"
) else (
    echo [�G���[] �_�E�����[�h�Ɏ��s���܂���: !url!
    echo �G���[�R�[�h: !exit_code!
    echo �_�E�����[�h���s >> "!log_file!"
)

:success_cleanup
echo --------------------------------------------------------------- >> "!log_file!"
echo. >> "!log_file!"
echo [���] �_�E�����[�h����log.txt�ɋL�^���܂����B

REM �ꎞ�t�@�C���폜
echo �ꎞ�t�@�C�����폜���Ă��܂�...
for %%i in (vtt jpg webp json png) do (
    if exist "!output_dir!\*.%%i" del /q "!output_dir!\*.%%i"
)
if exist "!output_dir!\*.temp.mp4" del /q "!output_dir!\*.temp.mp4"
echo �N���[���A�b�v���������܂����B
echo �����L�[�������ƏI�����܂�...
pause > nul

popd
exit