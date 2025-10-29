#!/bin/bash
read -p "Digite o endereço para testar a conexão: " endereco
ping -c 4 $endereco
