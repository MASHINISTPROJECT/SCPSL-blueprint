#!/bin/bash

echo "###############################################################"
echo "#                     Waenara / SCPSL-Egg                     #"
echo "#   Pterodactyl egg for simplified SCP:SL server management   #"
echo "###############################################################"

# Переходим в папку, которая монтируется на диск (видна в панели)
cd /mnt/server || exit 1

# 1. Скачиваем SteamCMD во временную папку /tmp (чтобы не мусорить)
echo "Downloading SteamCMD..."
mkdir -p /tmp/steamcmd
cd /tmp/steamcmd
curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
chmod +x steamcmd.sh

# 2. Скачиваем SCP:SL Dedicated Server СРАЗУ в /mnt/server
echo "Downloading SCP:SL Server..."
# +app_info_print 996560 — прогревает кэш SteamCMD для первого запуска
./steamcmd.sh +force_install_dir /mnt/server +login anonymous +app_info_print 996560 +app_update 996560 -beta "$BETA_NAME" $( [ "$BETA_PASSWORD" != "none" ] && echo "-betapassword $BETA_PASSWORD" ) validate +quit

# 3. Убираем временные файлы SteamCMD
rm -rf /tmp/steamcmd

# 4. Установка Exiled (если включено)
if [ "$EXILED_INSTALLATION" -ne 0 ]; then
    echo "Installing Exiled..."
    mkdir -p /tmp/exiled
    cd /tmp/exiled
    curl -L "https://github.com/ExSLMod-Team/EXILED/releases/latest/download/Exiled.Installer-Linux" -o Exiled.Installer-Linux
    chmod +x Exiled.Installer-Linux
    ./Exiled.Installer-Linux --path /mnt/server --appdata /mnt/server/.config/ --exiled /mnt/server/.config/ $([ "$EXILED_INSTALLATION" -eq 2 ] && echo --pre-releases)
    rm -rf /tmp/exiled
fi

# 5. Установка Discord-бота (если включено)
if [ "$SCPDISCORD_INSTALLATION" -eq 1 ]; then
    echo "Installing SCPDiscord..."
    mkdir -p /tmp/scpdiscord
    cd /tmp/scpdiscord
    curl -L "https://github.com/KarlOfDuty/SCPDiscord/releases/download/3.3.0-RC5/SCPDiscordBot_Linux_SC" -o SCPDiscordBot_Linux_SC
    chmod +x SCPDiscordBot_Linux_SC

    # Закидываем плагин и зависимости в .config
    mkdir -p "/mnt/server/.config/SCP Secret Laboratory/LabAPI/dependencies/global/"
    cd "/mnt/server/.config/SCP Secret Laboratory/LabAPI/"
    curl -L "https://github.com/KarlOfDuty/SCPDiscord/releases/download/3.3.0-RC5/dependencies.zip" -o dependencies.zip
    unzip -o dependencies.zip "dependencies/*" -d temp_extracted
    mv -f temp_extracted/dependencies/* "dependencies/global/"
    rm -rf dependencies.zip temp_extracted

    mkdir -p "/mnt/server/.config/SCP Secret Laboratory/LabAPI/plugins/global/"
    rm -f "/mnt/server/.config/SCP Secret Laboratory/LabAPI/plugins/global/SCPDiscord.dll"
    cd "/mnt/server/.config/SCP Secret Laboratory/LabAPI/plugins/global/"
    curl -L "https://github.com/KarlOfDuty/SCPDiscord/releases/download/3.3.0-RC5/SCPDiscord.dll" -o SCPDiscord.dll

    # Чистим за собой
    rm -rf /tmp/scpdiscord
else
    rm -f "/mnt/server/.config/SCP Secret Laboratory/LabAPI/plugins/global/SCPDiscord.dll"
fi

echo "###############################################################"
echo "#                   Installation completed!                   #"
echo "###############################################################"
