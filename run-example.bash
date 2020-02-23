#!/bin/bash

# Notes:
# 1. For some reason dynamic loader does not load needed binary on it's own. Have to pass explicitly as a first argument.
# 2. Default search path s /lib. We override it with LD_LIBRARY_PATH= (see relibc's entry point).
LD_LIBRARY_PATH=${PWD}/target/lib ./example example
