#!/bin/bash
set -e

echo "###############################################################"
echo "#                     Waenara / SCPSL-Egg                     #"
echo "#   Pterodactyl egg for simplified SCP:SL server management   #"
echo "###############################################################"

cd /mnt/server || exit 1

# Запоминаем реального владельца тома (pterodactyl на ноде)
OWNER_UGID=$(stat -c '%u:%g' /mnt/server 2>/dev/null || echo "1000:1000")

# 1. Скачиваем и предварительно обновляем SteamCMD во временную папку /tmp
echo "Downloading SteamCMD..."
rm -rf /tmp/steamcmd
mkdir -p /tmp/steamcmd
cd /tmp/steamcmd
curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxf -
chmod +x steamcmd.sh

# Холостой запуск, чтобы steamcmd обновился до скачивания игры
./steamcmd.sh +quit || true

# 2. Формируем аргументы ветки (для public флаг -beta не нужен)
BETA_ARGS=""
if [ -n "$BETA_NAME" ] && [ "$BETA_NAME" != "public" ]; then
    BETA_ARGS="-beta $BETA_NAME"
    if [ -n "$BETA_PASSWORD" ] && [ "$BETA_PASSWORD" != "none" ]; then
        BETA_ARGS="$BETA_ARGS -betapassword $BETA_PASSWORD"
    fi
fi

# 3. Скачиваем SCP:SL Dedicated Server (до 3 попыток из-за бага Missing configuration)
echo "Downloading SCP:SL Server..."
INSTALLED=0
for i in 1 2 3; do
    echo "SteamCMD attempt $i/3..."
    if ./steamcmd.sh \
        +@sSteamCmdForcePlatformType linux \
        +force_install_dir /mnt/server \
        +login anonymous \
        +app_info_update 1 \
        +app_update 996560 $BETA_ARGS validate \
        +quit; then
        if [ -f "/mnt/server/LocalAdmin" ]; then
            INSTALLED=1
            break
        fi
    fi
    echo "Attempt $i failed, retrying in 5 seconds..."
    sleep 5
done

if [ "$INSTALLED" -ne 1 ]; then
    echo "ERROR: SteamCMD failed to install SCP:SL Server after 3 attempts!"
    exit 1
fi

# 4. Убираем временные файлы SteamCMD
rm -rf /tmp/steamcmd

# 5. Установка Exiled (если включено)
if [ "${EXILED_INSTALLATION:-0}" -ne 0 ]; then
    echo "Installing Exiled..."
    rm -rf /tmp/exiled
    mkdir -p /tmp/exiled
    cd /tmp/exiled
    curl -fsSL "https://github.com/ExSLMod-Team/EXILED/releases/latest/download/Exiled.Installer-Linux" -o Exiled.Installer-Linux
    chmod +x Exiled.Installer-Linux
    ./Exiled.Installer-Linux --path /mnt/server --appdata /mnt/server/.config/ --exiled /mnt/server/.config/ $([ "$EXILED_INSTALLATION" -eq 2 ] && echo --pre-releases)
    rm -rf /tmp/exiled
fi

# 6. Установка Discord-бота (если включено)
if [ "${SCPDISCORD_INSTALLATION:-0}" -eq 1 ]; then
    echo "Installing SCPDiscord..."
    rm -rf /tmp/scpdiscord
    mkdir -p /tmp/scpdiscord
    cd /tmp/scpdiscord
    curl -fsSL "https://github.com/KarlOfDuty/SCPDiscord/releases/download/3.3.0-RC5/SCPDiscordBot_Linux_SC" -o SCPDiscordBot_Linux_SC
    chmod +x SCPDiscordBot_Linux_SC

    mkdir -p "/mnt/server/.config/SCP Secret Laboratory/LabAPI/dependencies/global/"
    cd "/mnt/server/.config/SCP Secret Laboratory/LabAPI/"
    curl -fsSL "https://github.com/KarlOfDuty/SCPDiscord/releases/download/3.3.0-RC5/dependencies.zip" -o dependencies.zip
    unzip -o dependencies.zip "dependencies/*" -d temp_extracted
    mv -f temp_extracted/dependencies/* "dependencies/global/"
    rm -rf dependencies.zip temp_extracted

    mkdir -p "/mnt/server/.config/SCP Secret Laboratory/LabAPI/plugins/global/"
    rm -f "/mnt/server/.config/SCP Secret Laboratory/LabAPI/plugins/global/SCPDiscord.dll"
    cd "/mnt/server/.config/SCP Secret Laboratory/LabAPI/plugins/global/"
    curl -fsSL "https://github.com/KarlOfDuty/SCPDiscord/releases/download/3.3.0-RC5/SCPDiscord.dll" -o SCPDiscord.dll

    rm -rf /tmp/scpdiscord
else
    rm -f "/mnt/server/.config/SCP Secret Laboratory/LabAPI/plugins/global/SCPDiscord.dll"
fi

# 7. Выставляем права и делаем бинарники исполняемыми
echo "Setting permissions (${OWNER_UGID})..."
chmod +x /mnt/server/LocalAdmin
chmod +x /mnt/server/SCPSL.x86_64 2>/dev/null || true
if [ "$(id -u)" -eq 0 ]; then
    chown -R "${OWNER_UGID}" /mnt/server
fi

echo "###############################################################"
echo "#                   Installation completed!                   #"
echo "###############################################################"
