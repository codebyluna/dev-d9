To create a QuickStart Template of this application, run "create_quickstart.sh"

This will recreate/refresh the following dump files and commit them to your repo:
.devpanel/db.sql.tgz
.devpanel/files.tgz

It will also create/update the following files:
.devpanel/quickstart/quickstart.url
.devpanel/quickstart/deploy-to-bitnami.txt

The quickstart.url file has the url that you can share with others to let them duplicate/clone this application in their own Free DevPanel account. 

You can limit access to your application by making your repo private and only sharing your repo and the quickstart url with the people you want.

The deploy-to-bitnami.txt file has instructions on how to deploy this application to a Bitnami VPS. 
NOTE: This file is not managed by DevPanel and must be maintained by the author of the each quickstart template. 