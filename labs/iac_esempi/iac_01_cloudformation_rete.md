# Esempio integrativo IaC 01 - Dalle subnet manuali a CloudFormation

## Obiettivo

Ricostruire con un template la rete studiata nei **Lab 04 e 05 di VM, Reti e Storage con AWS**: una VPC, una subnet pubblica, una privata e le rispettive tabelle di routing. Esercizio di raccordo con il corso IaC, durata indicativa **60–75 minuti**.

Al termine devi saper spiegare `Parameters`, `Resources`, `Outputs`, `Ref`, dipendenze implicite, `DependsOn` e un Change Set. La soluzione completa è in [rete.yaml](iac_esempi/cloudformation/rete.yaml); prova prima gli esercizi di lettura e usa il file per confrontare il risultato.

## Prerequisiti e limiti

- Conoscere CIDR, subnet e routing dai Lab 04/05; aver seguito l'introduzione a CloudFormation del corso IaC.
- Learner Lab avviato e console in `us-east-1`, oppure `us-west-2`. Il template seleziona un'AZ della regione corrente.
- Per il percorso CLI: AWS CLI installata e credenziali temporanee valide, incluso il **session token**. `aws sts get-caller-identity` deve restituire l'account del Learner Lab.
- Per il controllo locale facoltativo: `cfn-lint` installato nell'ambiente Python scelto.

Il template crea risorse nuove e indipendenti dai lab precedenti. Usa `10.50.0.0/16` e non modifica `demo-vpc`. Non crea istanze EC2, NAT Gateway, Elastic IP, ruoli IAM o risorse di monitoring dell'Academy. Non ci sono costi orari di istanze o NAT in questo esercizio; eventuali estensioni hanno costi propri.

La compatibilità è stata confrontata con `AWS Academy Learner Lab lab.policy` e `AWS Academy Learner Lab lab.template`: `cloudformation:*` ed `ec2:*` sono autorizzati nelle regioni indicate. Eventuali limiti aggiuntivi dell'account o quote VPC possono comunque impedire un deploy. Vedi [note per il docente e matrice dei permessi](iac_esempi/README.md).

## Scenario

Un collega deve ricreare la rete del tuo progetto senza ripetere tutti i clic. Devi consegnargli un file, due parametri e una procedura verificabile.

| Elemento         | Risultato atteso                                           |
| ---------------- | ---------------------------------------------------------- |
| VPC              | `10.50.0.0/16`, DNS abilitato                              |
| Subnet pubblica  | `10.50.1.0/24`, tabella dedicata con `0.0.0.0/0 → IGW`     |
| Subnet privata   | `10.50.2.0/24`, tabella dedicata con sola rotta locale     |
| Internet Gateway | Collegato alla VPC                                         |
| Tag              | `Name`, `Owner`, `Project` sulle risorse che li supportano |

La subnet privata **non ha uscita Internet** in questa versione. Per aggiungerla servirebbe, ad esempio, un NAT Gateway nella subnet pubblica e una rotta privata verso di esso: è un'estensione da progettare, non necessaria per completare il lab.

## Step 1 - Prima il ragionamento

Senza lanciare il template, rispondi:

1. Quale rotta rende pubblica la prima subnet?
2. `MapPublicIpOnLaunch: true` basterebbe senza quella rotta?
3. Perché entrambe le subnet hanno un'associazione esplicita alla propria route table?
4. Da quale risorsa dipende la creazione della rotta verso IGW?
5. Quali risorse del Lab 05 mancano e quale funzionalità manca di conseguenza?

## Step 2 - Leggere e validare la soluzione

Apri [rete.yaml](iac_esempi/cloudformation/rete.yaml) e identifica:

- `StudentId` e `Owner`: input validati; `StudentId` accetta 3–12 caratteri minuscoli, numeri e trattini, iniziando con una lettera.
- `VpcId: !Ref LabVpc`: il riferimento collega le risorse e introduce una dipendenza implicita.
- `PublicDefaultRoute.DependsOn: GatewayAttachment`: la rotta deve attendere anche il collegamento dell'IGW alla VPC, oltre alla creazione degli ID che referenzia.
- `Outputs`: ID reali da usare nelle verifiche, senza copiarli a mano nel template.

Apri il terminale nella cartella **`iac_esempi/cloudformation`**. I seguenti comandi su una riga funzionano su **Ubuntu/bash, macOS/zsh e Windows PowerShell**:

```bash
aws --version

aws sts get-caller-identity --region us-east-1

aws cloudformation validate-template --region us-east-1 --template-body file://rete.yaml
```

`validate-template` chiama AWS e non garantisce che il deploy riesca. Per controllare localmente anche proprietà e riferimenti:

```bash
cfn-lint -t rete.yaml -r us-east-1 us-west-2
```

Se lavori in `us-west-2`, usa quella regione anche nei comandi successivi. Non salvare credenziali nel template o nel repository.

## Step 3 - Creare prima il Change Set

Percorso console: **CloudFormation → Create stack → With new resources → Upload a template file**. Carica `rete.yaml`, assegna un nome come `iac-rete-rossi01`, valorizza i parametri e crea il Change Set dalla schermata finale, prima di eseguirlo. Leggi l'elenco delle risorse previste.

Percorso CLI equivalente, dalla cartella del template. Sostituisci `rossi01` e `Mario-Rossi` con i tuoi valori; mantieni lo stesso nome stack in tutti i comandi:

```bash
aws cloudformation create-change-set --region us-east-1 --stack-name iac-rete-rossi01 --change-set-name prima-creazione --change-set-type CREATE --template-body file://rete.yaml --parameters ParameterKey=StudentId,ParameterValue=rossi01 ParameterKey=Owner,ParameterValue=Mario-Rossi

aws cloudformation wait change-set-create-complete --region us-east-1 --stack-name iac-rete-rossi01 --change-set-name prima-creazione

aws cloudformation describe-change-set --region us-east-1 --stack-name iac-rete-rossi01 --change-set-name prima-creazione --query "Changes[].ResourceChange.{Action:Action,LogicalId:LogicalResourceId,Type:ResourceType}" --output table
```

Risultato atteso: **10 risorse da aggiungere**. Lo stack può essere `REVIEW_IN_PROGRESS`: la rete non è ancora stata creata. Non servono `CAPABILITY_IAM`, un nuovo ruolo IAM o modifiche a `LabRole`; nei comandi non è impostato un service role.

Solo dopo aver letto il piano:

```bash
aws cloudformation execute-change-set --region us-east-1 --stack-name iac-rete-rossi01 --change-set-name prima-creazione

aws cloudformation wait stack-create-complete --region us-east-1 --stack-name iac-rete-rossi01

aws cloudformation describe-stacks --region us-east-1 --stack-name iac-rete-rossi01 --query "Stacks[0].Outputs" --output table
```

Controlla **Events**, **Resources** e **Outputs** nella console. Dieci risorse dichiarate non significano dieci oggetti totali visibili: AWS crea anche componenti predefiniti della VPC, ad esempio la main route table.

## Step 4 - Verificare il significato della rete

In **VPC → Subnets**, apri le subnet tramite gli ID degli Outputs e controlla **Route table**:

- pubblica: `10.50.0.0/16 → local` e `0.0.0.0/0 → igw-...`;
- privata: `10.50.0.0/16 → local`, senza rotta predefinita Internet.

Per una verifica CLI, sostituisci la stringa `VPC_ID_REALE` con l'Output `VpcId`:

```bash
aws ec2 describe-route-tables --region us-east-1 --filters Name=vpc-id,Values=VPC_ID_REALE --query "RouteTables[].{Id:RouteTableId,Routes:Routes,Associations:Associations}" --output json
```

La presenza di IGW e rotte non dimostra una connessione HTTP: qui non abbiamo avviato nessun server. Spiega quali altri elementi servirebbero, inclusi IP pubblico e regole di rete adeguate.

## Step 5 - Modificare un parametro, leggere il diff

In console scegli **Create change set for current stack → Use current template**. Mantieni `StudentId` e cambia solo `Owner`, per esempio da `Mario-Rossi` a `Mario-Rossi-rete`.

1. Leggi il Change Set: attese modifiche ai tag, senza sostituzione della VPC o delle subnet.
2. Verifica `Replacement` e gli ID prima di eseguire.
3. Esegui e attendi `UPDATE_COMPLETE`.
4. Confronta gli ID: devono essere rimasti uguali. Controlla i tag aggiornati.

Non cambiare CIDR o logical ID per questo test: quelle modifiche possono richiedere sostituzioni. Uno stesso template con parametri identici può produrre un Change Set senza modifiche, non una seconda rete.

## Step 6 - Drift, senza equivoci

Esegui **Stack actions → Detect drift**, attendi e apri i risultati. Su una rete appena creata, senza modifiche manuali, il risultato atteso per le risorse supportate è `IN_SYNC`.

Bonus: cambia dalla console **solo il tag Owner della VPC** in `test-drift`, poi ripeti il rilevamento. Individua il valore atteso e quello effettivo. Per chiudere questa prova, ripristina il valore atteso del tag e rileva di nuovo il drift, documentando la correzione.

Il rilevamento **non corregge** automaticamente le differenze. Non assumere che ripresentare un template identico forzi la riconciliazione: un aggiornamento senza cambiamenti può non intervenire sulla risorsa. Un intervento tramite codice deve prevedere una modifica esplicita e un nuovo Change Set da verificare. [Comportamento documentato del drift CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-stack-drift.html).

## Cleanup obbligatorio

Elimina soltanto lo stack creato in questo esercizio; non eliminare lo stack di provisioning dell'Academy.

```bash
aws cloudformation delete-stack --region us-east-1 --stack-name iac-rete-rossi01
aws cloudformation wait stack-delete-complete --region us-east-1 --stack-name iac-rete-rossi01
```

Verifica che la VPC dell'esercizio non esista più. Se la cancellazione fallisce, leggi **Events**: risorse aggiunte manualmente alla VPC possono bloccarla. Non avendo creato oggetti esterni né usato `Retain`, il solo template deve poter essere smontato come stack.

## Deliverable e soluzione ragionata

Consegna il template, uno screenshot del Change Set iniziale, gli Outputs, le rotte e cinque risposte brevi:

| Domanda iniziale               | Risposta attesa                                                                      |
| ------------------------------ | ------------------------------------------------------------------------------------ |
| Cosa rende pubblica la subnet? | La rotta predefinita verso IGW nella tabella associata                               |
| Basta assegnare IP pubblici?   | No: servono anche route e configurazione di accesso adeguate                         |
| Perché due associazioni?       | Rendono esplicita la separazione dei percorsi e non dipendono dalla main route table |
| Perché `DependsOn`?            | L'IGW deve essere collegato alla VPC prima di creare la rotta                        |
| Cosa manca rispetto al Lab 05? | NAT per uscita dalla privata e bastion/istanze per la prova SSH                      |

Annota anche modifica dei tag, ID invariati e cleanup riuscito. Se manca accesso AWS, consegna il controllo locale e una lettura del template: indica **deploy non eseguito**, senza inventare ID o screenshot.

## Errori comuni

- **AccessDenied:** verifica account, session token e regione; non creare ruoli per aggirare i limiti.
- **VpcLimitExceeded:** hai raggiunto la quota; non cancellare VPC estranee al tuo esercizio.
- **Change Set failed/no changes:** controlla se hai davvero modificato un parametro; non implica che la rete sia guasta.
- **CREATE_FAILED:** leggi il primo errore di risorsa negli Events prima degli errori di rollback.

Riferimento per il collegamento fra rotta e gateway: [AWS::EC2::Route](https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-resource-ec2-route.html).
