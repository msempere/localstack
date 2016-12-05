AWS_STS_URL = http://central.maven.org/maven2/com/amazonaws/aws-java-sdk-sts/1.11.14/aws-java-sdk-sts-1.11.14.jar
ES_URL = https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/zip/elasticsearch/2.3.3/elasticsearch-2.3.3.zip
	TMP_ARCHIVE_ES = /tmp/localstack.es.zip

install: install-libs compile

install-libs:
	(pip install --upgrade pip)
	(test ! -e requirements.txt || (pip install -r requirements.txt))
	(test -e localstack/infra/elasticsearch || { mkdir -p localstack/infra; cd localstack/infra; test -f $(TMP_ARCHIVE_ES) || (curl -o $(TMP_ARCHIVE_ES) $(ES_URL)); cp $(TMP_ARCHIVE_ES) es.zip; unzip -q es.zip; mv elasticsearch* elasticsearch; rm es.zip; }) && \
		(test -e localstack/infra/amazon-kinesis-client/aws-java-sdk-sts.jar || { mkdir -p localstack/infra/amazon-kinesis-client; curl -o localstack/infra/amazon-kinesis-client/aws-java-sdk-sts.jar $(AWS_STS_URL); }) && \
		(cd localstack/ && (test ! -e package.json || (npm install)))

install-web:
	(cd localstack/dashboard/web && (test ! -e package.json || npm install))

compile:
	python -c 'from localstack.utils.kinesis import kclipy_helper; print kclipy_helper.get_kcl_classpath()'
	javac -cp $(shell python -c 'from localstack.utils.kinesis import kclipy_helper; print kclipy_helper.get_kcl_classpath()') localstack/utils/kinesis/java/com/atlassian/*.java

infra:
	(python localstack/mock/infra.py)

web:
	($(bin/localstack web --port=8081)

test: 
	PYTHONPATH=`pwd` nosetests --with-coverage --logging-level=WARNING --nocapture --no-skip --exe --cover-erase --cover-tests --cover-inclusive --cover-package=localstack --with-xunit . && \
			   make lint

lint:
	(pep8 --max-line-length=120 --ignore=E128 --exclude=node_modules,legacy,dist .)

clean:
	rm -rf localstack/dashboard/web/node_modules/
	rm -rf localstack/mock/target/
	rm -rf localstack/infra/amazon-kinesis-client
	rm -rf localstack/infra/elasticsearch
	rm -rf localstack/node_modules/
	rm -f localstack/utils/kinesis/java/com/atlassian/*.class

.PHONY: compile clean install web install-web infra test install-libs
