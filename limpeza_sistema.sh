#!/bin/bash
sudo apt clean
sudo apt autoclean
sudo apt autoremove -y
sudo journalctl --vacuum-time=7d
echo "🧹 Limpeza de sistema concluída."
