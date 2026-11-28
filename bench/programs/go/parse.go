package main

import (
	"fmt"
	"time"
)

func main() {
	const target, passes = 4194304, 8
	buf := make([]byte, target+64)
	n := 0
	var state uint64 = 777
	for n < target {
		for field := 0; field < 3; field++ {
			state = state*6364136223846793005 + 1442695040888963407
			v := (state >> 33) % 1000000
			var digits [8]byte
			d := 0
			if v == 0 {
				digits[d] = 48
				d++
			}
			for v > 0 {
				digits[d] = byte(48 + v%10)
				d++
				v /= 10
			}
			for d > 0 {
				d--
				buf[n] = digits[d]
				n++
			}
			if field == 2 {
				buf[n] = 10
			} else {
				buf[n] = 44
			}
			n++
		}
	}
	start := time.Now()
	var sum uint64
	for p := 0; p < passes; p++ {
		var value uint64
		for i := 0; i < n; i++ {
			c := buf[i]
			if c >= 48 && c <= 57 {
				value = value*10 + uint64(c-48)
			} else {
				sum = sum*31 + value
				value = 0
			}
		}
	}
	elapsed := time.Since(start).Nanoseconds()
	fmt.Printf("%d %d\n", elapsed, sum)
}
