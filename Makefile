build:
	docker build -t pyama86/simekirikirimai:0.0.1 .

push: build
	docker push pyama86/simekirikiriMai

run: build
	docker run -e GITHUB_TOKEN=$(GITHUB_TOKEN) \
		-e GOOGLE_CALENDER_ID=$(GOOGLE_CALENDER_ID) \
		-v `pwd`/credential.json:/opt/simekiri/credential.json \
		-v `pwd`/token.yaml:/opt/simekiri/token.yaml \
		-it pyama86/simekirikirimai:0.0.1
