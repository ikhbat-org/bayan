package main

import (
	"fmt"
	"time"
)

func main() {
	const size, passes = 8388608, 16
	buf := make([]byte, size)
	var state uint64 = 12345
	for i := 0; i < size; i++ {
		state = state*6364136223846793005 + 1442695040888963407
		buf[i] = byte(state >> 56)
	}
	start := time.Now()
	var h uint64 = 14695981039346656037
	for p := 0; p < passes; p++ {
		for i := 0; i < size; i++ {
			h = (h ^ uint64(buf[i])) * 1099511628211
		}
	}
	elapsed := time.Since(start).Nanoseconds()
	fmt.Printf("%d %d\n", elapsed, h)
}
