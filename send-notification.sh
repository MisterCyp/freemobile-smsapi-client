#!/bin/sh

# 
# Script d'envoi de notification SMS via l'API Free Mobile
# https://github.com/C-Duv/freemobile-smsapi-client
# 
# Auteur: DUVERGIER Claude (http://claude.duvergier.fr)
# 
# Nécessite: sed, sh et wget
# 
# Possible usages:
#   send-notification.sh "All your base are belong to us"
#   echo "All your base are belong to us" | send-notification.sh
#   uptime | send-notification.sh


##
## Configuration système
##

# Caractère de fin de ligne (http://en.wikipedia.org/wiki/Percent-encoding#Character_data)
NEWLINE_CHAR="%0D" # Valeurs possibles : %0A, %0D et %0D%0A

# URL d'accès à l'API
SMSAPI_BASEURL="https://smsapi.free-mobile.fr"

# Action d'envoi de notification
SMSAPI_SEND_ACTION="sendmsg"


##
## Configuration utilisateur
##

#Chargement des identifiants dans le fichier configuration

. ./configuration

# Texte qui sera ajouté AVANT chaque message envoyé
MESSAGE_HEADER="Notification :${NEWLINE_CHAR}"

# Texte qui sera ajouté APRÈS chaque message envoyé
MESSAGE_FOOTER="${NEWLINE_CHAR}--${NEWLINE_CHAR}Le serveur de la maison"


##
## Traitement du message
##

MESSAGE_TO_SEND=""
if [ "$1" ]; then # Message en tant qu'argument de la ligne de commande
    MESSAGE_TO_SEND="$1"
else # Message lu de STDIN
    while read line
    do
        MESSAGE_TO_SEND="$MESSAGE_TO_SEND$line$NEWLINE_CHAR"
    done
    MESSAGE_TO_SEND=$(echo $MESSAGE_TO_SEND | sed 's/'$NEWLINE_CHAR'$//') # Retire le dernier saut de ligne
fi

FINAL_MESSAGE_TO_SEND="$MESSAGE_HEADER$MESSAGE_TO_SEND$MESSAGE_FOOTER" # Assemble header, message et footer

##
## Appel à l'API (envoi)
##

# echo "Will send the following to $USER_LOGIN:" #DEBUG
# echo "$FINAL_MESSAGE_TO_SEND" #DEBUG

# --insecure : Certificat de $SMSAPI_BASEURL ne fourni pas d'informations sur son propriétaire
# --write-out "%{http_code}" --silent --output /dev/null : Renvoi le code réponse HTTP uniquement
HTTP_STATUS_CODE=$(curl --insecure --get "$SMSAPI_BASEURL/$SMSAPI_SEND_ACTION" --data "user=$USER_LOGIN" --data "pass=$API_KEY" --data "msg=$FINAL_MESSAGE_TO_SEND" --write-out "%{http_code}" --silent --output /dev/null)

# Codes réponse HTTP possibles
# 200 : Le SMS a été envoyé sur votre mobile.
# 400 : Un des paramètres obligatoires est manquant.
# 402 : Trop de SMS ont été envoyés en trop peu de temps.
# 403 : Le service n'est pas activé sur l'espace abonné, ou login / clé incorrect.
# 500 : Erreur côté serveur. Veuillez réessayez ultérieurement.

if [ "$HTTP_STATUS_CODE" -eq 200 ]; then
    # echo "API responded with 200: exiting with 0" #DEBUG
    exit 0
else
    echo "Error: API responded with $HTTP_STATUS_CODE"
    exit 1
fi
