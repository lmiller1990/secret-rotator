pip install -r requirements.txt --upgrade -t package --only-binary=:all: --python-version 3.12 --platform manylinux2014_x86_64
cp -r rotate package/
cd package ; zip -r ../lambda.zip . -x '*.pyc'
