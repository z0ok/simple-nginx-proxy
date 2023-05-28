### Generate dh-params

2048 or 4096

```
openssl dhparam -out ssl-dhparam.pem 2048
```

```
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ./ca.key -out ./ca.pem
```
