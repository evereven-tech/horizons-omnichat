#!/bin/bash

set -e    # Exit on error
#set -x    # Print commands before executing them (helpful for debugging)

# 1. Obtener el ARN de la última task definition                                                                                                                                       
 TASK_ARN=$(aws ecs list-task-definitions --family-prefix horizons-compute-ollama --sort DESC --max-items 1 --query 'taskDefinitionArns[0]' --output text)                              
                                                                                                                                                                                        
 # 2. Obtener los atributos requeridos por la tarea                                                                                                                                     
 TASK_ATTRS=$(aws ecs describe-task-definition --task-definition $TASK_ARN --query 'taskDefinition.requiresAttributes[].name' --output json)                                            
                                                                                                                                                                                        
 # 3. Obtener los atributos de la instancia (corregido)                                                                                                                                 
 INSTANCE_ATTRS=$(aws ecs describe-container-instances \
    --cluster horizons-compute-ec2 \
   --container-instances 8c1155e7347e4a38baaa81c16c33acc8 \
   --query 'containerInstances[].attributes[].name' \
   --output json)                                                                                                        
                                                                                                                                                                                        
 # 4. Mostrar los resultados                                                                                                                                                            
 echo "Task Definition ARN: $TASK_ARN"                                                                                                                                                  
 echo -e "\nAtributos requeridos por la tarea:"                                                                                                                                         
 echo $TASK_ATTRS | jq '.'                                                                                                                                                              
 echo -e "\nAtributos de la instancia:"                                                                                                                                                 
 echo $INSTANCE_ATTRS | jq '.'                                                                                                                                                          
                                                                                                                                                                                        
 # 5. Comparar y mostrar los que faltan                                                                                                                                                 
 echo -e "\nAtributos requeridos por la tarea pero no presentes en la instancia:"                                                                                                       
 echo $TASK_ATTRS | jq -c '.[]' | while read -r attr; do                                                                                                                                
     if ! echo $INSTANCE_ATTRS | jq -e "contains([$attr])" > /dev/null; then                                                                                                            
         echo "- $attr"                                                                                                                                                                 
     fi                                                                                                                                                                                 
 done