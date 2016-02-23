#!/bin/bash  
function traverse(){
for file in `ls $1`
      do
         if [ -d $1"/"$file ]
         then
            traverse $1"/"$file
         else
            echo $1"/"$file 
         fi
      done
   } 
traverse "/usr/local/src"
