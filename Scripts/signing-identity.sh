#!/bin/zsh

# Shared, fail-closed Apple signing identity selection and verification helpers.
# This file is sourced by the release scripts; it does not handle private keys.

typeset -gr STAGEPANE_OFFICIAL_TEAM_ID='94HVVWXLK3'
typeset -gr STAGEPANE_DIRECT_IDENTITY_SHA1='E4B85511B94B3161EC9EF0E6601AD8465D2A623D'
typeset -gr STAGEPANE_DIRECT_IDENTITY_CN='Developer ID Application: Shungo Ichikawa (94HVVWXLK3)'

stagepane_normalize_sha1() {
    local candidate=${1:-}
    local sha1_pattern='^[[:xdigit:]]{40}$'

    if [[ ! "$candidate" =~ "$sha1_pattern" ]]; then
        return 70
    fi
    print -r -- "${(U)candidate}"
}

# Emits tab-separated SHA-1 and certificate common name records. `security -v`
# lists only identities that currently satisfy the requested policy and have an
# accessible private key.
stagepane_valid_identity_records() {
    local policy=${1:-codesigning}
    local output line fingerprint subject
    local identity_pattern='^[[:space:]]*[0-9]+\)[[:space:]]+([[:xdigit:]]{40})[[:space:]]+"(.*)"[[:space:]]*$'

    if ! output=$(/usr/bin/security find-identity -v -p "$policy"); then
        print -u2 "Unable to inspect valid Keychain identities for policy: $policy"
        return 70
    fi

    while IFS= read -r line; do
        if [[ "$line" =~ "$identity_pattern" ]]; then
            fingerprint=${(U)match[1]}
            subject=${match[2]}
            print -r -- "$fingerprint"$'\t'"$subject"
        fi
    done <<< "$output"
}

stagepane_require_direct_identity() {
    local records fingerprint subject
    local -i matching_fingerprints=0
    local -i matching_subjects=0

    if ! records=$(stagepane_valid_identity_records codesigning); then
        return 70
    fi

    while IFS=$'\t' read -r fingerprint subject; do
        [[ -n "$fingerprint" ]] || continue
        if [[ "$fingerprint" == "$STAGEPANE_DIRECT_IDENTITY_SHA1" ]]; then
            (( matching_fingerprints += 1 ))
            if [[ "$subject" == "$STAGEPANE_DIRECT_IDENTITY_CN" ]]; then
                (( matching_subjects += 1 ))
            fi
        fi
    done <<< "$records"

    if [[ "$matching_fingerprints" -ne 1 || "$matching_subjects" -ne 1 ]]; then
        print -u2 "The approved Developer ID Application identity is not uniquely available in Keychain"
        print -u2 "Expected SHA-1: $STAGEPANE_DIRECT_IDENTITY_SHA1"
        print -u2 "Expected certificate: $STAGEPANE_DIRECT_IDENTITY_CN"
        return 70
    fi
}

# Prints the selected Apple Distribution SHA-1. With no explicit selector there
# must be exactly one valid Team identity. An explicit selector resolves a
# multi-identity Keychain without inventing or silently choosing a certificate.
stagepane_select_app_store_identity() {
    local team_id=${1:-}
    local requested_selector=${2:-}
    local normalized_selector=''
    local records fingerprint subject selected=''
    local -i matches=0
    local team_pattern='^[A-Z0-9]{10}$'

    if [[ ! "$team_id" =~ "$team_pattern" ]]; then
        print -u2 "Refusing a malformed Apple Developer Team ID"
        return 70
    fi
    if [[ -n "$requested_selector" ]]; then
        if ! normalized_selector=$(stagepane_normalize_sha1 "$requested_selector"); then
            print -u2 "STAGEPANE_APPSTORE_IDENTITY must be a 40-hex certificate SHA-1"
            return 70
        fi
    fi
    if ! records=$(stagepane_valid_identity_records codesigning); then
        return 70
    fi

    while IFS=$'\t' read -r fingerprint subject; do
        [[ -n "$fingerprint" ]] || continue
        if [[ "$subject" == "Apple Distribution: "* && \
              "$subject" == *" ($team_id)" && \
              ( -z "$normalized_selector" || "$fingerprint" == "$normalized_selector" ) ]]; then
            (( matches += 1 ))
            selected=$fingerprint
        fi
    done <<< "$records"

    if [[ "$matches" -eq 0 ]]; then
        print -u2 "No valid Apple Distribution identity for Team $team_id matches the requested selection"
        return 70
    fi
    if [[ "$matches" -ne 1 ]]; then
        print -u2 "Multiple valid Apple Distribution identities exist for Team $team_id"
        print -u2 "Set STAGEPANE_APPSTORE_IDENTITY to the approved identity's 40-hex SHA-1"
        return 70
    fi

    print -r -- "$selected"
}

# Verifies signature integrity plus the signed leaf certificate. Certificate 0
# from codesign is the leaf certificate in DER form; hashing that exact DER is
# equivalent to the SHA-1 identifier emitted by `security find-identity`.
stagepane_verify_signed_identity() (
    emulate -L zsh
    set -u

    local artifact_path=${1:-}
    local expected_fingerprint=${2:-}
    local expected_team_id=${3:-}
    local expected_role=${4:-}
    local expected_common_name=${5:-}
    local signature_details detail_line signature_team='' signing_authority=''
    local certificate_temp=''
    local leaf_certificate digest actual_fingerprint

    cleanup_certificate_temp() {
        if [[ -n "$certificate_temp" && -d "$certificate_temp" && \
              "$certificate_temp" == /tmp/stagepane-signature.* ]]; then
            /bin/rm -rf -- "$certificate_temp"
        fi
    }
    trap cleanup_certificate_temp EXIT
    trap 'exit 70' HUP INT TERM

    if [[ ! -e "$artifact_path" ]]; then
        print -u2 "Cannot verify a missing signed artifact: $artifact_path"
        exit 70
    fi
    if ! expected_fingerprint=$(stagepane_normalize_sha1 "$expected_fingerprint"); then
        print -u2 "Internal error: expected signing fingerprint is malformed"
        exit 70
    fi
    if [[ "$expected_role" != 'developer-id-application' && \
          "$expected_role" != 'apple-distribution' ]]; then
        print -u2 "Internal error: unsupported signing certificate role: $expected_role"
        exit 70
    fi

    if ! /usr/bin/codesign --verify --strict --verbose=2 "$artifact_path"; then
        print -u2 "Code signature verification failed: $artifact_path"
        exit 70
    fi
    if [[ "$expected_role" == 'apple-distribution' ]] && \
       ! /usr/bin/codesign --verify --strict \
           --test-requirement='=anchor apple generic' "$artifact_path"; then
        print -u2 "App Store signature is not anchored to Apple's code-signing trust chain"
        exit 70
    fi
    if ! signature_details=$(/usr/bin/codesign -d --verbose=4 "$artifact_path" 2>&1); then
        print -u2 "Unable to inspect code signature metadata: $artifact_path"
        exit 70
    fi
    for detail_line in ${(f)signature_details}; do
        if [[ "$detail_line" == TeamIdentifier=* ]]; then
            signature_team=${detail_line#TeamIdentifier=}
        elif [[ -z "$signing_authority" && "$detail_line" == Authority=* ]]; then
            signing_authority=${detail_line#Authority=}
        fi
    done
    if [[ "$signature_team" != "$expected_team_id" ]]; then
        print -u2 "Signed artifact has unexpected TeamIdentifier: ${signature_team:-not set}"
        print -u2 "Expected TeamIdentifier: $expected_team_id"
        exit 70
    fi
    if [[ "$expected_role" == 'developer-id-application' ]]; then
        if [[ "$signing_authority" != "$expected_common_name" ]]; then
            print -u2 "Signed artifact does not use the approved Developer ID Application certificate"
            print -u2 "Expected certificate: $expected_common_name"
            print -u2 "Actual certificate: ${signing_authority:-not set}"
            exit 70
        fi
    elif [[ "$signing_authority" != "Apple Distribution: "* || \
            "$signing_authority" != *" ($expected_team_id)" ]]; then
        print -u2 "Signed artifact does not use an Apple Distribution certificate for Team $expected_team_id"
        print -u2 "Actual certificate: ${signing_authority:-not set}"
        exit 70
    fi

    if ! certificate_temp=$(/usr/bin/mktemp -d /tmp/stagepane-signature.XXXXXX); then
        print -u2 "Unable to create a temporary certificate inspection directory"
        exit 70
    fi
    # codesign requires the argument-bearing long option in `--option=value`
    # form; the separated form is parsed as another artifact path.
    if ! /usr/bin/codesign -d --extract-certificates="$certificate_temp/chain-" \
        "$artifact_path" >/dev/null 2>&1; then
        print -u2 "Unable to extract the signing certificate: $artifact_path"
        exit 70
    fi
    leaf_certificate="$certificate_temp/chain-0"
    if [[ ! -s "$leaf_certificate" ]]; then
        print -u2 "Signed artifact has no extractable leaf certificate: $artifact_path"
        exit 70
    fi

    if ! digest=$(/usr/bin/shasum -a 1 "$leaf_certificate"); then
        print -u2 "Unable to fingerprint the signing certificate: $artifact_path"
        exit 70
    fi
    actual_fingerprint=${(U)${digest%% *}}
    if [[ "$actual_fingerprint" != "$expected_fingerprint" ]]; then
        print -u2 "Signed artifact uses an unexpected certificate fingerprint"
        print -u2 "Expected SHA-1: $expected_fingerprint"
        print -u2 "Actual SHA-1: $actual_fingerprint"
        exit 70
    fi
)
