###############################################################
#This script scales down all the  microservices in the cluster#
#starting from user facing, ending up with  the rest          #
###############################################################

#!/bin/bash
USER_FACING_MICRO_1=""
USER_FACING_MICRO_2=""
USER_FACING_MICRO_3=""
SYSTEM_MICRO_1=""
SYSTEM_MICRO_2=""
SYSTEM_MICRO_3=""
SYSTEM_MICRO_4=""
NAMESPACE=""
USER_FACING_MICROS=`kubectl get deployment $USER_FACING_MICRO_1 $USER_FACING_MICRO_2 $USER_FACING_MICRO_3 -n $NAMESPACE | grep -v account | awk 'FNR > 1 {print $1}'`
     echo "scaling down user facing microservices" && sleep 2


for i in ${USER_FACING_MICROS}
  do
  kubectl scale deployment $i -n $NAMESPACE --replicas=0
  done
     echo "waiting 45 seconds for USER FACING MICRO  pods to terminate  "&& sleep 45
     echo "checking if user facing microservices are down and scaling down SYSTEM MICROS" && sleep 2


for i in ${USER_FACING_MICROS}
  do
  if [[ $(kubectl -n $NAMESPACE get deploy $i  | grep -q '0/0') && ${?} -ne 0 ]]
  then
     echo "user facing microservices are not down exiting" && exit 1
  else
     echo "USER FACING MICROs are down,scaling down SYSTEM MICROS"
  fi
 done

SYSTEM_MICROS=`kubectl get deployment $SYSTEM_MICRO_1 $SYSTEM_MICRO_2 $SYSTEM_MICRO_3 $SYSTEM_MICRO_4 -n $NAMESPACE | awk 'FNR > 1 {print $1}'`
      echo "scaling down SYSTEM MICROS" && sleep 2

for i in ${SYSTEM_MICROS}
  do
  kubectl scale deployment $i -n $NAMESPACE --replicas=0
  done
     echo "waiting 45 seconds for SYSTEM MICROs  pod to terminate  "&& sleep 45
     echo checking if system micros are down and scaling down rest of the deployments && sleep 2

for i in ${SYSTEM_MICROS}
  do
  if [[ $(kubectl -n $NAMESPACE get deploy $i  | grep -q '0/0') && ${?} -ne 0 ]]
  then
     echo "system facing microservices are not down exiting" && exit 1
  else
     echo "SYSTEM MICROS are down,scalin  the rest"
  fi
 done


sleep 3

PRODUCTION_DEPLOYMENTS=`kubectl get deploy -n $NAMESPACE  | grep production | awk '{print $1}'`
for i in ${PRODUCTION_DEPLOYMENTS}
  do
  kubectl scale deployment $i -n $NAMESPACE  --replicas=0
done
