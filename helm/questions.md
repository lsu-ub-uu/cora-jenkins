


# Access
Åtkomst till "infra" klustret?

# Questions
* CertManager vad används den för?
* Shibboleth config vart finns den?
* Varför finns det en koppling mellan uub och serverhallen?
* Vad är tanken med infra kluster? Varför inte alla drift applikationer finns där istället (zabbix,grafana,...)

###Argos vs Ansible
* Vi har redan Ansible, behöver vi ArgosCD?
kubectl (från jenkins), ansible, argoCD relation mellan???

## Storage
Hur skapas pv / pvc?
Kan vi "titta" på filer, t.ex. en konverterad fil för alvin, eller liknande?


//////////////////Olovs below this line... (for now)
# Access
Åtkomst till "infra" klustret?


# Running systems
Ansible, serverkonfiguration (via ssh, från egen masking, åtkomst som din ssh har rätt till):
https://git.epc.ub.uu.se/cora/drift-infra

ArgoCD, deployment: (vs ansible?)
https://argocd.cora.statsverket.org/

zabbix, övervakning:
https://zabbix.cora.statsverket.org
finns i (varför inte drift-infra) https://git.epc.ub.uu.se/cora/zabbix
Zabbix installerades som ett test via ArgoCD och alla filer finns på https://git.epc.ub.uu.se/cora/zabbix och installationen använder Zabbix helm-chart.


kubectl (från jenkins), ansible, argoCD relation mellan???


Relation mellan ArgoCD och Zabbix??

Netbox, serverdokumenttation:
http://NetboxUrl:Port/dcim/devices/?rack_id=1
(ligger i "infra" kluster)


Vad avgör om det ligger i det stora klustret eller i infraklustret???

# Questions
Varför finns det en koppling mellan uub och serverhallen?

## Storage
Hur skapas pv?
Kan vi "titta" på filer, t.ex. en konverterad fil för alvin, eller liknande?