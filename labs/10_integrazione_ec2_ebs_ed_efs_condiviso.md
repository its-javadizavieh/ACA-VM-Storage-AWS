# Lab 10 - Integrazione EC2-EBS ed EFS Condiviso tra Istanze

## Obiettivo

- Focus operativo: collegare volumi EBS dedicati a due istanze e un file system EFS condiviso tra entrambe, verificando che un file scritto da un'istanza sia immediatamente visibile dall'altra.
- Deliverable atteso: due istanze con volume EBS dedicato, file system EFS con mount target funzionanti, evidenza di condivisione riuscita.
- Nomi di risorsa usati in questa soluzione: file system EFS `demo-efs-shared`, Security Group `demo-sg-efs`, mount point `/mnt/efs-shared`, file di test `condiviso.txt`. Volume EBS riusato da `demo-data-vol` (Lab 07) per la prima istanza.

## Prerequisiti

- Accesso attivo all'AWS Academy Learner Lab, con almeno due istanze EC2 disponibili (es. dai lab precedenti).
- AWS Management Console o AWS CLI configurata con le credenziali del Learner Lab.
- Accesso SSH alle istanze e pacchetto `amazon-efs-utils` (o NFS client) disponibile o installabile.
- Fallback previsto: se il Learner Lab non è raggiungibile, documentare l'architettura di mount (device EBS, mount target EFS per AZ) pianificata su tabella Markdown, senza creare risorse reali.

## Scenario

- Il tuo gruppo deve dare a due istanze applicative accesso a una directory di upload condivisa, mantenendo però dati privati separati su ciascuna istanza.
- Devi collegare un volume EBS dedicato a ciascuna istanza per i dati privati, e un file system EFS condiviso montato da entrambe per i dati comuni.
- Devi verificare che un file scritto da un'istanza sulla directory EFS sia immediatamente visibile dall'altra istanza.

## Step

1. Preparare due istanze **Amazon Linux 2023**, `demo-web-01` e `demo-web-02`, nella stessa VPC e in due AZ diverse, raggiungibili in SSH e con accesso ai repository dei pacchetti. Riavviare quelle conservate oppure crearle seguendo il Lab 01. Usare istanze indipendenti dall'ASG, così una sostituzione automatica non interrompe la prova.
2. In **EC2 → Volumes**, verificare per ogni istanza un volume dati `gp3` da 10 GiB nella sua AZ: riusare `demo-data-vol` sulla prima se compatibile e creare `demo-data-vol-02` per la seconda. Allegarli, individuare i device e montarli su `/mnt/demo-data` seguendo il Lab 07. Non riformattare un volume riusato.
3. Verificare nella VPC **DNS resolution** e **DNS hostnames** abilitati. In **EC2 → Security Groups → Create security group**, creare `demo-sg-efs` nella VPC delle istanze; inbound **NFS/TCP 2049**, origine il Security Group delle istanze applicative (una regola per ogni gruppo client se diversi).
4. In **EFS → Create file system**, impostare `demo-efs-shared` e la stessa VPC; scegliere un file system **Regional**, storage Standard e prestazioni **General Purpose**. Creare il file system e annotare l'ID `fs-...`.
5. Aprire **EFS → demo-efs-shared → Network → Manage**. Verificare o creare un mount target in ciascuna AZ delle due istanze, scegliendo una subnet di quella AZ. Associare `demo-sg-efs` a ogni target e rimuovere gruppi non necessari; attendere `available`.
6. In due sessioni SSH, installare `amazon-efs-utils`, creare `/mnt/efs-shared` e montare con l'ID reale usando i comandi sotto. In presenza di NACL personalizzate, verificare NFS e traffico di ritorno; ripristinare prima la NACL di test del Lab 06.
7. Verificare con `findmnt` su entrambe le istanze che il mount sia riuscito prima di scrivere: altrimenti si scriverebbe nella directory locale. Scrivere `condiviso.txt` sulla prima e leggerlo sulla seconda.
8. Confrontare la directory EFS condivisa con i due volumi EBS separati; documentare ID, AZ, mount target e output, poi eseguire il cleanup.

## Esempio di deliverable compilato

|    # | Elemento              | Evidenza sintetica                                                                        |
| ---: | --------------------- | ----------------------------------------------------------------------------------------- |
|    1 | Volumi EBS dedicati   | `demo-data-vol` (demo-web-01), volume dedicato (demo-web-02), montati su percorsi privati |
|    2 | File system EFS       | `demo-efs-shared`, modalità `generalPurpose`                                              |
|    3 | Security Group EFS    | `demo-sg-efs`, NFS (2049) solo dal SG delle istanze applicative                           |
|    4 | Mount point condiviso | `/mnt/efs-shared` su entrambe le istanze                                                  |
|    5 | Evidenza condivisione | `condiviso.txt` scritto da `demo-web-01`, letto identico da `demo-web-02`                 |

## Comandi eseguiti e output

Installazione e mount da eseguire **su entrambe le istanze Amazon Linux 2023**, nelle sessioni SSH (anche con terminale locale PowerShell). Sostituire `fs-0123456789abcdef0` con l'ID della console EFS, uguale su entrambe:

```bash
sudo dnf install -y amazon-efs-utils
sudo mkdir -p /mnt/efs-shared
LAB_EFS_ID=fs-0123456789abcdef0
sudo mount -t efs -o tls "$LAB_EFS_ID":/ /mnt/efs-shared
findmnt /mnt/efs-shared
```

Il tag `demo-efs-shared` è un nome descrittivo, non un endpoint da passare al comando di mount. Usare il File system ID e attendere i mount target disponibili ([montaggio EFS](https://docs.aws.amazon.com/en_en/efs/latest/ug/mounting-fs-mount-helper-ec2-linux.html)). Se il comando fallisce, risolvere il mount prima del test di scrittura.

Scrittura del file condiviso dalla prima istanza e lettura dalla seconda (eseguiti in due sessioni SSH separate):

**Ubuntu (bash) / macOS (zsh/bash) / Windows PowerShell (dopo accesso SSH alla EC2 Linux)**

```bash
# Su demo-web-01
echo "scritto dalla istanza 1" | sudo tee /mnt/efs-shared/condiviso.txt

# Su demo-web-02
cat /mnt/efs-shared/condiviso.txt
```

Output atteso su `demo-web-02` (identico a quanto scritto da `demo-web-01`, senza copia manuale):

```
scritto dalla istanza 1
```

Verifica dei mount target via AWS CLI:

**Ubuntu (bash) / macOS (zsh/bash)**

```bash
aws efs describe-mount-targets --file-system-id <fs-id-demo-efs-shared> \
  --query "MountTargets[].{AZ:AvailabilityZoneName,State:LifeCycleState}"
```

**Windows PowerShell**

```powershell
aws efs describe-mount-targets --file-system-id <fs-id-demo-efs-shared> `
  --query "MountTargets[].{AZ:AvailabilityZoneName,State:LifeCycleState}"
```

Output atteso (illustrativo: l'ID del file system varia a ogni creazione reale):

```
[
    {"AZ": "us-east-1a", "State": "available"},
    {"AZ": "us-east-1b", "State": "available"}
]
```

Il fatto che `cat` su `demo-web-02` restituisca esattamente il testo scritto da `demo-web-01` conferma che il file system è realmente condiviso in tempo reale, non semplicemente replicato con ritardo.

## Template operativo

```markdown
# Deliverable Lab 10

## Volumi EBS dedicati
- demo-web-01: demo-data-vol, montato su /mnt/demo-data
- demo-web-02: volume dedicato, montato su percorso privato equivalente

## File system EFS condiviso
- Nome: demo-efs-shared
- Security Group: demo-sg-efs (NFS 2049 dal SG istanze)
- Mount target: 1 per AZ, stato available
- Mount point su entrambe le istanze: /mnt/efs-shared

## Evidenza condivisione
- File scritto da demo-web-01: condiviso.txt
- Letto correttamente da demo-web-02: si

## Cleanup
- EFS smontato da entrambe le istanze: si/no
- Mount target e file system EFS eliminati: si/no
- Volumi EBS dedicati staccati/eliminati (se non più necessari): si/no
```

## Esempio sintetico

- Decisione corretta: usare EFS (non EBS) per la directory condivisa, perché i volumi EBS `gp3` usati qui si allegano a una sola istanza alla volta.
- Evidenza minima: il contenuto letto da `demo-web-02` deve corrispondere esattamente a quanto scritto da `demo-web-01`, senza alcun passaggio manuale intermedio.
- Fallback accettabile: se il Learner Lab non è raggiungibile, documentare l'architettura di mount (device EBS, mount target EFS per AZ) su tabella Markdown.
- Cleanup atteso: EFS smontato da entrambe le istanze, mount target e file system eliminati, volumi EBS dedicati rimossi se non più necessari.

## Checkpoint

- [x] Volumi EBS dedicati a ciascuna istanza, montati su percorsi distinti dai dati EFS
- [x] File system EFS con mount target funzionante in ogni Availability Zone delle istanze
- [x] Scrittura di un file da un'istanza visibile dall'altra tramite EFS, senza copia manuale
- [x] Cleanup (EFS, mount target, volumi EBS) eseguito o giustificato

## Errori comuni da evitare

- Tentare di condividere un volume EBS tra due istanze invece di usare EFS: i volumi `gp3` del lab supportano una sola istanza alla volta.
- Dimenticare il mount target in una delle Availability Zone dove si trova un'istanza: quell'istanza non riesce a montare il file system.
- Configurare il Security Group del mount target senza permettere la porta NFS (2049) dal Security Group delle istanze.
- Montare per errore due file system EFS diversi sulle due istanze, rendendo la "condivisione" solo apparente.

## Troubleshooting rapido

- Se il mount EFS fallisce con timeout, verifica che il Security Group del mount target permetta traffico NFS (porta 2049) dal Security Group delle istanze.
- Se un'istanza in una nuova Availability Zone non riesce a montare l'EFS, verifica che esista un mount target in quella specifica AZ.
- Se il volume EBS non compare come device separato, usa `lsblk` per verificare il nome effettivo assegnato dal sistema operativo.
- Se il file scritto da un'istanza non è visibile dall'altra, verifica che entrambe stiano montando lo stesso `file-system-id`, non file system EFS diversi creati per errore.

## Cleanup obbligatorio

- Esegui `sudo umount /mnt/efs-shared` su entrambe le istanze; rimuovi eventuali voci aggiunte a `/etc/fstab`.
- Elimina i mount target EFS e il file system EFS creati per il test.
- Elimina `demo-sg-efs` dopo la rimozione dei mount target. Smonta i volumi dati prima di staccarli; conserva `demo-data-vol` e il relativo snapshot per i Lab 12/14 oppure eliminali se il percorso termina qui. Ferma o termina le istanze che non servono più.
- Conferma nel deliverable che il cleanup è stato completato o indica cosa non è stato possibile rimuovere.
