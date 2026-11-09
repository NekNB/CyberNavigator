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
	baseURL := os.Getenv("BASE_URL")
	apiClient := http.New(log, baseURL)

	login := os.Getenv("LOGIN")
	password := os.Getenv("PASSWORD")

	if login == "" || password == "" {
		log.Fatal("Login or Password Not Found")
		os.Exit(1)
	}
	apiClient.Login(login, password)

	log.Info("Инициализация проекта началась...")
	if err := parser.ProcessArticles(apiClient, log); err != nil {
		log.Warning(err)
	}

	if err := parser.InitScenarios(apiClient, log); err != nil {
		log.Warning(err)
	}
}
