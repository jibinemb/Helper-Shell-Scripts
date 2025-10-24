#!/bin/bash

# Generate a password that meets:
# - at least 1 uppercase
# - at least 1 lowercase
# - at least 1 number
# - at least 1 special character
# - length >= 8

PASSWORD=$(tr -dc 'A-Z' </dev/urandom | head -c1)      # 1 uppercase
PASSWORD+=$(tr -dc 'a-z' </dev/urandom | head -c1)     # 1 lowercase
PASSWORD+=$(tr -dc '0-9' </dev/urandom | head -c1)     # 1 number
PASSWORD+=$(tr -dc '!@#$%^&*()_+{}|:<>?' </dev/urandom | head -c1) # 1 special char
PASSWORD+=$(tr -dc 'A-Za-z0-9!@#$%^&*()_+{}|:<>?' </dev/urandom | head -c4) # remaining chars

# Shuffle characters so order is random
echo "$PASSWORD" | fold -w1 | shuf | tr -d '\n'; echo

