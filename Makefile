AWS_STS_URL = http://central.maven.org/maven2/com/amazonaws/aws-java-sdk-sts/1.11.14/aws-java-sdk-sts-1.11.14.jar
ES_URL = https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/zip/elasticsearch/2.3.3/elasticsearch-2.3.3.zip
	TMP_ARCHIVE_ES = /tmp/localstack.es.zip

usage:             ## Show this help
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

install:           ## Install npm/pip dependencies, compile code
	make install-libs && \
	make compile

install-libs:      ## Install npm/pip dependencies, compile code
	(pip install --upgrade pip)
	(test ! -e requirements.txt || (pip install -r requirements.txt))
	(test -e localstack/infra/elasticsearch || { mkdir -p localstack/infra; cd localstack/infra; test -f $(TMP_ARCHIVE_ES) || (curl -o $(TMP_ARCHIVE_ES) $(ES_URL)); cp $(TMP_ARC
	(test -e localstack/infra/amazon-kinesis-client/aws-java-sdk-sts.jar || { mkdir -p localstack/infra/amazon-kinesis-client; curl -o localstack/infra/amazon-kinesis-cl
	(cd localstack/ && (test ! -e package.json || (npm install)))

install-web:       ## Install npm dependencies for dashboard Web UI
	(cd localstack/dashboard/web && (test ! -e package.json || npm install))

compile:           ## Compile Java code (KCL library utils)
	echo "Compiling"
	python -c 'from localstack.utils.kinesis import kclipy_helper; print kclipy_helper.get_kcl_classpath()'
	javac -cp $(shell python -c 'from localstack.utils.kinesis import kclipy_helper; print kclipy_helper.get_kcl_classpath()') localstack/utils/kinesis/java/com/atlassian/*.java

infra:             ## Manually start the local infrastructure for testing
	(python localstack/mock/infra.py)

web:               ## Start web application (dashboard)
	($(bin/localstack web --port=8081)

test:              ## Run automated tests
	PYTHONPATH=`pwd` nosetests --with-coverage --logging-level=WARNING --nocapture --no-skip --exe --cover-erase --cover-tests --cover-inclusive --cover-package=localstack --wit
	make lint

lint:              ## Run code linter to check code style
	(pep8 --max-line-length=120 --ignore=E128 --exclude=node_modules,legacy,dist .)

clean:             ## Clean up (npm dependencies, downloaded infrastructure code, compiled Java classes)
	rm -rf localstack/dashboard/web/node_modules/
	rm -rf localstack/mock/target/
	rm -rf localstack/infra/amazon-kinesis-client
	rm -rf localstack/infra/elasticsearch
	rm -rf localstack/node_modules/
	rm -f localstack/utils/kinesis/java/com/atlassian/*.class
