n=0
blank=0
while IFS= read -r line; do
  n=$((n + 1))
  if [ -z "$line" ]; then
    blank=$((blank + 1))
    continue
  fi
  printf '%d: %s\n' "$n" "$line"
done
echo "$n lines, $blank blank"
