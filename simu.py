# Python script to simulate a hacking tool interface
import pyfiglet
import shutil
import brute_force_attack
from exec_attack import run_command_injection
from xxs_reflected_attack import run_xxs_reflected_attack
from sql_injection_attack import run_sql_injection_attack

def display_header():
    # Get terminal width
    terminal_width = shutil.get_terminal_size().columns

    # Create ASCII art with a max width for the first text
    f1 = pyfiglet.Figlet(font='slant_relief', width=terminal_width)
    ascii_banner1 = f1.renderText(',--------, |-RTF*M-| .`---------\'')

    # Create ASCII art with a max width for 'Choose Attack'
    f2 = pyfiglet.Figlet(font='sub-zero', width=terminal_width)  # Using 'slant' font for 'Choose Attack'
    ascii_banner2 = f2.renderText('Choose Attack')

    # Print both ASCII arts
    print(ascii_banner1)
    print(ascii_banner2)

def main_menu():
    print("1. Brute Force Attack")
    print("2. XSS Reflected Attack")
    print("3. SQL Injection Attack")
    print("4. Exit")
    choice = input("Select an option: ")
    return choice

def run_brute_force_wrapper():
    # Call the brute force function from brute_force_attack.py
    brute_force_attack.run_brute_force_attack()

def run_xxs_reflected_attack_wrapper():
    dvwa_url = input("Enter the base URL of the DVWA: ")
    choice = input("Do you have a session cookie? (y/n): ")

    if choice.lower() == 'y':
        session_cookie = input("Enter your PHPSESSID value: ")
        run_xxs_reflected_attack(dvwa_url, session_cookie)
    else:
        run_xxs_reflected_attack(dvwa_url)

def run_sql_injection_wrapper():
    dvwa_url = input("Enter the base URL of the DVWA: ")
    choice = input("Do you have a session cookie? (y/n): ")

    if choice.lower() == 'y':
        session_cookie = input("Enter your PHPSESSID value: ")
        run_sql_injection_attack(dvwa_url, session_cookie)
    else:
        run_sql_injection_attack(dvwa_url)

def run_script():
    display_header()
    while True:
        choice = main_menu()
        if choice == '1':
            run_brute_force_wrapper()
        elif choice == '2':
            run_xxs_reflected_attack_wrapper()
        elif choice == '3':
            run_sql_injection_wrapper()
        elif choice == '4':
            print("Exiting tool...")
            break
        else:
            print("Invalid choice, please try again.")

if __name__ == "__main__":
    run_script()