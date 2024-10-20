# Projet final: Conteneurisation et Déploiement d'un Site Web Vitrine avec Intégration CI/CD et Kubernetes.


## Objectif

Déployer une application WordPress et sa base de données MySQL dans un cluster Kubernetes, en assurant la persistance des données et l'accès via des services Kubernetes, tout en utilisant des manifests YAML.

## Étapes à suivre 

## **1) Conteneurisation de l’application web**

## **2) Partie 2 : Mise en place d'un pipeline CI/CD à l'aide de JENKINS et de ANSIBLE.



Pour créer le namespace, exécutez la commande suivante :
```bash
kubectl apply -f app-namespace.yml
```

## Conclusion 

Ce mini-projet Kubernetes nous a permis d'explorer et de comprendre le processus de déploiement d'une application complète (WordPress et MySQL) sur Kubernetes en utilisant des manifests YAML. Nous avons appris à gérer les déploiements, les services, ainsi que la persistance des données à l'aide de volumes dans Kubernetes.