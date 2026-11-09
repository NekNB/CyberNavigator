# CyberNavigator
**English** | [Русский](README.ru.md)

CyberNavigator — online platform featuring articles on digital hygiene and a fraud scheme simulator
The fraud scheme simulator — online game where the player is targeted by a scammer in a messaging app. Players must spot the tell-tale signs and avoid falling for the scam

<img width="1509" height="844" alt="image" src="https://github.com/user-attachments/assets/fd8daf21-936a-47fa-b742-2655709537c5" />

### Stack
- [Docker Swarm](https://docs.docker.com/engine/swarm/) — Container orchestration
- [NuShell](https://www.nushell.sh/) — Structured terminal shell
- Golang — The entire backend
- NextJS + TypeScript — The entire frontend
- Postgres — Metadata of services
- Mongo — Texts of articles
- Nginx — Reverse Proxy + SSL certificates + traffik router
- Docker — Cleaning up dead containers

### Prepare
1. Edit /nginx/conf and /nginx/scripts. **Change the domain**
2. Enter the nushell with command `nu`
3. Activate the manage.nu module with command `use manage.nu *`
4. Initialize the secret data with command `init`
5. Edit the secret data located at /secrets/env/*
6. Return to the project root
7. Create the secrets with the command `secrets-create`

### Project management
Use the manage.nu module  in nushell with command `use manage.nu *`
- deploy env — Project Deployment
- down — Delete the stack
- update serviceName — Update the service and its image version
- secrets-update — Use after modifiing the files in /secrets/env/*.secret.env
- start serviceName — Set 1 replica for the serviceName service
- stop serviceName — Set 0 replicas for the serviceName service

### Development
> Change image owner «neknarej» to your own in the files: compose.*.yaml and manage.nu. Then reload the manage.nu module with the command `use manage.nu *`
- send — send all images to Docker Hub. `send serviceName` — send only serviceName
- tag — Link a local image to an online repo
- push — Send a local image to an online repo
- build — Build an image

### About The Project Code
The project supports 3 environments:
- local — Used on host
- dev — Used inside docker for local development (switches the project to local network operation)
- prod — Used inside docker in production (switches the project to external network operation)

> The gateway-server and services use a connection secured via mTLS
>
> Each service has the Swagger UI at `service_url/swagger`
> 
> All services Swagger UI page at `gateway-server_url/swagger`
> 
> To edit the OpenApi specification, you should edit files in /swagger/docs/*. Then run nu-script nu /nu/swagger-gen.nu FileName. **Important!!!** Provide only filename *.swagger.yaml. If you create a new file, edit the nu-script. Then commit the changes and update the service with the command `go get your-repo/swagger@commit-hash`
