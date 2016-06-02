#!/bin/bash


IMAGES=(
fabric8/fabric8-console         
fabric8/fabric8                 
fabric8/gogs                    
fabric8/fluentd-kubernetes      
fabric8/gerrit                  
fabric8/eclipse-orion           
fabric8/fabric8-java            
fabric8/nexus                   
fabric8/zookeeper               
fabric8/brackets                
fabric8/fabric8-forge           
fabric8/fabric8-hawtio-builder  
fabric8/fabric8-http-gateway    
fabric8/fabric8-jbpm-designer   
fabric8/fabric8-kiwiirc         
fabric8/fabric8-mq              
fabric8/fabric8-workflow-builder
fabric8/hubot-irc               
fabric8/hubot-slack             
fabric8/jenkins                 
fabric8/jenkins-docker          
fabric8/jenkins-jnlp-client     
fabric8/lets-chat               
)

for image in "${IMAGES[@]}"; do

   docker save -o $(echo $image | cut -f 2 -d '/').tar $image

done



