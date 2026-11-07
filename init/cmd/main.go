package main

import (
	"os"
	"github.com/NekNB/CyberNavigator/init/internal/http"
	parser "github.com/NekNB/CyberNavigator/init/internal/init"
	"github.com/NekNB/CyberNavigator/init/internal/lib/logger"
)

func main() {

	log, err := logger.Init("local")
	if err != nil {
		panic(err)
	}

	apiClient := http.New(log, "http://cyber-navigator_gateway-server:80/api/v1")

	login := os.Getenv("LOGIN")
	password := os.Getenv("PASSWORD")
	apiClient.Login(login, password)


	log.Info("Инициализация проекта началась...")
	if err := parser.ProcessArticles(apiClient, log); err != nil {
		log.Warning(err)
	}

	if err := parser.InitScenarios(apiClient, log); err != nil {
		log.Warning(err)
	}
}
