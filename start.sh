#!/bin/bash
[ -f .env ]  && source .env
coffee app.coffee "$@"
