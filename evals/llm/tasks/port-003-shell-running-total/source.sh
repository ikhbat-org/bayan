sum=0
max=0
while read -r amount; do
  [ -z "$amount" ] && continue
  sum=$((sum + amount))
  if [ "$amount" -gt "$max" ]; then
    max=$amount
  fi
  echo "after $amount: $sum"
done
echo "sum=$sum max=$max"
