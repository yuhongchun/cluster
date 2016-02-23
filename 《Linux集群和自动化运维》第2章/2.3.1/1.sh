for n in {100..200}
do
         host=192.168.1.$n
         ping -c2 $host &>/dev/null
         if [ $? = 0 ]; then
                      echo "$host is UP"
         else
                      echo "$host is DOWN"
         fi
done
