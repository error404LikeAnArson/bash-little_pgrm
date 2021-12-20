#! /bin/bash

afficher_usage()
{
  echo "USAGE: $0 [-n]" 
}

afficher_niveau_suivant() # val1 val2 ...
{
  local -a tabaux
  local taille i
  
  tabaux=("$@")
  taille="${#tabaux[*]}"
  
  echo -n "1 "
  
  for ((i=1; i<taille; i++)) ; do
    echo -n "$((tabaux[i-1] + tabaux[i])) "
  done

  echo "1"
}

ajouter_decalage() # total courant
{
  local total=$1
  local courant=$2  
  local i

  for ((i=courant; i<total; i++)) ; do
    echo -n " "
  done
}


declare -a tab=(1)
declare -a tab2
n=5


if (($# > 1)) ; then
  afficher_usage
  exit 1
fi
  
if (($# == 1)) ; then
  n=$((-$1-1))
fi 
 
ajouter_decalage $n -1
echo "${tab[@]}"
for ((i=0; i<n; i++)) ; do
  tab2=$(afficher_niveau_suivant ${tab[@]})
  ajouter_decalage $n $i  
  echo "${tab2[@]}"
  tab=(${tab2[@]})
done 


