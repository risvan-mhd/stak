package main

import "core:fmt"
import "core:os"
import "core:strconv"
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


generate_code :: proc(program: []Instruction) -> string {
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

compile :: proc(tokens: [dynamic]Token) -> (program: [dynamic]Instruction, ok: bool) {
	program = make([dynamic]Instruction)
	for token in tokens {
		instr: Instruction
		switch token.text {
		case "dump":
			instr = Dump{}

		case "+":
			instr = Add{}

		case:
			num, ok := strconv.parse_i64(token.text)
			if !ok {
				fmt.eprintfln("Expected an int, got '%s'", token.text)
				return
			}
			instr = Push{num}
		}

		append(&program, instr)
	}

	ok = true
	return
}

main :: proc() {
	filepath :: "./examples/compile_me.stack"
	data, ok := os.read_entire_file(filepath, context.allocator)
	if ok != nil {
		fmt.eprintln("Failed to read file:", filepath)
		return
	}
	defer delete(data)

	source := string(data)
	tokens := lex(source)
	defer delete(tokens)

	program, success := compile(tokens)
	if !success do return

	code := generate_code(program[:])
	fmt.println(code)

}
