# Official framework image. Look for the different tagged releases at:
# https://hub.docker.com/r/library/node/tags/

image: alpine:latest

variables:
  KUBE_INGRESS_BASE_DOMAIN: 6ddqdptug4.lb.c1.gra7.k8s.ovh.net
  HELM_VERSION: 2.12.2
  DOCKER_DRIVER: overlay2
  KUBERNETES_VERSION: 1.17.0

stages:
  - build
  - deploy_prod

cache:
  paths:
    - node_modules/

build_apps:
  stage: build
  image: docker:stable-git
  services:
    - docker:stable-dind
  script:
    - setup_docker
    - registry_login
    - build_docker

deploy_production:
  stage: deploy_prod
  script:
    - install_dependencies
    - initialize_tiller
    - create_secret
    - deploy
  environment:
    name: prod
    url: https://rtmp.music4heroes.live
  only:
    - master

# ------------------------------------------------------------------

.auto_devops: &auto_devops |
  # Auto DevOps variables and functions
  [[ "$TRACE" ]] && set -x
  export CI_APPLICATION_TAG=$CI_COMMIT_SHA
  export CI_APPLICATION_REPOSITORY=$CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG
  export TILLER_NAMESPACE=$KUBE_NAMESPACE



  function setup_docker() {
    if ! docker info &>/dev/null; then
      if [ -z "$DOCKER_HOST" -a "$KUBERNETES_PORT" ]; then
        export DOCKER_HOST='tcp://localhost:2375'
      fi
    fi
  }


  function create_secret() {
    echo "Create secret..."
    if [[ "$CI_PROJECT_VISIBILITY" == "public" ]]; then
      return
    fi

    kubectl create secret -n "$KUBE_NAMESPACE" \
      docker-registry gitlab-registry \
      --docker-server="$CI_REGISTRY" \
      --docker-username="${CI_DEPLOY_USER:-$CI_REGISTRY_USER}" \
      --docker-password="${CI_DEPLOY_PASSWORD:-$CI_REGISTRY_PASSWORD}" \
      --docker-email="$GITLAB_USER_EMAIL" \
      -o yaml --dry-run | kubectl replace -n "$KUBE_NAMESPACE" --force -f -
  }


  function initialize_tiller() {
    echo "Checking Tiller..."

    export HELM_HOST="localhost:44134"
    tiller -listen ${HELM_HOST} -alsologtostderr > /dev/null 2>&1 &
    echo "Tiller is listening on ${HELM_HOST}"

    if ! helm version --debug; then
      echo "Failed to init Tiller."
      return 1
    fi
    echo ""
  }

  function build_docker() {
    echo "- KUBE_INGRESS_BASE_DOMAIN : $KUBE_INGRESS_BASE_DOMAIN"
    echo "- CI_APPLICATION_REPOSITORY : $CI_APPLICATION_REPOSITORY"

    echo "Building Dockerfile-based application..."
    docker pull $CI_REGISTRY_IMAGE:latest || true
    docker build --cache-from $CI_APPLICATION_REPOSITORY:latest --tag "$CI_APPLICATION_REPOSITORY:$CI_APPLICATION_TAG" --tag $CI_APPLICATION_REPOSITORY:latest .

    echo "Pushing to GitLab Container Registry..."
    docker push "$CI_APPLICATION_REPOSITORY:latest"
    docker push "$CI_APPLICATION_REPOSITORY:$CI_APPLICATION_TAG"
  }

  function install_dependencies() {
    apk add -U openssl curl tar gzip bash ca-certificates git
    curl -L -o /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub
    curl -L -O https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.28-r0/glibc-2.28-r0.apk
    apk add glibc-2.28-r0.apk
    rm glibc-2.28-r0.apk

    curl "https://kubernetes-helm.storage.googleapis.com/helm-v${HELM_VERSION}-linux-amd64.tar.gz" | tar zx
    mv linux-amd64/helm /usr/bin/
    mv linux-amd64/tiller /usr/bin/
    helm version --client
    tiller -version

    curl -L -o /usr/bin/kubectl "https://storage.googleapis.com/kubernetes-release/release/v${KUBERNETES_VERSION}/bin/linux/amd64/kubectl"
    chmod +x /usr/bin/kubectl
    kubectl version --client
  }

   function registry_login() {
      if [[ -n "$CI_REGISTRY_USER" ]]; then
        echo "Logging to GitLab Container Registry with CI credentials..."
        docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" "$CI_REGISTRY"
        echo ""
      fi
   }

  function deploy() {
    track="${1-stable}"
    name=$(deploy_name "$track")
    echo "KUBE_NAMESPACE: $KUBE_NAMESPACE";
    echo "Deploying new release... $CI_ENVIRONMENT_URL - $name"
    helm upgrade --install \
      --wait \
      --set image.repository="$CI_APPLICATION_REPOSITORY" \
      --set releaseOverride="$CI_ENVIRONMENT_SLUG" \
      --set image.tag="$CI_APPLICATION_TAG" \
      --set image.pullPolicy=IfNotPresent \
      --set image.secrets[0].name="gitlab-registry" \
      --set service.commonName="le.$KUBE_INGRESS_BASE_DOMAIN" \
      --set service.url="$CI_ENVIRONMENT_URL" \
      --set env.HLS_API="$HLS_API" \
      --namespace="$KUBE_NAMESPACE" \
      "$name" \
      ci/chart/
  }

  function deploy_name() {
    name="$CI_ENVIRONMENT_SLUG"
    track="${1-stable}"

    if [[ "$track" != "stable" ]]; then
      name="$name-$track"
    fi

    echo $name
  }



before_script:
  - *auto_devops
