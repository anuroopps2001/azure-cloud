FROM mcr.microsoft.com/azure-functions/python:4-python3.10

ENV AzureWebJobScriptRoot=/home/site/wwwroot \
    AzureFunctionsJobHost__Loggin__Console__IsEnabled=true

COPY requirements.txt .
RUN pip install --no-cache-dir -r /requirements.txt

COPY . /home/site/wwwroot
