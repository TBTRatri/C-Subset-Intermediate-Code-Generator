# C-Subset Intermediate Code Generator (TAC & AST)

A compiler backend phase for a structured subset of C, implemented using **GNU Flex**, **Bison**, and **C++**. This project builds an **Abstract Syntax Tree (AST)** from syntactic derivations and translates high-level control flows and expressions into **Three-Address Code (TAC)** intermediate representation.

---

## 📌 Architecture & Core Modules

### 1. Abstract Syntax Tree Construction (`ast.h`)
- Generates hierarchical AST node structures capturing operator precedence, branch logic (`if-else`, loops), function invocations, and compound blocks.
- Provides tree traversal utilities for intermediate analysis and visualization.

### 2. Intermediate Code Generation (`three_addr_code.h`)
- Emits linear **Three-Address Code (TAC)** with instruction quadruples/triples.
- Manages synthetic temporary variable allocations (`t0`, `t1`, `t2`, ...) for subexpression evaluation.
- Implements conditional and unconditional label generation (`L0`, `L1`, ...) to translate structured control flows into linear jump instructions.

### 3. Syntax-Directed Translation (`parser.y` & `lexer.l`)
- Context-free LALR(1) grammar enriched with semantic actions for AST generation and code emission.
- Maintains static type checks and symbol lookups across nested scopes using `SymbolTable` and `ScopeTable`.

---

## 📂 File Hierarchy

```text
.
├── lexer.l             # Flex lexical analyzer specification
├── parser.y            # Bison grammar with TAC & AST emission actions
├── ast.h               # Abstract Syntax Tree class definitions
├── three_addr_code.h   # TAC representation, temps, and label manager
├── symbol_info.h       # Symbol token and identifier descriptors
├── scope_table.h       # Hash-based local scope storage
├── symbol_table.h      # Hierarchical nested scope stack
├── input.c             # Sample C source testbench
├── script.sh           # GCC/Clang compilation script
└── README.md           # Documentation
