#!/usr/local/bin/bash
# ------------------------------------------

clear


read -ep "Enter Policy Text to search for: " -i "LGPL-2.1-or-later" search_text
read -ep "Enter text for resolution note: " -i "Closed for reason XXX: Closed by XXX" closed_note

curl --request GET --url https://fossa.local/api/issues/list-minimal\?scanScope%5Btype%5D\=global\&status\=active\&types%5B0%5D\=policy_conflict\&types%5B1%5D\=policy_flag --header 'Authorization: token d34cc38aec0accab6b43fc54bf306f5f' -k | jq -r '.[] | select(.rule.licenseId == '\"$search_text\"') | .parents[] as $P | [$P.locator, (.id|tostring)] | @csv' >> issue_out.txt

INPUT="issue_out.txt"


[ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 99; }

while IFS=',' read project issue_id
do
	project_value=$(echo "$project" | sed -e 's/^"//' -e 's/"$//')
	issue_id_value=$(echo "$issue_id" | sed -e 's/^"//' -e 's/"$//')
	issue_id_value=$(expr $issue_id_value + 0)

	project_id_agg="projectId=$project_value"
	curl -vL --request PUT --url https://fossa.local/api/issues/"$issue_id_value"/ignore? \
       --data-urlencode $project_id_agg \
       -d resolved=true \
       -d notes="$closed_note" \
       --header 'Authorization: token d34cc38aec0accab6b43fc54bf306f5f'

done < $INPUT

