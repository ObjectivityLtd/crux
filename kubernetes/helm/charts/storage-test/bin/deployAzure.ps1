helm upgrade storage-test ../ --set storage-class.storage.host=azure --install --namespace helm --create-namespace --dry-run