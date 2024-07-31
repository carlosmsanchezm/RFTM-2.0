# RTFM-2

## 🔧 **Prerequisites**

Before starting this lab, ensure you have the following installed and set up:

1. **Terraform:** Download and install [Terraform](https://www.terraform.io/downloads).
2. **AWS CLI:** Install the [AWS CLI](https://aws.amazon.com/cli/) and configure it with your AWS account credentials.
3. **Ansible:** Install [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/index.html).
4. **Git:** Install [Git](https://git-scm.com/downloads) for version control.
5. **AWS Account:** Ensure you have an [AWS account](https://aws.amazon.com/free/).
6. **GitHub Account:** Create a [GitHub account](https://github.com/) if you don't have one.

## 🛠️ **Step-by-Step Instructions**

### 🔑 **Step 0: Generate SSH Key Pair**

### Overview

**Step 0** is foundational and crucial for the rest of the lab. It involves generating an SSH key pair, which will be used to securely access the AWS EC2 instances created later in the lab. SSH keys are a pair of cryptographic keys that can be used to authenticate to an SSH server as an alternative to password-based logins.

- **Technical Aspect**: This step uses the **`ssh-keygen`** command to create a 2048-bit RSA key pair. The **`t rsa`** specifies the type of key to create (RSA in this case), and **`b 2048`** sets the key length. The **`f ~/.ssh/id_rsa`** argument specifies the filename of the key. The process creates two files: a private key (**`id_rsa`**) and a public key (**`id_rsa.pub`**).
- **Conceptual Understanding**:
    - **SSH Key Importance**: SSH keys provide a more secure way of logging into a server with SSH than using a password alone. While a password can eventually be cracked with enough time and computing power, SSH keys are nearly impossible to decipher by brute force.
    - **Public and Private Keys**: The public key is placed on the server and the private key is what you keep secure and use to authenticate yourself.
    - **Security Best Practices**: Not using a passphrase for the key in this context is a choice made for simplicity, as this is a controlled lab environment. In a real-world scenario, especially in production, it's recommended to secure your private key with a passphrase for an additional layer of security.

By the end of this step, you will have generated a secure method to authenticate to your AWS EC2 instances, setting the stage for the rest of the activities in the lab.

Before running Terraform, generate an SSH key pair to be used with your EC2 instances:

1. **Open a local Terminal**.
2. **Generate SSH Key Pair**:
    - Generate a key-pair:
        
        ```bash
        ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa
        ```
        
    - When prompted for a passphrase, press Enter for no passphrase.
    - Two files will be created: **`id_rsa`** (private key) and **`id_rsa.pub`** (public key) in your **`~/.ssh/`** directory.
    
    Expected Output:
    
    ```bash
    The key's randomart image is:
    +---[RSA 2048]----+
    |..=o+*@=*+o      |
    |.+ o=B+O+  .     |
    |  . o==o .       |
    |    .. .         |
    |     ..oS        |
    |      .E+        |
    |      o.+.       |
    |     .o*o.       |
    |   .o+++o.       |
    +----[SHA256]-----+
    ```
    
3. **Verify Key Creation**:
    - Ensure the keys exist in the **`~/.ssh/`** directory:
        
        ```bash
        ls ~/.ssh/id_rsa*
        ```
        

### 📁 **Step 1: Clone and Set Up Your Own Repository**

### Overview

**Step 1** introduces you to Git, a distributed version control system, and GitHub, a cloud-based hosting service that lets you manage Git repositories. This step is about cloning an existing repository, removing its Git history, initializing a new Git repository, and pushing it to your own GitHub account.

- **Technical Aspect**:
    - **Cloning a Repository**: You start by cloning an existing repository from GitHub. This action creates a local copy of the repository on your machine.
    - **Removing Existing Git History**: By deleting the **`.git`** folder, you remove the existing version control history. This step is necessary because you'll be creating a new repository based on the contents of the cloned one.
    - **Initializing a New Repository**: Using **`git init`** starts a new Git repository in your current directory, allowing you to track changes to these files independently.
    - **Changing the Remote Repository URL**: **`git remote add origin`** points your local repository to your new GitHub repository. This step is essential for pushing your local changes to the remote repository.
    - **Committing and Pushing Changes**: The **`git add`**, **`git commit`**, and **`git push`** commands are used to add changes to the local Git index, commit these changes with a message, and then push them to the remote repository on GitHub.
- **Conceptual Understanding**:
    - **Version Control**: Understanding how Git tracks changes to files and why this is beneficial is crucial. It allows multiple people to work on the same project without conflicting changes, and it tracks history so changes can be reverted if needed.
    - **Repository Management**: Learning how to handle repositories on GitHub - creating, pushing, and managing them - is an essential skill for collaborative software development.
    - **Importance of Clean Slate**: Starting with a new Git history is important when you fork or clone a project to make it your own. It allows you to start fresh and keep track of your modifications from the beginning.

By completing Step 1, you will have a solid foundation in managing and versioning your code using Git and GitHub. This step is critical as it sets the stage for all the subsequent development and change management you will do in this lab.

1. **Clone the Git Repository**:
    
    ```bash
    git clone https://github.com/carlosmsanchezm/RFTM-1.0.git
    cd RFTM-1.0
    ```
    
    **Remove the Existing Git History**:
    
    ```bash
    rm -rf .git
    ```
    
    **Initialize a New Git Repository**:
    
    ```bash
    git init
    ```
    
2. **Create a New Repository on GitHub**:
    - Go to [GitHub](https://github.com/) and sign in.
    - Click the "+" icon in the top right corner and select "New repository".
    
    ![Untitled](RTFM-2%20c938847569e0470c8957ff30a83d48e3/Untitled.png)
    
    - For `Repository name` write **RFTM-1-TEST**. Do not fill any other field. Click `Create Repository`
    
    ![Untitled](RTFM-2%20c938847569e0470c8957ff30a83d48e3/Untitled%201.png)
    
3. **Change the Remote Repository URL**:
    - Point your local repository to your new GitHub repository:
        
        ```bash
        git remote add origin https://github.com/your-username/your-new-repository.git
        ```
        
    - Replace **`https://github.com/your-username/your-new-repository.git`** with your new repository's URL.
    
    ![Untitled](RTFM-2%20c938847569e0470c8957ff30a83d48e3/Untitled%202.png)
    
4. **Initialize New Repo**
    
    **Add Files to the New Repository**:
    
    ```bash
    git add .
    ```
    
    **Commit the Changes**:
    
    ```bash
    git commit -m "Initial commit"
    ```
    
    **Push to the New Repository**:
    
    ```bash
    git push -u origin main
    ```
    
    Expected Output:
    
    ```bash
    Enumerating objects: 9, done.
    Counting objects: 100% (9/9), done.
    Delta compression using up to 8 threads
    Compressing objects: 100% (5/5), done.
    Writing objects: 100% (5/5), 572 bytes | 572.00 KiB/s, done.
    Total 5 (delta 4), reused 0 (delta 0), pack-reused 0
    remote: Resolving deltas: 100% (4/4), completed with 4 local objects.
       f9de077..bdf7d01  main -> main
    ```
    
    Refresh github repo page and see your repo updated with directory:
    
    ![Untitled](RTFM-2%20c938847569e0470c8957ff30a83d48e3/Untitled%203.png)
    

**Pre-Step 2: Configure AWS CLI**

Before starting with `terraform`, ensure your AWS CLI is configured with the necessary credentials. This is essential for Terraform to interact with your AWS account. Run the following command and follow the prompts:

```bash
aws configure --profile userprod
```

Enter your AWS credentials as follows:

- **AWS Access Key ID**: Enter your access key ID.
- **AWS Secret Access Key**: Enter your secret access key.
- **Default region name**: Enter your preferred AWS region (e.g., **`us-east-1`**).
- **Default output format**: Enter the output format (e.g., **`json`**).

These credentials are necessary for Terraform to authenticate and manage resources in your AWS account.

### 🏗️ **Step 2: Infrastructure Setup with Terraform**

### Overview

**Step 2** is all about using Terraform to set up your cloud infrastructure on AWS. Terraform is an open-source infrastructure as code (IaC) tool that allows you to build, change, and version infrastructure efficiently.

- **Technical Aspect**:
    - **Initializing Terraform**: The **`terraform init`** command initializes a Terraform working directory by installing the necessary plugins. It's the first command that should be run after writing new Terraform configurations.
    - **Planning Terraform Deployment**: **`terraform plan`** creates an execution plan. It's a way to check whether the execution plan for a set of changes matches your expectations without making any changes to real resources or the state.
    - **Applying Terraform Plan**: By running **`terraform apply`**, you apply the changes required to reach the desired state of the configuration, or the pre-determined set of actions generated by a Terraform plan execution plan.
- **Conceptual Understanding**:
    - **Infrastructure as Code (IaC)**: This step will help you understand the concept of IaC, which is crucial for automating the setup, configuration, and management of infrastructure using code instead of manual processes.
    - **Importance of Planning in IaC**: The plan step in Terraform is crucial for predicting changes, ensuring that the infrastructure deployment happens as expected, and reducing the likelihood of surprises.
    - **Applying Changes Safely**: Understanding the significance of applying changes in a controlled manner helps in maintaining the stability and reliability of infrastructure environments.

By the end of Step 2, you will gain practical experience with Terraform in setting up infrastructure, reinforcing the principles of IaC. This step is critical in the lab as it lays the groundwork for deploying the web application in a secure and repeatable manner.

Before initializing `terraform` 

1. **Initialize Terraform**:
    
    ```bash
    terraform init
    ```
    
    Expected Output:
    
    ```
    Terraform has been successfully initialized!
    ```
    
2. **Plan Terraform Deployment**:
    
    ```bash
    terraform plan
    ```
    
    Expected Output:
    
    ```bash
    Plan: 7 to add, 0 to change, 0 to destroy.
    ```
    
3. **Apply Terraform Plan**:
    
    ```bash
    terraform apply
    ```
    
    When prompted, type **`yes`** to proceed.
    
    Expected Output:
    
    ```makefile
    Apply complete! Resources: 7 added, 0 changed, 0 destroyed.
    Outputs:
    instance_details = ...
    ```
    

### 🌐 **Step 3: Setup Bastion Host with Ansible**

Run the **`bastion_host.yaml`** playbook to set up the Bastion Host:

```bash
ansible-playbook bastion_host.yaml -i inventory.ini
```

Expected Output:

```bash
TASK [Congratulatory Message] *************************************************************************************************************************************************
ok: [localhost] => {
    "msg": "Now SSH into the bastion host using the command 'ssh -A -i ~/.ssh/id_rsa ec2-user@xxx.xxx.xxx.xxx'. Remember to add your SSH key using 'ssh-add' if you haven't already."
}

PLAY RECAP ********************************************************************************************************************************************************************
bastion
```

### **Step 4: Connect to the Bastion Host**

SSH into the Bastion Host using the output from the Ansible playbook:

```bash
ssh -A -i ~/.ssh/id_rsa ec2-user@[Bastion Host IP]
```

Expected Output:

```bash
,     #_
   ~\_  ####_        Amazon Linux 2023
  ~~  \_#####\
  ~~     \###|
  ~~       \#/ ___   https://aws.amazon.com/linux/amazon-linux-2023
   ~~       V~' '->
    ~~~         /
      ~~._.   _/
         _/ _/
       _/m/'
Last login: **********************************************************************
[ec2-user@ip-*-*-*-* ~]$
```

### **Step 5: Deploy DVWA and MySQL Containers**

Inside the Bastion Host, navigate to the directory with **`RFTM-2.0`** and execute the playbook:

```bash
[ec2-user@ip-*-*-*-* ~]$ ls
RFTM-2.0
[ec2-user@ip-*-*-*-* ~]$ cd RFTM-2.0/
[ec2-user@ip-*-*-*-* ~]$ ls
ansible.cfg            config.inc.php.j2        infra.yaml      main.tf     outputs.tf     sql_injection_attack.py   usernames.txt
bastion_host.yaml      dvwa_database_setup.sql  inventory.ini   mycert.crt  passwords.txt  terraform.tfstate         xxs_reflected_attack.py
brute_force_attack.py  exec_attack.py           inventory.tmpl  mykey.key   simu.py        terraform.tfstate.backup
[ec2-user@ip-*-*-*-* ~]$ ansible-playbook application_deployment.yaml -i inventory.ini
```

Expected Output:

```bash
PLAY RECAP ******************************************************************
```

### **Step 6: Accessing the DVWA Web Application**

After successfully deploying the DVWA and MySQL containers, you are ready to access the DVWA web application.

**Accessing via ELB DNS Record**

1. **Find the DNS Record:** 
    1. In your AWS Console, navigate to the EC2 Dashboard by typing into top search bar *EC2.* 
    2. On the left side scroll down to the dropdown *Load Balancing* and click *Load Balancers*. 
    3. Click on *example-elb* load balancer
    4. copy *DNS name*
    
    ![Untitled](RTFM-2%20c938847569e0470c8957ff30a83d48e3/Untitled%204.png)
    
2. **Access DVWA:** Open your web browser and paste the ELB DNS name into the URL bar. Press Enter to navigate to the DVWA login page.

![Untitled](RTFM-2%20c938847569e0470c8957ff30a83d48e3/Untitled%205.png)

**Setup DVWA**

1. Click `Login` **WITHOUT** inputing Username and Password
2. on **Database Setup** page on the bottom click `Create/Reset Database`

**Logging into DVWA**

- **Username:** admin
- **Password:** password

### **Step 7: Run Attack Simulations**

In the `RFTM-2.0` directory execute the **`simu.py`** script to simulate different attacks:

```bash
python3 simu.py
```

Expected Output:

```bash
 ______     __  __     ______     ______     ______     ______        ______     ______   ______   ______     ______     __  __    
/\  ___\   /\ \_\ \   /\  __ \   /\  __ \   /\  ___\   /\  ___\      /\  __ \   /\__  _\ /\__  _\ /\  __ \   /\  ___\   /\ \/ /    
\ \ \____  \ \  __ \  \ \ \/\ \  \ \ \/\ \  \ \___  \  \ \  __\      \ \  __ \  \/_/\ \/ \/_/\ \/ \ \  __ \  \ \ \____  \ \  _"-.  
 \ \_____\  \ \_\ \_\  \ \_____\  \ \_____\  \/\_____\  \ \_____\     \ \_\ \_\    \ \_\    \ \_\  \ \_\ \_\  \ \_____\  \ \_\ \_\ 
  \/_____/   \/_/\/_/   \/_____/   \/_____/   \/_____/   \/_____/      \/_/\/_/     \/_/     \/_/   \/_/\/_/   \/_____/   \/_/\/_/ 
                                                                                                                                   
1. Brute Force Attack
2. XSS Reflected Attack
3. SQL Injection Attack
4. Exit
Select an option:
```

**Performing a Brute Force Attack:**

- Select option **`1`** for Brute Force Attack.
- Enter the base URL of the DVWA. For example, **`example-elb-*******.us-east-1.elb.amazonaws.com`**.
- The script will attempt various username and password combinations to find valid credentials.

**Performing an XSS Reflected Attack:**

- Select option **`2`** for XSS Reflected Attack.
- Provide the DVWA base URL.
- Choose whether you have a session cookie (usually **`n`** for no if not logged in).
- The script will attempt to inject a JavaScript alert to demonstrate an XSS vulnerability.

**Performing a SQL Injection Attack:**

- Choose option **`3`** for SQL Injection Attack.
- Again, input the DVWA base URL.
- Indicate your session cookie preference.
- The tool attempts to perform an SQL Injection, exploiting vulnerabilities in the database query handling.

**Exiting the Tool:**
To exit the tool, choose option **`4`**.

### **Step 7: Monitor AWS CloudWatch Alarms**

Access the AWS Console and navigate to CloudWatch to observe any triggered alarms during the attack simulations.

### **Step 8: Enable PHPIDS**

Enable PHPIDS in the DVWA settings to enhance security.

### **Step 9: Re-run Attack Simulations**

Run the **`simu.py`** script again with PHPIDS enabled to observe the change in the application's response to the attacks.

### **Step 10: Review AWS CloudWatch Logs**

Investigate the logs in AWS CloudWatch to analyze the details of the attacks and the effectiveness of PHPIDS.

### **Step 11: Review PHPIDS Logs**

After noting that no new alarms are triggered in CloudWatch, examine the PHPIDS logs for insights into how PHPIDS is detecting and preventing attacks. This step will help you understand the role and effectiveness of an Intrusion Detection System in a web application context.