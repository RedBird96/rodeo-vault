start:
	go run *.go

testing:
	env RODEO_ENV=staging go run *.go

abi:
	abigen --abi abi_strategy.json --pkg main --type Strategy --out abi_strategy.go
	abigen --abi abi_oracle.json --pkg main --type Oracle --out abi_oracle.go
	abigen --abi abi_helper.json --pkg main --type Helper --out abi_helper.go
	abigen --abi abi_other.json --pkg main --type Other --out abi_other.go
	abigen --abi abi_investor.json --pkg main --type Investor --out abi_investor.go

db:
	psql -d rodeo

dbsetup:
	psql -c "CREATE ROLE admin WITH SUPERUSER LOGIN PASSWORD 'admin';" || true
	psql -c "CREATE DATABASE rodeo WITH OWNER admin;" || true
	psql -d rodeo < db.sql || true

dbreset:
	psql -c "DROP DATABASE rodeo;" || true
	psql -c "CREATE DATABASE rodeo WITH OWNER admin;" || true
	psql -d rodeo < db.sql || true

ssh:
	ssh $(RODEO_SSH_REMOTE)

deploy-build:
	GOOS=linux GOARCH=amd64 go build -ldflags "-s -w -extldflags=-static" -installsuffix cgo -o server *.go

deploy: deploy-build
	scp server $(RODEO_SSH_REMOTE):/tmp/dtmpl
	ssh $(RODEO_SSH_REMOTE) "mv /tmp/dtmpl /home/ubuntu/app"
	ssh $(RODEO_SSH_REMOTE) "sudo systemctl restart app"

deploy-testing: deploy-build
	scp server $(RODEO_SSH_REMOTE):/tmp/dtmpl
	ssh $(RODEO_SSH_REMOTE) "mv /tmp/dtmpl /home/ubuntu/testing"
	ssh $(RODEO_SSH_REMOTE) "sudo systemctl restart testing"

deploy-setup:
	scp config_nginx.conf $(RODEO_SSH_REMOTE):/tmp/dtmpl
	ssh $(RODEO_SSH_REMOTE) "sudo rm -rf /etc/nginx/sites-enabled/default"
	ssh $(RODEO_SSH_REMOTE) "sudo mv /tmp/dtmpl /etc/nginx/sites-enabled/app.conf"
	ssh $(RODEO_SSH_REMOTE) "sudo systemctl restart nginx"
	scp config_app.service $(RODEO_SSH_REMOTE):/tmp/dtmpl
	ssh $(RODEO_SSH_REMOTE) "sudo mv /tmp/dtmpl /etc/systemd/system/app.service"
	ssh $(RODEO_SSH_REMOTE) "sudo systemctl daemon-reload"
	ssh $(RODEO_SSH_REMOTE) "sudo systemctl enable app"

deploy-setup-testing:
	scp config_nginx.conf $(RODEO_SSH_REMOTE):/tmp/dtmpl
	ssh $(RODEO_SSH_REMOTE) "sudo rm -rf /etc/nginx/sites-enabled/default"
	ssh $(RODEO_SSH_REMOTE) "sudo mv /tmp/dtmpl /etc/nginx/sites-enabled/testing.conf"
	ssh $(RODEO_SSH_REMOTE) "sudo systemctl restart nginx"
	scp config_app.service $(RODEO_SSH_REMOTE):/tmp/dtmpl
	ssh $(RODEO_SSH_REMOTE) "sudo mv /tmp/dtmpl /etc/systemd/system/testing.service"
	ssh $(RODEO_SSH_REMOTE) "sudo systemctl daemon-reload"
	ssh $(RODEO_SSH_REMOTE) "sudo systemctl enable testing"
