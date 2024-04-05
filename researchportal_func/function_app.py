import azure.functions as func
import logging
import os, sys
import json
from azure.storage.blob import BlobServiceClient

app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)

@app.route(route="get_reports")
def Get_Reports(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    connection_string = os.environ["AzureWebJobsStorage"]
    blob_service_client = BlobServiceClient.from_connection_string(connection_string)
    container_name = "reports"
    container_client = blob_service_client.get_container_client(container_name)

    json_files = []
    for blob in container_client.list_blobs():
        json_blob_client = container_client.get_blob_client(blob)
        json_content = json_blob_client.download_blob().readall()
        json_data = json.loads(json_content)
        # Her - lagre bare deler av dataen som skal returneres. Detaljer skal hentes med egen funksjonskall 
        report = {
            "id": json_data['id'],
            "date": json_data['date'],
            "researcher": json_data['researcher'],
            "mutation_name": json_data['mutation_name']
        }
        json_files.append(report)
    
    if json_files:
        return func.HttpResponse(json.dumps(json_files),mimetype="application/json")

    else:
        return func.HttpResponse("Could not find any files.",404)

@app.route(route="get_report", auth_level=func.AuthLevel.FUNCTION)
def get_report(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')
    '''
    p = req.params.get('path')
    if p:
        output = ''
        entries = os.scandir(p)
        for entry in entries:
            output = output + entry.name + '\n'
        return func.HttpResponse(output)
    '''
    filename = req.params.get('filename')
    storage_account_name = os.getenv("storage_account_name")

    if filename:
        # Change the url to environment variable
        command = f'/usr/bin/curl https://{storage_account_name}.blob.core.windows.net/reports/{filename}'
        logging.info('1')
        output = os.popen(command)
        logging.info('2')
        return func.HttpResponse(str(output.read()))
    else:
        return func.HttpResponse("This worked just fine, but you need to include report url for a more detailed report. ", status_code=200)