#!/bin/bash
	
cd 200-pipeline_jenkins/terraform
curl "http://$(~/terraform output | grep public_dns | awk '{print $2;exit}')" | sed -e "s/\",//g"
