package http

import (
	"fmt"
	"strings"

	"github.com/imroc/req/v3"
	"github.com/sirupsen/logrus"
)

type Response[T any] struct {
	Code int
	Body *T
}

type APIClient struct {
	log       *logrus.Logger
	apiClient *req.Client
}

func New(log *logrus.Logger, baseUrl string) *APIClient {

	apiClient := req.NewClient()

	apiClient.
		SetBaseURL(baseUrl).
		EnableInsecureSkipVerify().
		SetCommonRetryCount(1).
		SetCommonRetryCondition(func(resp *req.Response, err error) bool {
			if err != nil {
				return false
			}
			log.Debug(resp.Request.URL.Path)
			return resp.StatusCode == 401 && !strings.Contains(resp.Request.URL.Path, "/auth")
		}).
		SetCommonRetryHook(func(resp *req.Response, err error) {
			log.Info("Получили 401 пытаемся обновить токены")
			refreshResp, err := apiClient.R().Put("/auth/refresh")
			if err != nil {
				log.Errorf("Ошибка сети при обновлении куки: %v", err)
				return
			}
			if !refreshResp.IsSuccessState() {
				log.Errorf("Сервер вернул ошибку при обновлении куки: %d", refreshResp.StatusCode)
				return
			}
			log.Info("Куки успешно обновлены, повторяем исходный запрос...")
		})

	return &APIClient{
		log:       log,
		apiClient: apiClient,
	}
}

func (a *APIClient) Login(username, pasword string) error {
	resp, err := a.apiClient.R().SetBody(map[string]string{
		"username": username,
		"password": pasword,
	}).Post("/auth/login")
	if err != nil {
		a.log.Warn(err)
		return err
	}
	if !resp.IsSuccessState() {
		a.log.Warn(resp.StatusCode)
		return fmt.Errorf("Неизвестная ошибка %d", resp.StatusCode)
	}
	return nil
}
