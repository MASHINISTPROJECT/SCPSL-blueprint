#!/bin/bash

echo "###############################################################"
echo "#                     Waenara / SCPSL-Egg                     #"
echo "#   Pterodactyl egg for simplified SCP:SL server management   #"
echo "###############################################################"

# Рабочая директория — корень сервера (куда Pterodactyl монтирует файлы)
cd /home/container || exit 1

# 1. Скачиваем SteamCMD во временную папку
echo "Downloading SteamCMD..."
mkdir -p /home/container/steamcmd
cd /home/container/steamcmd
curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
chmod +x steamcmd.sh

# 2. Скачиваем SCP:SL Dedicated Server
echo "Downloading SCP:SL Server..."
./steamcmd.sh +force_install_dir /home/container +login anonymous +app_update 996560 -beta "$BETA_NAME" $( [ "$BETA_PASSWORD" != "none" ] && echo "-betapassword $BETA_PASSWORD" ) validate +quit

# 3. Убираем временные файлы SteamCMD после установки
cd /home/container
rm -rf steamcmd

# 4. Установка Exiled (если включено)
if [ "$EXILED_INSTALLATION" -ne 0 ]; then
    echo "Installing Exiled..."
    mkdir -p /home/container/exiled
    cd /home/container/exiled
    curl -L "https://github.com/ExSLMod-Team/EXILED/releases/latest/download/Exiled.Installer-Linux" -o Exiled.Installer-Linux
    chmod +x Exiled.Installer-Linux
    ./Exiled.Installer-Linux --path /home/container --appdata /home/container/.config/ --exiled /home/container/.config/ $([ "$EXILED_INSTALLATION" -eq 2 ] && echo --pre-releases)
    cd /home/container
    rm -rf exiled
fi

# 5. Установка Discord-бота (если включено)
if [ "$SCPDISCORD_INSTALLATION" -eq 1 ]; then
    echo "Installing SCPDiscord..."
    mkdir -p /home/container/scpdiscord
    cd /home/container/scpdiscord
    curl -L "https://github.com/KarlOfDuty/SCPDiscord/releases/download/3.3.0-RC5/SCPDiscordBot_Linux_SC" -o SCPDiscordBot_Linux_SC
    chmod +x SCPDiscordBot_Linux_SC

    # Закидываем плагин и зависимости в .config
    mkdir -p "/home/container/.config/SCP Secret Laboratory/LabAPI/dependencies/global/"
    cd "/home/container/.config/SCP Secret Laboratory/LabAPI/"
    curl -L "https://github.com/KarlOfDuty/SCPDiscord/releases/download/3.3.0-RC5/dependencies.zip" -o dependencies.zip
    unzip -o dependencies.zip "dependencies/*" -d temp_extracted
    mv -f temp_extracted/dependencies/* "dependencies/global/"
    rm -rf dependencies.zip temp_extracted

    mkdir -p "/home/container/.config/SCP Secret Laboratory/LabAPI/plugins/global/"
    rm -f "/home/container/.config/SCP Secret Laboratory/LabAPI/plugins/global/SCPDiscord.dll"
    cd "/home/container/.config/SCP Secret Laboratory/LabAPI/plugins/global/"
    curl -L "https://github.com/KarlOfDuty/SCPDiscord/releases/download/3.3.0-RC5/SCPDiscord.dll" -o SCPDiscord.dll

    # Возвращаемся и чистим за собой
    cd /home/container
    rm -rf scpdiscord
else
    rm -f "/home/container/.config/SCP Secret Laboratory/LabAPI/plugins/global/SCPDiscord.dll"
fi

echo "###############################################################"
echo "#                   Installation completed!                   #"
echo "###############################################################"
