#!/bin/sh
registration_url="https://api.github.com/orgs/${GITHUB_OWNER}/actions/runners/registration-token"
echo "Requesting registration URL at '${registration_url}'"
payload=$(curl -sX POST -H "Authorization: Bearer ${GITHUB_PERSONAL_TOKEN}" ${registration_url})
export RUNNER_TOKEN=$(echo $payload | jq .token --raw-output)
./config.sh \
    --name $(hostname) \
    --token ${RUNNER_TOKEN} \
    --url https://github.com/${GITHUB_OWNER}/${GITHUB_REPOSITORY} \
    --work ${RUNNER_WORKDIR} \
    --unattended \
    --replace
remove() {
    ./config.sh remove --unattended --token "${RUNNER_TOKEN}"
}
trap 'remove; exit 130' INT
trap 'remove; exit 143' TERM
./run.sh "$*" &
wait $!