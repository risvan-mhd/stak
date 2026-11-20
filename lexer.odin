package main

import "core:strings"

Token :: struct {
	text: string,
	idx:  int,
}

is_whitespace :: proc(ch: u8) -> bool {
	return ch == ' ' || ch == '\n' || ch == '\r' || ch == '\t'
}

lex :: proc(source: string) -> [dynamic]Token {
	tokens := make([dynamic]Token)

	line_idx := 0

	it := source
	for line in strings.split_lines_iterator(&it) {
		defer line_idx += 1

		i := 0
		for i < len(line) {
			if is_whitespace(line[i]) {
				i += 1
				continue
			}

			start := i
			for i < len(line) {
				if is_whitespace(line[i]) do break
				i += 1
			}

			text := line[start:i]
			line_start := int(uintptr(raw_data(line)) - uintptr(raw_data(source)))
			idx := line_start + start

			append(&tokens, Token{text = text, idx = idx})

		}
	}

	return tokens
}
