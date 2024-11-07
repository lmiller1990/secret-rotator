import os
import boto3
import requests

ssm = boto3.client("ssm")


def handler(event, context):
    parameter_name = os.getenv("SSM_PARAMETER_NAME")
    auth_api_url = os.getenv("AUTH_API_URL")
    username = os.getenv("AUTH_API_USERNAME")

    if parameter_name is None:
        raise RuntimeError("SSM_PARAMETER_NAME required")

    if auth_api_url is None:
        raise RuntimeError("AUTH_API_URL required")

    if username is None:
        raise RuntimeError("AUTH_API_USERNAME required")

    # Retrieve SecureString from AWS SSM
    response = ssm.get_parameter(Name=parameter_name, WithDecryption=True)
    password = response["Parameter"]["Value"]

    # Make an API request with payload
    payload = {"username": username, "password": password}
    api_response = requests.post(auth_api_url, json=payload)
    api_response.raise_for_status()
    new_password = api_response.json().get("token")

    # Update SSM with new string from API response
    if new_password:
        ssm.put_parameter(
            Name=parameter_name, Value=new_password, Type="SecureString", Overwrite=True
        )

    return {"msg": "SSM updated successfully"}
