#!/bin/bash
kubectl describe serviceaccount admin -n kube-system
kubectl describe secret admin-token-f4bb4 -n kube-system
