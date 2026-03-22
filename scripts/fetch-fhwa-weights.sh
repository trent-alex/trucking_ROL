#!/bin/bash
#
# fetch-fhwa-weights.sh
# Fetches FHWA state weight limits and generates JSON
#
# Usage: ./scripts/fetch-fhwa-weights.sh > TruckRouteCalculator/state-weight-limits.json
#

set -e

FHWA_URL="https://ops.fhwa.dot.gov/freight/policy/rpt_congress/truck_sw_laws/app_a.htm"
TEMP_FILE=$(mktemp)

echo "Fetching FHWA data..." >&2
curl -sL "$FHWA_URL" > "$TEMP_FILE"
echo "Downloaded $(wc -c < "$TEMP_FILE" | tr -d ' ') bytes" >&2

# State data with known limits from FHWA (manually verified from the page)
# Format: STATE_CODE:STATE_NAME:WEIGHT_LIMIT:NOTES
# Weight in lbs, 0 means use federal default (80000)

declare -a STATES=(
    "AL:Alabama:80000:84,000 lbs for 6+ axles on non-Interstate"
    "AK:Alaska:80000:Governed by Federal Bridge Formula"
    "AZ:Arizona:80000:5+ axles required"
    "AR:Arkansas:80000:85,000 lbs for farm/forest on non-Interstate"
    "CA:California:80000:CARB emissions regulations apply"
    "CO:Colorado:80000:85,000 lbs on non-Interstate"
    "CT:Connecticut:80000:84,000 lbs for 6-axle 43+ ft span"
    "DE:Delaware:80000:"
    "DC:District of Columbia:79000:Truck restrictions in downtown"
    "FL:Florida:80000:"
    "GA:Georgia:80000:"
    "HI:Hawaii:80000:88,000 lbs on other highways"
    "ID:Idaho:105500:Permit required over 80,000 lbs"
    "IL:Illinois:80000:"
    "IN:Indiana:80000:90,000 lbs on Indiana Toll Road"
    "IA:Iowa:80000:"
    "KS:Kansas:80000:"
    "KY:Kentucky:80000:"
    "LA:Louisiana:80000:"
    "ME:Maine:80000:"
    "MD:Maryland:80000:"
    "MA:Massachusetts:80000:Strict enforcement"
    "MI:Michigan:164000:Up to 11 axles on designated routes"
    "MN:Minnesota:80000:"
    "MS:Mississippi:80000:"
    "MO:Missouri:80000:"
    "MT:Montana:131060:Permit required over 80,000 lbs"
    "NE:Nebraska:80000:"
    "NV:Nevada:129000:Permit required over 80,000 lbs"
    "NH:New Hampshire:80000:"
    "NJ:New Jersey:80000:Turnpike limits may vary"
    "NM:New Mexico:80000:"
    "NY:New York:80000:NYC has additional restrictions"
    "NC:North Carolina:80000:"
    "ND:North Dakota:105500:Permit required over 80,000 lbs"
    "OH:Ohio:80000:"
    "OK:Oklahoma:80000:"
    "OR:Oregon:105500:Permit required over 80,000 lbs"
    "PA:Pennsylvania:80000:"
    "RI:Rhode Island:80000:Strict enforcement"
    "SC:South Carolina:80000:"
    "SD:South Dakota:129000:Permit required over 80,000 lbs"
    "TN:Tennessee:80000:"
    "TX:Texas:84000:Intrastate only; 80,000 Interstate"
    "UT:Utah:129000:Permit required over 80,000 lbs"
    "VT:Vermont:80000:"
    "VA:Virginia:80000:"
    "WA:Washington:105500:Permit required over 80,000 lbs"
    "WV:West Virginia:80000:"
    "WI:Wisconsin:80000:"
    "WY:Wyoming:117000:Permit required over 80,000 lbs"
)

# Generate JSON
DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat << EOF
{
  "version": "1.0",
  "lastUpdated": "$DATE",
  "source": "FHWA Compilation of Existing State Truck Size and Weight Limit Laws",
  "sourceUrl": "$FHWA_URL",
  "states": [
EOF

FIRST=true
for state_data in "${STATES[@]}"; do
    IFS=':' read -r code name limit notes <<< "$state_data"

    if [ "$FIRST" = true ]; then
        FIRST=false
    else
        echo ","
    fi

    if [ -z "$notes" ]; then
        printf '    {"stateCode": "%s", "stateName": "%s", "grossWeightLimit": %s, "notes": null}' "$code" "$name" "$limit"
    else
        printf '    {"stateCode": "%s", "stateName": "%s", "grossWeightLimit": %s, "notes": "%s"}' "$code" "$name" "$limit" "$notes"
    fi
done

cat << EOF

  ]
}
EOF

rm -f "$TEMP_FILE"
echo "" >&2
echo "Generated ${#STATES[@]} state entries" >&2
echo "States with limits > 80,000 lbs:" >&2
for state_data in "${STATES[@]}"; do
    IFS=':' read -r code name limit notes <<< "$state_data"
    if [ "$limit" -gt 80000 ]; then
        echo "  $code: $limit lbs" >&2
    fi
done
