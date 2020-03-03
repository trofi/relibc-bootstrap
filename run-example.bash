#!/bin/bash

# Notes:
# 1. Default search path s /lib. We override it with LD_LIBRARY_PATH= (see relibc's entry point).
LD_LIBRARY_PATH=${PWD}/target/lib ./example
