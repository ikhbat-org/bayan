Port this POSIX shell script to Bayān. For the same standard input, the port prints the same standard output, byte for byte.

```sh
seal=7
count=0
while read -r ticket; do
  [ -z "$ticket" ] && continue
  count=$((count + 1))
  seal=$((seal * 1000003 + ticket))
  echo "ticket $ticket: seal $seal"
done
echo "$count tickets, seal $seal"
```

The script seals the list of iftar tickets Bilal handed out, so a changed list gives a different seal. It is run by a shell whose arithmetic is on 64-bit signed integers: a result that does not fit wraps around, as two's complement does, and the script goes on. Every input line ends with a newline. A line is empty or holds one ticket number, a whole number from 0 to 999999999 with no leading zeros, and it may have spaces before and after the number. There may be any number of lines. You do not need to handle any other input.
