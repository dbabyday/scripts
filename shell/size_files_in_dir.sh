
read -p 'Directory: ' dir
#dir=/oradb/dmuts01/data

totalbytes=0
for f in ${dir}/*; do
	b=$(stat --printf="%s" $f)
	((totalbytes=$totalbytes+b))
done
mb=$(echo "scale=1; ${totalbytes}/1024/1024;" | bc)
gb=$(echo "scale=1; ${totalbytes}/1024/1024/1024;" | bc)
tb=$(echo "scale=1; ${totalbytes}/1024/1024/1024/1024;" | bc)
echo $mb MB
echo $gb GB
echo $tb TB