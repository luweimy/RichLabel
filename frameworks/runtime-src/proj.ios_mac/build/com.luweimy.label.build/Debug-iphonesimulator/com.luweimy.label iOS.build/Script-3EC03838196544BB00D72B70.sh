#!/bin/sh
find ${SRCROOT}/../../../src/ -name "*" -exec touch -cm {} \;
find ${SRCROOT}/../../../res/ -name "*" -exec touch -cm {} \;
