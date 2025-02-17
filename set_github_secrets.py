import os
import base64
import subprocess
import json
import boto3
from nacl import encoding, public
import requests
import yaml

def get_repository_name():
    """Get repository name from git remote URL"""
    try:
        remote_url = subprocess.check_output(['git', 'config', '--get', 'remote.origin.url']).decode('utf-8').strip()
        # Convert SSH or HTTPS URL to owner/repo format
        if remote_url.endswith('.git'):
            remote_url = remote_url[:-4]
        if remote_url.startswith('git@github.com:'):
            return remote_url.split('git@github.com:')[1]
        if remote_url.startswith('https://github.com/'):
            return remote_url.split('https://github.com/')[1]
        raise ValueError(f"Could not parse repository name from {remote_url}")
    except subprocess.CalledProcessError:
        raise ValueError("Not a git repository or no remote 'origin' set")

def encrypt(public_key: str, secret_value: str) -> str:
    """Encrypt a Unicode string using the public key."""
    public_key = public.PublicKey(public_key.encode("utf-8"), encoding.Base64Encoder())
    sealed_box = public.SealedBox(public_key)
    encrypted = sealed_box.encrypt(secret_value.encode("utf-8"))
    return base64.b64encode(encrypted).decode("utf-8")

def set_secret(token: str, repository: str, secret_name: str, secret_value: str):
    """Set a secret in a GitHub repository."""
    headers = {
        'Accept': 'application/vnd.github.v3+json',
        'Authorization': f'Bearer {token}',
    }

    # Get the public key for the repository
    url = f'https://api.github.com/repos/{repository}/actions/secrets/public-key'
    r = requests.get(url, headers=headers)
    r.raise_for_status()
    public_key_data = r.json()

    # Encrypt the secret value
    encrypted_value = encrypt(public_key_data['key'], secret_value)

    # Set the secret
    url = f'https://api.github.com/repos/{repository}/actions/secrets/{secret_name}'
    data = {
        'encrypted_value': encrypted_value,
        'key_id': public_key_data['key_id']
    }
    r = requests.put(url, headers=headers, json=data)
    r.raise_for_status()
    print(f"Successfully set secret: {secret_name}")

def get_secrets_from_ssm():
    """Get AWS and GitHub credentials from SSM Parameter Store"""
    # First get AWS credentials from environment
    aws_access_key = os.getenv("AMAZON_ACCESS_KEY_ID")
    aws_secret_key = os.getenv("AMAZON_SECRET_ACCESS_KEY")

    # If not in environment, try loading from .env file
    if not (aws_access_key and aws_secret_key):
        current_dir = os.path.dirname(os.path.abspath(__file__))
        env_path = os.path.join(current_dir, ".env")
        if os.path.exists(env_path):
            with open(env_path) as f:
                for line in f:
                    if line.startswith('AMAZON_ACCESS_KEY_ID='):
                        aws_access_key = line.split('=', 1)[1].strip().strip('\'"')
                    elif line.startswith('AMAZON_SECRET_ACCESS_KEY='):
                        aws_secret_key = line.split('=', 1)[1].strip().strip('\'"')

    if not (aws_access_key and aws_secret_key):
        raise ValueError("AWS credentials not found in environment or .env file")

    # Create AWS session
    session = boto3.Session(
        aws_access_key_id=aws_access_key,
        aws_secret_access_key=aws_secret_key,
        region_name="ap-northeast-1"
    )

    # Get GitHub PAT from SSM
    ssm = session.client('ssm')
    response = ssm.get_parameter(
        Name='GITHUB_SECRETS',
        WithDecryption=True
    )
    
    github_secrets = json.loads(response['Parameter']['Value'])
    if not github_secrets.get('PERSONAL_ACCESS_TOKEN', {}).get('my_token'):
        raise ValueError("GitHub PAT not found in SSM parameter GITHUB_SECRETS")
    
    return github_secrets['PERSONAL_ACCESS_TOKEN']['my_token']

def main():
    # Get repository name from git config
    repository = get_repository_name()
    print(f"Repository: {repository}")

    # Get GitHub token from SSM
    token = get_secrets_from_ssm()
    print("Successfully retrieved GitHub PAT from SSM")

    # Read secrets from .env file
    base_dir = os.path.dirname(os.path.abspath(__file__))
    env_file = os.path.join(base_dir, ".env")
    
    if not os.path.exists(env_file):
        raise FileNotFoundError(f".env file not found at {env_file}")

    with open(env_file, 'r') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            
            try:
                key, value = line.split('=', 1)
                # Remove any quotes
                value = value.strip('"\'')
                
                print(f"Setting secret: {key}")
                set_secret(token, repository, key, value)
            except Exception as e:
                print(f"Error setting secret {key}: {str(e)}")
                continue

if __name__ == "__main__":
    main()
