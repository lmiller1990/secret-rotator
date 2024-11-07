# Rotate

Lambda / Secrets Manager combo to handle rotating passwords.

## Running

It uses Terraform and Python 3.12.

Python:

Make a virtual env and install deps:

```sh
pip install -r requirements.txt
```

Build

```sh
./lambda.sh
```

And deploy (make sure to update `*.tfvars` first):

```sh
terraform init
terraform apply -var-file="dev.tfvars"      # Development
terraform apply -var-file="staging.tfvars"  # Staging
terraform apply -var-file="demo.tfvars"     # Demo
terraform apply -var-file="prod.tfvars"     # Production
```
