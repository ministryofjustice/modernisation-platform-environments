import ipaddress
import json
import os
import re


AWS_REGION = os.environ.get("AWS_REGION", os.environ.get("AWS_DEFAULT_REGION", ""))


def ip_in_cidr_list(ip_address, cidr_list):
    if not cidr_list:
        return True

    source_ip = ipaddress.ip_address(ip_address)
    return any(source_ip in ipaddress.ip_network(cidr) for cidr in cidr_list)


def server_id_in_allow_list(server_id, allow_list):
    if not allow_list:
        return True

    return server_id in allow_list


def replace_response_variables(response_data, username, account_id, server_id):
    response_variables = {
        "USERNAME": username,
        "AWS_REGION": AWS_REGION,
        "AWS_ACCOUNT": account_id,
        "SERVER_ID": server_id,
    }

    response_text = json.dumps(response_data)

    def replace_match(match):
        return response_variables.get(match.group(1), match.group(0))

    return json.loads(re.sub(r"\{\{(\w+)\}\}", replace_match, response_text))


def normalise_home_directory_details(response_data):
    home_directory_details = response_data.get("HomeDirectoryDetails")
    if isinstance(home_directory_details, list):
        response_data["HomeDirectoryDetails"] = json.dumps(home_directory_details)

    return response_data