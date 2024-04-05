 zip -r build/function_app.zip \
 researchportal_func/function_app.py researchportal_func/host.json researchportal_func/requirements.txt \
 -x '*__pycache__*' \

az functionapp deployment source config-zip \
 --resource-group LongYearResearchPortal \
 --name longyear-research-portal-func \
 --src build/function_app.zip \
 --build-remote true \
 --verbose
