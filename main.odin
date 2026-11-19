package main

import "core:fmt"
import "core:strings"

Push :: struct {
	val: i64,
}
Add :: struct {}
Dump :: struct {}

Instruction :: union {
	Push,
	Add,
	Dump,
}


C_HEADER :: """
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <inttypes.h>
#include <stdlib.h>

#define STACK_SIZE 1024

int64_t stack[STACK_SIZE];
size_t sp = 0;

void error(const char* msg) {
	printf("Error: %s\\n", msg);
	exit(1);
}

void push(int64_t x) { 
	if (sp >= STACK_SIZE) error("Stack Overflow");
	stack[sp++] = x;
}

int64_t pop() { 
	if (sp <= 0) error("Stack Underflow");
	return stack[--sp];
}

void add() {
	int64_t a = pop(), b = pop();
	push(a + b);
}

void dump() {
	int64_t a = pop();
	printf("%" PRId64 "\\n", a);
}

int main(void) { 

"""


C_FOOTER :: """
	return 0;
}
"""


gen_code :: proc(program: []Instruction) -> string {
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)

	strings.write_string(&sb, C_HEADER)

	for inst in program {
		switch v in inst {
		case Push:
			fmt.sbprintfln(&sb, "    push(%d);", v.val)
		case Add:
			fmt.sbprintfln(&sb, "    add();")
		case Dump:
			fmt.sbprintfln(&sb, "    dump();")
		}
	}

	strings.write_string(&sb, C_FOOTER)

	return strings.to_string(sb)
}

main :: proc() {
	program := [?]Instruction{Push{10}, Push{20}, Add{}, Dump{}}
	fmt.println(gen_code(program[:]))
}
