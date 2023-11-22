#!/bin/bash
set -e -x
docker build {{TAGS}} --file {{DOCKERFILE}} {{ARGS}} $@ - < {{CONTEXT}}
