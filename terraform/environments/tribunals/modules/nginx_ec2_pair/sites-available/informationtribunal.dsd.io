# This template is designed for simple 301 permanent redirects from the NGINX instance on 52.30.196.9

# INSTRUCTIONS:

## COPY SERVER BLOCK FROM TEMPLATE, REPLACING *URL* WITH THE URL TO BE REDIRECTED
#sudo cp /etc/nginx/sites-available/template /etc/nginx/sites-available/*URL*

## EDIT CONFIG, REPLACING *URL* WITH THE URL TO BE REDIRECTED (not including the http://), AND *TARGET* WITH THE TARGET URL 
#sudo vim /etc/nginx/sites-available/*URL*

#	server {
#	        listen 80;
#	        listen [::]:80;
#
#	        server_name *URL*;
#
#	        return  301 http://*TARGET*$request_uri;
#	}

## CREATE SYMBOLIC LINKS FROM 'sites-available' to 'sites-enabled'
#sudo ln -s /etc/nginx/sites-available/*URL* /etc/nginx/sites-enabled/

## RESTART NGINX
# sudo service nginx stop
# sudo service nginx start

server {
	listen 80;
	listen 443;

	server_name informationtribunal.dsd.io;
	
	location / {
		 return 301 https://www.gov.uk/guidance/information-rights-appeal-against-the-commissioners-decision$request_uri;
	}
	location ~* ^/Public {
		 return 301 https://informationrights.decisions.tribunals.gov.uk$request_uri;
	}
	location ~* ^/admin {
		return 301 https://www.google.com$request_uri;
	}
        location ~* ^/DBFiles {
                return 301 https://informationrights.decisions.tribunals.gov.uk$request_uri;
        }
}

