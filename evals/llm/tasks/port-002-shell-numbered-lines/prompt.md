Port this POSIX shell script to Bayān. For the same standard input, the port prints the same standard output, byte for byte.

```sh
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
```

Every input line ends with a newline. The input has no carriage returns and no backslashes. You do not need to handle any other input.
