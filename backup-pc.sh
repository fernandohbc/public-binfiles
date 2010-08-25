#!/bin/bash
#

# Execução do rsync
RSYNC="/usr/bin/rsync -av --delete --backup --backup-dir=/media/externo/del/pc --exclude-from=/home/rafael/bin/.rsync-exclude"

# Destino da sincronização
DEST="/media/externo/pc"

# Diretórios a serem "backupiados"
DIRETORIOS="/media/ayreon/rafael /media/ayreon/gilvan /media/ayreon/Fotos"

# Realiza copia dos diretórios
for i in $DIRETORIOS; do

   sudo $RSYNC $i $DEST

done

