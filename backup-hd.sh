#!/bin/bash
#

# Execução do rsync
RSYNC='/usr/bin/rsync -av --delete --backup --backup-dir=/media/externo/del/notebook --exclude=.gvfs'

# Destino da sincronização
DEST="/media/externo/notebook"

# Diretórios a serem "backup`ados"
DIRETORIOS="/home /etc /var/cache/pacman/pkg /srv/http"

# Realiza copia dos diretórios
for i in $DIRETORIOS; do

   sudo $RSYNC $i $DEST

done

