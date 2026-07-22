@echo off
echo ============================================
echo   Compression de Description_FAJAFRIC
echo ============================================
echo.
echo Cela peut prendre 20 a 40 minutes.
echo Ne fermez pas cette fenetre !
echo.

set "VIDEOS=%USERPROFILE%\Videos"
set "VLC=C:\Program Files\VideoLAN\VLC\vlc.exe"

rem Chercher le fichier (mkv ou mp4)
set "INPUT="
if exist "%VIDEOS%\Description_FAJAFRIC.mkv" set "INPUT=%VIDEOS%\Description_FAJAFRIC.mkv"
if exist "%VIDEOS%\Description_FAJAFRIC.mp4" set "INPUT=%VIDEOS%\Description_FAJAFRIC.mp4"
if exist "%VIDEOS%\Description_FAJAFRIC.avi" set "INPUT=%VIDEOS%\Description_FAJAFRIC.avi"

if "%INPUT%"=="" (
    echo ERREUR : Fichier non trouve dans: %VIDEOS%
    pause
    exit /b 1
)

set "OUTPUT=%VIDEOS%\Description_FAJAFRIC_small.mp4"

echo Fichier source  : %INPUT%
echo Fichier resultat: %OUTPUT%
echo.
echo Compression en cours...
echo.

"%VLC%" "%INPUT%" --sout "#transcode{vcodec=h264,vb=1500,acodec=mp3,ab=128,scale=1}:std{access=file,mux=mp4,dst=%OUTPUT%}" vlc://quit

echo.
echo Termine ! Fichier sauvegarde ici:
echo %OUTPUT%
echo.
echo Vous pouvez maintenant l'envoyer via WeTransfer.
pause
