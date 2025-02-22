FROM amazon/aws-sam-cli-build-image-python3.9:latest
WORKDIR /var/task
COPY requirements/ requirements/
RUN rm -rf python layer.zip && \
    mkdir -p python && \
    pip install --upgrade pip && \
    pip install -r requirements/prod.txt -t python && \
    zip -r layer.zip python/