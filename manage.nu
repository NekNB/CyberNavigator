const DefaultProjectName = "cyber-navigator"
const DefaultDockerHub =  "neknarej"

const services = [
	"nginx",
	"postgres",
	"mongo",
	"frontend",
	"article-service",
	"user-service",
	"simulator-service",
	"gateway-server",
]

export def build [
	Environment: string
	ServiceName: string
] {
	^docker build -f $"./docker/($Environment)/($ServiceName).dockerfile" -t $"($DefaultProjectName)_($Environment)/($ServiceName)" .
}

export def tag [
	Environment: string
	ServiceName: string
] {
	^docker tag $"($DefaultProjectName)_($Environment)/($ServiceName):latest" $"($DefaultDockerHub)/($DefaultProjectName)_($Environment)_($ServiceName):latest"
}

export def push [
	Environment: string
	ServiceName: string
] {
	docker push $"($DefaultDockerHub)/($DefaultProjectName)_($Environment)_($ServiceName):latest"
}

export def send [Environment: string ServiceName?: string] {
	if ($ServiceName | is-empty) {
		$services | each {
			|service|
			build $Environment $service
			tag $Environment $service
			push $Environment $service
		}
	} else {
		build $Environment $ServiceName
		tag $Environment $ServiceName
		push $Environment $ServiceName
	}
}

export def up [Environment: string ProjectName: string = $DefaultProjectName] {
	secrets-update
	deploy $Environment $ProjectName
}


export def deploy [
	Environment: string
	ProjectName: string = $DefaultProjectName
] {
	print $"(ansi y)WARNING: Deployment ($Environment) environment(ansi reset)"
	^docker stack deploy -c $"compose.($Environment).yaml" $ProjectName
}

export def secrets-remove [] {
	let secrets: table<ID: string, Name: string> = (docker secret ls --format json | from json --objects | select ID Name)
	$services | each {
		|service|
		let ServiceSecret = $"($service)_secret"
		let secret = $secrets | where Name == $ServiceSecret 
		if not ($secret | is-empty) {
			let result  = (do {^docker secret rm ($secret | get ID.0) | complete })
			if $result.exit_code != 0 {
					let serviceInUse = $result.stderr | find "is in use by the following service" | get 0 | ansi strip
				
					if not ($serviceInUse | is-empty) {
						let serviceName = ($serviceInUse | parse --regex "is in use by the following service: (?<serviceName>.+)") | get serviceName.0
						print $"(ansi y)WARNING: ($ServiceSecret) in use by the following service: ($serviceName)(ansi reset)"
					}
			} else {
				print $"Secret ($ServiceSecret) (ansi r) deleted(ansi reset)"
			}
		}
	} | ignore
}

export def secrets-create [] {
	ls ./secrets/env/*secret.env | get name | each {
		|secret|
		let secretName = $"($secret | parse "secrets\\env\\{serviceName}.{_}.{_}" | get serviceName.0)_secret"
		
		let result  = (do {^docker secret create $secretName $secret} | complete )
		if $result.exit_code != 0 {
			let secretAlreadyExists = $result.stderr | find $"secret ($secretName) already exists" | get 0 | ansi strip
			if not ($secretAlreadyExists | is-empty) {
				print $"(ansi y)WARNING: ($secretName) already exists(ansi reset)"
			}
		} else {
			print $"Secret ($secretName) (ansi g) created(ansi reset)"
		}
	} | ignore
}

export def secrets-update [service?: string] {
	secrets-remove 
	secrets-create 
}

export def start [service: string] {
	^docker service scale $"($DefaultProjectName)_($service)=1"
}
export def stop [service: string] {
	^docker service scale $"($DefaultProjectName)_($service)=0"
}

export def update [service: string Environment: string] {
	^docker service update --image $"neknarej/($DefaultProjectName)_($Environment)_($service):latest" --force $"($DefaultProjectName)_($service)" 
}
export def down [] {
	^docker stack rm $DefaultProjectName
}

export def init [] {
	^nu ./nu/convert-env.nu
	^nu ./nu/generate-mtls-certs.nu
	^nu ./nu/create-keys.nu
}

export def fill [] {
	let login = input "Login: "
	let password = input -s "Password: "
	print "Image build..."
	let imageHash = ^docker build -q -f ./docker/workers/fill.dockerfile .
	^docker service create --name fill-worker --mode replicated-job -e $'BASE_URL=https://cyber-navigator_gateway-server/api/v1' -e $'LOGIN=($login)' -e $'PASSWORD=($password)' --network $"($DefaultProjectName)_default" $imageHash
	unlet $login $password
	^docker service rm fill-worker
}