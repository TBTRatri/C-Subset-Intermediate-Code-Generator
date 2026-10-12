import streamlit as st
import pandas as pd
import re

st.set_page_config(
    page_title="C-Subset Intermediate Code Generator (TAC & AST)",
    page_icon="⚙️",
    layout="wide"
)

st.title("⚙️ C-Subset Intermediate Code Generator & AST Compiler")
st.markdown(
    "Interactive testbench demonstrating **Abstract Syntax Tree (AST)** generation, "
    "**Three-Address Code (TAC)** emission with temporary registers and jump labels, "
    "and scoped symbol tracking."
)

sample_programs = {
    "Arithmetic & Assignment": """int a, b, c;
void main() {
    a = 10;
    b = 20;
    c = a + b * 2 - 5;
}""",
    "If-Else Conditional Flow": """int x, y, max;
void main() {
    x = 15;
    y = 25;
    if (x > y) {
        max = x;
    } else {
        max = y;
    }
}""",
    "While Loop Iteration": """int count, sum;
void main() {
    count = 0;
    sum = 0;
    while (count < 10) {
        sum = sum + count;
        count = count + 1;
    }
}"""
}

col1, col2 = st.columns([1, 1])

with col1:
    st.subheader("📝 Input C Source Code")
    choice = st.selectbox("Select Preset Benchmark:", list(sample_programs.keys()))
    code_input = st.text_area("C-Subset Code", value=sample_programs[choice], height=340)
    run_btn = st.button("🚀 Generate TAC & Parse AST", type="primary")

class TACGenerator:
    def __init__(self):
        self.temp_count = 0
        self.label_count = 0
        self.instructions = []
        self.ast_nodes = []
        self.symbols = []

    def new_temp(self):
        t = f"t{self.temp_count}"
        self.temp_count += 1
        return t

    def new_label(self):
        l = f"L{self.label_count}"
        self.label_count += 1
        return l

    def emit(self, op, arg1, arg2, res):
        self.instructions.append({
            "Opcode": op,
            "Arg 1": arg1 if arg1 is not None else "-",
            "Arg 2": arg2 if arg2 is not None else "-",
            "Result": res
        })

    def parse_and_generate(self, code):
        lines = code.split("\n")
        in_main = False
        current_scope = "Global"

        for line_num, raw_line in enumerate(lines, 1):
            line = raw_line.strip()
            if not line or line.startswith("//"):
                continue

            # Declarations
            decl_match = re.match(r'^(int|float|void)\s+([a-zA-Z0-9_,\s]+);', line)
            if decl_match:
                d_type, vars_str = decl_match.groups()
                for v in [x.strip() for x in vars_str.split(",")]:
                    self.symbols.append({
                        "Identifier": v,
                        "Type": d_type,
                        "Scope": current_scope,
                        "Line": line_num
                    })
                self.ast_nodes.append(f"DeclStmt({d_type}: {vars_str})")
                continue

            if "void main()" in line or "int main()" in line:
                current_scope = "main()"
                self.emit("LABEL", "-", "-", "main:")
                self.ast_nodes.append("FunctionDef(main)")
                in_main = True
                continue

            # Simple while loop
            while_match = re.match(r'while\s*\((.*?)\)', line)
            if while_match:
                cond = while_match.group(1).strip()
                start_label = self.new_label()
                end_label = self.new_label()
                self.emit("LABEL", "-", "-", f"{start_label}:")
                
                parts = re.split(r'(<|<=|>|>=|==|!=)', cond)
                if len(parts) == 3:
                    left, relop, right = parts[0].strip(), parts[1].strip(), parts[2].strip()
                    temp_cond = self.new_temp()
                    self.emit(relop, left, right, temp_cond)
                    self.emit("IFFALSE", temp_cond, "GOTO", end_label)
                    self.ast_nodes.append(f"WhileLoopNode(Cond: {left} {relop} {right})")
                continue

            # Simple if condition
            if_match = re.match(r'if\s*\((.*?)\)', line)
            if if_match:
                cond = if_match.group(1).strip()
                else_label = self.new_label()
                parts = re.split(r'(<|<=|>|>=|==|!=)', cond)
                if len(parts) == 3:
                    left, relop, right = parts[0].strip(), parts[1].strip(), parts[2].strip()
                    temp_cond = self.new_temp()
                    self.emit(relop, left, right, temp_cond)
                    self.emit("IFFALSE", temp_cond, "GOTO", else_label)
                    self.ast_nodes.append(f"IfBranchNode(Cond: {left} {relop} {right})")
                continue

            if "else" in line:
                next_label = self.new_label()
                self.emit("GOTO", "-", "-", next_label)
                self.emit("LABEL", "-", "-", f"{else_label}:")
                self.ast_nodes.append("ElseBranchNode")
                continue

            # Assignments: e.g., c = a + b * 2 - 5;
            assign_match = re.match(r'^([a-zA-Z_]\w*)\s*=\s*(.*?);', line)
            if assign_match:
                lhs, rhs = assign_match.groups()
                
                # Check for arithmetic operations
                tokens = re.findall(r'[a-zA-Z_]\w*|\d+|[+\-*/]', rhs)
                if len(tokens) == 1:
                    self.emit("ASSIGN", tokens[0], "-", lhs)
                    self.ast_nodes.append(f"AssignNode({lhs} = {tokens[0]})")
                else:
                    # Multi-term arithmetic breakdown
                    curr_res = tokens[0]
                    idx = 1
                    while idx < len(tokens):
                        op = tokens[idx]
                        nxt = tokens[idx + 1]
                        temp = self.new_temp()
                        self.emit(op, curr_res, nxt, temp)
                        curr_res = temp
                        idx += 2
                    self.emit("ASSIGN", curr_res, "-", lhs)
                    self.ast_nodes.append(f"AssignNode({lhs} = {rhs})")

generator = TACGenerator()
generator.parse_and_generate(code_input)

with col2:
    st.subheader("🔍 Compiler Intermediate Output")
    tab_tac, tab_ast, tab_sym = st.tabs(["⚡ Three-Address Code (TAC)", "🌳 Abstract Syntax Tree", "🗂️ Symbol Scope Table"])

    with tab_tac:
        st.markdown("**Quadruple Intermediate Representation (IR):**")
        if generator.instructions:
            df_tac = pd.DataFrame(generator.instructions)
            st.dataframe(df_tac, use_container_width=True, height=280)
            
            st.markdown("**Linear TAC Listing:**")
            tac_listing = []
            for item in generator.instructions:
                op, a1, a2, res = item["Opcode"], item["Arg 1"], item["Arg 2"], item["Result"]
                if op == "LABEL":
                    tac_listing.append(f"{res}")
                elif op == "ASSIGN":
                    tac_listing.append(f"    {res} = {a1}")
                elif op in {"+", "-", "*", "/", "<", ">", "<=", ">=", "==", "!="}:
                    tac_listing.append(f"    {res} = {a1} {op} {a2}")
                elif op == "IFFALSE":
                    tac_listing.append(f"    ifFalse {a1} goto {res}")
                elif op == "GOTO":
                    tac_listing.append(f"    goto {res}")
                else:
                    tac_listing.append(f"    {op} {a1} {a2} -> {res}")
            st.code("\n".join(tac_listing), language="c")
        else:
            st.info("No executable statements found.")

    with tab_ast:
        st.markdown("**Syntactic Derivation Tree:**")
        if generator.ast_nodes:
            ast_repr = "ProgramNode\n"
            for idx, node in enumerate(generator.ast_nodes):
                branch = "└── " if idx == len(generator.ast_nodes) - 1 else "├── "
                ast_repr += f"  {branch}{node}\n"
            st.code(ast_repr, language="text")
        else:
            st.info("No AST derivations available.")

    with tab_sym:
        st.markdown("**Scoped Symbol Definitions:**")
        if generator.symbols:
            st.dataframe(pd.DataFrame(generator.symbols), use_container_width=True)
        else:
            st.info("No symbol declarations identified.")
