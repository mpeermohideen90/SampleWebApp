1. To create Entire infrastructure, need to run the IaC scripts from Infrastructure folder
2. "docker-compose.yml" is create and run the all relavent containers for StudentApp application
3. Github actions created for CI/CD process.
     - CICD will Trigger Once new commit applied in Github repo.
     - It will build and Test the code, and Deploy into the Azure web app environment.
