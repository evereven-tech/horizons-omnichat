
Reference: https://gauravve.medium.com/connecting-open-webui-to-aws-bedrock-a1f0082c8cb2

# Connecting Open-WebUI to AWS Bedrock

In my recent endeavor to create a Retrieval-Augmented Generation (RAG) solution, I encountered a challenge. RAG applications are inherently complex with numerous components. However, to make these applications user-friendly, it’s crucial to simplify user experience by providing a chat- interface that abstracts underlying complexities from end-users.

Observing the sophisticated chat interfaces of Claude and ChatGPT, which would be time-consuming to develop from scratch, I began searching for an open-source alternative that could offer similar functionality.

During my research, I discovered Open-WebUI (previously known as ollama-ui). This project stands out as the most comprehensive chat interface solution I’ve found so far. It closely resembles the functionality of Claude or ChatGPT’s interfaces and is actively maintained and developed.

🏡 Home | Open WebUI
Open WebUI is an extensible, feature-rich, and user-friendly self-hosted WebUI designed to operate entirely offline. It…
docs.openwebui.com

While many examples and videos talk about using it with Ollama, I got curious on how I can possibly integrate this to AWS Bedrock as that is what we were using to build our RAG solution. The biggest draw card for me was ability to authenticate users both locally and using OAuth.

Architecture
Adhering to established standards often simplifies integration processes. AWS has released a project called bedrock-access-gateway, which provides an API layer for Bedrock that conforms to the OpenAI API specification. This specification is publicly available on GitHub.

https://github.com/openai/openai-openapi/blob/master/openapi.yaml

Open-WebUI, by design, is compatible with OpenAI’s API specification, making it readily usable with this setup.

While the complete architecture has been illustrated using AWS icons, for the purposes of this blog post, we’ll focus on running the setup locally on a personal workstation.


Step 1 : Run Open Web UI
I prefer using Postgres as database backend to persist settings and chat. Otherwise, every time you shut down the container you have to start from scratch.

I used the the following docker compose to bring up Postgres and Openweb-UI

```
services:
  webui-db:
    image: hub.docker.internal.cba/postgres:13
    environment:
      - POSTGRES_DB=myapp_db
      - POSTGRES_USER=myapp_user
      - POSTGRES_PASSWORD=myapp_pass
    ports:
      - "5431:5431"
    command: -p 5431
    volumes:
      - /Users/vermag1/data/postgres/open-webui:/var/lib/postgresql/data
    healthcheck:
      test: [ "CMD-SHELL", "pg_isready -U myapp_user -d myapp_db -p 5431" ]
      interval: 3s
      timeout: 5s
      retries: 5
    restart: always

  open-webui:
    image: ghcr.io/open-webui/open-webui:0.3.10
    container_name: open-webui
    depends_on:
      - webui-db
    ports:
      - 3002:8080
    environment:
      - 'OLLAMA_BASE_URL=http://host.docker.internal:11434'
      - 'WEBUI_SECRET_KEY='
      - 'WEBUI_DB_HOST=webui-db'
      - 'DATABASE_URL=postgresql://myapp_user:myapp_pass@webui-db:5431/myapp_db'
    extra_hosts:
      - host.docker.internal:host-gateway
    restart: unless-stopped

volumes:
  ollama: {}
  open-webui: {}

```


I am using port 3002 here as my 3000 is already take by another application but feel free to use a port that works best for you.

All things going to plan , you will see something like the logs shown below

Step 2 : Run Bedrock access Gateway
We need to build docker image for Bedrock access gateway before it can be used. Here are the steps

Clone https://github.com/aws-samples/bedrock-access-gateway
Run the following command
docker build . -f Dockerfile_ecs -t bedrock-gateway
3. Authenticate to get AWS access tokens or get AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY and set them up as environment variables.

4. Run the following command

```
docker run -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
-e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
-e AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN \
-e API_KEY_PARAM_NAME=123456 \
-e AWS_REGION=ap-southeast-2 \
-e DEBUG=true \
-d -p 8000:80 \
bedrock-gateway
```


All things going to plan you should see an output similar to this in about 10 seconds


Step 3: Connect Open-WebUI to Bedrock access gateway
To connect add a new connection [Admin Panel → Settings → Connections]


Check connectivity by pressing the sync icon. This also fetched as list of models from the models endpoint.

There is a default API key used by bedrock access gateway which can be found in repository documentation.

Step 4: Use Claude 3 Sonnet on AWS Bedrock
Congratulations to make it this far. Whats left is to open a new chat window, change the model to Claude 3 Sonnet as shown below and test the model.


Change the model

Test the model
Logs from the access Gateway will look something similar to this



Next steps
Next blog post, I will talk about how can we run this setup on AWS using ECS Fargate. There are some security considerations to run this on AWS.

Thank you for reading. Hope you found this helpful.
