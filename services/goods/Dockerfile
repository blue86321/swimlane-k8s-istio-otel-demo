FROM python:3.12-slim

WORKDIR /app

RUN apt-get update && \
  apt-get install -y --no-install-recommends build-essential

# Copy to nested "some/folder/" to address relative import issue
# source: https://github.com/grpc/grpc/issues/9575#issuecomment-293934506
COPY proto proto/proto

COPY services/goods .

# Compile the protobuf files for Python
RUN pip install --upgrade pip
RUN pip install --upgrade setuptools wheel
RUN pip install grpcio-tools==1.60.0
RUN python -m grpc_tools.protoc -I proto --python_out=. --grpc_python_out=. proto/proto/*.proto

# Install dependencies
RUN pip install -r requirements.txt

# Don't buffer `stdout` and `stderr`
ENV PYTHONUNBUFFERED=1

EXPOSE 50052

CMD ["python", "main.py"]