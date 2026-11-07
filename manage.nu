const DefaultDockerComposeFile = "docker-compose.yaml"
const DefaultProjectName = "cyber-navigator"

const services = [
	"nginx",
	"postgres",
	"mongo",
	"article-service",
	"user-service",
	"simulator-service",
	"gateway-server",
]

export def build [
	Environment: string
	ServiceName: string
] {
	^docker build -f $"./docker/($Environment)/($ServiceName).dockerfile" -t $"($DefaultProjectName)/($ServiceName)" .
}

export def tag [
	ServiceName: string
] {
	^docker tag $"cyber-navigator/($ServiceName):latest" $"neknarej/($DefaultProjectName)_($ServiceName):latest"
}

export def push [
	ServiceName: string
] {
	docker push $"neknarej/($DefaultProjectName)_($ServiceName):latest"
}

export def send [serviceName?: string] {
	if ($serviceName | is-empty) {
		$services | each {
			|service|
			build prod $service
			tag $service
			push $service
		}
	} else {
		build prod $serviceName
		tag $serviceName
		push $serviceName
	}
}

export def up [
	Environment: string	
] {
	secrets-update
	deploy
}


export def deploy [
	DockerComposeFile: string = $DefaultDockerComposeFile
	ProjectName: string = $DefaultProjectName
] {
	^docker stack deploy -c $DockerComposeFile $ProjectName
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
		# print $secretName $secret
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

export def update [service: string] {
	^docker service update --image $"neknarej/($DefaultProjectName)_($service):latest" --force $"($DefaultProjectName)_($service)" 
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
	let imageHash = ^docker build -q -f ./docker/init.dockerfile .
	^docker run --rm -it -e $'LOGIN="($login)"' -e $'PASSWORD="($password)"' --network "$($DefaultProjectName)_default" $imageHash
	unlet $login $password
}