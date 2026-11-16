#!/bin/bash
set -e

echo "###############################################################"
echo "#                     Waenara / SCPSL-Egg                     #"
echo "#   Pterodactyl egg for simplified SCP:SL server management   #"
echo "###############################################################"

cd /mnt/server || exit 1

# Запоминаем реального владельца папки тома (pterodactyl на ноде)
OWNER_UGID=$(stat -c '%u:%g' /mnt/server 2>/dev/null || echo "1000:1000")

# 1. Скачиваем и предварительно обновляем SteamCMD во временную папку /tmp
echo "Downloading SteamCMD..."
rm -rf /tmp/steamcmd
mkdir -p /tmp/steamcmd
cd /tmp/steamcmd
curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxf -
chmod +x steamcmd.sh

# Первый холостой запуск, чтобы steamcmd обновился сам до скачивания игры
./steamcmd.sh +quit || true

# 2. Скачиваем SCP:SL Dedicated Server в /mnt/server
echo "Downloading SCP:SL Server..."
BETA_NAME=${BETA_NAME:-public}
BETA_ARGS=""
if [ -n "$BETA_PASSWORD" ] && [ "$BETA_PASSWORD" != "none" ]; then
    BETA_ARGS="-betapassword $BETA_PASSWORD"
fi

./steamcmd.sh \
    +force_install_dir /mnt/server \
    +login anonymous \
    +app_update 996560 -beta "$BETA_NAME" $BETA_ARGS validate \
    +quit

# 3. Убираем временные файлы SteamCMD
rm -rf /tmp/steamcmd

# 4. Установка Exiled (если включено)
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

# 5. Установка Discord-бота (если включено)
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

# 6. Выставляем права на реального владельца тома и делаем бинарники исполняемыми
echo "Setting permissions (${OWNER_UGID})..."
chmod +x /mnt/server/LocalAdmin
chmod +x /mnt/server/SCPSL.x86_64 2>/dev/null || true
if [ "$(id -u)" -eq 0 ]; then
    chown -R "${OWNER_UGID}" /mnt/server
fi

echo "###############################################################"
echo "#                   Installation completed!                   #"
echo "###############################################################"
