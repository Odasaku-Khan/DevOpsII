#!/bin/bash 
useradd sysadm 
useradd operations
groupadd sysadmins
groupadd operation
usermod -aG sysadmin sysadm
usermod -aG operation operations
visudo
#%sysadmin ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart /usr/bin/systemctl start  /usr/bin/systemctstop
#%operation ALL=(ALL) NOPASSWD: /usr/bin/podman exec

git clone https://github.com/dvalyayevkbtu/payment
cd payment 

cat >> Dockerfile 
FROM golang:1.24.2 -alpine AS builder 
WORKDIR /app
COPY go.sum go.mod
RUN go mod download 
COPY . . 
RUN go build -o payment .

FROM alpine:3.19 
WORKDIR /app
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
COPY --from=builder /app/payment . 
USER appuser 
EXPOSE 8080
HEALTHCHECK --intervals=30s --timeout=5s CMD wget -q0- https://localhost:8080/health || exit 1
CMD ["./payment"]
#end of Dockerfile

podman login docker.io

podman build -t payment_harden:latest odasaku/payment_harden:latest
podman push odasaku/payment_harden:latest

podman rum -d --name payment --cpus="1" --memory="512m" -p 8080:8080 payment_harden:latest

cat >> container.sh
#!/bin/bash
git clone https://github.com/dvalyayevkbtu/payment
cd payment 

cat >> Dockerfile 
FROM golang:1.24.2 -alpine AS builder 
WORKDIR /app
COPY go.sum go.mod
RUN go mod download 
COPY . . 
RUN go build -o payment .

FROM alpine:3.19 
WORKDIR /app
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
COPY --from=builder /app/payment . 
USER appuser 
EXPOSE 8080
HEALTHCHECK --intervals=30s --timeout=5s CMD wget -q0- https://localhost:8080/health || exit 1
CMD ["./payment"]

podman login docker.io

podman build -t payment_harden:latest odasaku/payment_harden:latest
podman push odasaku/payment_harden:latest

podman rum -d --name payment --cpus="1" --memory="512m" -p 8080:8080 payment_harden:latest

podman rm -rf payment

rm -rf payment
#end of container.sh
chwon operations:operation container.sh
chmod 750 container.sh

cat >> /etc/audit/rules.d/container.rules
-w /root/container.sh -p wa -k container_script
#end of container.rules
sudo augenrules --load
sudo service auditd restart

sudo -U sysadm /root/container.sh

cat>> /etc/nftables.conf
table inet filter {
    chain input{
        type filter hook input priority 0; policy drop;
        iif "lo" accept 
        ct state established,related accept
        tcp dport 22 accept
        tcp dport 4200 accept 
        tcp dport 8080 accept
        }
    chain forward{
        type filter hook forward priority 0; policy drop;
        }
    chain output{
        type filter hook output priority 0; policy accept;
        }
}
#end of nftables.conf






