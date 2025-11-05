# Jenkins Setup Guide

This guide provides step-by-step instructions for setting up Jenkins Controller-Agent architecture on Ubuntu 22.04 LTS, creating a deployment pipeline job, and configuring GitHub webhooks for automated deployments.

## Table of Contents

1. [Initial Jenkins Controller Setup](#initial-jenkins-controller-setup)
2. [Install Required Plugins](#install-required-plugins)
3. [Configure NodeJS Tool](#configure-nodejs-tool)
4. [Configure Jenkins Agent](#configure-jenkins-agent)
5. [Disable Built-in Node](#disable-built-in-node)
6. [Create the Pipeline Job](#create-the-pipeline-job)
7. [Configure GitHub Webhook](#configure-github-webhook)
8. [Test the Pipeline](#test-the-pipeline)
9. [Troubleshooting](#troubleshooting)

---

## Initial Jenkins Controller Setup

### 1. Access Jenkins Controller

After Terraform deploys the infrastructure, access Jenkins through your browser:

```bash
http://<JENKINS_CONTROLLER_PUBLIC_IP>:8080
```

Get the public IP from Terraform outputs: `jenkins-controller-url`

### 2. Unlock Jenkins

Retrieve the initial admin password via SSM Session to the controller:

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Copy the password and paste it into the Jenkins web interface.

### 3. Customize Jenkins

- Select: "Install suggested plugins"
- Wait for installation (3-5 minutes)

### 4. Create Admin User

- Username: `admin` (or your choice)
- Password: Choose a strong password
- Full name: Your name
- Email: Your email

Click **Save and Continue**.

### 5. Instance Configuration

- Jenkins URL: Auto-filled as `http://<PUBLIC_IP>:8080/`
- Verify and click **Save and Finish**
- Click **Start using Jenkins**

---

## Install Required Plugins

### Navigate to Plugin Manager

1. **Manage Jenkins** > **Plugins** > **Available plugins**

### Install These Plugins

- **GitHub plugin**
- **NodeJS plugin**

Click **Install without restart** and optionally check **Restart Jenkins when installation is complete**.

---

## Configure NodeJS Tool

### Setup Node.js 22.2.0

1. **Manage Jenkins** > **Global Tool Configuration**
2. Scroll to **NodeJS** section
3. Click **Add NodeJS**
   - **Name**: `NodeJS 22.2.0` (must match Jenkinsfile exactly)
   - **Install automatically**: ✅ Checked
   - **Version**: Select `NodeJS 22.2.0`
4. Click **Save**

**Note**: Use Node.js 22.2.0 (version 25+ may fail with Vite). Jenkins will auto-download on first build.

---

## Configure Jenkins Agent

### Generate SSH Key Pair (Already Done in Terraform)

The SSH key pair was generated during Terraform setup:

```bash
ssh-keygen -t rsa -b 4096 -f jenkins-agent-key -C "jenkins-agent"
```

Public key is in AWS, private key is local.

### Add Agent Node in Jenkins

1. **Manage Jenkins** > **Nodes** > **New Node**
2. **Node name**: `jenkins-agent`
3. Select **Permanent Agent** > **Create**

#### Configure Agent

- **Number of executors**: `1`
- **Remote root directory**: `/home/ubuntu/agent`
- **Labels**: `agent` (optional)
- **Usage**: **Use this node as much as possible**
- **Launch method**: **Launch agents via SSH**
  - **Host**: Use Terraform output `jenkins-agent-private-dns` (e.g., `ip-10-0-4-x.ec2.internal`)
  - **Credentials**: Click **Add** > **Jenkins**
    - **Kind**: SSH Username with private key
    - **Scope**: Global
    - **ID**: `jenkins-agent-key`
    - **Description**: `Jenkins Agent SSH Key`
    - **Username**: `ubuntu`
    - **Private Key**: Select **Enter directly** > Paste your private key content from local `jenkins-agent-key` file
    - Click **Add**
  - Select the newly created credential from dropdown
  - **Host Key Verification Strategy**: **Non verifying Verification Strategy**
- **Availability**: **Keep this agent online as much as possible**

Click **Save**.

### Verify Agent Connection

The agent should automatically connect. Check **Manage Jenkins** > **Nodes** - the agent status should show a green checkmark.

---

## Disable Built-in Node

To force all builds to run on the agent:

1. **Manage Jenkins** > **Nodes** > **Built-In Node** > **Configure**
2. Set **Number of executors** to `0`
3. Click **Save**

---

## Create the Pipeline Job

### 1. Create New Item

1. **New Item** (top left)
2. Name: `deploy-vite-app`
3. Select **Pipeline** > **OK**

### 2. Configure Job

#### General

- ✅ **GitHub project**: `https://github.com/<YOUR_USERNAME>/<YOUR_REPO>/`

#### Build Triggers

- ✅ **GitHub hook trigger for GITScm polling**

#### Pipeline

- **Definition**: Pipeline script
- **Script**: Copy entire contents of `Jenkinsfile`

**Update environment variables in the script**:

```groovy
environment {
    REGION = 'us-east-1'
    BUCKET = 'your-s3-bucket-name'
    KEY_PREFIX = 'artifacts'
    APP_TAG_KEY = 'Role'
    APP_TAG_VAL = 'App'
}
```

**Update repository URL** (in Checkout stage):

```groovy
git branch: 'main',
    url: 'https://github.com/YOUR_USERNAME/YOUR_REPO.git'
```

Click **Save**.

---

## Configure GitHub Webhook

### 1. Add Webhook in GitHub

1. Go to your GitHub repository > **Settings** > **Webhooks** > **Add webhook**

### 2. Configure Webhook

- **Payload URL**: `http://<JENKINS_CONTROLLER_PUBLIC_IP>:8080/github-webhook/`
  - Get from Terraform output: `jenkins-controller-url`
  - **Trailing `/` is required**
- **Content type**: `application/json`
- **Which events**: Select **Just the push event**
- ✅ **Active**

Click **Add webhook**.

### 3. Verify

GitHub sends a test ping. You should see a green checkmark ✅. If red ❌, check security group allows port 8080.

---

## Test the Pipeline

### Manual Test

1. Jenkins Dashboard > `deploy-vite-app` > **Build Now**
2. Check **Console Output** for logs

### Webhook Test

Push a change to your repository:

```bash
git commit --allow-empty -m "Test webhook"
git push
```

Build should trigger automatically in Jenkins.

### Verify Deployment

Access your app via ALB URL from Terraform outputs and verify the deployment.

---

## Troubleshooting

### Agent Not Connecting

- Check security group allows SSH (port 22) from controller to agent
- Verify private DNS hostname is correct
- Check `/home/ubuntu/agent` directory exists on agent
- Review agent logs: **Manage Jenkins** > **Nodes** > **jenkins-agent** > **Log**

### Build Fails on Agent

- Verify agent has Java installed: `java -version`
- Check IAM role on agent allows S3 and SSM permissions
- Review Console Output for specific errors

### Node.js Issues

- Ensure "NodeJS 22.2.0" tool name matches exactly in Global Tool Configuration
- Avoid Node.js 25+ (use 22.2.0 for compatibility)

### Webhook Not Triggering

- Verify webhook URL has trailing `/`: `/github-webhook/`
- Check GitHub webhook delivery history for errors
- Ensure Jenkins controller security group allows inbound port 8080

### Getting Terraform Outputs

```bash
cd terraform/root
terraform output
```

---

## Quick Reference

### Prerequisites Checklist

1. ✅ Generate SSH key pair locally
2. ✅ Deploy infrastructure with Terraform (add public key to tfvars)
3. ✅ Access Jenkins controller and complete initial setup
4. ✅ Install GitHub and NodeJS plugins
5. ✅ Configure NodeJS 22.2.0 tool
6. ✅ Add and configure Jenkins agent node
7. ✅ Disable built-in node (set executors to 0)
8. ✅ Create pipeline job with Jenkinsfile
9. ✅ Set up GitHub webhook
10. ✅ Test deployment

### Key URLs

- **Jenkins Controller**: `http://<controller-ip>:8080`
- **Webhook**: `http://<controller-ip>:8080/github-webhook/`
- **Application**: Check Terraform output `project-url`

---

## Additional Resources

### Pipeline Fails at "Verify Node.js" Stage

**Issue**: Node.js or npm not found in PATH

**Solution**:

1. **Check if NodeJS tool is configured in Jenkins**:
   - Go to **Manage Jenkins** > **Global Tool Configuration**
   - Verify **NodeJS 22.2.0** is configured with auto-install enabled
   - Ensure the name matches exactly what's in your Jenkinsfile

2. **Check Jenkins Plugin Manager**:
   - Go to **Manage Jenkins** > **Plugins**
   - Ensure **NodeJS Plugin** is installed

3. **Check build console output** for Node.js download messages:
   - First build should show "Unpacking nodejs..."
   - If it fails to download, check internet connectivity from Jenkins EC2

4. **Restart Jenkins** after configuration changes:

   ```bash
   sudo systemctl restart jenkins
   ```

### Pipeline Fails at "Deploy via SSM" Stage

**Common Causes**:

1. **IAM Permissions**: Jenkins EC2 doesn't have permission to use SSM
   - Check IAM instance profile attached to Jenkins EC2
   - Verify it has `ssm:SendCommand` and `ssm:ListCommandInvocations` permissions

2. **Target Instances Not Found**:
   - Verify app EC2 instances have the correct tags (`Role=App`)
   - Verify SSM agent is running on target instances

3. **Script Not Found on Target**:
   - Verify `/opt/deploy/pull_and_switch.sh` exists on target instances
   - Check it's executable: `sudo chmod +x /opt/deploy/pull_and_switch.sh`

**Debug Commands**:

```bash
# From Jenkins EC2, test SSM access
aws ssm describe-instance-information --region us-east-1

# Check if target instances are visible
aws ssm send-command \
  --region us-east-1 \
  --document-name "AWS-RunShellScript" \
  --targets "Key=tag:Role,Values=App" \
  --parameters 'commands=["echo test"]'
```

### Build Fails at "Upload to S3" Stage

**Issue**: AWS credentials or permissions

**Solution**:

- Verify Jenkins EC2 has IAM permissions to write to S3 bucket
- Check bucket name is correct in pipeline environment variables
- Test S3 access manually:

  ```bash
  sudo su - jenkins
  echo "test" > test.txt
  aws s3 cp test.txt s3://YOUR-BUCKET/test.txt --region us-east-1
  ```

### "Error: Workspace is dirty" or Git Issues

**Issue**: Git repository state issues

**Solution**:

- The pipeline has `cleanWs()` in the post section
- If issues persist, you can manually clean:

```bash
  ```bash
  sudo su - jenkins
  cd /var/lib/jenkins/workspace/deploy-vite-app
  git clean -fdx
```

---

## Additional Configuration

### Enable Build Notifications (Optional)

Configure email notifications:

1. **Manage Jenkins** > **System**
2. Scroll to **E-mail Notification**
3. Configure SMTP server
4. Add to pipeline post section:

   ```groovy
   post {
       success {
           mail to: 'team@example.com',
                subject: "Deployment Successful: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "Good news! Deployment completed successfully."
       }
       failure {
           mail to: 'team@example.com',
                subject: "Deployment Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "Deployment failed. Check Jenkins for details."
       }
   }
   ```

### Secure Jenkins (Production)

1. **Enable HTTPS**:
   - Use a reverse proxy (nginx) with SSL certificate
   - Or configure Jenkins with a Java keystore

2. **Configure Security Realm**:
   - **Manage Jenkins** > **Security**
   - Configure proper authentication (LDAP, SAML, etc.)

3. **Restrict Permissions**:
   - Use Matrix-based security
   - Create role-based access control

4. **Regular Backups**:
   - Backup `/var/lib/jenkins` directory regularly
   - Consider using ThinBackup plugin

---

## Useful Jenkins Commands

```bash
# Restart Jenkins
sudo systemctl restart jenkins

# Stop Jenkins
sudo systemctl stop jenkins

# Start Jenkins
sudo systemctl start jenkins

# View logs
sudo journalctl -u jenkins -f

# Check Jenkins status
/opt/jenkins-scripts/jenkins-status.sh

# Get webhook info
/opt/jenkins-scripts/webhook-info.sh

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

---

## Next Steps

1. ✅ Complete initial Jenkins setup
2. ✅ Install required plugins
3. ✅ Create and configure pipeline job
4. ✅ Set up GitHub webhook
5. ✅ Test manual and automatic deployments
6. 🔄 Monitor builds and deployments
7. 🔄 Optimize pipeline as needed
8. 🔄 Implement security best practices

---

## Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [GitHub Webhooks](https://docs.github.com/en/developers/webhooks-and-events/webhooks)
- [AWS SSM Documentation](https://docs.aws.amazon.com/systems-manager/)

---

**Last Updated**: October 31, 2025
