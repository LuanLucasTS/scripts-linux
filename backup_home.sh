#!/bin/bash
destino=~/backup_$(date +%F).tar.gz
tar -czf $destino ~/Documents ~/Downloads
echo "📦 Backup salvo em $destino"
