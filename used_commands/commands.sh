#! /bin/bash

# ============================================================================================================================================================
# REQUESTS TO TEST
curl -X POST -H "Content-Type: application/json" -d '{"fahrenheit": 32}' http://localhost:8080/convert
# Example minikube tunnel for service api
curl -X POST -H "Content-Type: application/json" -d '{"fahrenheit": 32}' http://127.0.0.1:55343/convert
curl -X GET http://localhost:8080/probe
# kubectl exec openx-api-684b578f57-nhll5 -- curl -X POST -H "Content-Type: application/json" -d '{"fahrenheit": 32}' http://localhost:5000/convert
# ============================================================================================================================================================

# ============================================================================================================================================================
# API STEPS
docker build -t openx_intern_task .
docker build -t openx_intern_task -f Dockerfile-go .
docker run -p 8080:8080 srpl/openx_intern_task:1.0.0
helm install openx-chart ./api
# Very important cause of minikube internal tunneling
minikube service openx-api
# ============================================================================================================================================================

# ============================================================================================================================================================
# LOCUST STEPS
locust -f locustfile.py --headless --csv output/locust.txt -t5m --host=http://localhost:8080
docker build -t openx_intern_task_locust -f Dockerfile-locust .
docker tag openx_intern_task_locust:latest srpl/openx_intern_task_locust:1.0.0
docker login
docker push openx_intern_task_locust:1.0.0
# ============================================================================================================================================================

# ============================================================================================================================================================
# TENSORFLOW SERVING STEPS
docker pull tensorflow/serving
docker build --no-cache -t openx_intern_task_tfs -f Dockerfile-tf-serving .
docker tag openx_intern_task_tfs:latest srpl/openx_intern_task_tfs:1.0.0
docker run -t --rm -p 8501:8501 -v "/model/saved_model" -e MODEL_NAME=saved_model tensorflow/serving 
docker login
docker push openx_intern_task_tfs:1.0.0


# Download the TensorFlow Serving Docker image and repo
docker pull tensorflow/serving

git clone https://github.com/tensorflow/serving
# Location of demo models
TESTDATA="$(pwd)/serving/tensorflow_serving/servables/tensorflow/testdata"

# Start TensorFlow Serving container and open the REST API port
docker run -t --rm -p 8501:8501 \
    -v "$TESTDATA/saved_model_half_plus_two_cpu:/models/half_plus_two" \
    -e MODEL_NAME=half_plus_two \
    tensorflow/serving &

# Query the model using the predict API
curl -d '{"instances": [1.0, 2.0, 5.0]}' \
    -X POST http://localhost:8501/v1/models/half_plus_two:predict

# Returns => { "predictions": [2.5, 3.0, 4.5] }
# ============================================================================================================================================================

