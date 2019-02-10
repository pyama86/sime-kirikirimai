build:
	docker build -t pyama/simekirikirimai:0.0.1 .

push: build
	docker push pyama/simekirikirimai:0.0.1

run: build
	docker run -e GITHUB_TOKEN=$(GITHUB_TOKEN) \
		-e GOOGLE_CALENDER_ID=$(GOOGLE_CALENDER_ID) \
		-v `pwd`/credential.json:/opt/simekiri/credential.json \
		-v `pwd`/token.yaml:/opt/simekiri/token.yaml \
		-it pyama/simekirikirimai:0.0.1
