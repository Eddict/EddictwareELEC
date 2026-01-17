#!/bin/bash

LE_ko="./distributions/LibreELEC/kernel_options"
EE_ko="./distributions/EddictwareELEC/kernel_options"
EE_dko="./distributions/EddictwareELEC/distribution_kernel_options"

if ! diff -q <(cat "$LE_ko" <(echo) "$EE_dko") "$EE_ko" >/dev/null; then
    cat "$LE_ko" <(echo) "$EE_dko" > "$EE_ko"
    chmod 644 "$EE_ko"
    echo "EddictwareELEC kernel_options file updated."
fi
