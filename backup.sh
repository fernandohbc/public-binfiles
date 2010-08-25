#!/bin/bash
#
# /sbin/scripts/backup.sh
#


# Execução do rsync
RSYNC='/usr/bin/rsync -av --delete'

# Módulo referente ao cliente
MODULO="backup"

# Usuário deste módulo
USUARIO="rafael"

# IP ou Hostname do servidor de backup
SERVIDOR="ayreon"

# Destino da sincronização
DEST="$USUARIO@$SERVIDOR::$MODULO/Backup"

# Log do script
LOG="/home/rafael/bin/backup.log"

# Diretórios a serem "backup`ados"
DIRETORIOS="/home/rafael/Documentos /home/rafael/Imagens"


# Grava a data/hora de inicio do backup
echo -e "\nInicio do backup - `date`\n" >> $LOG

# Realiza copia dos diretórios
for i in $DIRETORIOS; do

   $RSYNC $i $DEST >> $LOG 2>&1

done

# Grava a data/hora de fim do backup
echo -e "\nFim do backup - `date`\n" >> $LOG 
