#!/bin/sh

pip-compile --output-file requirements/prod.txt requirements.in/prod.txt
pip-compile --output-file requirements/dev.txt requirements.in/dev.txt
