Port this POSIX shell script to Bayān. For the same standard input, the port prints the same standard output, byte for byte.

```sh
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
```

Every input line ends with a newline. A line is empty or holds one whole number of 0 or more, with no leading zeros and at most nine digits, and it may have spaces before and after the number. You do not need to handle any other input.
