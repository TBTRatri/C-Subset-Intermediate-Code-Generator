#!/bin/bash

# 1. Cleanup
rm -f y.tab.c y.tab.h lex.yy.c y.o l.o compiler log.txt error.txt code.txt

# 2. Smart Bison Path Search
if [ -f "/opt/homebrew/opt/bison/bin/bison" ]; then
    BISON_EXEC="/opt/homebrew/opt/bison/bin/bison"
elif [ -f "/usr/local/opt/bison/bin/bison" ]; then
    BISON_EXEC="/usr/local/opt/bison/bin/bison"
else
    # Fallback to the brew command itself
    BISON_EXEC=$(brew --prefix bison)/bin/bison
fi

echo "Using Bison at: $BISON_EXEC"
$BISON_EXEC -d -y 22101869.y

# 3. Run Flex
flex 22101869.l

# 4. Compile
if [ -f "y.tab.c" ]; then
    g++ -w -c -o y.o y.tab.c
    g++ -w -c -o l.o lex.yy.c
    g++ -o compiler y.o l.o
    
    if [ -f "compiler" ]; then
        ./compiler input.c
        echo "Success! log.txt, error.txt, and code.txt have been generated."
    else
        echo "Linking failed."
    fi
else
    echo "Parser generation failed. Check your .y file syntax."
fi
