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

And deploy:

```sh
terraform init
terraform apply
```
