# Installation instructions for CentOS 7

## Assumptions
elksrv.testlab.local __(ELK master)__

client.testlab.local __(client machine)__

## ELK Stack installation on server.example.com
###### Install Java 8
```
yum install -y java-1.8.0-openjdk
```
###### Import PGP Key
```
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
```
###### Create Yum repository
```
cat >>/etc/yum.repos.d/elasticsearch.repo<<EOF
[elasticsearch]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF
```
### Elasticsearch
###### Install Elasticsearch
```
yum install -y elasticsearch
```
###### Enable and start elasticsearch service
```
systemctl daemon-reload
systemctl enable elasticsearch
systemctl start elasticsearch
journalctl --unit elasticsearch
```
### Kibana
###### Install kibana
```
yum install -y kibana
```
###### Enable and start kibana service
```
systemctl daemon-reload
systemctl enable kibana
systemctl start kibana
journalctl --unit
```
###### Install Nginx
```
yum install -y epel-release
yum install -y nginx
```
###### Create Proxy configuration
Remove server block from the default config file /etc/nginx/nginx.conf
And create a new config file
```
cat >>/etc/nginx/conf.d/kibana.conf<<EOF
server {
    listen 80;
    server_name elksrv.testlab.local;
    location / {
        proxy_pass http://localhost:5601;
    }
}
EOF
```
###### Enable and start nginx service
```
systemctl enable nginx
systemctl start nginx
```
### Logstash
###### Install logstash
```
yum install -y logstash
```
###### Generate SSL Certificates
```
openssl req -subj '/CN=*.testlab.local/' -x509 -days 3650 -nodes -batch -newkey rsa:2048 -keyout /etc/pki/tls/private/testlab.key -out /etc/pki/tls/certs/testlab.crt
```
###### Create Logstash config file
```
vi /etc/logstash/conf.d/01-logstash-simple.conf
```
Paste the below content
```
input {
  beats {
    port => 5044
    ssl => true
    ssl_certificate => "/etc/pki/tls/certs/logstash.crt"
    ssl_key => "/etc/pki/tls/private/logstash.key"
  }
}

filter {
    if [type] == "syslog" {
        grok {
            match => {
                "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:syslog_message}"
            }
            add_field => [ "received_at", "%{@timestamp}" ]
            add_field => [ "received_from", "%{host}" ]
        }
        syslog_pri { }
        date {
            match => [ "syslog_timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
        }
    }
}

output {
    elasticsearch {
        hosts => "localhost:9200"
        index => "%{[@metadata][beat]}-%{+YYYY.MM.dd}"
    }
}
```
###### Enable and Start logstash service
```
systemctl enable logstash
systemctl start logstash
journalctl --unit logstash
```

## FileBeat installation on client.testlab.local
###### Create Yum repository
```
cat >>/etc/yum.repos.d/elasticsearch.repo<<EOF
[elasticsearch]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF
```
###### Install Filebeat
```
yum install -y filebeat
```
###### Copy SSL certificate from server.example.com
```
scp server.example.com:/etc/pki/tls/certs/logstash.crt /etc/pki/tls/certs/
```
###### Configure Filebeat 

###### Enable and start Filebeat service
```
systemctl enable filebeat
systemctl start filebeat
journalctl --unit filebeat
```
### Configure Kibana Dashboard
All done. Now you can head to Kibana dashboard and add the index.
