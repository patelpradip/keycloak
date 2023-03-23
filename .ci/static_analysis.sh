#!/usr/bin/env bash
set -ev
echo "=========================== Starting Static Analysis Script ==========================="

java -jar vosp-api-wrappers-java-${VERACODE_WRAPPER_VERSION}.jar \
  -vid "${VERACODE_API_ID}" \
  -vkey "${VERACODE_API_KEY}" \
  -action uploadandscan \
  -appname "Alfresco Identity Service" \
  -sandboxname "${VERACODE_SANDBOX}" \
  -createprofile false \
  -filepath $ARTIFACT_TO_SCAN \
  -version "${JOB_NAME} - ${BUILD_NUMBER}" \
  || (sleep 5m; exit 1) # wait 5 minutes before retry


echo "=========================== Finishing Static Analysis Script =========================="