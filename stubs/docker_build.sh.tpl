#!/bin/bash
set -e -x
docker build {{TAGS}} {{DOCKERFILE}} {{ARGS}} $@ - < {{CONTEXT}}
