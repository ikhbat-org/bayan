seal=7
count=0
while read -r ticket; do
  [ -z "$ticket" ] && continue
  count=$((count + 1))
  seal=$((seal * 1000003 + ticket))
  echo "ticket $ticket: seal $seal"
done
echo "$count tickets, seal $seal"
