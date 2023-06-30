# !/bin/bash

sf project deploy start \
    --metadata ApexClass \
    --metadata ApexTrigger \
    -c --test-level RunLocalTests \
    --coverage-formatters clover \
    --coverage-formatters cobertura \
    --coverage-formatters html-spa \
    --coverage-formatters html \
    --coverage-formatters json \
    --coverage-formatters json-summary \
    --coverage-formatters lcovonly \
    --coverage-formatters none \
    --coverage-formatters teamcity \
    --coverage-formatters text \
    --coverage-formatters text-summary \
    --results-dir .local/