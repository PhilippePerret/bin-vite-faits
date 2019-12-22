#!/usr/bin/env bash

# Les deux arguments sont obligatoires :
#   le path absolu du fichier à enregistrer
#   le nombre de secondes de l'enregistrement
ffmpeg -f avfoundation -i ":0" -t $2 "$1" 2> /dev/null &
