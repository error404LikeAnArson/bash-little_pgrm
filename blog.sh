#! /bin/bash

creer_config ()
{
  local user
  local serveur
  local	fichier_blog
  local fichier_destination

  echo "Création du fichier de configuration"
  echo -n "Entrez nom utilisateur : "
	read user
	echo "$user" >| "$HOME/.blog_conf"
	echo -n "Entrez adresse du serveur : "
	read serveur
	echo "$serveur" >> "$HOME/.blog_conf"
	echo -n "Entrez chemin du fichier du blog : "
	read fichier_blog
	echo "$fichier_blog" >> "$HOME/.blog_conf"
	echo -n "Entrez chemin du fichier html dans le serveur : "
	read fichier_destination
	echo "$fichier_destination" >> "$HOME/.blog_conf"
}

lire_config () 
{
# 	local luser
# 	local lserveur
# 	local lfichier_blog
# 	local lfichier_destination
# 	if  [ -r "$HOME/.blog_conf" ] ; then
#   	{ read luser
# 			read lserveur
# 			read lfichier_blog
# 		  read lfichier_destination
# 		} < "$HOME/.blog_conf"
#   	echo "$luser $lserveur $lfichier_blog $lfichier_destination"
#     return 1
#   else
#     return 0
#   fi
  cat "$HOME/.blog_conf"
}

ajouter_message_lien () # type fichier_blog message
{
  local type_ml="$1" 
	local fb="$2"
  local message_lien="$3"
  local ligne
	local cdate="$(date)"

  # nouveau message/lien
	echo "$type_ml $cdate @ $message_lien" >| "$$.tmp"

  # copie anciens messages/liens
	while read ligne
	do
		echo "$ligne" >> "$$.tmp"
	done < "$fb"

  cp "$$.tmp" "$fb" 
	rm "$$.tmp"
}

recuperer_date () # ligne
{
	local ligne="$1"
	local sanstype=${ligne:2}
	local ldate="${sanstype% @*}"

  echo "$ldate"
}

recuperer_message () # ligne
{
	local ligne="$1"
	local message="${ligne#*@}"

  echo "$message"
}


recuperer_type () # ligne
{
	local ligne="$1"
	local type="${ligne%% *}"

  echo "$type"
}

ecrire_entete () # fichier_html user
{
	local lfichier="$1"
	local luser="$2"

	cat >| "$lfichier" << FINENTETE
<!DOCTYPE html>
<meta charset="utf-8" />
<html>
	<head>
		<title>$luser</title>
	</head>
	<body>
FINENTETE
}

ecrire_bas_de_page () # fichier_html
{
	local lfichier="$1"

	cat >> "$lfichier" << FINBASDEPAGE

	</body>
</html>
FINBASDEPAGE
}

generer_html() # fichier_blog 
{
	local fb="$1"
	local ligne
	local type_ml
	local ldate
	local ml

	if ! ecrire_entete "$$.html" "$user" ; then
	  return 1
	fi

	while read ligne ; do
		type_ml="$(recuperer_type "$ligne")"
		ldate="$(recuperer_date "$ligne")"
		ml="$(recuperer_message "$ligne")"
		case "$type_ml" in
			"m" )  echo "			<p> $ldate - $ml </p>" >> "$$.html" ;;
			"l" )  echo "			<p> $ldate - <a href=\"$ml\"> $ml </a>" >> "$$.html" ;;
		esac
	done  < "$fb"
	
	ecrire_bas_de_page "$$.html"
}

copier_html_vers_serveur()  # fichier_local utilisateur serveur fichier_serveur
{
 	local fl="$1"
	local user="$2"
	local server="$3"
	local fs="$4"

  #if scp "$1" "$user@$server:$fs" ; then # decomenter pour copier vers un serveur
  if cp "$fl" "$fs" ; then
  	rm "$fl"
  fi
}

supprimer_date () # fichier_blog date
{
      local fb="$1"
      local ldate="$2"
      local mdate
      local ligne

      echo "$fb"
      echo "$ldate"
      
      >| "$$.tmp"
      
      while read ligne ; do
      	mdate="$(recuperer_date "$ligne")"	 
        case "$mdate" in
          *$ldate* ) echo "$(recuperer_message "$ligne")";;
          *    ) echo "$ligne" >> "$$.tmp" ;;      
        esac 
      done < "$fb"

      mv "$$.tmp" "$fb"
}

tester_presence_config ()
{
  if ! [ -r "$HOME/.blog_conf" ] ; then
    if ! creer_config ; then
      return 1
    fi  
  fi
  return 0
}

afficher_usage ()
{
  echo "Usage : "
  echo "$0 -c|--config"
  echo "$0 -a|--ajoute \"message\""
  echo "$0 -l|--lien \"lien\""
  echo "$0 -s|--supprime \"date\""
}

user=
serveur=
fichier_blog=
fichier_destination=

if (($# < 1)) ; then
	afficher_usage > /dev/stderr
	exit 1
fi

case "$1" in
	-c|--config ) if (($# != 1)) ; then
                  afficher_usage > /dev/stderr
	                exit 1
                else
                  if creer_config ; then
                    exit 0
                  else
                    exit 1
                  fi 
                 fi ;;
	-a|--ajoute|-l|--lien|-s|--supprime ) 
                if (($# != 2)) ; then
                  afficher_usage > /dev/stderr
	                exit 1
                fi ;;
	* ) afficher_usage > /dev/stderr
	    exit 1 ;; 
esac

if ! tester_presence_config ; then
  echo "Erreur de création du fichier de configuration" > /dev/stderr
  exit 1
fi

if ! read user serveur fichier_blog fichier_destination <<< $(lire_config) ; then
  echo "Erreur de lecture du fichier de configuration" > /dev/stderr
  exit 1
fi


    case "$1" in
      -a|--ajoute ) shift ; ajouter_message_lien "m" "$fichier_blog" "$@" ;;
      -l|--lien )   shift ; ajouter_message_lien "l" "$fichier_blog" "$@"  ;;
      -s|--supprime ) shift; supprimer_date "$fichier_blog" "$@" ;;
    esac
    
    generer_html "$fichier_blog"
    copier_html_vers_serveur "$$.html" "$user" "$serveur" "$fichier_destination"

exit 0
