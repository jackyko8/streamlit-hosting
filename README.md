# Streamlit Hosting

**Streamlit Hosting** is a tool to deploy a Streamlit application on AWS.
The CloudFormation templates in `./src/cfn` can be used for non-Streamlit application hosting on EC2 as well.

## Installation

***IMPORTANT: All steps must be executed from the repository root directory.***

### Prerequisites

- Python 3.9 or later
- AWS CLI
- [jq](https://jqlang.github.io/jq/download/) (for build only)

### Running locally

1. Clone the repository:

   ```bash
   git clone https://github.com/jackyko8/streamlit-hosting.git
   cd streamlit-hosting
   ```

2. Create a virtual environment and install dependencies:

   ```bash
   python -m venv venv
   source venv/bin/activate # On Windows: venv\Scripts\activate
   pip install -r src/app/config/requirements.txt
   ```

3. Start the Streamlit app:

   ```bash
   ./bin/start_app.sh
   ```

   The application will be available at http://localhost:8501.
   If you want to run Streamlit in foreground: `streamlit run src/app/app.py`

4. Stop the Streamlit app:

   ```bash
   ./bin/stop_app.sh
   ```


---

## Deployment

### Prerequisites

- Set up

  - Update `./bin/setup.sh` with your stack name and deployment S3 path.
    - Add a line: `export STACK_NAME=[your_stack_name]`
  - Run `source ./bin/setup.sh`.

- S3 Bucket for deploying source code

  - Create an S3 Bucket in the same region where you deploy the stack.

- Modify the CloudFormation template

  - Copy one of the template files in `./src/cfn/` to `./src/cfn/[your_stack_name].yml`
  - Supply all parameters in `[...]`, including the `S3BucketName` created above.

- If you are using a custom domain

  - Create a ACM Certificate.
  - Create a Route 53 Hosted Zone (the main domain).
  - Define `CustomDomain`, `ACMCertificateArn`, and `HostedZoneId`.

### Deploying on AWS

1. Build

   ```bash
   ./bin/build.sh -c
   ```

   For subsequent updates, please use `./bin/build.sh -u`.

2. Monitor

   ```bash
   ./bin/stack_status.sh complete
   ```

   Wait until CREATE_COMPLETE, then few more minutes to allow `pip install` to complete on the EC2 instance.

3. Test the URLs shown in the CloudFormation output: CloudFront URL, Custom URL, StreamlitAppURL (backend direct for testing)


### Debugging

To perform the following, please connect to the EC2 instance first (via the AWS Console or SSH if you are using a key pair).

- Logs

  - EC2 User Data Script Log: `/var/log/ec2-userdata.log`
  - Streamlit App Log: `/var/log/streamlit-app.log`

- Journal

  - `journalctl -u streamlit-app`

- Restart streamlit-app

  ```bash
  sudo systemctl restart streamlit-app
  ```

  This will automatically check the deployment S3 bucket and install any updates if found.

- Force update

  - If failed to start streamlit or did not detect new updates on S3
    ```bash
    rm -f /home/ec2-user/streamlit-app/app.zip*
    sudo systemctl restart streamlit-app
    tail -f /var/log/streamlit-app.log
    ```

To verify if the streamlit is running, look for the following at near the end of `/var/log/streamlit-app.log`:

```
  You can now view your Streamlit app in your browser.

  Local URL: http://localhost:8501
  Network URL: http://10.1.1.135:8501
  External URL: http://54.66.220.139:8501
```

### Technical Notes

- User Data

  - EC2 UserData only run at the first boot, not at every boot.

  - For testing, this will "trick" cloud-init into running the userdata script in the next boot only.

    ```bash
    sudo rm -rf /var/lib/cloud/instance /var/lib/cloud/instances/*
    sudo rm -rf /var/log/cloud-init.log /var/log/cloud-init-output.log
    sudo cloud-init clean
    sudo reboot
    ```

    Upon the next login, say "yes" to host key verification.

- To recreate the EC2
  - Open the CloudFormation template.
  - Comment out the EC2 block and references to EC2Instance.
  - Update the stack: `./bin/build.sh -u`
  - Uncomment the EC2 block and references to EC2Instance.
