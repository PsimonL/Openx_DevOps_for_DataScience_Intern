Invoke-RestMethod -Uri http://localhost:8080/convert -Method Post -ContentType "application/json" -Body '{"fahrenheit": 32}'

docker build -t openx_intern_task:1.0 .

docker run -p 8080:8080 openx_intern_task:1.0

helm install openx-chart ./openx-flask-api
