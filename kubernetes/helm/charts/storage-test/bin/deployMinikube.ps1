helm upgrade storage-test ../ --set storage-class.storage.host=minikube --install --namespace helm --create-namespace