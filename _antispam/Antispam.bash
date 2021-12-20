#! /bin/bash
#TP N'5
#Groupe : DEPART Gwenaëlle; MALIGUE Dylan

declare -a tabExpBlo
declare -a mots
declare -a poids


#prends en argument un fichier email 
#pour en extraire l'expéditeur
extraire_expediteur(){
	local name_file=$1
	head -2 $name_file | tail -1
}

#prends en argument un fichier email 
#pour en extraire le sujet
extraire_object(){
	local name_file=$1
	head -3 $name_file | tail -1
}

#prends en argument un fichier 
#pour verifier qu'il s'agit d'un fichier email
#dans le cas contraire, la fonction echoue
verifier_email(){
	
	# on verifie que le nom passé en parametre correspond bien à un fichier
	if [ -d $1 ] ; then 
		return 1
	fi
	local name_file=$1
	local LINE=$(head -1 $name_file | tail -1)
	
	if [ "$LINE" != "#email" ]; then
		return 1
	fi
}

#extrait les adresses mail bloqué du fichier .expblo pour en faire un tableau
recuperer_expediteurs_bloques(){
	tabExpBlo=()
	
	while read line
	do
		tabExpBlo+=($line)
	done < .expblo
}

#extrait les mots suspect et leur poids du fichier .motsup pour en faire deux tableaux
recuperer_mots_poids(){
	mots=()
	poids=()
	
	while read line
	do
		mots+=(${line% *})
		poids+=(${line#* })
	done < .motsup
}

#prend en argument l'expediteur
#pour verifier si l'expediteur fait parti de la liste des adresses bloquées
#dans le cas contraire, la fonction echoue
verifier_si_expediteur_bloque(){
	local sender=$1
	recuperer_expediteurs_bloques 
	local taille i
	taille="${#tabExpBlo[*]}"
	
	for((i=0; i<taille; i++)) ; do
		if [ "$sender" = ${tabExpBlo[i]} ]; then
			return 0
		fi
	done
	return 1
}

#calcule le "poids" en fonction des mots suspects trouvés dans un object
#si le seuil de "suspect" n'est pas dépassé, la fonction echoue

depassement_du_seuil(){
	local -a objects
	local object=$1
	local totalPoids=0
	objects=("$@")
	recuperer_mots_poids
	local taille i
	local taille2 j
	taille="${#mots[*]}"
	taille2="${#objects[*]}"
	
	for((i=0; i<taille; i++)) ; do
		for ((j=0; j<taille2; j++)) ; do
			if [ ${objects[j]} = ${mots[i]} ]; then
				((totalPoids+=${poids[i]})) 	
			fi
		done
	done
	
	if [ $totalPoids -gt 60 ]; then
		return 0
	else
		return 1
	fi			   
}

#prend en argument un fichier email
#pour definir le statut (bloqué, suspect, clair) du mail
classer_email(){
	local name_email=$1
	local name_object=$(extraire_object $1)
	local name_expediteur=$(extraire_expediteur $1)

	if verifier_si_expediteur_bloque $name_expediteur ; then
		echo "BLOCKED"
	elif depassement_du_seuil $name_object ; then
		echo "SUSPECT"
	else
		echo "CLEAN"
	fi
}

#déplace les fichiers en fonction de leur statut dans les dossiers correspondants
classer_tous_emails(){
	for file in * ; do
		if verifier_email $file; then
			case $(classer_email $file) in
				BLOCKED) mv $file BLOCKED;;
				SUSPECT) mv $file SUSPECT;;
				CLEAN) mv $file CLEAN;;
				*) echo "erreur"
					exit 1;;
			esac
		fi
	done
}

#crée les repertoires necessaires s'ils n'existent pas
#le fonction echoue si à la fin de la fonction les 3 repertoires n'existent toujours pas
creer_repertoires(){
	for file in * ; do
		if [ ! -d BLOCKED ]; then
			mkdir BLOCKED
		elif [ ! -d SUSPECT ]; then
			mkdir SUSPECT
		elif [ ! -d CLEAN ]; then
			mkdir CLEAN
		fi
	done
	
	if [ -d "BLOCKED" ] && [ -d "SUSPECT" ] && [ -d "CLEAN" ]; then
		return 0
	else
		return 1
	fi
}

#test si les fichiers necessaires existent et peuvent être lus
#dans le cas contraire, la fonction echoue
tester_existence_fichiers(){
	local provisoire=0
	if [ ! -r ".expblo" ]; then
		(( provisoire=1 ))
		echo "absence du fichier expblo"
	fi
	if [  ! -r ".motsup" ]; then	
		(( provisoire=provisoire+1 ))
		echo "absence du fichier motsup"
	fi
	if [ $provisoire -gt 1 ]; then
		(( provisoire=1 ))
		
	fi	
	return $provisoire
}

#Programme principal ( Main )

if ( ! creer_repertoires) || ( ! tester_existence_fichiers); then
	exit 1
fi

classer_tous_emails

#Fin du programme antispam.sh
