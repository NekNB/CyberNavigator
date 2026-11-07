# Запоминаем текущую директорию и переходим в secrets
use std/dirs

def main [] {
    if (which openssl | is-empty) {
        print $"(ansi red) ERROR: openssl not available. Check $env.PATH(ansi reset)"
    }
  dirs add "secrets"
  mut Output = "Ключи уже существуют"
  
  # Создаем папку keys, если её нет
  mkdir ./keys
  
  # Если нет приватного ключа, генерируем новые
  if not ("./keys/private.pem" | path exists) {
    cd ./keys
    ^openssl genrsa -out private.pem 2048
    ^openssl rsa -in private.pem -pubout -out public.pem
    
    # Присваиваем новое значение переменной (в PS тут была ошибка с записью в файл)
    $Output = "Созданы новые ключи"
  } 
  print $Output
  
  # Возвращаемся в исходную директорию
  dirs drop
}